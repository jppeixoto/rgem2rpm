require 'rgem2rpm/ext/builder'

class RGem2Rpm::Ext::RakeBuilder < RGem2Rpm::Ext::Builder

  def self.build(extension, dest_path)
    # create build string
    build = StringIO.new
    if File.basename(extension) =~ /mkrf_conf/i then
      build << "#{File.basename Gem.ruby} #{extension}"
      build << " #{Gem::Command.build_args.join " "}" unless Gem::Command.build_args.empty?
      build << "\n"
    end

    # Deal with possible spaces in the path, e.g. C:/Program Files
    dest_path = '"' + dest_path + '"' if dest_path.include?(' ')

    rake = ENV['rake']

    rake ||= begin
               "\"#{File.basename Gem.ruby}\" -rubygems #{Gem.bin_path('rake')}"
             rescue Gem::Exception
             end

    rake ||= Gem.default_exec_format % 'rake'

    build << "#{rake} RUBYARCHDIR=#{dest_path} RUBYLIBDIR=#{dest_path}" # ENV is frozen
    # return build string
    return build.string
  end

end

