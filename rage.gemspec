require File.join(File.dirname(__FILE__), 'lib', 'rage', 'version')

Gem::Specification.new do |s|
  s.name        = 'rage-trader'
  s.version     = Rage::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'A coin evaluator'
  s.description = 'A coin evaluator'
  s.authors     = ["Bryan Brandau"]
  s.email       = 'agent462@gmail.com'
  s.has_rdoc    = false
  s.licenses    = ['MIT']
  s.homepage    ='http://github.com/agent462/rage'

  s.add_dependency('rainbow', '1.1.4')
  s.add_dependency('mixlib-config', '1.1.2')
  s.add_dependency('rufus-scheduler')
  s.add_dependency('redis')
  s.add_dependency('mtgox')
  s.add_dependency('mail')

  s.add_development_dependency('rspec')
  s.add_development_dependency('rubocop')

  s.files         = Dir.glob('{bin,lib}/**/*') + %w[rage.gemspec README.md settings.example.rb]
  s.executables   = Dir.glob('bin/**/*').map { |file| File.basename(file) }
  s.require_paths = ['lib']
end
