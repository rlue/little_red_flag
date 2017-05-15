module LittleRedFlag
  # Scrapes IMAP account settings from MRA config files
  module MailAgent
    AGENT_MAP = { mbsync:      { role: :mra,     config: '.mbsyncrc'       },
                  mu:          { role: :indexer, config: '.mu'             },
                  notmuch:     { role: :indexer, config: '.notmuch-config' },
                  offlineimap: { role: :mra,     config: '.offlineimaprc'  } }

    class << self
      def new(agent)
        validate(agent)
        const_get(agent.to_s.capitalize).new
      end

      def validate(agent)
        check_supported(agent)
        check_config(agent)
        check_roles(agent)
      end

      def detect
        AGENT_MAP.select { |_k, v| File.exist?(path_to(v[:config])) }.keys
      end

      def path_to(config)
        "#{ENV['HOME']}/#{config}"
      end

      private
      
      def check_supported(agent)
        raise ArgumentError, "#{agent} is not a supported mail agent" \
          unless AGENT_MAP.keys.include?(agent)
      end

      def check_config(agent)
        raise "#{path_to(AGENT_MAP[agent][:config])} not found" \
          unless File.exist?(path_to(AGENT_MAP[agent][:config]))
      end

      def check_roles(agent)
        @@role_rosters ||= Hash.new { |k, v| k[v] = [] }
        roster = @@role_rosters[AGENT_MAP[agent][:role]]
        roster << agent
        if roster.length > 1
          raise "Conflicting mail agents detected " \
                "(#{roster.map(&:to_s).join(', ')}).\n" \
                "Remove dotfiles associated with unused mail agents,\n" \
                "or specify active ones explicitly with the -a flag:\n\n" \
                "    little-red-flag -a mbsync,notmuch"
        end
      end
    end

    def name
      self.class.name.downcase.split('::').last
    end

    # TODO: fix this...
    def dotfile
      MailAgent.path_to(AGENT_MAP[name.to_sym][:config])
    end

    def mra?
      false
    end

    def indexer?
      false
    end

    Server      = Struct.new(:host, :port, :ssl)
    Credentials = Struct.new(:user, :pass) # TODO: address pass v. passcmd
    Account     = Struct.new(:server, :credentials, :connection) do
      def listen(mbox = 'INBOX')
        connection.examine(mbox)
        connection.idle do |res|
          yield if %w(EXISTS FETCH).include?(res.name)
        end
      end

      def initiate_idle
        self.connection = Net::IMAP.new(server.host,
                                        port: server.port,
                                        ssl:  server.ssl)
        connection.authenticate('PLAIN', credentials.user, credentials.pass)
      end

      def close_idle
        connection.idle_done
      end
    end
  end
end
