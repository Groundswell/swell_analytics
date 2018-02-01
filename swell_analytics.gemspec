$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "swell_analytics/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "swell_analytics"
  s.version     = SwellAnalytics::VERSION
  s.authors     = ["Gk Parish-Philp", "Michael Ferguson"]
  s.email       = ["gk@groundswellenterprises.com"]
  s.homepage    = "http://www.groundswellenterprises.com"
  s.summary     = "A simple analytics Solution for Rails."
  s.description = "A simple analytics Solution for Rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  # s.test_files = Dir["test/**/*"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'user_agent_parser'
  s.add_dependency 'browser'
  s.add_development_dependency "sqlite3"
end
