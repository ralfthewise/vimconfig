require 'logger'
require 'net/http'
require 'json'
require 'uri'
require 'open3'
require 'shellwords'
require 'pathname'
require 'stringio'
require_relative '../completion_entry'
require_relative 'base'

module Juggler::Plugins
  class Lsp < Base
    @shared_across_filetypes = false

    MSG_INITIALIZE = {
      textDocument: {
        synchronization: {
          didSave: true,
        },
        definition: {
          dynamicRegistration: false,
          linkSupport: false,
        },
        completion: {
          dynamicRegistration: false,
        },
        references: {
          dynamicRegistration: false,
        },
      },
    }.freeze
    # MSG_INITIALIZE = JSON.parse('{"processId":27197,"clientInfo":{"name":"Visual Studio Code","version":"1.79.2"},"locale":"en-us","rootPath":"/home/tim/dev/lsp-test","rootUri":"file:///home/tim/dev/lsp-test","capabilities":{"workspace":{"applyEdit":true,"workspaceEdit":{"documentChanges":true,"resourceOperations":["create","rename","delete"],"failureHandling":"textOnlyTransactional","normalizesLineEndings":true,"changeAnnotationSupport":{"groupsOnLabel":true}},"didChangeConfiguration":{"dynamicRegistration":true},"didChangeWatchedFiles":{"dynamicRegistration":true},"symbol":{"dynamicRegistration":true,"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]},"tagSupport":{"valueSet":[1]}},"codeLens":{"refreshSupport":true},"executeCommand":{"dynamicRegistration":true},"configuration":true,"workspaceFolders":true,"semanticTokens":{"refreshSupport":true},"fileOperations":{"dynamicRegistration":true,"didCreate":true,"didRename":true,"didDelete":true,"willCreate":true,"willRename":true,"willDelete":true}},"textDocument":{"publishDiagnostics":{"relatedInformation":true,"versionSupport":false,"tagSupport":{"valueSet":[1,2]},"codeDescriptionSupport":true,"dataSupport":true},"synchronization":{"dynamicRegistration":true,"willSave":true,"willSaveWaitUntil":true,"didSave":true},"completion":{"dynamicRegistration":true,"contextSupport":true,"completionItem":{"snippetSupport":true,"commitCharactersSupport":true,"documentationFormat":["markdown","plaintext"],"deprecatedSupport":true,"preselectSupport":true,"tagSupport":{"valueSet":[1]},"insertReplaceSupport":true,"resolveSupport":{"properties":["documentation","detail","additionalTextEdits"]},"insertTextModeSupport":{"valueSet":[1,2]}},"completionItemKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]}},"hover":{"dynamicRegistration":true,"contentFormat":["markdown","plaintext"]},"signatureHelp":{"dynamicRegistration":true,"signatureInformation":{"documentationFormat":["markdown","plaintext"],"parameterInformation":{"labelOffsetSupport":true},"activeParameterSupport":true},"contextSupport":true},"definition":{"dynamicRegistration":true,"linkSupport":true},"references":{"dynamicRegistration":true},"documentHighlight":{"dynamicRegistration":true},"documentSymbol":{"dynamicRegistration":true,"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]},"hierarchicalDocumentSymbolSupport":true,"tagSupport":{"valueSet":[1]},"labelSupport":true},"codeAction":{"dynamicRegistration":true,"isPreferredSupport":true,"disabledSupport":true,"dataSupport":true,"resolveSupport":{"properties":["edit"]},"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["","quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"honorsChangeAnnotations":false},"codeLens":{"dynamicRegistration":true},"formatting":{"dynamicRegistration":true},"rangeFormatting":{"dynamicRegistration":true},"onTypeFormatting":{"dynamicRegistration":true},"rename":{"dynamicRegistration":true,"prepareSupport":true,"prepareSupportDefaultBehavior":1,"honorsChangeAnnotations":true},"documentLink":{"dynamicRegistration":true,"tooltipSupport":true},"typeDefinition":{"dynamicRegistration":true,"linkSupport":true},"implementation":{"dynamicRegistration":true,"linkSupport":true},"colorProvider":{"dynamicRegistration":true},"foldingRange":{"dynamicRegistration":true,"rangeLimit":5000,"lineFoldingOnly":true},"declaration":{"dynamicRegistration":true,"linkSupport":true},"selectionRange":{"dynamicRegistration":true},"callHierarchy":{"dynamicRegistration":true},"semanticTokens":{"dynamicRegistration":true,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator"],"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"formats":["relative"],"requests":{"range":true,"full":{"delta":true}},"multilineTokenSupport":false,"overlappingTokenSupport":false},"linkedEditingRange":{"dynamicRegistration":true}},"window":{"showMessage":{"messageActionItem":{"additionalPropertiesSupport":true}},"showDocument":{"support":true},"workDoneProgress":true},"general":{"regularExpressions":{"engine":"ECMAScript","version":"ES2020"},"markdown":{"parser":"marked","version":"1.1.0"}}},"initializationOptions":{"enablePages":true,"viewsPath":"/home/tim/.vscode/extensions/castwide.solargraph-0.24.0/views","transport":"external","externalServer":{"host":"localhost","port":7658},"commandPath":"solargraph","useBundler":false,"bundlerPath":"bundle","checkGemVersion":true,"completion":true,"hover":true,"diagnostics":false,"autoformat":false,"formatting":false,"symbols":true,"definitions":true,"rename":true,"references":true,"folding":true,"logLevel":"warn"},"trace":"off","workspaceFolders":[{"uri":"file:///home/tim/dev/lsp-test","name":"lsp-test"}]}')

    def initialize(project_dir:, current_file:, cmd: nil, host: nil, port: 7658, **opts)
      super

      raise "#{self.class} - At least one of `cmd` or `host` must be specified" if cmd.nil? && host.nil?

      # TODO: this is very ruby specific, needs to be moved somewhere else
      # If a Gemfile exists in our current dir consider that to be the project dir
      # project_dir = Dir.getwd if File.file?(File.join(Dir.getwd, 'Gemfile')) || File.file?(File.join(Dir.getwd, '.solargraph.yml'))
      glob = ['Gemfile', 'Gemfile.lock', '.solargraph.yml'] # Files to look for
      project_dir = Juggler.walk_tree_looking_for_files(File.expand_path('..', current_file), glob: glob) || project_dir

      @sent_file_versions = Hash.new(0)
      @root_path = Pathname.new(File.expand_path(project_dir))

      @msg_id = 0
      @version_id = 0

      @initialized_mutex = Mutex.new
      parent_thread = Thread.current

      Thread.new do
        @initialized_mutex.lock
        launch(parent_thread, cmd, host, port)
      end
      Thread.stop # Call this to ensure we switch to the other thread and give the language server a chance to startup before we continue
    end

    def wait_until_initialized
      return unless @initialized_mutex.locked? && !@initialized_mutex.owned?

      logger.info {'Waiting for LSP connection to be initialized'}
      @initialized_mutex.lock
      @initialized_mutex.unlock
    end

    def read_and_log(tag, pipe)
      while (line = pipe.gets) do
        logger.info {"LSP Server #{tag}: #{line}"}
      end
    end

    def launch(parent_thread, cmd, host, port)
      if !cmd.nil?
        sanitized_cmd = "env -i - HOME=#{Shellwords.escape(ENV['HOME'])} bash -l -c #{Shellwords.escape(cmd)}"
        # sanitized_cmd = "env -i - HOME=#{Shellwords.escape(ENV['HOME'])} #{cmd}"
        Dir.chdir(@root_path) do
          logger.info {"Launching LSP server in #{File.expand_path(Dir.getwd)}: #{sanitized_cmd}"}
          @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(sanitized_cmd)
        end
        @stderr_thr = Thread.new {read_and_log('STDERR', @stderr)}
        @send_socket = @stdin
        @receive_socket = @stdout
        @child_pid = @wait_thr[:pid]
        logger.info {"LSP server started (PID: #{@child_pid})"}
      end

      parent_thread.wakeup

      if !host.nil?
        try_until = Time.now + 5 # try for 5 seconds
        while Time.now < try_until do
          begin
            s = TCPSocket.open(host, 7658)
            @send_socket = s
            @receive_socket = s
            logger.info {"Connected to LSP server at tcp://#{host}:#{port}"}
            break
          rescue Errno::ECONNREFUSED
            logger.info {"LSP server refused connection at tcp://#{host}:#{port}"}
            sleep(0.5)
          end
        end
        @stdout_thr = Thread.new {read_and_log('STDOUT', @stdout)} if !cmd.nil?
      end

      msg = {
        initializationOptions: {},
        rootUri: "file://#{@root_path}",
        rootPath: @root_path,
        capabilities: MSG_INITIALIZE,
        processId: nil,
      }
      send_msg('initialize', msg)
      receive_msgs
      send_msg('initialized', {})
      receive_msgs
      logger.info {'LSP connection initialized'}
      @initialized_mutex.unlock
    end

    def dump
      loop do
        print @receive_socket.readpartial(65_536)
        # print @receive_socket.read(1)
      end
    rescue EOFError
      # EOFError indicates we're terminating
    end

    def close
      send_msg('shutdown', nil)
      receive_msgs
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
          version: msg_version,
          text: File.read(absolute_path),
        },
      }
      send_msg('textDocument/didOpen', msg)
      receive_msgs
      # send_msg('textDocument/foldingRange', { textDocument: { uri: "file://#{absolute_path}" } })
      # receive_msgs
      # send_msg('textDocument/documentSymbol', { textDocument: { uri: "file://#{absolute_path}" } })
      # receive_msgs
    end

    def buffer_left_hook(absolute_path)
      send_changes_if_needed(absolute_path)
    end

    def send_changes_if_needed(path)
      absolute_path = File.expand_path(path)
      return unless Juggler::Completer.instance.file_contents.file_modified?(absolute_path, @sent_file_versions[absolute_path])

      did_change(absolute_path)
    end

    def did_change(absolute_path)
      current_contents = Juggler.file_contents(absolute_path)
      msg = {
        textDocument: {
          uri: "file://#{absolute_path}",
          version: msg_version,
        },
        contentChanges: [{text: current_contents[:contents].join("\n")}],
      }
      send_msg('textDocument/didChange', msg)
      @sent_file_versions[absolute_path] = current_contents[:version]
      receive_msgs
    end

    # Should return an array of objects with the following properties:
    #   file: path to file (relative to project root)
    #   line: line in the file (starting from 1, not 0)
    #   col: column of the line (starting from 1, not 0)
    #   desc: description to display
    # `line` and `col` should be zero-based
    def go_to_definition(path, line, col, _term)
      send_changes_if_needed(path)

      absolute_path = File.expand_path(path)
      msg = {
        textDocument: { uri: "file://#{absolute_path}" },
        position: { line: line, character: col },
      }
      send_msg('textDocument/definition', msg)
      result = receive_msgs
      result.last.map do |entry|
        logger.debug("Entry: #{entry}")
        uri = URI.parse(entry['uri'])
        full_path = URI.decode_www_form_component(uri.path)
        path = Pathname.new(full_path).relative_path_from(Dir.getwd)
        line_num = entry['range']['start']['line'] + 1 # for display we use a 1 based line
        col = entry['range']['start']['character']
        line_display = Juggler.file_contents(full_path)[:contents][line_num - 1]
        {file: path.to_s, line: line_num, col: col, desc: line_display}
      end
    end

    def show_references(path, line, col, _term)
      send_changes_if_needed(path)

      # [{"uri"=>"file:///home/tim/dev/vimconfig/bundle/juggler/autoload/test.rb", "range"=>{"start"=>{"line"=>16, "character"=>11}, "end"=>{"line"=>16, "character"=>26}}}, ...]
      result = find_references(path, line, col)
      result.map do |entry|
        full_path = entry['uri'][7..-1]
        path = Pathname.new(full_path).relative_path_from(Dir.getwd)
        line_num = entry['range']['start']['line'] + 1 # for display we use a 1 based line
        line_display = Juggler.file_contents(full_path)[:contents][line_num - 1]
        {file: path.to_s, line: line_num, tag_line: line_display}
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
      receive_msgs
    end

    # {"jsonrpc":"2.0","id":6,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///home/tim/dev/lsp-test/test.rb"},"position":{"line":1,"character":2},"context":{"triggerKind":1}}}
    def generate_completions(absolute_path, _base, cursor_info)
      send_changes_if_needed(absolute_path)
      solargraph_patch(absolute_path, cursor_info)

      msg = if cursor_info['type'] == 'omnitrigger'
              {
                textDocument: { uri: "file://#{absolute_path}" },
                position: { line: cursor_info['linenum'] - 1, character: cursor_info['cursorindex'] },
                context: { triggerKind: 2, triggerCharacter: cursor_info['trigger'][-1] },
              }
            else
              {
                textDocument: { uri: "file://#{absolute_path}" },
                position: { line: cursor_info['linenum'] - 1, character: cursor_info['cursorindex'] },
                context: { triggerKind: 1 },
              }
            end
      send_msg('textDocument/completion', msg)
      receive_msgs.last['items'].each_with_index do |item, index|
        signature = item.dig('data', 'path')
        file = item.dig('data', 'location', 'filename')
        kind = case item['kind']
               when 2 then 'method'
               when 6 then 'variable'
               end
        entry = Juggler::CompletionEntry.new(source: :lsp, tag: item['label'], index: index, file: file, kind: kind, signature: signature, info: signature)
        line = item.dig('data', 'location', 'range', 'start', 'line')
        entry.line = line + 1 unless line.nil?
        yield(entry)
      end
    end

    protected

    # solargraph has a bug where sometimes it doesn't return completions
    # properly. The simplest example would be a file with the contents:
    #   "t = Time.new\nt.\n"
    # and trigger a completion with the cursor after the last '.'. Triggering a
    # `contentChanges` message with a range param that replaces the character
    # before the cursor with the same character fixes the issue.
    def solargraph_patch(absolute_path, cursor_info)
      # First get the character right before the cursor
      current_contents = Juggler.file_contents(absolute_path)
      char = current_contents[:contents][cursor_info['linenum'] - 1][cursor_info['cursorindex'] - 1]

      msg = {
        textDocument: {
          uri: "file://#{absolute_path}",
          version: msg_version,
        },
        contentChanges: [{
          range: {start: {line: cursor_info['linenum'] - 1, character: cursor_info['cursorindex'] - 1}, end: {line: cursor_info['linenum'] - 1, character: cursor_info['cursorindex']}},
          rangeLength: 1,
          text: char,
        }],
      }
      send_msg('textDocument/didChange', msg)
      receive_msgs
    end

    def msg_version
      @version_id += 1
    end

    def send_msg(method, params)
      wait_until_initialized
      wrapped = ->(s, size) {"Content-Length: #{size}\r\n\r\n#{s}"}
      msg = JSON.pretty_generate({jsonrpc: '2.0', id: (@msg_id += 1), method: method, params: params})
      logger.debug {"Sending message:\n#{wrapped.call(Juggler::Utils::Colorize.yellow(msg), msg.size)}"}
      @send_socket.write(wrapped.call(msg, msg.size))
    end

    def receive_msgs
      IO::select([@receive_socket])
      data = ''
      begin
        loop do
          data += @receive_socket.read_nonblock(65_536)
        end
      rescue IO::WaitReadable
        logger.debug {"Received raw data:\n#{data}"}
      end

      msgs = []
      max_id_received = 0
      msg_io = StringIO.new(data)
      while (msg = receive_msg(msg_io))
        msgs << msg['result']
        max_id_received = msg['id'] if msg['id'] > max_id_received
      end

      if msgs.empty?
        logger.warn {'No messages received, trying again'}
        return receive_msgs
      end

      # Make sure we've received all messages up to and including the last `id` we sent
      msgs += receive_msgs if max_id_received < @msg_id

      msgs
    end

    def receive_msg(io)
      headers = ''
      content_length = nil
      while (line = io.gets)
        headers += line

        content_length = /\d+/.match(line)[0].to_i if line.downcase.include?('content-length:')

        if line.downcase.include?('content-length:')
          content_length = /\d+/.match(line)[0].to_i
        end

        break if line == "\r\n"
      end
      # raise 'No "Content-Length" header received' if content_length.nil?
      return nil if content_length.nil?

      json = io.read(content_length)
      msg = JSON.parse(json)
      logger.debug {"Received message:\n#{headers}#{Juggler::Utils::Colorize.green(JSON.pretty_generate(msg))}"}
      msg
    end
  end
end
