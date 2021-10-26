require 'proteus/helpers/path_helpers'

module Proteus
  module Backend
    class Backend
      include Proteus::Helpers::PathHelpers
      include Thor::Shell

      attr_reader :backend_key

      def initialize(config:, context:, environment:)
        @config = config
        @context = context
        @environment = environment

        find_backend_key
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

      def show_backends
        require 'terminal-table'
        table = Terminal::Table.new do |t|
            t << ['Context', 'Environment', 'Profile', 'Bucket']

          @config[:contexts].each do |ctx|
            ctx[:environments].each do |env|
              env[:match].each do |m|
                t << [
                  ctx[:name],
                  m,
                  @config[:backend][env[:backend]][:profile],
                  @config[:backend][env[:backend]][:bucket][:name]
                ]
              end
            end
          end
        end

        say table, :green

      end

      def aws_profile
        @config[:backend][@backend_key][:profile]
      end

      protected

      def find_backend_key
        @config[:contexts].each do |ctx|
          if ctx[:name] == @context
            ctx[:environments].each do |env|
              env[:match].each do |m|
                if @environment == m
                  @backend_key = env[:backend]
                  say "Using backend #{@backend_key}", :green
                  return
                end
              end
            end
          end
        end
      end

      def template
        <<~TEMPLATE
          terraform {
            backend "s3" {
              bucket  = "<%= @config[:backend][@backend_key][:bucket][:name] %>"
              key     = "<%= @config[:backend][@backend_key][:key_prefix] %>#{@context}-#{@environment}.tfstate"
              region  = "<%= @config[:backend][@backend_key][:bucket][:region] %>"
              profile = "<%= @config[:backend][@backend_key][:profile]%>"
              <%- if (@config[:backend][@backend_key].keys & ["encrypt", "kms_key_id"]).size == 2 -%>
              encrypt = true
              kms_key_id = "<%= @config[:backend][@backend_key][:kms_key_id] %>"
              <%- end -%>
            }
          }
        TEMPLATE
      end
    end
  end
end
