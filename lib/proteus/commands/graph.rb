module Proteus
  module Commands
    module Graph
      def self.included(thor_class)
        thor_class.class_eval do

          desc "graph", "Creates a graph showing the resources and their relations."
          def graph
            say "Generating graph. This might take a while"
            graph_command = <<~GRAPH_COMMAND
              cd #{context_path(context)} \
              && terraform graph -draw-cycles -module-depth=1 | dot -Tpng > graph.png \
              && open graph.png
            GRAPH_COMMAND
            `#{graph_command}`
          end

        end
      end
    end
  end
end
