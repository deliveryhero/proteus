module Proteus
  module Validators
    module ValidationHelpers
      def keys_to_hierarchy(*keys)
        keys.inject() { |hierarchy, key| "#{hierarchy} => #{key}" }
      end
    end
  end
end
