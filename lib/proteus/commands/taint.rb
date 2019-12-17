module Proteus
  module Commands
    module Taint
      def self.included(thor_class)
        thor_class.class_eval do

          desc "taint", "Taints an existing resource"
          long_desc <<-LONGDESC
            Taints an existing resource

            --resource The resource to taint
          LONGDESC
          option :resource, type: :string, aliases: "-r", required: true
          option :module, type: :string, aliases: "-m", required: false, default: nil
          def taint
            init(verbose: parent_options[:verbose])
            confirm question: "Do you really want to run 'terraform taint' on environment '#{environment}' in context '#{context}'?", color: :on_red, exit_code: 0 do

              taint_command = <<~TAINT_COMMAND
                cd #{context_path(context)} && \
                terraform taint \
                #{options[:module] ? "-module=#{options[:module]}" : ""} \
                #{options[:resource]}
              TAINT_COMMAND
              syscall taint_command.squeeze(' ')
            end
          end

        end
      end
    end
  end
end
