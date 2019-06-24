require 'hcl/checker'

module Proteus
  module Templates
    class Partial < TemplateBinding

      include Proteus::Helpers::PathHelpers
      include Thor::Shell

      def initialize(name:, context:, environment:, module_name:, data:, data_context: nil, force_rendering: true, deep_merge: false, terraform_variables:, scope_resources: nil)
        @name = name
        @context = context
        @environment = environment
        @module_name = module_name
        @data = data
        @data_context = data_context
        @force_rendering = force_rendering
        @deep_merge = deep_merge
        @terraform_variables = terraform_variables
        @scope_resources = scope_resources

        @defaults = {}
        set(@name.split('/').last, {})

        if data.dig('partials', @name)
          @partial_data_present = true

          @data['partials'][@name].delete('render')

          set(@name, @data['partials'][@name])
        end

      end

      def render
        if partial_data? || @force_rendering
          defaults_file = File.join(module_templates_path(@context, @module_name), 'defaults', "#{@name}.yaml")

          default_partial_path = File.join(module_templates_path(@context, @module_name), "_#{@name}.tf.erb")
          sub_directory_partial_path = File.join(module_templates_path(@context, @module_name), "#{@name}.tf.erb")

          if File.file?(default_partial_path)
            partial_file = default_partial_path
          else
            partial_file = sub_directory_partial_path
          end


          if File.file?(partial_file)
            partial_template = File.read(partial_file)

            if File.file?(defaults_file)
              @defaults = YAML.load_file(defaults_file, {}).with_indifferent_access

              partial_data = instance_variable_get("@#{@name}")

              if @deep_merge == false
                @defaults.each do |key, value|
                  if !partial_data.key?(key)
                    partial_data[key] = value
                  end
                end
              elsif @deep_merge == :each
                merged_data = []

                partial_data.each do |item|
                  merged_data << @defaults.deep_merge(item)
                end

                instance_variable_set("@#{@name.split('/').last}", merged_data)
              else
                instance_variable_set("@#{@name.split('/').last}", @defaults.deep_merge(partial_data))
              end

            end

            begin
              if @scope_resources
                return scope_resources(manifest: Erubis::Eruby.new(partial_template).result(get_binding), scope: @scope_resources)
              else
                return Erubis::Eruby.new(partial_template).result(get_binding)
              end
            rescue Exception => e
              say "Error in partial: #{partial_file}", :magenta
              e.backtrace.each { |line| say line, :magenta }
              say e.message, :magenta
              exit 1
            end
          end
        end
      end

      def partial_data?
        @partial_data_present
      end

      def scope_resources(manifest:, scope:)
        scoped = []
        manifest.each_line do |line|
          if matches = line.match(/resource( +)"(?<resource_type>[a-z0-9_]+)"( +)"(?<resource_name>[a-zA-Z0-9_\-]+)"( +)(\{)/)
            say "MATCHED RESOURCE: #{line}", :green
            matches = matches.named_captures.with_indifferent_access
            scoped << "resource \"#{matches[:resource_type]}\" \"#{scope}_#{matches[:resource_name]}\" {"
            say "CHANGED TO:       #{scoped.last}", :green
          elsif matches = line.match(/(?<pre>.*(\{|\())(?<data>data\.)?(?<resource_type>(?<provider>aws|kubernetes|helm|tls_private_key|null_resource)[a-z_0-9]*)\.(?<resource_name>[a-z0-9_]+)(?<attribute>(?<wildcard>.\*)?\.[a-z_]+)?(?<post>.*)?/)
            matches = matches.named_captures.with_indifferent_access

            if !matches[:data]
              say "MATCHED REFERENCE: #{line}", :green
              scoped << "#{matches[:pre]}#{matches[:resource_type]}.#{scope}_#{matches[:resource_name]}#{matches[:attribute]}#{matches[:post]}"
              say "CHANGED TO:        #{scoped.last}", :green
            else
              scoped << line
            end
          else
            scoped << line
          end
        end
        scoped.map!(&:chomp).join("\n")
      end
    end
  end
end
