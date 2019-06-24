require 'proteus/helpers/path_helpers'
require 'proteus/modules/terraform_module'
require 'proteus/backend/backend'

module Proteus
  module Modules

    class Manager
      include Thor::Shell
      include Proteus::Helpers::PathHelpers

      def initialize(context:, environment:)
        @context = context
        @environment = environment
        initialize_modules
      end

      def render_modules
        @modules.map(&:process)
      end

      def clean
        @modules.map(&:clean)
      end

      private

      def initialize_modules
        say "Initializing modules", :green

        tfvars_content = File.read(File.join(environments_path(@context), "terraform.#{@environment}.tfvars"))

        if tfvars_content.empty?
          terraform_variables = []
        else
          terraform_variables = HCL::Checker.parse(tfvars_content).with_indifferent_access
        end

        @modules = []

        Dir.glob("#{modules_path(@context)}/*").each do |directory|
          @modules << TerraformModule.new(
            name: File.basename(directory),
            context: @context,
            environment: @environment,
            terraform_variables: terraform_variables
          )
        end
      end

    end
  end
end
