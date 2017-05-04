require 'net/imap'
require 'net/ping'

def initiate_idle(server, user, pass)
  server[:imap] = Net::IMAP.new(server[:addr], port: 993, ssl: true)
  puts 'initialization complete.'
  server[:imap].authenticate('PLAIN', user, pass)
  puts 'login complete.'
  server[:imap].examine('INBOX')
  puts 'INBOX selected.'
  server[:imap].idle do |res|
    sync if %w(EXISTS FETCH).include?(res.name)
  end
end

def close_idle
  server[:imap].idle_done
end

def sync
  `mbsync inboxes; notmuch new`
end

server = { addr: 'imap.gmail.com' }
server[:ping] = Net::Ping::External.new(server[:addr])

loop do
  if server[:ping].ping
    # sync
    # initiate_idle(server[:addr])
    puts "I'd totally be syncing right now"
    puts "I'd totally be IDLING too"
    loop do
      puts "Now I'm going to bed for 5 seconds (#{Time.now.strftime('%H:%M:%S')})"
      sleep 5
      break unless server[:ping].ping
    end
    puts "Now I'd be closing the idle connection"
    # close_idle
  else
    puts 'connection down'
    sleep 5
  end
end
