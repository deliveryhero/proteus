module Proteus
  module Generators
    module Init
      def self.included(thor_class)
        thor_class.class_eval do

          desc 'init', 'Initializes a new proteus root directory in the current working directory'
          def init

            say 'Creating config directory.', :green
            empty_directory(config_dir)

            say 'Creating sample config.', :green
            template(
              'config/config.yaml.erb',
              File.join(
                config_dir,
                'config.yaml'
              )
            )

            say 'Creating contexts directory.', :green
            empty_directory(contexts_path)

            confirm(question: 'Do you want to create a default proteus context?', color: :green, exit_on_no: false) do
              invoke 'proteus:generate:context', ['default']
            end

            confirm(question: 'Do you want to create a sample proteus environment?', color: :green, exit_on_no: false) do
              invoke 'proteus:generate:environment', [], context: 'default', environment: 'staging'
            end

            say "proteus root directory created.", :green
            say "Please customize config/config.yaml. Then go ahead and create some modules.", :green
          end
        end
      end
    end
  end
end
