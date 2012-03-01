require 'erb'

class RGem2Rpm::Rpm
  attr_accessor :name, :version, :release, :license, :summary, :group, :description, :installdir
  
  def initialize(args)
    @template = args[:template] || File.dirname(__FILE__) + '/../../conf/template.spec'
    @name = args[:installname]
    @gemname = args[:name]
    @version = args[:version]
    @release = args[:release] || '1'
    @license = "See #{args[:homepage]}"
    @summary = args[:summary]
    @group = args[:group] || 'Ruby/Gems'
    @osuser = args[:osuser] || 'root'
    @osgroup = args[:osgroup] || 'root'
    @description = args[:description]
    @installdir = args[:installdir] || '/opt/ruby'
    @arch = args[:architecture]
    @files = args[:files]
    @rubygem = args[:rubygem]
    @dependencies = args[:dependencies]
  end
  
  def create
    # create spec
    spec
    # build rpm
    build
  end
  
  def installlist
    install_str = StringIO.new
    install_str << "rm -rf %{buildroot}\n"
    # get directories
    @files[:directories].each { |directory|
      directory.gsub!(/%/, '%%')
      install_str << "install -d \"#{directory}\" %{buildroot}%{prefix}/\"#{directory}\"\n"
    }
    # get files
    @files[:files].each { |file|
      file.gsub!(/%/, '%%')
      install_str << "install -m 644 \"#{file}\" %{buildroot}%{prefix}/\"#{file}\"\n"
    }
    # get executables
    @files[:executables].each { |executable|
      executable.gsub!(/%/, '%%')
      install_str << "install -m 0755 \"#{executable}\" %{buildroot}%{prefix}/\"#{executable}\"\n"
    }
    # return install string
    install_str.string
  end
  
  def filelist
    files_str = StringIO.new
    files_str << "%defattr(0644,#{@osuser},#{@osgroup},0755)\n"
    files_str << "%dir %{prefix}\n"
    files_str << "%dir %{prefix}/bin\n"
    files_str << "%dir %{prefix}/gems\n"
    files_str << "%dir %{prefix}/#{@files[:gempath]}\n"
    files_str << "%dir %{prefix}/specifications\n"
    files_str << "%{prefix}/#{@files[:specification]}\n"
    files_str << "%{prefix}/#{@files[:gempath]}/*\n"
    
    # get executables
    @files[:executables].each { |executable|
      files_str << "%attr(0755,#{@osuser},#{@osgroup}) %{prefix}/#{executable}\n"
    }
    # return file string
    files_str.string
  end
  
  def buildarch
    @arch == 'all' ? 'noarch' : nil
  end
  
  def requires
    req_str = StringIO.new
    # set rubygems dependency
    unless @rubygem.nil?
      req_str << "rubygems"
      req_str << " #{@rubygem}" unless @rubygem == '>= 0'
    end
    # set runtime dependencies
    @dependencies.each { |d|
      d.requirement.requirements.each { |v|
        req_str << ', ' unless req_str.size == 0
        req_str << "rubygem(#{d.name})"
        req_str << " #{v[0].gsub('~>','>=')} #{v[1].to_s}" unless v[0] =~ /!=/
        if v[0] =~ /~>/
          version = v[1].to_s.strip.split('.')
          version[version.size - 1] = "0"
          version[version.size - 2] = (version[version.size - 2].to_i + 1).to_s
          req_str << ", rubygem(#{d.name}) < #{version.join('.')}"
        end
      }
    }
    # return string with dependencies
    req_str.string
  end
  
  def conflicts
    conflict_str = StringIO.new
    # set conflicts
    @dependencies.each { |d|
      d.requirement.requirements.each { |v|
        conflict_str << ', ' unless conflict_str.size == 0
        conflict_str << "rubygem(#{d.name}) #{v[0].gsub('!=','=')} #{v[1].to_s}" if v[0] =~ /!=/
      }
    }
    # returns string with conflicts
    conflict_str.string
  end
  
  # return gem provides clause
  def provides
    prv_str = StringIO.new
    prv_str << "rubygem(#{@gemname}) = #{@version}"
    prv_str.string
  end
  
  # return changelog information
  def changelog
    change_str = StringIO.new
    change_str << "* #{Time.now.strftime('%a %b %d %Y')} rgem2rpm <https://github.com/jppeixoto/rgem2rpm> #{@version}-#{@release}\n"
    change_str << "- Create rpm package\n"
    change_str.string
  end
  
  # clean temporary files
  def clean
    FileUtils.rm_rf "#{@name}-#{@version}.spec"
    FileUtils.rm_rf "./rpmtemp"
  end
  
  private
    def spec
      template = ERB.new(File.read(@template))
      # write rpm spec file file
      File.open("#{@name}-#{@version}.spec", 'w') { |f|
        f.write(template.result(binding))
      }
    end

    def build
      create_rpm_env
      # move to rpmbuild path
      FileUtils.mv "#{@name}-#{@version}.spec", "rpmtemp/rpmbuild/SPECS"
      # move sources to rpmbuild
      FileUtils.mv "#{@name}-#{@version}.tar.gz", "rpmtemp/rpmbuild/SOURCES"
      # define rpm build args
      options = "-bb --rmspec --rmsource"
      define = "--define \"_topdir #{Dir.pwd}/rpmtemp/rpmbuild\" --define \"_tmppath #{Dir.pwd}/rpmtemp/rpmbuild/tmp\""
      specfile = "#{Dir.pwd}/rpmtemp/rpmbuild/SPECS/#{@name}-#{@version}.spec"
      # create rpm
      res = system "rpmbuild #{options} #{define} #{specfile}"
      # check errors
      raise "Error creating rpm" unless res
      # clean temporary files
      Dir.glob("rpmtemp/rpmbuild/RPMS/**/*.rpm") do |file|
        FileUtils.mv file, "./"
      end
      clean
    end
  
    def create_rpm_env
      FileUtils.mkdir_p "rpmtemp/rpmbuild/SPECS"
      FileUtils.mkdir_p "rpmtemp/rpmbuild/BUILD"
      FileUtils.mkdir_p "rpmtemp/rpmbuild/RPMS"
      FileUtils.mkdir_p "rpmtemp/rpmbuild/SRPMS"
      FileUtils.mkdir_p "rpmtemp/rpmbuild/SOURCES"
      FileUtils.mkdir_p "rpmtemp/rpmbuild/tmp"
    end
end