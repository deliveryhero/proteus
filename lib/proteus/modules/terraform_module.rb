require 'proteus/helpers/path_helpers'
require 'proteus/helpers/string_helpers'
require 'proteus/modules/defaults_parser'
require 'yaml'
require 'fileutils'

module Proteus
  module Modules
    class TerraformModule
      @@hooks = {}

      include Thor::Shell
      extend Thor::Shell
      include Proteus::Helpers::PathHelpers
      extend Proteus::Helpers::PathHelpers
      include Proteus::Helpers::StringHelpers

      attr_reader :name

      def initialize(name:, context:, environment:, terraform_variables:)
        @name = name
        @context = context
        @environment = environment
        @terraform_variables = terraform_variables
        @hook_variables = {}
      end

      def process
        clean
        run_hooks
        load_data
        return if !data?
        validate
        render
      end

      def clean
        File.file?(manifest) ? FileUtils.rm(manifest) : nil
      end

      def self.register_hook(module_name, hook)
        @@hooks[module_name] ||= Array.new
        @@hooks[module_name] << hook
      end

      def run_hooks
        Dir.glob(File.join(module_hooks_path(@context, @name), '*')).each do |file|
          require file
        end

        hooks_module = "Proteus::Modules::#{camel_case(@name)}::Hooks"
        if Kernel.const_defined?(hooks_module)
          say "Hooks present for module #{@name}", :green
          Kernel.const_get(hooks_module).constants.each do |constant|
            say "Found hook: #{constant}", :green
            self.class.include(Kernel.const_get("#{hooks_module}::#{constant}"))
          end
        end

        if @@hooks.key?(@name)
          @@hooks[@name].each do |hook|
            hook_result = hook.call(@environment, @context, @name)

            if hook_result.is_a?(Hash)
              @hook_variables.merge!(hook_result)
            end

            @@hooks[@name].delete(hook)
          end
        end
      end

      private


      def load_data
        @data = {}

        if File.file?(config_file)
          @data = YAML.load_file(config_file, {}).with_indifferent_access
          load_referenced_data(@data)

           puts "LOADED DATA"
          pp @data
        end
      end

      def i(i)
        ' ' * 2 * i
      end

      def read(data)
        if data.end_with?('.yaml')
          # single file load request
          file = File.join(module_data_path(@context, @name), data)
          YAML.load_file(file)
        else
          files = Dir.glob(
            File.join(module_data_path(@context, @name), data, '*.yaml')
          )

          files.collect do |f|
            YAML.load_file(f)
          end.flatten
        end
      end

      def load_referenced_data(data, indent: 0, debug: false)
        if data.is_a?(Array)
          puts "#{i(indent)}Array" if debug
          data.each_with_index do |_, index|
            load_referenced_data(data[index], indent: indent + 1)
          end
        elsif data.is_a?(Hash)
          puts "#{i(indent)}Hash" if debug
          data.each do |key, value|
            if value =~ /__load: (.*)/
              puts "#{i(indent)}LOAD #{Regexp.last_match(1)}" if debug
              data[key] = read(Regexp.last_match(1))
            end
            load_referenced_data(data[key], indent: indent + 1)
          end
        elsif debug
          puts "#{i(indent)}Scalar: #{data}"
        end
      end

      def data?
        return false unless @data

        @data.any?
      end

      def validate
        if data? && File.file?(validator_file)
          require validator_file

          begin
            validator_class = "Proteus::Validators::#{camel_case(@name)}Validator"

            Kernel.const_get(validator_class).new(@data, @environment)

            say "Ran #{camel_case(@name)}Validator for environment #{@environment} #{"\u2714".encode('utf-8')}", :green
          rescue Proteus::Validators::ValidationError => validation_error
            say "#{validator_class}: #{validation_error.message} [modules/#{@name}/config/#{@environment}.yaml] #{"\u2718".encode('utf-8')}", :red
            exit 1
          end
        else
          say "Module #{@name} has no validator.", :magenta
        end
      end

      def render
        File.open(manifest, "w") do |manifest|
          manifest << global_resources

          @data.fetch('template_data', {}).each do |template, data|
            manifest << render_template(File.join(module_templates_path(@context, @name), "#{template}.tf.erb"), data)
          end
        end
      end

      def render_template(template_file, data)
        if File.file?(template_file)
          template = File.read(template_file)
          begin
            return "#{Erubis::Eruby.new(template).result(template_binding(data).get_binding)}\n\n"
          rescue Exception => e
            say "Error in template: #{template_file}", :magenta
            e.backtrace.each { |line| say line, :magenta }
            say e.message, :magenta
            exit 1
          end
        end
      end

      def template_binding(data)
        binding = Proteus::Templates::TemplateBinding.new(
          context: @context,
          environment: @environment,
          module_name: @name,
          data: data,
          defaults: parse_defaults
        )

        binding.set(:terraform_variables, @terraform_variables)

        @hook_variables.each do |key, value|
          binding.set(key, value)
        end

        binding
      end

      def parse_defaults
        return [] unless File.file?(File.join(module_path(@context, @name), 'io.tf'))

        defaults_parser = DefaultsParser.new(File.read(File.join(module_path(@context, @name), 'io.tf')))
        defaults_parser.parse_variables

        return defaults_parser.variables
      end

      def global_resources
        Dir.glob(File.join(module_config_path(@context, @name), 'global_resources/*')).inject("") do |memo, resource_file|
					if resource_file =~ /tf\.erb/
						"#{memo}\n#{render_template(resource_file, @data.dig('global_resources', File.basename(resource_file, '.tf.erb')))}"
					else
          "#{memo}#{File.read(resource_file)}\n"
					end
        end
      end

      def config_file
        File.join(module_config_path(@context, @name), "#{@environment}.yaml")
      end

      def validator_file
        File.join(module_config_path(@context, @name), 'validator.rb')
      end

      def manifest
        File.join(context_root_path(@context), "#{@name}.tf")
      end
    end
  end
end
