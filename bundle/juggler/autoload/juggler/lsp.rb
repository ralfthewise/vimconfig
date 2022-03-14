require 'logger'
require 'net/http'
require 'json'
require 'uri'
require 'open3'
require 'shellwords'

module Juggler
  class Lsp
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

    def initialize(logger: Logger.new($stdout, level: Logger::INFO))
      @logger = logger
      @msg_id = 0
    end

    def launch
      @stdin, @stdout, @stderr, @wait_thr = Open3.popen3("env -i - HOME=#{Shellwords.escape(ENV['HOME'])} bash -l -c #{Shellwords.escape('bundle exec solargraph stdio')}")
      @child_pid = @wait_thr[:pid]
      @logger.info { "Solargraph started with PID: #{@child_pid}" }
      @stdout.gets # FIXME: hack for my .bashrc
      send_msg('initialize', MSG_INITIALIZE)
      receive_msg
    end

    def close
      @stdin.close
      @stdout.close
      @stderr.close
      @wait_thr.value
    end

    def send_msg(method, params)
      msg = {jsonrpc: '2.0', id: (@msg_id += 1), method: method, params: params}.to_json
      wrapped = "Content-Length: #{msg.size}\r\n\r\n#{msg}"
      @logger.debug { "Sending message:\n#{wrapped}" }
      @stdin.write(wrapped)
    end

    def receive_msg
      headers = @stdout.gets
      cl = /\d+/.match(headers)[0].to_i
      headers += @stdout.gets
      json = @stdout.read(cl)
      @logger.debug { "Received message:\n#{headers}#{json}" }
      msg = JSON.parse(json)
      msg['result']
    end

    # def initialize(stdio: nil, url: nil)
    #   raise 'Either `stdio` or `url` must be specified' if stdio.nil? && url.nil?

    #   uri = URI.parse(url)
    #   @http = Net::HTTP.new(uri.host, uri.port)
    # end
  end
end
