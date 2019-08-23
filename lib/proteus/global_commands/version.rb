module Proteus
  module GlobalCommands
    module Version

      def self.included(thor_class)
        thor_class.class_eval do
          desc "version", "Print version information"

          long_desc <<-LONGDESC
            Print version information
          LONGDESC
          def version
            say Proteus::VERSION, :green
          end
        end
      end
    end
  end
end
