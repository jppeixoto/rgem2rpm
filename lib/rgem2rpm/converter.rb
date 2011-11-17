require 'rubygems/installer'
require 'fileutils'
require 'zlib'
require 'archive/tar/minitar'
require 'erb'
include Archive::Tar

class RGem2Rpm::Converter < Gem::Installer
  ##
  # Constructs an Installer instance that will install the gem located at
  # +gem+.  +options+ is a Hash with the following keys:
  #
  # :rpm_top_dir:: path used by rpmbuild to generate rpms
  def initialize(options_parse, gem)
    # set spectemplate
    @spec_template = options_parse.spec_template
    # set rpm release
    @rpm_release = options_parse.rpm_release
    # set rpm group
    @rpm_group = options_parse.rpm_group
    # set rpm no arch
    @rpm_no_arch = true
    # set os user
    @os_user = options_parse.os_user
    # set os group
    @os_group = options_parse.os_group
    # set os installation dir
    @os_install_dir = options_parse.os_install_dir
    # initialize rpm_top_dir
    @rpm_top_dir = "#{Dir.pwd}/rpmbuild"
    # set defaul options
    super(gem)
    # load spec
    self.spec
    # initialize temp dir
    @rpm_tmp_dir = "#{@rpm_top_dir}/tmp/#{@spec.full_name}"
    # initialize unpack dir
    @rpm_unpack_dir = "#{@rpm_tmp_dir}/#{@spec.full_name}"
    # initialize gemspec filename
    @gemspec_filename = "#{@rpm_tmp_dir}/#{@spec.full_name}.gemspec"
    # initialize bin dir
    @bin_dir = "#{@rpm_tmp_dir}/bin"
    # create rpm build environment
    create_rpm_env
  end

  # return gem name
  def name
    @spec.name
  end

  # return gem version
  def version
    @spec.version
  end

  # return rpm release
  def rpm_release
    @rpm_release
  end

  # return rpm group
  def rpm_group
    @rpm_group
  end

  # return rpm no arch value
  def rpm_no_arch
    @rpm_no_arch
  end

  # return os installation user
  def os_user
    @os_user
  end

  # return os installation group
  def os_group
    @os_group
  end

  # return os installation group
  def os_install_dir
    @os_install_dir
  end

  # return gem homepage
  def homepage
    @spec.homepage
  end

  # return summary
  def summary
    @spec.summary
  end

  # return rpm install bin
  def rpm_install
    @rpm_install
  end

  # return rpm post
  def rpm_post
    @rpm_post
  end

  ##
  # Converts gem into rpm using rpmbuild command
  def create_rpm
    # unpack gem software
    unpack @rpm_unpack_dir
    # check if gem has extensions
    unless @spec.extensions.empty?
      # set rpm arch
      @rpm_no_arch = false
      # build extensions
      build_extensions
      # clean build
      build_clean
    end
    # create file list with build files
    generate_file_list
    # generate install
    generate_install
    # generate executable files
    generate_bin
    # create gemspec file
    File.open(@gemspec_filename, 'w') { |f|
      f.write(@spec.to_ruby)
    }
    # create rpm spec file
    write_rpm_spec_from_template
    # create rpm source file
    create_rpm_source("#{@rpm_top_dir}/tmp")
    # create rpm
    rpmbuild
    # clean temp directory
    FileUtils.rm_rf "#{@rpm_tmp_dir}"
  end

  # return gem runtime dependencies
  def requires
    req_str = StringIO.new
    # get ruby dependency
    req_str << "ruby #{@spec.required_ruby_version || ">= 0" }"
    # get rubygems dependency
    req_str << ", rubygems #{@spec.required_rubygems_version}" unless @spec.required_rubygems_version.nil?
    # get runtime dependencies
    req_str << ", #{@spec.runtime_dependencies.join(', ').gsub(', runtime', '').gsub(')', '').gsub('(', '').gsub('~>', '>=')}" unless @spec.runtime_dependencies.empty?
    # return string with dependencies
    return req_str.string
  end

  # return gem description
  def description
    @spec.description
  end

  # return gem files
  def files
    @files
  end

  private
  ##
  # Get list of files generated during build operation
  def generate_file_list
    # check if gem has native extensions
    if @spec.extensions.empty?
      # use gemspec file list
      @file_list = @spec.files
    else
      # initialize build files array
      build_files = Array.new
      # get required path
      first_element = @spec.require_paths.first
      require_path = if first_element.kind_of? Array then first_element.join("/") else first_element end
      # start building make command
      Dir.chdir("#{@rpm_tmp_dir}/#{@spec.full_name}/#{require_path}") do |path|
        Dir.glob("**/*") do |file|
          build_files << "#{require_path}/#{file}" unless File.directory?("#{path}/#{file}")
        end
      end
      # include build files in the list of files
      @file_list = @spec.files + build_files
      # delete duplicate values
      @file_list.uniq!
    end
  end

  ##
  # Create install string.
  def generate_install
    files_str = StringIO.new
    install_str = StringIO.new
    install_str << "rm -rf %{buildroot}\n"
    install_str << "mkdir -p %{buildroot}%{prefix}/bin\n"
    install_str << "mkdir -p %{buildroot}%{prefix}/specifications\n"
    install_str << "mkdir -p %{buildroot}%{prefix}/gems/%{name}-%{version}\n"
    install_str << "install -p -m 644 %{name}-%{version}.gemspec %{buildroot}%{prefix}/specifications"
    files_str << "%{prefix}/specifications/%{name}-%{version}.gemspec"
    # get files list
    @file_list.each { |file|
      if File.file? "#{@rpm_unpack_dir}/#{file}"
        install_str << "\ninstall -p -D -m 644 %{name}-%{version}/\"#{file}\" %{buildroot}%{prefix}/gems/%{name}-%{version}/\"#{file}\""
        files_str << "\n\"%{prefix}/gems/%{name}-%{version}/#{file}\""
      elsif File.directory? "#{@rpm_unpack_dir}/#{file}"
        install_str << "\nmkdir -p %{buildroot}%{prefix}/gems/%{name}-%{version}/\"#{file}\""
      end
    }
    # get executable file list
    @spec.executables.each { |file|
      install_str << "\ninstall -p -m 0755 bin/#{file} %{buildroot}%{prefix}/bin"
      files_str << "\n%{prefix}/bin/#{file}"
    }
    @rpm_install = install_str.string
    @files = files_str.string
  end

  def generate_bin
    return if @spec.executables.nil? or @spec.executables.empty?

    # If the user has asked for the gem to be installed in a directory that is
    # the system gem directory, then use the system bin directory, else create
    # (or use) a new bin dir under the gem_home.
    bindir = @bin_dir ? @bin_dir : Gem.bindir(@gem_home)

    Dir.mkdir bindir unless File.exist? bindir
    raise Gem::FilePermissionError.new(bindir) unless File.writable? bindir

    @spec.executables.each do |filename|
      filename.untaint
      bin_path = File.expand_path "#{@spec.bindir}/#{filename}", @gem_dir
      if File.exist?(bin_path)
        mode = File.stat(bin_path).mode | 0111
        File.chmod mode, bin_path
      end
      generate_bin_script filename, bindir
    end
  end

  def generate_bin_script(filename, bindir)
    @rpm_install = "#{@rpm_install}\nsed -i \"1i $(if (ruby -v 1>/dev/null 2>&1); then echo '\#\!/usr/bin/env ruby'; else echo '\#\!/usr/bin/env jruby'; fi;)\" %{buildroot}%{prefix}/bin/#{filename}"
    bin_script_path = File.join bindir, formatted_program_filename(filename)

    File.open bin_script_path, 'wb', 0755 do |file|
      file.print app_script_text(filename)
    end
  end

   ##
  # Return the text for an application file.

  def app_script_text(bin_file_name)
    <<-TEXT
#
# This file was generated by RubyGems.
#
# The application '#{@spec.name}' is installed as part of a gem, and
# this file is here to facilitate running it.
#

require 'rubygems'

version = "#{Gem::Requirement.default}"

if ARGV.first =~ /^_(.*)_$/ and Gem::Version.correct? $1 then
  version = $1
  ARGV.shift
end

gem '#{@spec.name}', version
load Gem.bin_path('#{@spec.name}', '#{bin_file_name}', version)
TEXT
  end

  def build_clean
    # clean each build
    @spec.extensions.each do |extension|
      Dir.chdir(File.dirname("#{@rpm_tmp_dir}/#{@spec.full_name}/#{extension}")) do |path|
        # delete intermediate build files
        system "make clean"
        # delete makefile
        FileUtils.rm_rf("#{path}/Makefile")
      end
    end
  end

  def create_rpm_env
    FileUtils.mkdir_p "#{@rpm_top_dir}/SPECS" unless File.exists?("#{@rpm_top_dir}/SPECS")
    FileUtils.mkdir_p "#{@rpm_top_dir}/BUILD" unless File.exists?("#{@rpm_top_dir}/BUILD")
    FileUtils.mkdir_p "#{@rpm_top_dir}/RPMS" unless File.exists?("#{@rpm_top_dir}/RPMS")
    FileUtils.mkdir_p "#{@rpm_top_dir}/SRPMS" unless File.exists?("#{@rpm_top_dir}/SRPMS")
    FileUtils.mkdir_p "#{@rpm_top_dir}/SOURCES" unless File.exists?("#{@rpm_top_dir}/SOURCES")
  end

  def write_rpm_spec_from_template
    template = ERB.new(File.read(@spec_template))
    # write rpm spec file file
    rpmspec_filename = "#{@rpm_top_dir}/SPECS/#{@spec.name}-#{@spec.version}.spec"
    File.open(rpmspec_filename, 'w') {|f|
      f.write(template.result(binding))
    }
  end

  def create_rpm_source(orig)
    # create tar.gz source file
    tgz = Zlib::GzipWriter.new(File.open("#{@rpm_top_dir}/SOURCES/#{@spec.name}-#{@spec.version}.tar.gz", 'wb'))
    # Warning: tgz will be closed!
    FileUtils.cd "#{orig}"
    Minitar.pack("#{@spec.name}-#{@spec.version}", tgz)
    FileUtils.cd "#{@rpm_top_dir}"
  end

  def rpmbuild
    # define rpm build args
    options = "-bb --rmspec --rmsource"
    define = "--define \"_topdir #{@rpm_top_dir}\" --define \"_tmppath #{@rpm_top_dir}/tmp\""
    specfile = "#{@rpm_top_dir}/SPECS/#{@spec.name}-#{@spec.version}.spec"
    # create rpm
    system "rpmbuild #{options} #{define} #{specfile}"
  end
end
