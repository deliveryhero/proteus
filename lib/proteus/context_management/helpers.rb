module Proteus
  module ContextManagement
    module Helpers
      include Proteus::Helpers::PathHelpers
      def contexts
        say "loading contexts", :green

        Dir.glob(File.join(contexts_path, "*")).collect do |context_path|
          Context.new(name: File.basename(context_path))
        end
      end
    end
  end
end
