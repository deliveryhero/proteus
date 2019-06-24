require 'proteus/generators/context'
require 'proteus/generators/environment'
require 'proteus/generators/module'

module Proteus
  class Generate < Thor
    include Thor::Actions
    include Helpers

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), 'generators', 'templates'))
    end

    include Generators::Context
    include Generators::Environment
    include Generators::Module
  end
end
