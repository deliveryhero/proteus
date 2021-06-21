require 'proteus/modules/manager'

module Proteus
  module Commands
    module Render
      def self.included(thor_class)
        thor_class.class_eval do

          desc "render", "Renders the module templates"
          long_desc <<-LONGDESC
            Renders the module templates without running Terraform
          LONGDESC
          option :init, type: :boolean, default: false
          def render
            render_backend
            module_manager = Proteus::Modules::Manager.new(context: context, environment: environment)
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

            init(verbose: parent_options[:verbose]) if options[:init]

            say "Formatted files:", :green
            say fmt_output, :green
          end
        end
      end
    end
  end
end
