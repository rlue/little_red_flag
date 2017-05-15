module LittleRedFlag
  # Methods for interacting with a Maildir mail store on the local filesystem.
  module Maildir
    class << self
      def of(file)
        validate_dir(file = File.dirname(File.expand_path(file)))
        dir = File.directory?(file) ? file : File.dirname(file)
        until Dir.glob(dir + '/{cur,new,tmp}').length == 3
          dir = File.dirname(dir)
          raise "#{file}: No user-readable maildir on this path" \
            if !File.readable?(dir) || dir == '/'
        end
        dir
      end

      private

      def validate_dir(dir)
        raise ArgumentError, "#{dir}: no such directory" \
          unless File.exist?(dir)
      end
    end
  end
end
