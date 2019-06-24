module Proteus
  module Commands
    module Remove
      def self.included(thor_class)
        thor_class.class_eval do

          desc "remove", "Remove a resource from the terraform state"
          long_desc <<-LONGDESC
            Remove a resource from the terraform state
            --bulk Enables bulk import mode

            --resource_address Terraform address of resource to remove from the terraform state

            --resources_file File containing resource addresses and identifiers
          LONGDESC
          option :bulk, type: :boolean, aliases: "-b", required: false, default: false
          option :resource_address, type: :string, aliases: "-a", required: false, default: nil
          option :resources_file, type: :string, aliases: "-f", required: false, default: nil
          def remove
            if options[:bulk]
              if !options[:resources_file]
                say "Supply a file containing resource identifiers and Terraform addresses for bulk operations", :red
                exit 1
              end
            else
              if !options[:resource_address]
                say "You need to supply a resource address.", :red
                exit 1
              end
            end

            init(verbose: parent_options[:verbose])

            confirm question: "Do you really want to run 'terraform state rm' in context '(#{context}, #{environment})'?", color: :on_red, exit_code: 0 do
              state_remove_command = <<~STATE_REMOVE_COMMAND
                cd #{context_path(context)} && \
                terraform state rm \
                -var-file=#{var_file(context, environment)} \
                #{aws_profile} \
                %{resource_addresses}
              STATE_REMOVE_COMMAND

              if options[:bulk]
                if File.file?(options[:resources_file])
                  File.open(options[:resources_file], "r") do |file|
                    resource_addresses = []
                    file.each_line do |line|
                      resource = line.chomp.split(" = ")
                      resource_addresses << resource[0]
                    end

                    resource_addresses.each_slice(500) do |slice|
                      syscall (state_remove_command % { resource_addresses: slice.join(' ') }).squeeze(' ')
                    end

                  end
                else
                  say "File #{options[:resources_file]} does not exist.", :red
                  exit 1
                end
              else
                syscall (state_remove_command % { resource_addresses: options[:resource_address] })
              end
            end
          end

        end
      end
    end
  end
end
