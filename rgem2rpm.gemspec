Gem::Specification.new do |s|
   s.name = %q{rgem2rpm}
   s.version = "1.1.0"
   s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
   s.required_rubygems_version = Gem::Requirement.new(">= 1.4.2") if s.respond_to?(:required_rubygems_version=)
   s.date = %q{2011-04-26}
   s.authors = ["Joao Peixoto"]
   s.email = %q{peixoto.joao@gmail.com}
   s.summary = %q{Convert ruby gems into rpm}
   s.homepage = %q{https://github.com/jppeixoto/rgem2rpm}
   s.description = %q{Application that enables conversion of rubygems to rpms.}
   s.platform = Gem::Platform::RUBY
   s.bindir = 'bin'
   s.executables = 'rgem2rpm'
   s.files = ["Rakefile", 
              "bin/rgem2rpm",
              "rgem2rpm.gemspec",
              "lib/rgem2rpm.rb",
              "lib/rgem2rpm/argumentparse.rb",
              "lib/rgem2rpm/converter.rb",
              "lib/rgem2rpm/version.rb",
              "conf/template.spec"]
   s.add_dependency 'minitar', '>= 0.5.3'
end
