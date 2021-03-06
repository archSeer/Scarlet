require 'scarlet/plugin'
require 'scarlet/helpers/base_helper'

module Scarlet::Plugins
  class Command
    include Scarlet::Plugin

    on :privmsg do |event|
      # if we detect a command sequence, we remove the prefix and execute it.
      # it is prefixed with config.control_char or by mentioning the bot's current nickname
      if params.first =~ /^#{event.server.current_nick}[:,]?\s*/i
        params[0] = params[0].split[1..-1].join(' ')
        process_command(event.dup)
      elsif params.first.starts_with? config.control_char
        params.first.slice!(0)
        process_command(event.dup)
      end
    end

    def initialize
      # Contains all of our listeners.
      # @return [Hash<Regexp, Listener>]
      @listeners = {}

      @loader = Scarlet::Command::Loader.new(self)
      load_commands
    end

    # Registers a new listener for bot commands.
    #
    # @param [Regexp] patterns The regex that should match when we want to trigger our callback.
    # @param [Proc] block The block to execute when the command is used.
    def hear *patterns, &block
      # make a prefab Listener
      ls = Scarlet::Command::Listener.new.tap { |l| Scarlet::Command::Builder.new(l).instance_eval(&block) }
      patterns.each do |regex|
        regex = Regexp.new "^#{regex.source}$", regex.options
        @listeners[regex] = ls
      end
    end

    # Loads a command file from the given path
    #
    # @param [String] path
    def load_command(path)
      logger.debug "Loading command: #{path}"
      @loader.load_file path
    end

    # Loads a command file from the given name.
    def load_command_rel(name)
      load_command File.join(Scarlet.root, 'commands', name)
    end

    # Loads (or reloads) commands from the /commands directory under the
    # +Scarlet.root+ path.
    def load_commands
      old_listeners = @listeners.dup
      @listeners.clear
      begin
        Dir[File.join(Scarlet.root, 'commands/**/*.rb')].each do |path|
          load_command path
        end
        true
      rescue => ex
        logger.error ex.inspect
        logger.error ex.backtrace.join("\n")
        @listeners.replace old_listeners
        false
      end
    end

    # Selects all commands which evaluate true in the block.
    #
    # @yieldparam [Listener]
    # @return [Array<Listener>]
    def select_commands
      return to_enum :select_commands unless block_given?
      @listeners.each_value.select do |l|
        yield l
      end
    end

    # Selects all commands which match the provided command string
    #
    # @param [String] command
    # @return [Array<Listener>]
    def match_commands command
      return @listeners.each_value unless command.present?
      select_commands { |c| c.usage.include? command }
    end

    # Returns help matching the specified string. If no command is used, then
    # returns the entire list of help.
    #
    # @param [String] command The keywords to search for.
    def get_help command = nil
      help = match_commands(command).map(&:help)
      # remove all blank entries,
      # make each line unique,
      # and finally sort the result.
      help.reject(&:blank?).uniq.sort
    end

    # Initialize is here abused to run a new instance of the Command.
    #
    # @param [Event] event The event that was caught by the server.
    def process_command event
      @listeners.keys.each do |key|
        listener = @listeners[key]
        key.match event.params.first do |matches|
          if check_access(event, listener.clearance)
            ev = event.dup.tap { |ev| ev.data[:commands] = self }
            listener.invoke ev, matches
          end
        end
      end
    end

    private # Make the checks private.

    # Checks whether the user actually has access to the command and can use it.
    # @param [Event] event The event that was recieved.
    # @param [Proc] clearance  proc to determine if the use passes clearance
    # @return [Boolean] True if access is allowed, else false.
    def check_access event, clearance
      ctx = self.class.context.new event
      nick = Scarlet::Nick.first nick: event.sender.nick
      return false if check_ban(event) # if the user is banned
      return true unless clearance

      user = event.server.users.get(event.sender.nick)
      if user.try(:identified?) # check login
        if !nick # check that user is registered
          ctx.reply "Registration not found, please register."
          return false
        elsif !clearance.call(nick)
          ctx.reply "Your security clearance does not grant access."
          return false
        end
      else
        ctx.reply "Test subject #{event.sender.nick} is not logged in with NickServ."
        return false
      end
      return true
    end

    # @return [Boolean] true if user is banned, else false.
    def check_ban event
      ban = Scarlet::Ban.first nick: event.sender.nick
      if ban and ban.level > 0 and ban.servers.include?(event.server.config.address)
        event.reply "#{event.sender.nick} is banned and cannot use any commands."
        return true
      end
      return false
    end
  end
end
