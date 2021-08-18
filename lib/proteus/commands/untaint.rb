module Proteus
  module Commands
    module Untaint
      def self.included(thor_class)
        thor_class.class_eval do

          desc "untaint", "Untaints an existing resource"
          long_desc <<-LONGDESC
            Untaints an existing resource

            --resource The resource to untaint
          LONGDESC
          option :resource, type: :string, aliases: "-r", required: true
          def untaint
            init(verbose: parent_options[:verbose])
            confirm question: "Do you really want to run 'terraform untaint' on environment '#{environment}' in context '#{context}'?", color: :on_red, exit_code: 0 do

              untaint_command = <<~UNTAINT_COMMAND
                cd #{context_path(context)} && \
                terraform untaint \
                #{options[:resource]}
              UNTAINT_COMMAND
              syscall untaint_command.squeeze(' ')
            end
          end

        end
      end
    end
  end
end
