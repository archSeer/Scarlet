class Scarlet
  module Fmt
    # Formats a given uri suitable for the irc
    def self.uri(u)
      # Speed said that his irc client picks up ( ) as a apart of the uri, so adding some spaces
      # shouldn't hurt.
      "( #{u} )"
    end

    # Formats a Github sha value
    def self.commit_sha(sha)
      sha[0, 8].center(10, ' ').irc_color(1, 0)
    end

    # Removes excess spaces from the string
    #
    # @param [String] msg
    # @return [String]
    def self.strip_msg msg
      msg.gsub(/\s+/, ' ').strip
    end

    # Removes newlines and returns from the string
    #
    # @param [String] msg
    # @return [String]
    def self.purify_msg msg
      msg.gsub(/[\n\r]+/, ' ')
    end

    # Chops string into chunks of 450 characters or less.
    #
    # @param [String] str
    # @yieldparam [String]
    def self.chop_msg str
      return to_enum(:chop_msg, str) unless block_given?
      str.each_line do |line|
        msg = line.chomp
        next yield msg if msg.length < 450
        s = 0 # start point
        i = 0 # increment
        bp = -1 # breakpoint
        loop do
          # unless this character is a word character, treat it as a breakpoint
          unless msg[s + i] =~ /\w/
            bp = s + i
          end
          i += 1
          # has the incrementor gone over the break limit?
          if i >= 450
            # if no breakpoint was set, set it as the start position + the current run
            bp = s + i if bp == -1
            yield msg[s..bp]
            # set the start position as the last breakpoint
            s = bp
            # reset the breakpoint
            bp = -1
            # reset the incrementer
            i = 0
          # have we reached the end of the string?
          elsif (s + i) >= msg.length
            yield msg[s, msg.length]
            break
          end
        end
      end
    end

    # Formats a Date object
    #
    # @param [Date] dat
    # @return [String]
    def self.date dat
      dat.strftime("%A, %B %d, %Y")
    end

    # Formats a Time object
    #
    # @param [Time] tme
    # @return [String]
    def self.time tme
      tme.strftime("%T %Z, %A, %B %d, %Y")
    end

    # Formats a Time object, with a shortened format
    #
    # @param [Time] tme
    # @return [String]
    def self.short_time tme
      tme.strftime("%H:%M %b %-d, %Y")
    end

    # Formats a time object, in a digit format
    #
    # @param [Time] tme
    # @return [String]
    def self.digital_time tme
      tme.strftime("%H:%M %Y-%m-%d")
    end
  end
end
