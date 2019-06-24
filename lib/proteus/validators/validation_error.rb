module Proteus
  module Validators
    class ValidationError < StandardError
      def initialize(message: "A validation error occured: ", message_suffix: "")
        super("#{message}#{message_suffix}")
      end
    end
  end
end
