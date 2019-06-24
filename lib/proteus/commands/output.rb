module Proteus
  module Commands
    module Output
      def self.included(thor_class)
        thor_class.class_eval do

          desc "output", "Query Terraform outputs"
          long_desc <<-LONGDESC
            Query Terraform outputs.
          LONGDESC
          option :name, type: :string, default: nil, required: false
          def output

            init(verbose: parent_options[:verbose])

            terraform_command = <<~TERRAFORM_COMMAND
              cd #{context_path(context)} && \
              terraform output \
              -state=#{state_file(context, environment)} \
              #{options[:name] ? options[:name] : ''}
            TERRAFORM_COMMAND

            syscall(terraform_command.squeeze(' '))
          end
        end
      end
    end
  end
end
