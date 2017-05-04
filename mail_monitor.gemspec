require File.expand_path('../lib/mail_monitor/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'mail_monitor'
  s.version = MailMonitor::VERSION
  s.author  = 'Ryan Lue'
  s.email   = 'ryan.lue@gmail.com'

  s.summary = 'Run mbsync all the damn time'
  s.description = s.summary
  s.homepage = 'http://github.com/rlue/mail_monitor'
  s.license = 'MIT'

  s.files      = `git ls-files -z`.split("\x0").reject do |f|
                       f.match(%r{^(spec/|\.\w)})
                     end
  s.executables   = ['mail_monitor']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'net-ping', '~> 2.0'
  s.add_runtime_dependency 'listen', '~> 3.1'
end
