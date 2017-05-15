require File.expand_path('../lib/little_red_flag/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'little_red_flag'
  s.version = LittleRedFlag::VERSION
  s.author  = 'Ryan Lue'
  s.email   = 'ryan.lue@gmail.com'

  s.summary = 'Sync IMAP mail to your machine. Automatically, instantly, all ' \
    'the time.'
  s.description = 'isync (mbsync) is a command-line tool for synchronizing ' \
    'IMAP and local Maildir mailboxes. It’s faster and stabler than the next ' \
    'most popular alternative (OfflineIMAP), but still must be invoked ' \
    'manually. Little Red Flag keeps an eye on your mailboxes and runs the ' \
    'appropriate `mbsync` command anytime changes occur, whether locally or ' \
    'remotely. It also detects the presence of `mu` / `notmuch` mail ' \
    'indexers, and re-indexes after each sync.'
  s.homepage = 'http://github.com/rlue/little_red_flag'
  s.license = 'MIT'

  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec/|\.\w)})
  end
  s.executables   = ['littleredflag']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.2.5'
  s.add_runtime_dependency 'listen', '~> 3.1'
  s.add_runtime_dependency 'net-ping', '~> 2.0'
  s.add_runtime_dependency 'sys-proctable', '~> 1.1'
end
