# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "area_51/version"

Gem::Specification.new do |s|
  s.name        = "area_51"
  s.version     = Area51::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chad Boyd"]
  s.email       = ["hoverlover@gmail.com"]
  s.homepage    = "https://github.com/hoverlover/area_51"
  s.summary     = %q{Gem used for simple path-based access control.}
  s.description = %q{Area51 allows you to define restricted and unrestricted sections of your application by defining paths in your controllers.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
