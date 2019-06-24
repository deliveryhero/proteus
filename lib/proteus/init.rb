require 'proteus/generators/init'

module Proteus
  class Init < Thor
    include Thor::Actions
    include Helpers

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), 'generators', 'templates'))
    end

    include Generators::Init

    default_task :init
  end
end
