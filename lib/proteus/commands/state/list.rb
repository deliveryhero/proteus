module Proteus
  module Commands
    module StateCommands
      module List
        def self.included(thor_class)
          thor_class.class_eval do

            desc "list", "List resources in the state"
            def list
              list_cmd = <<~LIST_CMD
                cd #{context_path(context)} && \
                terraform state list
              LIST_CMD

              init(verbose: parent_options[:verbose])

              syscall list_cmd.squeeze(' ')
            end

          end
        end
      end
    end
  end
end
