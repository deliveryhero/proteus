module Proteus
  module Modules
    class DefaultsParser
      attr_reader :variables

      def initialize(input)
        @hcl = input
        @variables = {}
      end

      def parse_variables
        lines = @hcl.split("\n")
        lines.reject! { |l| l.start_with?("#") }

        lines.each_with_index do |line, index|
          if line =~ /$variable/
            # ignore mandatory variables
            if line =~ /{/ && line =~ /}/
              next
            end

            variable_lines = find_variable_range(lines, index)

            if variable_lines && variable_lines.any?
              variable = evaluate_variable(variable_lines)

              @variables.merge!({variable[:name] => variable[:value]}) unless variable.nil?
            end
          end
        end
      end

      protected

      # finds range of lines relevant to a single variable.
      # returns nil if the default value is non scalar
      def find_variable_range(lines, start_index)
        closing_brace_index = 0

        lines[start_index..-1].each_with_index do |line, idx|

          # ignore maps and lists
          if line =~ /default/ && (line =~ /\[/ || line =~ /\{/)
            return nil
          end

          if line =~ /^\}$/
            closing_brace_index = idx
            break
          end
        end

        lines[start_index..start_index + closing_brace_index]
      end

      def evaluate_variable(lines)
        variable = {}

        variable[:name] = lines[0].match(/variable "(.+)"/)[1]
        lines.each do  |line|
          next if line =~ /type/ || line =~ /description/

          if match_data = line.match(/=(.+)/)
            variable[:value] =  match_data[1].gsub('"','').lstrip.rstrip
            break
          end
        end

        return variable if variable.key?(:value)

        nil
      end
    end
  end
end
