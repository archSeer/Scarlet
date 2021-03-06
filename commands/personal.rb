hear(/login/i) do
  clearance nil
  description 'Logs the user into his bot account.'
  usage 'login'
  on do
    message = "%s, you do not have an account yet. Use the register command."
    with_nick nick: sender.nick, msgfmt: message do
      if !sender.user.identified?
        server.check_ns_login sender.nick
        notify "#{sender.nick}, you have been logged in successfuly."
      else
        notify "#{sender.nick}, you are already logged in!"
      end
    end
  end
end

hear(/logout/i) do
  clearance(&:registered?)
  description 'Logs the user out from his bot account.'
  usage 'logout'
  on do
    if sender.user.identified?
      sender.user.ns_login = false
      notify "#{sender.nick}, you are now logged out."
    end
  end
end

hear(/register/i) do
  clearance nil
  description 'Registers an account with the bot.'
  usage 'register'
  on do
    if !Scarlet::Nick.first(nick: sender.nick)
      Scarlet::Nick.create(nick: sender.nick)
      notify "Successfuly registered with the bot."
    else
      notify "ERROR: You are already registered!"
    end
  end
end
