module Proteus
  module Commands
    module StateCommands
      module Move
        def self.included(thor_class)
          thor_class.class_eval do

            desc "move FROM TO", "Moves an existing resource within the Terraform state"
            def move(from, to)
              init(verbose: parent_options[:verbose])
              confirm question: "Do you really want to move #{from} to #{to} in context '(#{context}, #{environment})'?", color: :on_red, exit_code: 0 do

                state_move_command = <<~STATE_MOVE_COMMAND
                  cd #{context_path(context)} && \
                  terraform state mv \
                  #{from} \
                  #{to}
                STATE_MOVE_COMMAND
                syscall state_move_command.squeeze(' '), dryrun:  dryrun
              end
            end

          end
        end
      end
    end
  end
end
