module LittleRedFlag
  module MailAgent
    class Mbsync
      # Parses .mbsyncrc configuration files
      # and exposes their contents as instance methods
      module Config
        def initialize(dotfile)
          raw_conf = self.class.sanitize(File.read(dotfile))
          settings = self.class.structify(raw_conf)
          populate_instance_variables(settings)
          # postprocess
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
