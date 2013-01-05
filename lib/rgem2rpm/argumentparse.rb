# -*- encoding : utf-8 -*-
require 'optparse'

class RGem2Rpm::ArgumentParse
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = {}

    opts = OptionParser.new do |opt|
      opt.banner = "Usage: rgem2rpm [options] [gemfilename]"
      opt.separator "options:"

      # Template argument
      opt.on("--template TEMPLATE", "RPM spec template.") do |template|
        options[:template] = template
      end

      # Release name
      opt.on("--release RELEASE", "RPM spec release.") do |release|
        options[:release] = release
      end
	  
      # rpm group
      opt.on("--group GROUP", "RPM spec group.") do |group|
        options[:group] = group
      end
	  
      # operating system install user
      opt.on("--osuser OSUSER", "OS install user.") do |osuser|
        options[:osuser] = osuser
      end

      # operating system install group
      opt.on("--osgroup OSGROUP", "OS install group.") do |osgroup|
        options[:osgroup] = osgroup
      end
	  
      # operating system install dir
      opt.on("--installdir INSTALLDIR", "OS install directory.") do |installdir|
        options[:installdir] = installdir
      end
      
      # jruby gem
      opt.on("--jruby", "Build RPM to jruby platform (only when gem has executables).") do
        options[:platform] = 'jruby'
      end
      #custom rpm name
      opt.on("--rpmname RPMNAME", "Custom package name (in case you don't want it to be rubygem-gemname") do |rpmname|
        options[:rpmname] = rpmname
      end

	  
      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opt.on_tail("--help", "Show this message.") do
        puts opt
        exit
      end

      # Another typical switch to print the version.
      opt.on_tail("--version", "Show version.") do
        puts RGem2Rpm::VERSION
        exit
      end
    end
	
    begin
      # parse options
      opts.parse!(args)
      # return options
      options
    rescue => e
      puts e.message
      exit
    end
  end
end
