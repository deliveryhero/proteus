module Proteus
  module Templates
    class TemplateBinding

      include Proteus::Helpers::PathHelpers
      include Proteus::Helpers::StringHelpers

      def initialize(context:, environment:, module_name:, data: {}, defaults:  [])
        @context = context
        @environment = environment
        @module_name = module_name

        data.each do |key, value|
          set(key, value)
        end
        @defaults = defaults
      end

      def set(name, value)
        instance_variable_set("@#{name}", value)
      end

      def get_binding
        binding
      end

      def render_defaults(context, demo: false)
        @defaults.inject("") do |memo, default|
          if context.has_key?(default)
            memo << "#{demo ? "# " : ""}#{default} = \"#{context[default]}\"\n"
          else
            memo
          end
        end
      end

      # return output of partial template
      # name: symbol (template_name)
      def render_partial(name:, data:, data_context: nil, force_rendering: true, deep_merge: false, scope_resources: nil)
        partial = Partial.new(
          name: name.to_s,
          context: @context,
          environment: @environment,
          module_name: @module_name,
          data: data,
          data_context: data_context,
          force_rendering: force_rendering,
          deep_merge: deep_merge,
          terraform_variables: @terraform_variables,
          scope_resources: scope_resources
        )

        partial.render
      end

      def default_true(context, key)
        return context.has_key?(key) ? context[key] : true
      end
    end
  end
end

