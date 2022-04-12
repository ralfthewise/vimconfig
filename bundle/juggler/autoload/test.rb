load 'juggler/plugins/lsp.rb'

c = Juggler::Plugins::Lsp.new(root_path: '.', cmd: "bash -l -c #{Shellwords.escape('bundle exec solargraph socket')}", host: '127.0.0.1', logger: Logger.new($stdout, level: Logger::DEBUG))
puts "\n\nOpening file"
c.open_file('juggler/completer.rb')
# puts c.receive_msg

puts "\n\nDefinition"
result = c.definition('juggler/completer.rb', 79, 57)
puts result.to_json


puts "\n\nReferences"
# result = c.show_references('juggler/completer.rb', 79, 57, '')
# "character":8,"line":227
# result = c.show_references('juggler/completer.rb', 227, 8, '')
result = c.show_references('test.rb', 16, 17, '')
puts result.to_json
c.close


puts "\n\nDump"
puts c.dump
