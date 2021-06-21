require 'proteus/helpers/path_helpers'
require 'proteus/modules/terraform_module'
require 'proteus/backend/backend'
require 'proteus/modules/defaults_parser'
require 'json'

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
          terraform_variables = JSON.parse(parse_tfvars(tfvars: tfvars_content)).merge({
            'proteus_environment' => @environment
          })
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

      def parse_tfvars(tfvars:)
        lines = tfvars.split("\n")
        lines.reject! {|l| l.empty? || l.match(/#/) }
        substituted_lines = []

        lines.each_with_index do |line, index|
          next_line = lines[index + 1] || ""

          # insert comma after closing bracket and curly brace
          if line =~ /\]$|\}$/ && index != lines.size-1
            substituted_lines << "#{line},"
          else
            if index == lines.size-1 || line =~ /\[|\{/ || next_line =~ /\]|\}/
              substituted_lines << line.gsub(/([a-z0-9_]+)( *=)(.*)/,  "\"\\1\": \\3")
              if substituted_lines.last =~ /,$/ && next_line =~ /\]|\}/
                substituted_lines.last.gsub!(/,$/, "")
              end
            else
              if line =~ /=/
                substituted_lines << line.gsub!(/([a-z0-9_]+)( *=)(.*)/,  "\"\\1\": \\3,")
              else
                substituted_lines << line
              end
            end
          end
        end

        "{\n#{substituted_lines.join("\n")}\n}"
      end
    end
  end
end
