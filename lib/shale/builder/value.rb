# typed: true
# frozen_string_literal: true

require 'shale'

module Shale
  module Builder
    # Represents a value of a particular shale attribute.
    # Hold the value and a reference to the attribute definition.
    class Value
      extend T::Sig

      # Shale attribute definition
      #
      #: Shale::Attribute
      attr_reader :attribute

      # Value of the attribute.
      #
      #: untyped
      attr_reader :value

      #: (Shale::Attribute, untyped) -> void
      def initialize(attribute, value)
        @attribute = attribute
        @value = value
      end
    end
  end
end
