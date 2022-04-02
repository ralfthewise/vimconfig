require 'logger'
require 'net/http'
require 'json'
require 'uri'
require 'open3'
require 'shellwords'
require 'pathname'
require_relative '../completion_entry'
require_relative 'base_completer'

module Juggler::Completers
  class LspCompleter < BaseCompleter
    MSG_INITIALIZE = {
      textDocument: {
        synchronization: {
          didSave: true,
        },
        definition: {
          dynamicRegistration: false,
          linkSupport: false,
        },
        references: {
          dynamicRegistration: false,
        },
      }
    }.freeze

    def initialize(root_path:, cmd: nil, host: nil, port: 7658, logger: Logger.new($stdout, level: Logger::INFO))
      raise 'At least one of `cmd` or `host` must be specified' if cmd.nil? && host.nil?

      @root_path = Pathname.new(File.expand_path(root_path))
      @logger = logger

      @msg_id = 0
      @version_id = 0

      @initialized_mutex = Mutex.new
      parent_thread = Thread.current

      Thread.new do
        @initialized_mutex.lock
        launch(parent_thread, cmd, host, port)
      end
      Thread.stop
    end

    def wait_until_initialized
      if @initialized_mutex.locked? && !@initialized_mutex.owned?
        @logger.info { 'Waiting for LSP connection to be initialized' }
        @initialized_mutex.lock
        @initialized_mutex.unlock
      end
    end

    def read_and_log(tag, pipe)
      while(line = pipe.gets) do
        @logger.info { "LSP Server #{tag}: #{line}" }
      end
    end

    def launch(parent_thread, cmd, host, port)
      if !cmd.nil?
        # sanitized_cmd = "env -i - HOME=#{Shellwords.escape(ENV['HOME'])} bash -l -c #{Shellwords.escape('bundle exec solargraph stdio')}"
        sanitized_cmd = "env -i - HOME=#{Shellwords.escape(ENV['HOME'])} #{cmd}"
        @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(sanitized_cmd)
        @stderr_thr = Thread.new { read_and_log('STDERR', @stderr) }
        @send_socket = @stdin
        @receive_socket = @stdout
        @child_pid = @wait_thr[:pid]
        @logger.info { "LSP server started (PID: #{@child_pid}) with cmd: #{sanitized_cmd}" }
      end

      parent_thread.wakeup

      if !host.nil?
        try_until = Time.now + 5 # try for 5 seconds
        while Time.now < try_until do
          begin
            s = TCPSocket.open(host, 7658)
            @send_socket = s
            @receive_socket = s
            @logger.info { "Connected to LSP server at tcp://#{host}:#{port}" }
            break
          rescue Errno::ECONNREFUSED
            @logger.info { "LSP server refused connection at tcp://#{host}:#{port}" }
            sleep(0.5)
          end
        end
        @stdout_thr = Thread.new { read_and_log('STDOUT', @stdout) } if !cmd.nil?
      end

      msg = {
        initializationOptions: {},
        rootUri: "file://#{@root_path}",
        rootPath: @root_path,
        capabilities: MSG_INITIALIZE,
        processId: nil,
      }
      send_msg('initialize', msg)
      receive_msg
      send_msg('initialized', {})
      receive_msg
      @logger.info { 'LSP connection initialized' }
      @initialized_mutex.unlock
    end

    def dump
      loop do
        print @receive_socket.readpartial(65536)
        # print @receive_socket.read(1)
      end
    rescue EOFError
    end

    def close
      send_msg('shutdown', nil)
      receive_msg
      send_msg('exit', nil)

      # @stdin.close
      # @stdout.close
      # @stderr.close
      @stdout_thr&.join
      @stderr_thr&.join
      @wait_thr.value

    end

    def file_opened(absolute_path)
      open_file(absolute_path)
    end

    def open_file(path)
      absolute_path = File.expand_path(path)
      msg = {
        textDocument: {
          uri: "file://#{absolute_path}",
          languageId: 'ruby',
          version: (@version_id += 1),
          text: File.read(absolute_path),
        },
      }
      send_msg('textDocument/didOpen', msg)
      receive_msg
    end

    # `line` and `col` should be zero-based
    def definition(path, line, col)
      absolute_path = File.expand_path(path)
      msg = {
        textDocument: {
          uri: "file://#{absolute_path}",
        },
        position: {
          line: line,
          character: col,
        },
      }
      send_msg('textDocument/definition', msg)
      receive_msg
    end

    def show_references(path, line, col)
      # [{"uri"=>"file:///home/tim/dev/vimconfig/bundle/juggler/autoload/test.rb", "range"=>{"start"=>{"line"=>16, "character"=>11}, "end"=>{"line"=>16, "character"=>26}}}, ...]
      result = find_references(path, line, col)
      result.map do |entry|
        path = Pathname.new(entry['uri'][7..-1]).relative_path_from(@root_path)
        {file: path.to_s, line: entry['range']['start']['line'] + 1}
      end
    end

    def find_references(path, line, col)
      absolute_path = File.expand_path(path)
      msg = {
        context: { includeDeclaration: true },
        textDocument: { uri: "file://#{absolute_path}" },
        position: { line: line, character: col },
      }
      send_msg('textDocument/references', msg)
      receive_msg
    end

    def send_msg(method, params)
      wait_until_initialized
      msg = {jsonrpc: '2.0', id: (@msg_id += 1), method: method, params: params}.to_json
      wrapped = "Content-Length: #{msg.size}\r\n\r\n#{msg}"
      @logger.debug { "Sending message:\n#{wrapped}" }
      @send_socket.write(wrapped)
    end

    def receive_msg
      headers = ''
      content_length = nil
      while (line = @receive_socket.gets)
        headers += line
        if line.downcase.include?('content-length:')
          content_length = /\d+/.match(line)[0].to_i
        end

        break if line == "\r\n"
      end
      raise 'No "Content-Length" header received' if content_length.nil?

      json = @receive_socket.read(content_length)
      @logger.debug { "Received message:\n#{headers}#{json}" }
      msg = JSON.parse(json)
      msg['result']
    end
  end
end
