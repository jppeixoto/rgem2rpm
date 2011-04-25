require 'rubygems/ext/builder'

class RGem2Rpm::Ext::Builder < Gem::Ext::Builder

  def self.make_str(dest_path)
    # create make command strings
    make = StringIO.new
    # change makefile variables
    make << "sed -i 's/RUBYARCHDIR\s*=\s*\$[^$]*/RUBYARCHDIR = #{dest_path.gsub(/\//, '\/')}/g' Makefile\n"
    make << "sed -i 's/RUBYLIBDIR\s*=\s*\$[^$]*/RUBYLIBDIR = #{dest_path.gsub(/\//, '\/')}/g' Makefile\n"
    make << "make #{redirector}\n"
    # create make command strings
    make << "make install #{redirector}"
    # return make string
    return make.string
  end

  def self.redirector
    '2>&1'
  end

end

