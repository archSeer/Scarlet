require 'scarlet/time'

hear(/uptime/i) do
  clearance nil
  description 'Displays the start time and uptime of the bot'
  usage 'uptime'
  on do
    tthen = server.started_at
    now = Time.now
    scale = (now - tthen).to_i.timescale
    reply "I started at #{fmt.time(tthen)}. My uptime is #{scale}"
  end
end

hear(/version/i) do
  clearance nil
  description 'Displays the version information.'
  usage 'version'
  on do
    str = "Scarlet v#{Scarlet::Version::STRING}"
    if commit = Scarlet::Git.data[:commit].presence
      str << " commit #{fmt.commit_sha(commit)}"
    end
    reply str
  end
end

hear(/ruby version/i) do
  clearance nil
  description 'Displays current ruby version.'
  usage 'ruby version'
  on do
    reply "#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} [#{RUBY_PLATFORM}]"
  end
end

hear(/update/) do
  clearance(&:sudo?)
  description "Restarts the bot, updating to the latest version"
  usage 'update'
  on do
    Process.harakiri 'USR2'
  end
end

hear(/reload commands/i) do
  clearance(&:sudo?)
  description 'Loads all available commands.'
  usage 'reload commands'
  on do
    if event.data[:commands].load_commands
      notify "Commands loaded."
    else
      notify "Command loading failed."
    end
  end
end

hear(/reload command\s+(\w+)/i) do
  clearance(&:sudo?)
  description 'Loads a command set from the commands directory.'
  usage 'reload command <name>'
  on do
    filename = File.basename(params[0])
    begin
      event.data[:commands].load_command_rel(filename)
      notify "Command #{filename} loaded."
    rescue => ex
      notify "Command #{filename} load error: #{ex.inspect}"
    end
  end
end

hear(/hcf/) do
  clearance(&:sudo?)
  description 'Stop, Hammer Time.'
  usage 'hcf'
  on do
    Process.harakiri 'TERM'
  end
end
