require 'proteus/validators/validation_error'
require 'proteus/validators/validation_helpers'
require 'proteus/validators/validation_dsl'

module Proteus
  module Validators
    class BaseValidator
      include ValidationDSL
      include ValidationHelpers

      def initialize(data, environment = nil)
        @data = data
        @environment = environment
        validate
      end

      private

      def validate
        raise "Override this method in your module validator class."
      end
    end
  end
end
