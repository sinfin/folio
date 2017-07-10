$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "folio/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "folio"
  s.version     = Folio::VERSION
  s.authors     = ["Filip Ornstein"]
  s.email       = ["filip@sinfin.cz"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Folio."
  s.description = "TODO: Description of Folio."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.2"

  s.add_development_dependency "sqlite3"
end
