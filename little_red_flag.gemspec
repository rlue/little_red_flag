require File.expand_path('../lib/little_red_flag/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'little_red_flag'
  s.version = LittleRedFlag::VERSION
  s.author  = 'Ryan Lue'
  s.email   = 'ryan.lue@gmail.com'

  s.summary = 'Run mbsync all the damn time'
  s.description = s.summary
  s.homepage = 'http://github.com/rlue/little_red_flag'
  s.license = 'MIT'

  s.files      = `git ls-files -z`.split("\x0").reject do |f|
                       f.match(%r{^(spec/|\.\w)})
                     end
  s.executables   = ['little-red-flag']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'listen', '~> 3.1'
  s.add_runtime_dependency 'net-ping', '~> 2.0'
  s.add_runtime_dependency 'sys-proctable', '~> 1.1'
end
