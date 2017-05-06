module LittleRedFlag
  # Scrapes IMAP account settings from MRA config files
  class MRAConfig
    attr_reader :accounts

    def initialize(configs = default_configs)
      @accounts = configs.map { |f| scrape(f) }.flatten!
    end

    Account     = Struct.new(:server, :credentials)
    Server      = Struct.new(:host, :port, :ssl)
    Credentials = Struct.new(:user, :pass) # TODO: address pass v. passcmd

    private

    def default_configs
      ["#{ENV['HOME']}/.mbsyncrc", "#{ENV['HOME']}/.offlineimaprc"]
        .select! { |f| File.file?(f) }
    end

    def scrape(file)
      raise ArgumentError "#{file}: file not found" unless File.file?(file)
      case File.basename(file)
      when '.mbsyncrc'
        MBSync.scrape(file)
      when '.offlineimaprc'
        OfflineIMAP.scrape(file)
      else
        raise ArgumentError "#{file}: unsupported config file"
      end
    end
  end
end
