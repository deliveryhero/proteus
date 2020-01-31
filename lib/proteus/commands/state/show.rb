module Proteus
  module Commands
    module StateCommands
      module Show
        def self.included(thor_class)
          thor_class.class_eval do

            desc "show", "Show a resource in the state"
            def show(resource)
              list_cmd = <<~LIST_CMD
                cd #{context_path(context)} && \
                terraform state show #{resource}
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
