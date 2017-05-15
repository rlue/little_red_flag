module LittleRedFlag
  module MailAgent
    class Notmuch
      include MailAgent

      def indexer?
        true
      end

      def command
        'notmuch new'
      end

      def ignore_pat
        /\.notmuch/
      end
    end
  end
end
