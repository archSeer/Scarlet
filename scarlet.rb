# IRCBot! Currently one channel based.
# uses mustache templating and blank?
# errors - light_red, info - light_blue, success - light_green
require 'mustache'

class Hash # instead of hash[:key][:key], hash.key.key
  def method_missing(method, *params)
    return self[method.to_s] if self.keys.collect {|key| key}.include?(method.to_s)
    return self[method.to_sym] if self.keys.collect {|key| key}.include?(method.to_sym)
    super
  end
end

module Scarlet; end

base_path = File.expand_path File.dirname(__FILE__)
Modules.load_models base_path
Modules.load_libs base_path

module Scarlet
  @config = {}
  @@servers = {}
  class << self
    attr_accessor :config

    def loaded
      $config[:irc_bot] = YAML.load_file("#{File.expand_path File.dirname(__FILE__)}/config.yml").symbolize_keys!
      $config.irc_bot.modes.symbolize_values!
      @@servers[:default] = Server.new $config.irc_bot.server, $config.irc_bot.port #temp hax
      @@servers.values.each do |server|
        server.connection = EventMachine::connect(server.address, server.port, Connection, server)
      end
      puts 'IRC Bot has started.'.green
    end

    def unload
      @@servers.values.each do |server|
        server.disconnect
        server.log.close_all
        server.scheduler.remove_all
      end
    end

    def load_commands root
        Dir["#{root}/commands/**/*.rb"].each {|path| load path }
    end

    def hear regex, clearance=nil, &block
      Command.hear regex, clearance, &block
    end
  end
end

Dir["#{base_path}/commands/**/*.rb"].each {|path| 
  load path 
  Scarlet::Command.parse_help path
}