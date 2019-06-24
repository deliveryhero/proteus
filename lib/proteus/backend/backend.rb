require 'proteus/helpers/path_helpers'

module Proteus
  module Backend
    class Backend
      include Proteus::Helpers::PathHelpers
      include Thor::Shell

      def initialize(config:, context:, environment:)
        @config = config
        @context = context
        @environment = environment
      end

      def render
        File.open(File.join(context_path(@context), 'backend.tf'), 'w') do |file|
          file.write(Erubis::Eruby.new(template).result(binding))
        end
      rescue StandardError => e
        say 'Error rendering backend config.', :magenta
        say e.message, :magenta
        exit 1
      end

      protected

      def template
        <<~TEMPLATE
          terraform {
            backend "s3" {
              bucket  = "<%= @config[:backend][:bucket][:name] %>"
              key     = "<%= @config[:backend][:key_prefix] %>#{@context}-#{@environment}.tfstate"
              region  = "<%= @config[:backend][:bucket][:region] %>"
              profile = "<%= @config[:backend][:bucket][:profile]%>"
            }
          }
        TEMPLATE
      end
    end
  end
end
