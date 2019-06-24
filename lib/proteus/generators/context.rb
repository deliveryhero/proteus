module Proteus
  module Generators
    module Context
      def self.included(thor_class)
        thor_class.class_eval do

          desc "context CONTEXT", "Generate a new context"
          def context(context)

            if context !~ /^([a-z0-9])+(_{1}[a-z0-9]+)*$/
              say "The name of your context has to be valid snake case. For example: 'foo_bar'", :red
              exit 1
            end

            context_directory = File.join(context_path(context))
            empty_directory(context_directory)
            empty_directory(File.join(context_directory, 'environments'))
            empty_directory(File.join(context_directory, 'modules'))

            template_binding = Proteus::Templates::TemplateBinding.new(
              context: context,
              environment: nil,
              module_name: nil
            )

            ['main', 'variables'].each do |template_name|
              template(
                "context/#{template_name}.tf.erb",
                File.join(
                  context_directory,
                  "#{template_name}.tf"
                ),
                context: template_binding.get_binding
              )
            end

            gitignore = File.join(destination_root, ".gitignore")

            if File.file?(gitignore)
              matches = File.readlines(gitignore).select do |line|
                line.match(/\/contexts\/#{context}\/backend.tf/)
              end
            end

            if !File.file?(gitignore) || matches.none?
              File.open(gitignore, 'a') do |file|
                file.puts "/contexts/#{context}/backend.tf"
              end
            end

            say "Context #{context} created. Go ahead and create environments and modules.", :green
          end
        end
      end
    end
  end
end
