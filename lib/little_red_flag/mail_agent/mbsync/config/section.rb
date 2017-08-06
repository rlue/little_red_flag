module LittleRedFlag
  module MailAgent
    class Mbsync
      module Config
        class Section < String
          CASE_SENS_OPTS = %w(path inbox master slave pattern patterns).freeze
          attr_reader :type, :label, :properties

          # Takes a config stanza from RCFile#stanzas and
          # exposes its contents as #type, #label, and a #properties hash.
          def initialize(stanza)
            replace(stanza)
            head, body    = split("\n", 2)
            @type, @label = head.to_s.downcase.split(" ", 2)
            @properties   = body.to_h
          end

          # Converts the raw text body of a stanza into a hash,
          # collecting multiple values with the same key into arrays
          # and consolidating `Channel[s]`/`Pattern[s]` keywords
          def to_h
            split("\n").each.with_object({}) do |setting, hash|
              key, val = setting.safe_downcase.split(/\s+/, 2)
              key = "#{key}s" if %w(channel pattern).include?(key)
              key = key.to_sym
              hash[key] = (hash.key?(key) ? [hash[key], val].flatten : val)
            end
          end

          def safe_downcase
            return nil unless match(/\A.*\Z/)   # for one-line section entries
            keyword, argument = split(/\s+/, 2)
            keyword.downcase!
            argument.downcase! unless CASE_SENS_OPTS.include?(keyword)
            keyword << ' ' << argument
          end
        end
      end
    end
  end
end
