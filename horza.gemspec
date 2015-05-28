$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'horza'
  s.version = '0.2.0'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Blake Turner']
  s.description = 'Horza is a shapeshifter that provides common inputs and outputs for your ORM'
  s.summary = 'Keep your app ORM-agnostic'
  s.email = 'mail@blakewilliamturner.com'
  s.homepage = 'https://github.com/onfido/horza'
  s.license = 'MIT'

  s.files         = Dir.glob('{bin,lib}/**/*') + %w(LICENSE.txt README.md)
  s.test_files    = Dir.glob('{spec}/**/*')
  s.require_paths = ['lib']

  s.add_runtime_dependency 'hashie', '3.4.0'
  s.add_runtime_dependency 'activesupport', '>= 2.3.11'

  s.add_development_dependency 'rspec', '>= 2.4.0'
  s.add_development_dependency 'byebug', '>= 4.0'
  s.add_development_dependency 'activerecord', '>= 3.2.15'
  s.add_development_dependency 'sqlite3'
end
