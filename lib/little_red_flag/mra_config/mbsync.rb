module LittleRedFlag
  class MRAConfig
    # Scrapes mbsync config files
    class MBSync
      class << self
        # returns an array of Accounts (see mra_config.rb)
        def scrape(file)
          raw_settings = File.read(file)
          accounts = parse(raw_settings).select { |sxn| sxn.key?(:imapaccount) }
          structify(accounts)
        end

        private

        def parse(raw)
          hashify(arrayify(raw))
        end

        def arrayify(text)
          text.downcase.gsub(/^#.*\n/, '').strip.gsub(/(?:\n){2,}/, "\n\n")
              .split("\n\n").map { |section| section.split("\n") }
        end

        def hashify(array)
          array.map do |section|
            section.map! do |line|
              setting = line.split(' ', 2)
              [setting.first.to_sym, setting.last]
            end.to_h
          end
        end

        def structify(accounts)
          accounts.map! do |acct|
            ssl = acct[:ssltype] == 'imaps'
            port = acct[:port] || (ssl ? 993 : 143)
            server = Server.new(acct[:host], port, ssl)
            pass = # FIX THIS
            credentials = Credentials.new(acct[:user], acct[:passcmd])
            Account.new(server, credentials)
          end
        end
      end
    end
  end
end
