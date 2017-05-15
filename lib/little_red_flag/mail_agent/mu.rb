module LittleRedFlag
  module MailAgent
    class Mu
      include MailAgent

      def indexer?
        true
      end

      def command
        'mu index'
      end
    end
  end
end
