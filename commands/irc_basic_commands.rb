# part <#channel> - ask bot to leave #channel
Scarlet.hear /(?:leave|part)\s(\#\S+)(?:\s(.+))?/i, :dev do
  send_data "PART #{params[1]} #{params[2]}"
end
# join <#channel>[,<#channel>,<#channel>] - ask bot to join #channel or channels
Scarlet.hear /join\s(.+)/i do
  params[1].gsub(' ','').split(',').each do |channel_name|
    channel_name = ?# + channel_name unless channel_name.start_with? ?#
    send_data "JOIN #{channel_name}"
  end
end
# send <string> - send data to the server
#Scarlet.hear /send\s(.+)/i, :dev do
#  send_data params[1]
#end
# privmsg <#channel|user> <string> - msg to #channel or user
Scarlet.hear /privmsg\s(\S+)\s(.+)/i, :dev do
  send_data "PRIVMSG #{params[1]} #{params[2]}"
end
# notice <#channel|user> <string> - send notice to @channel or user
Scarlet.hear /notice\s(\S+)\s(.+)/i, :dev do
  send_data "NOTICE #{params[1]} #{params[2]}"
end
# cycle <#channel> - leave and rejoin #channel 
Scarlet.hear /cycle(?:\s(\S+))?/i, :dev do
  if params[1]
    send_data "CYCLE #{params[1]}"
  else
    server.channels.keys.each do |n| send_data "CYCLE #{n}" end
  end
end