module Proteus
  module Helpers
    module StringHelpers
      def camel_case(input)
        input.split('_').collect(&:capitalize).join
      end

      def _(input)
        input.gsub('-', '_')
      end
    end
  end
end
