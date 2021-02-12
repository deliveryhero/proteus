module Proteus
  module Commands
    module Apply
      def self.included(thor_class)
        thor_class.class_eval do

          desc 'apply', 'Applies the current terraform code'
          long_desc <<-LONGDESC
            Applies the current terraform code
          LONGDESC
          def apply
            init(verbose: parent_options[:verbose])

            confirm question: "Do you really want to run 'terraform apply' on environment '#{environment}' in context '#{context}'?", color: :on_red, exit_code: 0 do


              if !options[:dryrun]
                slack_notification(
                    context:  context,
                    environment: environment,
                    message: 'is running terraform apply. Wait for it.'
                  )
              end

              apply_command = <<~APPLY_COMMAND
                cd #{context_path(context)} && \
                terraform apply \
                -input=true \
                -refresh=true \
                #{plan_file(context, environment)}
              APPLY_COMMAND

              syscall apply_command.squeeze(' '), dryrun: dryrun

              if !options[:dryrun]
                slack_notification(
                    context: context,
                    environment: environment,
                    message: 'applied a new version of me!'
                  )
              end
            end
          end
        end

      end
    end
  end
end
