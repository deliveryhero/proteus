module Proteus
  module Generators
    module Environment
      def self.included(thor_class)
        thor_class.class_eval do

          desc "environment ENVIRONMENT", "Generate configuration for a new environment / region"
          option :context, type: :string, aliases: "-c", default: "default"
          option :environment, type: :string, aliases: "-e", required: true
          def environment

            if options[:context] !~ /^([a-z0-9])+(_{1}[a-z0-9]+)*$/
              say "The name of your context has to be valid snake case. For example: 'foo_bar'", :red
              exit 1
            end

            if options[:environment] !~ /^([a-z0-9])+(_{1}[a-z0-9]+)*$/
              say "The name of your environment has to be valid snake case. For example: 'foo_bar'", :red
              exit 1
            end

            template_binding = Proteus::Templates::TemplateBinding.new(
              environment: options[:environment],
              context: options[:context],
              module_name: nil
            )

            template(
              'environment/terraform.tfvars.erb',
              File.join(destination_root,
              'contexts',
              options[:context],
              'environments',
              "terraform.#{options[:environment]}.tfvars"),
              context: template_binding.get_binding
            )
          end
        end
      end
    end
  end
end
