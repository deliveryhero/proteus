module Proteus
  module Validators
    module ValidationDSL
      def init
        @key_stack ||= []
      end

      def current_data
        data = @data.dig(*@key_stack)
        if data.nil?
          raise ValidationError.new(message_suffix: "Key hierarchy #{keys_to_hierarchy(*@key_stack)} not found or empty.")
        end
        data
      end

      def peek
        @data.dig(*@key_stack)
      end

      def within(key, optional: false)
        init

        key.is_a?(Numeric) ? @key_stack.push(key) : @key_stack.push(key.to_s)

        if !peek && optional
          @key_stack.pop
          return
        end

        current_data
        yield if block_given?

        @key_stack.pop
      end

      def ensure_unique_values
        unless current_data.length == current_data.uniq.length
          raise ValidationError.new(message_suffix: "Values in hierarchy #{keys_to_hierarchy(*@key_stack)} have to be unique.")
        end
      end

      def ensure_data_type(type)
        unless current_data.is_a? type
          raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack)} has to be of type #{type}.")
        end
      end

      def ensure_value(key, options = {})
        if current_data.key?(key.to_s)
          if current_data[key.to_s].is_a? Array
            if options.key?(:in)
              current_data[key.to_s].each_with_index do |item, index|
                unless options[:in].include?(item)
                  raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack, key, index)} invalid. Value #{current_data[key.to_s][index]} is not allowed. Should be one of [#{options[:in].join(', ')}].")
                end
              end
            end

            if options.key?(:matches)
              current_data[key.to_s].each_with_index do |item, index|
                unless options[:matches].match?(item)
                  raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack, key, index)} invalid. Value of must match #{options[:matches].inspect}.")
                end
              end
            end

          else
            if options.key?(:in_range)
              unless options[:in_range].include?(current_data[key.to_s])
                raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack)} invalid. Value #{current_data[key.to_s]} is out of range (Valid range: #{options[:in_range]}).")
              end
            end

            if options.key?(:in)
              unless options[:in].include?(current_data[key.to_s])
                raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack)} invalid. Value of #{key.to_s} must be one of [#{options[:in].join(', ')}]")
              end
            end

            if options.key?(:matches)
              unless options[:matches].match?(current_data[key.to_s])
                raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack)} invalid. Value of #{current_data[key.to_s]} must match #{options[:matches].inspect}.")
              end
            end
          end
        else
          unless options.key?(:optional)
            raise ValidationError.new(message_suffix: "Data in hierarchy #{keys_to_hierarchy(*@key_stack)} invalid. Key #{key} not found.")
          end
        end
      end

      def collect(key)
        current_data.collect { |item| item[key.to_s] }
      end

      def ensure_uniqueness_across(*keys)
        keys.each do |key|
          @current_paths = []
          transform_to_paths(current_data)
          @current_paths = @current_paths.grep(/^:#{key}:/)

          unless @current_paths.length == @current_paths.uniq.length
            raise ValidationError.new(message_suffix: "Values in hierarchy #{keys_to_hierarchy(*@key_stack)} => * => #{key} have to be unique.")
          end
        end
      end

      def transform_to_paths(data, current_prefix = "", include_prefixes: false)
        if data.is_a?(Hash)
          data.each do |key, value|
            transform_to_paths(value, "#{current_prefix}:#{key}")
          end
        elsif data.is_a?(Array)
          if data.any?
            data.each do |value|
              transform_to_paths(value, "#{current_prefix}")
            end
          end

          if current_prefix.length > 0 && include_prefixes
            @current_paths << current_prefix
          end
        else
          @current_paths << "#{current_prefix}:#{data}"
        end
      end

      def in_case(key, options = {})
        if current_data.key?(key.to_s)
          if options.key?(:has_value)
            if options[:has_value].is_a? Array
              if options[:has_value].include?(current_data[key.to_s])
                yield
              end
            else
              if current_data[key.to_s] == options[:has_value]
                yield
              end
            end
          end
        end
      end

      def each_key
        current_data.each do |key, value|
          within key do
            yield
          end
        end
      end

      def ensure_keys(*keys)
        keys.each do |key|
          within key
        end
      end

      def each
        current_data.each_with_index do |item, index|
          within index do
            yield
          end
        end
      end

      def ensure_presence(key, optional: false)
        within(key, optional: optional)
      end
    end
  end
end
