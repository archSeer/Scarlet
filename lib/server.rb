module Scarlet

  class Server
    attr_accessor :scheduler, :banned, :connection, :config, :state
    attr_reader :channels, :users, :extensions, :cap_extensions, :current_nick, :mode_list, :vHost

    def initialize config
      @config         = config
      init_vars
      @current_nick   = @config.nick
      @config[:control_char] ||= Scarlet.config.control_char
      @config.freeze
    end  

    def init_vars
      @scheduler      = Scheduler.new
      @channels       = Channels.add_server(self.name) # users on channel
      @users          = Users.add_server(self.name)    # users (seen) on the server
      @state          = :connecting
      reset_vars
    end

    def reset_vars
      @banned         = []     # who's banned here?
      @modes          = []     # bot account's modes (ix,..)
      @extensions     = {}     # what the server-side supports (PROTOCTL)
      @cap_extensions = {}     # CAPability extensions (CAP REQ)
      @vHost          = nil    # vHost/cloak
    end

    def name
      @config[:server_name]
    end

    def disconnect
      send "QUIT :#{Scarlet.config.quit}"
      @state = :disconnecting
      connection.close_connection(true)
    end

    def unbind
      Channels.clean(self.name)
      Users.clean(self.name)
      reset_vars

      reconnect = lambda {
        print_error "Connection to server lost. Reconnecting..."
        connection.reconnect(@config.address, @config.port) rescue return EM.add_timer(3) { reconnect.call }
        connection.post_init
        init_vars
      }
      EM.add_timer(3) { reconnect.call } if not @state == :disconnecting
    end

    def send data
      if data =~ /(PRIVMSG|NOTICE)\s(\S+)\s(.+)/i
        stack = []
        command, trg, text = $1, $2, $3
        length = 510 - command.length - trg.length - 2 - 120
        text.word_wrap(length).split("\n").each do |s| stack << '%s %s %s' % [command,trg,s] end
      else
        stack = [data]
      end
      stack.each {|d| connection.send_data d}
      nil
    end

    def receive_line line
      p line
      parsed_line = Parser.parse_line line
      event = Event.new(self, parsed_line[:prefix],
                        parsed_line[:command].downcase.to_sym,
                        parsed_line[:target], parsed_line[:params])
      Log.write(event)
      handle_event event
    end

    #----------------------------------------------------------
    def msg target, message
      send "PRIVMSG #{target} :#{message}"
      write_log :privmsg, message, target
    end

    def notice target, message
      send "NOTICE #{target} :#{message}"
      write_log :notice, message, target
    end

    def join *channels
      send "JOIN #{channels.join(',')}"
    end

    def write_log command, message, target
      return if target =~ /Serv$/ # if we PM a bot, i.e. for logging in, that shouldn't be logged.
      log = Log.new(:nick => @current_nick, :message => message, :command => command.upcase, :target => target)
      log.channel = target if target.starts_with? "#"
      log.save!
    end

    def print_console message, color=nil
      return unless Scarlet.config.debug
      msg = Scarlet::Parser.parse_esc_codes message
      msg = "[#{Time.now.strftime("%H:%M")}] #{msg}"
      puts color ? msg.colorize(color) : msg
    end

    def print_error message
      msg = Scarlet::Parser.parse_esc_codes message
      msg = "[#{Time.now.strftime("%H:%M")}] #{msg}"
      puts msg.colorize(:light_red)
    end

    def check_ns_login nick
      # According to the docs, those servers that use STATUS may query up to
      # 16 nicknames at once. if we pass an Array do:
      #   a) on STATUS send groups of up to 16 nicknames
      #   b) on ACC, we have no such luck, send each message separately.

      if nick.is_a? Array
        if @ircd =~ /unreal/i
          nick.each_slice(16) {|group| msg "NickServ", "STATUS #{group.join(' ')}"}
        else
          nick.each {|nickname| msg "NickServ", "ACC #{nick}"}
        end 
      else # one nick was given, send the message
        msg "NickServ", "ACC #{nick}" if @ircd =~ /ircd-seven/i # freenode
        msg "NickServ", "STATUS #{nick}" if @ircd =~ /unreal/i
      end
    end

  end
end