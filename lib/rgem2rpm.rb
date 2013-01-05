# -*- encoding : utf-8 -*-
# initialize module RGem2Rpm
# added ruby 1.9 combatibility for gem build
#
lib = File.dirname(__FILE__)

require lib + '/rgem2rpm/version'
require lib + '/rgem2rpm/argumentparse'
require lib + '/rgem2rpm/converter'
require lib + '/rgem2rpm/gem'
require lib + '/rgem2rpm/rpm'
