require 'net/imap'

module LittleRedFlag
  module MailAgent
    class Mbsync
      # Stores .mbsyncrc configuration file data
      class Config
        CASE_SENSITIVE = %w(path inbox master slave pattern patterns pass).freeze

        Imapaccount = Struct.new(:label, :host, :port, :user, :pass, :passcmd,
          :tunnel, :authmechs, :ssltype, :sslversions, :systemcertificates,
          :certificatefile, :pipelinedepth, :connections) do
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
        Imapstore = Struct.new(:label, :path, :maxsize, :mapinbox, :flatten,
          :trash, :trashnewonly, :trashremotenew, :account, :usenamespace,
          :pathdelimiter, :path_of, :inbox)
        Maildirstore = Struct.new(:label, :path, :maxsize, :mapinbox, :flatten,
          :trash, :trashnewonly, :trashremotenew, :altmap, :inbox,
          :infodelimiter, :path_of)
        Channel = Struct.new(:label, :master, :slave, :patterns, :maxsize,
          :maxmessages, :expireunread, :sync, :create, :remove, :expunge,
          :copyarrivaldate, :syncstate, :localstore, :remotestore, :inboxes) do
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
        Group        = Struct.new(:label, :channels, :inboxes)
        Inbox        = Struct.new(:account, :folder, :channel) do
          def listen(interval=60, &block)
            name = folder.split('/').last.to_sym
            account.connections[name] = account.connect
            account.connections[name].examine(folder)
            Thread.new do
              loop { account.connections[name].idle(interval, &block) }
            end
          end
        end

        def initialize(dotfile)
          raw_data = sanitize(File.read(dotfile))
          settings = structify(arrayify(raw_data))
          populate_instance_variables(settings)
          postprocess
        end

        private

        # removes comments / normalizes whitespace
        def sanitize(config)
          config.gsub(/^#.*\n/, '').gsub(/\n+(?=\n\n)/, '').strip
        end

        # Takes text from #sanitize and returns a 3D array of SECTION arrays
        # of the form [["OPTION", "VALUE"], ["OPTION", "VALUE"]...]
        def arrayify(config)
          config.split("\n\n").map! do |section|
            section.split("\n").map! do |setting|
              key, val = *setting.split(/\s+/, 2)
              key.downcase!
              val.downcase! unless CASE_SENSITIVE.include?(key)
              [key, val]
            end
          end
        end

        # Takes a 3D array from #arrayify and returns an array of structs,
        # removing any global options
        def structify(config)
          config.map! do |section|
            struct_name, label = *section.shift
            next unless self.class.const_defined?(struct_name.capitalize!)
            section = hashify(section)
            struct = self.class.const_get(struct_name)
            struct.new(label, *section.values_at(*struct.members.drop(1)))
          end

          config.select { |section| section.respond_to?(:label) }
        end

        # Converts a single section's 2D array of settings into a hash,
        # collecting multiple values with the same key into arrays
        # and consolidating `Channel[s]`/`Pattern[s]` keywords
        def hashify(section)
          section.each.with_object({}) do |setting, hash|
            key, val = *setting
            key = (%w(channel pattern).include?(key) ? "#{key}s" : key).to_sym
            hash[key] = hash.key?(key) ? [hash[key], val].flatten : val
          end
        end

        def populate_instance_variables(var_array)
          var_array.each do |section|
            name = "#{section.class.name.split('::').last.downcase}s"
            unless instance_variable_defined?("@#{name}")
              instance_variable_set("@#{name}", [])
              self.class.send(:define_method, name.to_sym) do
                instance_variable_get("@#{name}")
              end
            end

            instance_variable_get("@#{name}") << section
          end
        end

        def postprocess
          expand_paths
          populate_channel_stores
          link_imapstore_accounts
          link_group_channels
          populate_imapstore_inboxes
          populate_channel_inboxes
          populate_group_inboxes
        end

        def expand_paths
          maildirstores.each do |store|
            %i(path inbox).each do |path|
              store.send("#{path}=", File.expand_path(store.send(path).unescape)) \
                unless store.send(path).nil?
            end
          end
        end

        def populate_channel_stores
          channels.each do |channel|
            [channel.master, channel.slave].each do |store|
              name = store.split(':')[1]
              if path_map.key?(name)
                channel.localstore = maildirstores.find { |m| m.label == name }
                channel.localpath = store.sub(/(?<=:)(?=[^:]+$)/, '/')
                                         .sub(":#{name}:", path_map[name])
              else
                channel.remotestore = imapstores.find { |m| m.label == name }
                channel.remotepath = store.sub(":#{name}:", '').unescape
              end
            end
          end
        end

        def path_map
          @stores ||= maildirstores.each.with_object({}) do |store, hash|
            hash[store.label] = store.path
          end
        end

        def link_imapstore_accounts
          imapstores.each do |store|
            store.account = imapaccounts.find { |acct| acct.label == store.account }
          end
        end

        def link_group_channels
          groups.each do |group|
            group.channels.map! do |name|
              channels.find { |channel| name == channel.label }
            end
          end
        end

        def populate_imapstore_inboxes
          imapstores.each do |store|
            channel = channels.find do |channel|
              channel.account == store.account && channel.remotepath == 'INBOX'
            end
            if channel
              channel = channel.label
            else
              channel = channels.find do |channel|
                channel.account == store.account && channel.remotepath.empty?
              end.label + ':INBOX'
            end
            store.inbox = Inbox.new(store.account, 'INBOX', channel)
          end
        end

        def populate_channel_inboxes
          imapstores.each do |store|
            store.account.connections ||= {init: store.account.connect}
            channels.select { |c| c.remotestore == store }.each do |channel|
              patterns = channel.patterns || '*'
              pattern_list = patterns.split(/ (?![^"]*[^\s!]")/).map(&:unescape)
              channel.inboxes = []
              pattern_list.each do |pattern|
                reduce_op = pattern.slice!(/^!/) ? :- : :+
                channel.inboxes = channel.inboxes.send(reduce_op, store.account.connections[:init].list(channel.remotepath, pattern)).flatten
              end
            end
          end

          channels.each do |channel|
            channel.inboxes.map! do |inbox|
              folder = inbox.name.sub(channel.remotepath, '').sub(/^\//, '')
              Inbox.new(channel.account,
                       inbox.name,
                       (channel.label + (folder.empty? ? '' : ":#{folder}")))
            end
          end
        end

        def populate_group_inboxes
          groups.each do |group|
            group.inboxes = []
            group.channels.each { |channel| group.inboxes.push(channel.inboxes).flatten }
          end
        end
      end
    end
  end
end
