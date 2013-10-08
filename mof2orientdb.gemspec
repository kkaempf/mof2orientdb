# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mof2orientdb/version"

Gem::Specification.new do |s|
  s.name        = "mof2orientdb"
  s.version     = Mof2OrientDB::VERSION

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Klaus Kämpf"]
  s.email       = ["kkaempf@suse.de"]
  s.homepage    = "https://github.com/kkaempf/mof2orientdb"
  s.summary     = %q{Import MOF information into OrientDB}
  s.description = %q{Import MOF information into OrientDB.}

  s.rubyforge_project = "mof2orientdb"

  s.files         = `git ls-files`.split("\n")
  s.files.reject! { |fn| fn == '.gitignore' }
  s.extra_rdoc_files    = Dir['README.md', 'LICENSE']
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
