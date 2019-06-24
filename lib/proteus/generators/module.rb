module Proteus
  module Generators
    module Module
      def self.included(thor_class)
        thor_class.class_eval do

          desc "module", "Generate a new module"
          option :context, type: :string, aliases: "-c", default: "default"
          option :module_name, type: :string, aliases: "-m", required: true
          def module

            unless File.directory?(context_path(options[:context]))
              say "The context #{options[:context]} does not exist.", :red
            end

            # check for valid module name
            if options[:module_name] !~ /^([a-z0-9])+(_{1}[a-z0-9]+)*$/
              say "The name of your module has to be valid snake case. For example: 'foo_bar'", :red
              exit 1
            end

            template_binding = Proteus::Templates::TemplateBinding.new(
              context: nil,
              environment: nil,
              module_name: options[:module_name],
            )

            module_directory = File.join(modules_path(options[:context]), options[:module_name])
            empty_directory(module_directory)

            template('module/io.tf.erb', File.join(module_directory, 'io.tf'), context: template_binding.get_binding)
            template('module/module.tf.erb', File.join(module_directory, "#{options[:module_name]}.tf"), context: template_binding.get_binding)


            confirm(question: "Will this module be included iteratively?", color: :green, exit_on_no: false) do

              empty_directory(File.join(module_directory, 'config'))
              empty_directory(File.join(module_directory, 'config', 'global_resources'))
              empty_directory(File.join(module_directory, 'config', 'templates'))

              confirm(question: "Do you want to implement validators for this module?", color: :green, exit_on_no: false) do
              template_binding = Proteus::Templates::TemplateBinding.new(
                context: nil,
                environment: nil,
                module_name: options[:module_name].split('_').collect(&:capitalize).join,
              )
                template('module/validator.rb.erb', File.join(module_directory, 'config', "validator.rb"), context: template_binding.get_binding)
              end

              say("Go ahead and create a configuration file for your environment in #{options[:module_name]}/config/your_environment.yaml", :green)

              # add /contexts/context/module_name.tf to gitignore
              gitignore = File.join(destination_root, ".gitignore")
              matches = File.readlines(gitignore).select do |line|
                line.match(/\/contexts\/#{options[:context]}\/#{options[:module_name]}/)
              end

              if matches.none?
                File.open(gitignore, 'a') do |file|
                  file.puts "/contexts/#{options[:context]}/#{options[:module_name]}.tf"
                end
              end
            end
          end # #module
        end # class_eval
      end # self.included
    end # module Module
  end # module Generators
end
