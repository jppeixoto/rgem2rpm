class RGem2Rpm::Converter
  class << self
    def process(options, filename)
      objects = []
      # execute gemfile installation
      gem = RGem2Rpm::Gem.new :filename => filename, :platform => options[:platform]
      objects << gem
      gem.install
      # build args to rpm
      args = gem.spec
      [:template, :release, :group, :osuser, :osgroup, :installdir].each {|key|
        args[key] = options[key] unless options[key].nil?
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
