module Proteus
  module Commands
    module Destroy
      def self.included(thor_class)
        thor_class.class_eval do

          desc "destroy", "Destroys AWS resources."
          long_desc <<-LONGDESC
            Destroys AWS resources.

            With --limit option, Terraform will only destroy the specified resources
            If --limit does not get passed as an argument, terraform will destroy all of the AWS assets in the state.
          LONGDESC
          option :limit, type: :array, aliases: "-l", required: false
          def destroy
            init(verbose: parent_options[:verbose])

            destroy_command = <<~DESTROY_COMMAND
              cd #{context_path(context)} && \
              terraform destroy \
              -var-file=#{var_file(context, environment)} \
              #{aws_profile} \
              ##{limit(options[:limit])}
            DESTROY_COMMAND

            plan_destroy_command = <<~PLAN_DESTROY_COMMAND
              cd #{context_path(context)} && \
              terraform plan \
              -destroy \
              -out=#{plan_file(context, environment)} \
              -var-file=#{var_file(context, environment)} \
              #{aws_profile} \
              ##{limit(options[:limit])}
            PLAN_DESTROY_COMMAND


            if dryrun
              puts destroy_command.squeeze(' ')
            else
              syscall plan_destroy_command.squeeze(' ')
              confirm question: "Do you really want to run 'terraform destroy' on environment '#{environment}'?", color: :on_red, exit_code: 0 do
                exec destroy_command.squeeze(' ')
              end
            end
          end

        end
      end
    end
  end
end
