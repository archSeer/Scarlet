# todo add <message> - Logs a message on the TODO tracker.
Scarlet.hear /todo add\s*(.+)/ do
  ::IrcBot::Todo.new(:msg => params[1], :by => sender.nick).save!
  reply "TODO was added."
end

# todo delete <id> - Deletes TODO with <id>.
Scarlet.hear /todo delete\s*(\d+)/, :dev do
  id = params[1].strip.to_i
  t = ::IrcBot::Todo.sort(:created_at).all[id-1].delete
  reply "TODO ##{id} was deleted."
end

# count todos - Shows the total count of TODO's.
Scarlet.hear /count todos/ do
  reply "TODO count: #{::IrcBot::Todo.all.count}"
end

# show todo <id> - Shows the message of TODO with <id>.
Scarlet.hear /show todo\s*(\d+)/ do
  id = params[1].strip.to_i
  t = ::IrcBot::Todo.sort(:created_at).all[id-1]
  if t
    crt = t.created_at.std_format
    table = ::IrcBot::ColumnTable.new(2,4)
    table.padding = 2
    table.set_row(0,0,"TODO"      ,"#%d"%id).set_row_color(1,0,0)
    table.set_row(0,1,"Date:"     ,crt     ).set_row_color(0,1,0)
    table.set_row(0,2,"By:"       ,t.by    ).set_row_color(0,1,0)
    table.set_row(0,3,"Entry:"    ,t.msg   ).set_row_color(0,1,0)
    table.compile.each { |line| reply line, true }
  else
    reply "TODO ##{id} could not be found."
  end
end

# list todos - Displays a list with the latest 10 TODO's.
Scarlet.hear /list todos/ do
  c = ::IrcBot::Todo.all.count
  if c > 0
    table = ::IrcBot::InfoTable.new(50)
    table.addHeader "Last 10 entries:"
    ::IrcBot::Todo.sort(:created_at.desc).limit(10).each_with_index { |t, i|
      break if i == 10 
      table.addRow "##{c-i}\t#{t.by}\t\t#{t.created_at.std_format}"
    }
    table.compile.each {|line| reply line, true }
  else
    reply "No entries found."
  end
end