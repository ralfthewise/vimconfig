module Juggler::Plugins
  @singleton_plugins = {}

  def self.load_plugin(name, options)
    return @singleton_plugins[name] if @singleton_plugins.key?(name)

    class_name = name.split('_').collect(&:capitalize).join
    plugin_class = Object.const_get("Juggler::Plugins::#{class_name}")
    plugin = plugin_class.new(**(options.transform_keys(&:to_sym)))
    @singleton_plugins[name] = plugin if plugin_class.shared_across_filetypes
    plugin
  end
end
