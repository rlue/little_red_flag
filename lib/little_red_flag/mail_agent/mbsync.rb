module LittleRedFlag
  module MailAgent
    # Controller for the mbsync mail retrieval agent
    class Mbsync
      include MailAgent

      attr_reader :config

      def initialize
        @config = Config.new(dotfile)
      end

      def mra?
        true
      end

      def command(channel = :all)
        'mbsync ' + (channel == :all ? '-a' : channel)
      end

      def ignore_pat
        /\.mbsync/
      end

      # returns an array of strings representing paths to local mailstores
      def stores
        @stores ||= config.maildirstores.map(&:path)
      end

      def channels
        @channels ||= config.select { |sxn| sxn.key?(:channel) }
                            .map! do |st|
                              st.key?(:group) ? st[:group] : st[:channel]
                            end
      end

      # takes the path of a maildir,
      # returns the channel.label ( + :mailfolder) most closely matching it
      def channel_for(maildir)
        @channel ||= {}
        @channel[maildir.to_sym] ||= begin
          channel = config.channels.max_by do |channel|
            localstore_path = channel.localstore.path_of[channel.label.to_sym]
            maildir.slice(localstore_path) ? localstore_path.intersection(maildir).length : 0
          end

          localstore_path = channel.localstore.path_of[channel.label.to_sym]

          folder = maildir.sub(%r{#{localstore_path}/?}, '')
                          .gsub(channel.localstore.flatten.unescape,
                                (channel.remotestore.pathdelimiter || '/'))

          channel.label + (folder.empty? ? '' : ":#{folder}")
        end
      end

      def account_for(channel)
        @account ||= {}
        @account[channel.to_sym] ||= begin
          config.channels.find { |c| channel.split(':').first == c.label }.account
        end
      end
    end
  end
end
