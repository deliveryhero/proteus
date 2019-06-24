require 'proteus/modules/manager'

module Proteus
  module Commands
    module Clean
      def self.included(thor_class)
        thor_class.class_eval do |klass|

          desc "clean", "Deletes rendered module manifests"
          long_desc <<-LONGDESC
            Deletes rendered module manifests without running Terraform
          LONGDESC
          def clean
            module_manager = Proteus::Modules::Manager.new(context: context, environment: environment)
            module_manager.clean
          end

        end
      end
    end
  end
end
