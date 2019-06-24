module Proteus
  module Commands
    module Import
      def self.included(thor_class)
        thor_class.class_eval do

          desc "import", "Imports an existing resource into the terraform state"
          long_desc <<-LONGDESC
            Imports existing resources into the terraform state

            --address Terraform internal address of the resource

            --bulk Enables bulk import mode

            --resource The resource to import into the terraform state

            --resources_file File containing resource addresses and identifiers
          LONGDESC
          option :address, type: :string, aliases: "-a", default: nil
          option :bulk, type: :boolean, aliases: "-b", required: false, default: false
          option :resource, type: :string, aliases: "-r", default: nil
          option :resources_file, type: :string, aliases: "-f", required: false, default: nil
          def import
            if options[:bulk]
              if !options[:resources_file]
                say "Supply a file containing resource identifiers and Terraform addresses for bulk operations", :red
                exit 1
              end
            else
              if !(options[:address] || !options[:resource])
                say "You need to supply a resource address and a resource.", :red
                exit 1
              end
            end

            init(verbose: parent_options[:verbose])

            confirm question: "Do you really want to run 'terraform import' in context '(#{context}, #{environment})'?", color: :on_red, exit_code: 0 do

              import_command = <<~IMPORT_COMMAND
                cd #{context_path(context)} && \
                terraform import \
                -var-file=#{var_file(context, environment)} \
                #{aws_profile} \
                %{address} \
                %{resource}
              IMPORT_COMMAND

              if options[:bulk]
                if File.file?(options[:resources_file])
                  File.open(options[:resources_file], "r") do |file|
                    resource_count = File.foreach(file).inject(0) {|count, line| count + 1}
                    index = 1
                    file.each_line do |line|
                      say "Processing resource #{index}/#{resource_count}", :green
                      resource = line.chomp.split(" = ")
                      syscall (import_command % { address: resource[0], resource: resource[1] }).squeeze(' ')
                      index += 1
                    end
                  end
                else
                  say "File #{options[:resources_file]} does not exist.", :red
                  exit 1
                end
              else
                syscall (import_command % { address: options[:address], resource: options[:resource] })
              end
            end
          end

        end
      end
    end
  end
end
