# -*- encoding : utf-8 -*-
class RGem2Rpm::Converter
  class << self
    def process(options, filename)
      objects = []
      # execute gemfile installation
      gem = RGem2Rpm::Gem.new :filename => filename, :platform => options[:platform], :rpmname => options[:rpmname]
      objects << gem
      gem.install
      # build args to rpm
      args = gem.spec
      [:template, :release, :group, :osuser, :osgroup, :installdir, :rpmname].each {|key|
        args[key] = options[key] if options[key]
      }
      # build rpm
      rpm = RGem2Rpm::Rpm.new args
      objects << rpm
      rpm.create
    rescue => e
      # clean temporary files
      objects.each { |obj| obj.clean }
      # write error message
      puts e.message
      exit
    end
  end
end
