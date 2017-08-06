module LittleRedFlag
  module MailAgent
    class Mbsync
      module Properties
        IMAPAccount = Struct.new(:label, :host, :port, :user, :pass, :passcmd,
                                 :tunnel, :authmechs, :ssltype, :sslversions,
                                 :systemcertificates, :certificatefile,
                                 :pipelinedepth, :connections) do

          def connect
            until Ping.new(host).ping
              10.downto(1) do |i|
                printf "#{host} unreachable. Trying again in #{i}s... \r"
                sleep 1
              end
              puts "#{host} unreachable. Trying again...          "
            end
            imap = Net::IMAP.new(host, port: port, ssl: (ssltype && (ssltype.downcase == 'imaps')))
            @auth ||= %w(LOGIN PLAIN) & imap.capability
                                            .select { |cap| cap['AUTH='] }
                                            .map { |auth| auth.sub('AUTH=','').upcase }
            imap.authenticate(@auth.first, user, pass || `#{passcmd.unescape}`.chomp)
            imap
          end
        end

        IMAPStore = Struct.new(:label, :path, :maxsize, :mapinbox, :flatten,
                               :trash, :trashnewonly, :trashremotenew,
                               :account, :usenamespace, :pathdelimiter,
                               :path_of, :inbox)

        Maildirstore = Struct.new(:label, :path, :maxsize, :mapinbox,
                                  :flatten, :trash, :trashnewonly,
                                  :trashremotenew, :altmap, :inbox,
                                  :infodelimiter, :path_of)

        Group = Struct.new(:label, :channels, :inboxes)

        Channel = Struct.new(:label, :master, :slave, :patterns, :maxsize,
                             :maxmessages, :expireunread, :sync, :create,
                             :remove, :expunge, :copyarrivaldate, :syncstate,
                             :localstore, :remotestore, :inboxes) do
          def localpath
            localstore.path_of[label.to_sym]
          end

          def localpath=(path)
            localstore.path_of ||= {}
            localstore.path_of[label.to_sym] = path
          end

          def remotepath
            remotestore.path_of[label.to_sym]
          end

          def remotepath=(path)
            remotestore.path_of ||= {}
            remotestore.path_of[label.to_sym] = path
          end

          def account
            remotestore.account
          end

          def behind?
            @behind
          end

          def behind!
            @behind = true
          end

          def caught_up!
            @behind = false
          end
        end

        Inbox = Struct.new(:account, :folder, :channel) do
          def listen(interval=60, &block)
            name = folder.split('/').last.to_sym
            account.connections[name] = account.connect
            account.connections[name].examine(folder)
            Thread.new do
              loop { account.connections[name].idle(interval, &block) }
            end
          end
        end
      end
    end
  end
end
