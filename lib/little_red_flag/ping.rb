require 'socket'
require 'timeout'
require 'open3'

module LittleRedFlag

  # Borrowed from the net/ping gem's Net::Ping::External class
  class Ping
    # The host to ping. In the case of Ping::HTTP, this is the URI.
    attr_accessor :host

    # The port to ping. This is set to the echo port (7) by default. The
    # Ping::HTTP class defaults to port 80.
    #
    attr_accessor :port

    # The maximum time a ping attempt is made.
    attr_accessor :timeout

    # If a ping fails, this value is set to the error that occurred which
    # caused it to fail.
    #
    attr_reader :exception

    # This value is set if a ping succeeds, but some other condition arose
    # during the ping attempt which merits warning, e.g a redirect in the
    # case of Ping::HTTP#ping.
    #
    attr_reader :warning

    # The number of seconds (returned as a Float) that it took to ping
    # the host. This is not a precise value, but rather a good estimate
    # since there is a small amount of internal calculation that is added
    # to the overall time.
    #
    attr_reader :duration

    # The default constructor for the Net::Ping class.  Accepts an optional
    # +host+, +port+ and +timeout+.  The port defaults to your echo port, or
    # 7 if that happens to be undefined.  The default timeout is 5 seconds.
    #
    # The host, although optional in the constructor, must be specified at
    # some point before the Net::Ping#ping method is called, or else an
    # ArgumentError will be raised.
    #
    # Yields +self+ in block context.
    #
    # This class is not meant to be instantiated directly.  It is strictly
    # meant as an interface for subclasses.
    #
    def initialize(host=nil, port=nil, timeout=5)
       @host      = host
       @port      = port || Socket.getservbyname('echo') || 7
       @timeout   = timeout
       @exception = nil
       @warning   = nil
       @duration  = nil

       yield self if block_given?
    end

    # Pings the host using your system's ping utility and checks for any
    # errors or warnings. Returns true if successful, or false if not.
    #
    # If the ping failed then the Ping::External#exception method should
    # contain a string indicating what went wrong. If the ping succeeded then
    # the Ping::External#warning method may or may not contain a value.
    #
    def ping(host = @host, count = 1, timeout = @timeout)
      raise ArgumentError, 'no host specified' unless host
      raise "Count must be an integer" unless count.is_a? Integer
      raise "Timeout must be a number" unless timeout.is_a? Numeric

      pcmd = ['ping']
      bool = false

      case RbConfig::CONFIG['host_os']
        when /linux/i
          pcmd += ['-c', count.to_s, '-W', timeout.to_s, host]
        when /aix/i
          pcmd += ['-c', count.to_s, '-w', timeout.to_s, host]
        when /bsd|osx|mach|darwin/i
          pcmd += ['-c', count.to_s, '-t', timeout.to_s, host]
        when /solaris|sunos/i
          pcmd += [host, timeout.to_s]
        when /hpux/i
          pcmd += [host, "-n#{count.to_s}", '-m', timeout.to_s]
        when /win32|windows|msdos|mswin|cygwin|mingw/i
          pcmd += ['-n', count.to_s, '-w', (timeout * 1000).to_s, host]
        else
          pcmd += [host]
      end

      start_time = Time.now

      begin
        err = nil

        Open3.popen3(*pcmd) do |stdin, stdout, stderr, thread|
          stdin.close
          err = stderr.gets # Can't chomp yet, might be nil

          case thread.value.exitstatus
            when 0
              info = stdout.read
              if info =~ /unreachable/ix # Windows
                bool = false
                @exception = "host unreachable"
              else
                bool = true  # Success, at least one response.
              end

              if err & err =~ /warning/i
                @warning = err.chomp
              end
            when 2
              bool = false # Transmission successful, no response.
              @exception = err.chomp if err
            else
              bool = false # An error occurred
              if err
                @exception = err.chomp
              else
                stdout.each_line do |line|
                  if line =~ /(timed out|could not find host|packet loss)/i
                    @exception = line.chomp
                    break
                  end
                end
              end
          end
        end
      rescue Exception => error
        @exception = error.message
      end

      # There is no duration if the ping failed
      @duration = Time.now - start_time if bool

      bool
    end

    def ping6(host = @host, count = 1, timeout = @timeout)

      raise "Count must be an integer" unless count.is_a? Integer
      raise "Timeout must be a number" unless timeout.is_a? Numeric

      pcmd = ['ping6']
      bool = false

      case RbConfig::CONFIG['host_os']
        when /linux/i
          pcmd += ['-c', count.to_s, '-W', timeout.to_s, host]
        when /aix/i
          pcmd += ['-c', count.to_s, '-w', timeout.to_s, host]
        when /bsd|osx|mach|darwin/i
          pcmd += ['-c', count.to_s, '-t', timeout.to_s, host]
        when /solaris|sunos/i
          pcmd += [host, timeout.to_s]
        when /hpux/i
          pcmd += [host, "-n#{count.to_s}", '-m', timeout.to_s]
        when /win32|windows|msdos|mswin|cygwin|mingw/i
          pcmd += ['-n', count.to_s, '-w', (timeout * 1000).to_s, host]
        else
          pcmd += [host]
      end

      start_time = Time.now

      begin
        err = nil

        Open3.popen3(*pcmd) do |stdin, stdout, stderr, thread|
          stdin.close
          err = stderr.gets # Can't chomp yet, might be nil

          case thread.value.exitstatus
            when 0
              info = stdout.read
              if info =~ /unreachable/ix # Windows
                bool = false
                @exception = "host unreachable"
              else
                bool = true  # Success, at least one response.
              end

              if err & err =~ /warning/i
                @warning = err.chomp
              end
            when 2
              bool = false # Transmission successful, no response.
              @exception = err.chomp if err
            else
              bool = false # An error occurred
              if err
                @exception = err.chomp
              else
                stdout.each_line do |line|
                  if line =~ /(timed out|could not find host|packet loss)/i
                    @exception = line.chomp
                    break
                  end
                end
              end
          end
        end
      rescue Exception => error
        @exception = error.message
      end

      # There is no duration if the ping failed
      @duration = Time.now - start_time if bool

      bool
    end

    alias ping? ping
    alias pingecho ping
  end
end
