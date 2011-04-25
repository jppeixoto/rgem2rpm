require 'rgem2rpm/ext/builder'

class RGem2Rpm::Ext::ConfigureBuilder < RGem2Rpm::Ext::Builder

  def self.build(extension, dest_path)
    # create make string
    build = StringIO.new
    unless File.exist?('Makefile') then
      build << "sh ./configure --prefix=#{dest_path}"
      build << " #{Gem::Command.build_args.join ' '}" unless Gem::Command.build_args.empty?
      build << "\n"
    end
    # get make commands
    build << make_str(dest_past)
    # return make string
    return build.string
  end

end

