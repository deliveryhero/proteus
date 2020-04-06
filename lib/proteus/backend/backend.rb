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

        @config[:providers].select {|p| p[:name] == 'aws' }.first[:environments].each do |env|
          env[:match].each do |m|
            if @environment == m
              @provider_environment = env
            end
          end
        end

        @backend_key = @provider_environment[:backend]
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
              bucket  = "<%= @config[:backend][@backend_key][:bucket][:name] %>"
              key     = "<%= @config[:backend][@backend_key][:key_prefix] %>#{@context}-#{@environment}.tfstate"
              region  = "<%= @config[:backend][@backend_key][:bucket][:region] %>"
              profile = "<%= @config[:backend][@backend_key][:bucket][:profile]%>"
            }
          }
        TEMPLATE
      end
    end
  end
end
