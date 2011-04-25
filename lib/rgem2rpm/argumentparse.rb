require 'optparse'
require 'ostruct'

class RGem2Rpm::ArgumentParse
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.spec_template = File.expand_path('../../../conf/template.spec', __FILE__)
    options.rpm_release = '1'
    options.rpm_group = 'Ruby/Gems'
    options.os_user = 'root'
    options.os_group = 'root'
    options.os_install_dir = '/opt/ruby'

    opts = OptionParser.new do |opt|
      opt.banner = "Usage: rgem2rpm [options] [gemfilename]"
      opt.separator "options:"

      # Template argument
      opt.on("--template SPECTEMPLATE", "Define new rpm spec template.") do |spec_template|
        options.spec_template = spec_template
      end

      # Release name
      opt.on("--release RPMRELEASE", "Define rpm spec release.") do |rpm_release|
        options.rpm_release = rpm_release
      end
	  
      # rpm group
      opt.on("--rpmgroup RPMGROUPNAME", "Define rpm spec group.") do |rpm_group|
        options.rpm_group = rpm_group
      end
	  
      # operating system install user
      opt.on("--osuser USERNAME", "Define rpm spec os install user.") do |os_user|
        options.os_user = os_user
      end

      # operating system install group
      opt.on("--osgroup GROUPNAME", "Define rpm spec os install group.") do |os_group|
        options.os_group = os_group
      end
	  
      # operating system install dir
      opt.on("--osinstalldir INSTALLDIR", "Define rpm spec os install directory.") do |os_install_dir|
        options.os_install_dir = os_install_dir
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
