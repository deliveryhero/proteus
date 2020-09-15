require 'proteus/modules/manager'
require 'proteus/helpers'

module Proteus
  module GlobalCommands
    module Validate

      include Proteus::Helpers

      def self.included(thor_class)
        thor_class.class_eval do
          desc "validate", "Renders templates for all contexts and environments"

          long_desc <<-LONGDESC
            Renders templates for all environments, reporting validation errors.
          LONGDESC
          option :selective, type: :boolean, default: false
          def validate
            # case 1: changes in root => run full validation
            # case 2: no changes in root => run contexts only
            status = `git --no-pager diff origin/master --stat --name-only`.split("\n")

            run_full_validation = if status.map {|l| !l.include?('/') }.any? || !options[:selective]
                                    say "Found changes in the root of the repository or --selective is not set. Running full validation.", :green
                                    true
                                  else
                                    say "Running selective validation.", :green
                                    false
                                  end
            selected_contexts = status.map { |s| s.scan(/contexts\/([a-zA-Z0-9_]+)\/((.+)\/)?/).flatten.first }.reject { |s| s.nil? }.uniq!

            self.class.contexts.each do |context|
              unless run_full_validation
                if !selected_contexts.include?(context.name)
                  say "Skipping context #{context.name}.", :green
                  next
                end
              end

              context.environments.each do |environment|
                module_manager = Proteus::Modules::Manager.new(context: context.name, environment: environment)
                module_manager.render_modules

                terraform = ENV.key?("TERRAFORM_BINARY") ? ENV["TERRAFORM_BINARY"] : "terraform"

                validate_command = <<~VALIDATE_COMMAND
                  cd #{context_path(context.name)} \
                  && #{terraform} init -backend=false \
                  && #{terraform} get \
                  && #{terraform} validate -var-file=#{var_file(context.name, environment)} -var 'aws_profile=needs_to_be_set'
                VALIDATE_COMMAND

                `#{validate_command.squeeze(' ')}`

                say "Validated (context: #{context.name}, environment: #{environment}) #{"\u2714".encode('utf-8')}", :green
                exit 1 if $?.exitstatus == 1
                module_manager.clean
              end
            end
          end

        end
      end
    end
  end
end
