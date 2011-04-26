require 'rgem2rpm/ext/builder'

class RGem2Rpm::Ext::ExtConfBuilder < RGem2Rpm::Ext::Builder

  def self.build(extension, dest_path)
    # create build string
    build = StringIO.new
    build << "cd %{prefix}/gems/%{name}-%{version}/#{File.dirname extension}\n"
    build << "#{File.basename Gem.ruby} #{File.basename extension}"
    #build << " #{Gem::Command.build_args.join ' '}" unless Gem::Command.build_args.empty?
    build << " #{redirector}\n"
    # get make commands
    build << make_str(dest_path)
    return build.string
  end

end
