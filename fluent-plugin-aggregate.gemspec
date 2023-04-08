# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-aggregate"
  gem.description = "Filter aggregtation plugin for Fluent"
  gem.homepage    = "https://github.com/superguillen/fluent-plugin-aggregate"
  gem.summary     = gem.description
  gem.version     = "1.0.6"
  gem.authors     = ["superguillen"]
  gem.email       = "superguillen.public@gmail.com"
  gem.license     = 'MIT'
  gem.files       = Dir['Rakefile', '{lib}/**/*', 'README*', 'LICENSE*']
  gem.require_paths = ['lib']

  gem.add_dependency "fluentd", [">= 0.10.58", "< 2"]
  gem.add_dependency "dataoperations-aggregate", [">= 0.0.7"]
  gem.add_development_dependency "rake", ">= 0.9.2"
  gem.add_development_dependency "test-unit", ">= 3.0.8"
end
