require 'pathname'
require 'rubygems'
require 'rubygems/installer'
require 'rubygems/remote_fetcher'

class RGem2Rpm::Gem
  # define accessors
  attr_accessor :spec
  
  def initialize(args)
    # initialize paramters
    @filename = args[:filename]
    @platform = args[:platform] || 'ruby'
  end
  
  # install gem to pwd
  def install
    # get spec information
    @spec = compute_spec
    # define name and platform
    @spec[:installname] = name_and_platform(@spec[:name])
    # set install dir
    @installdir = "#{@spec[:installname]}-#{@spec[:version]}"
    # install gem
    Gem::Installer.new(@filename, :env_shebang => true, :ignore_dependencies => true, :install_dir => @installdir, :bin_dir => "#{@installdir}/bin", :wrappers => true).install
    # install build files
    install_build_files
    # get file list
    files
    # build tar.gz
    build_source
  end
  
  # clean temporary files
  def clean
    return if @installdir.nil?
    FileUtils.rm_rf @installdir
    FileUtils.rm_rf "#{@installdir}.tar.gz"
  end
  
  private
    # get information from specification
    def compute_spec
      specinfo = {}
      File.open(@filename, 'r') do |f|
        Gem::Package.open(f, 'r') do |gem|
          # spec info
          metadata = gem.metadata
          # name
          specinfo[:name] = metadata.name
          # version
          specinfo[:version] = metadata.version
          # summary
          specinfo[:summary] = metadata.summary
          # homepage
          specinfo[:homepage] = metadata.homepage
          # platform
          specinfo[:platform] = metadata.platform
          # description
          specinfo[:description] = metadata.description
          # if the gemspec has extensions defined, then this should be a 'native' arch.
          specinfo[:architecture] = metadata.extensions.empty? ? 'all' : 'native'
          # rubygem required version
          specinfo[:rubygem] = metadata.required_rubygems_version
          # dependencies
          specinfo[:dependencies] = metadata.runtime_dependencies
          # extensions
          specinfo[:extensions] = metadata.extensions
          # executables
          specinfo[:executables] = metadata.executables
        end
      end
      specinfo
    end
    
    # define name and platform
    def name_and_platform(gemname)
      name = gemname
      if gemname =~ /jruby|jar|java/ or @spec[:platform].to_s == 'java'
        @platform = 'jruby'
        name = "jruby-#{gemname}" unless gemname =~ /jruby/
      elsif @platform == 'jruby' and !@spec[:executables].nil? and !@spec[:executables].empty?
        name = "jruby-#{gemname}"
      end
      "rubygem-#{name}"
    end
    
    # return hash with list of files and directories
    def files
      @spec[:files] = {:directories => [], :files => [], :executables => []}
      Dir.chdir(@installdir) do
        # create gem directory structure
        @spec[:files][:directories] << 'gems'
        @spec[:files][:directories] << 'specifications'
        @spec[:files][:directories] << 'bin'
        # get files and directories
        Dir.glob("gems/**/*") do |file|
          key = File.directory?(file) ? :directories : (File.executable?(file) || file.end_with?('.sh') ? :executables : :files)
          @spec[:files][key] << file
        end
        # get gem path
        Dir.glob("gems/*") do |file|
          @spec[:files][:gempath] = file
        end
        # get specification filename
        Dir.glob("specifications/*") do |file|
          @spec[:files][:specification] = file
        end
        # get executable files
        Dir.glob("bin/*") do |file|
          @spec[:files][:executables] << file
          shebang(file)
        end
      end
    end
    
    def shebang(filename)
      # alter first line of all executables
      file_arr = File.readlines(filename)
      file_arr[0] = "#!/usr/bin/env #{@platform}\n"
      File.open(filename, 'w') { |f| f.write(file_arr.join) }
    end
    
    def build_source
      # create tar.gz
      res = system "tar czf #{@installdir}.tar.gz #{@installdir}"
      # check errors
      raise "Error creating archive #{@installdir}.tar.gz" unless res
      # clean temporary files
      FileUtils.rm_rf @installdir
    end
    
    def install_build_files
      # get current directory
      pwd = FileUtils.pwd
      # clean build if gem has extensions
      @spec[:extensions].each { |extension|
        path = File.dirname("#{pwd}/#{@installdir}/gems/#{@filename[0, @filename.size-4]}/#{extension}")
        FileUtils.cp_r "#{path}/#{@installdir}", "#{pwd}/"
        FileUtils.rm_rf "#{path}/#{@installdir}"
        FileUtils.rm_rf Dir.glob("#{path}/*.o")
        FileUtils.rm_rf Dir.glob("#{path}/*.so")
        FileUtils.rm_rf "#{path}/Makefile"
      }
      # delete directories
      Dir["#{@installdir}/*"].each {|name| FileUtils.rm_rf(name) unless name =~ /bin|gems|specifications/ }
    end
end