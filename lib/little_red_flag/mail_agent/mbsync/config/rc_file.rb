module LittleRedFlag
  module MailAgent
    class Mbsync
      module Config
        # Parses the text of .mbsyncrc configuration files
        # and exposes each stanza of settings through #stanzas
        class RCFile < String
          def initialize(dotfile)
            replace(File.read(dotfile))
          end

          def stanzas
            sanitize.split("\n\n")
          end
          
          def sanitize
            distill.validate_stanzas
          end

          # removes comments, normalizes whitespace
          def distill
            gsub(/^#.*\n/, '').gsub(/\n+(?=\n\n)/, '').strip
          end

          # removes stanzas that do not describe valid mbsync sections
          def validate_stanzas
            replace(split("\n\n").select do |s|
              section_names.include?(s.split.first.downcase)
            end.join("\n\n"))
          end

          private

          def section_names
            Properties.constants.map(&:downcase).map(&:to_s)
          end
        end
      end
    end
  end
end
