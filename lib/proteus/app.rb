require 'proteus/common'
require 'proteus/generate'
require 'proteus/init'
require 'proteus/global_commands/validate'
require 'proteus/global_commands/version'
require 'proteus/context_management/context'
require 'proteus/context_management/helpers'
require 'proteus/templates/template_binding'
require 'proteus/templates/partial'

module Proteus

  class Context < Thor; end

  class App < Thor
    extend Proteus::Helpers
    extend Proteus::Helpers::StringHelpers
    extend Proteus::ContextManagement::Helpers

    class_option :dryrun, type: :boolean, default: false, aliases: '-d'
    class_option :verbose, type: :boolean, default: false, aliases: '-v'

    contexts.each do |context|

      if context.name != 'default'

        # generate class for subcommand within contexts subcommand
        context_subcommand_class = Class.new(Thor)
        context_subcommand_class_name = camel_case(context.name)
        Object.const_set(context_subcommand_class_name, context_subcommand_class)

        Proteus::Context.class_eval do
          desc "#{context.name} SUBCOMMAND", "Manage the #{context.name} context."
          subcommand(context.name, const_get(context_subcommand_class_name))
        end
      end

      mod_name = Object.const_set("Module#{camel_case(context.name)}", Module.new)

      context.environments.each do |environment|
        class_name = camel_case(environment)

        klass = Class.new(Proteus::Common)

        mod_name.const_set(class_name, klass)

        klass.class_eval do
          include Config
          @context = context.name
          @environment = environment

          def self.context
            @context
          end

          def self.environment
            @environment
          end
        end

        if context.name == 'default'
          # attach subcommands for the standard environments directly
          # eg.:
          # ./proteus production_eu SUBCOMMAND
          desc "#{environment} SUBCOMMAND", "Manage the #{environment} environment in context default"
          subcommand(environment, mod_name.const_get(class_name))
        else
          const_get(context_subcommand_class_name).class_eval do
            desc "#{environment} SUBCOMMAND", "Manage the #{environment} environment in context #{context.name}"
            subcommand(environment, mod_name.const_get(class_name))
          end
        end
      end
    end

    desc 'generate SUBCOMMAND', 'Generators for modules and environments'
    subcommand('generate', Proteus::Generate)

    desc 'context SUBCOMMAND', 'Context subcommands'
    subcommand('context', Context)

    desc 'init', 'Initializes a new proteus root directory in the current working directory'
    subcommand('init', Proteus::Init)

    include Proteus::GlobalCommands::Validate
    include Proteus::GlobalCommands::Version
  end
end
