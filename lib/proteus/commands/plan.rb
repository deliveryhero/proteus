module Proteus
  module Commands
    module Plan
      def self.included(thor_class)
        thor_class.class_eval do

          desc "plan", "Runs terraform plan"
          long_desc <<-LONGDESC
            Runs terraform plan.

            With --limit option, the plan run will be limited to the specified targets
          LONGDESC
          option :limit, type: :array, aliases: "-l", default: []
          option :destroy, type: :boolean, default: false
          def plan
            module_manager = Proteus::Modules::Manager.new(context: context, environment: environment)
            module_manager.clean
            module_manager.render_modules

            fmt_cmd = <<~FMT_CMD
              cd #{context_path(context)} && \
              terraform fmt -list=true .
            FMT_CMD

            fmt_output = syscall(
              fmt_cmd.squeeze(' '),
              capture: true,
              suppress: true
            )

            say "Formatted files:", :green
            say fmt_output, :green

            init(verbose: parent_options[:verbose]) if not dryrun

            terraform_command = <<~TERRAFORM_COMMAND
              cd #{context_path(context)} && \
              terraform plan \
              #{"-destroy" if options[:destroy]} \
              -input=false \
              -refresh=true \
              -module-depth=-1 \
              -var-file=#{var_file(context, environment)} \
              -out=#{plan_file(context, environment)} \
              #{aws_profile} #{limit(options[:limit])} \
              #{context_path(context)}
            TERRAFORM_COMMAND

             syscall terraform_command.squeeze(' '), dryrun: dryrun
          end
        end
      end
    end
  end
end
