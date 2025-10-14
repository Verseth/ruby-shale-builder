# typed: false
# frozen_string_literal: true

require 'shale'
require 'booleans'

module Shale
  module Builder
    # Include in a class tha already includes `Shale::Builder` to add support
    # for nested ActiveModel validations.
    #
    # @requires_ancestor: Object
    module NestedValidations
      extend T::Sig
      extend T::Helpers

      # @requires_ancestor: singleton(Shale::Mapper)
      module ClassMethods
        extend T::Sig

        sig { returns(T::Hash[Symbol, Shale::Attribute]) }
        def validatable_attributes
          @validatable_attributes ||= attributes.select do |_, val|
            val.validatable?
          end
        end
      end
      mixes_in_class_methods ClassMethods

      sig { returns(T::Boolean) }
      def valid?
        result = super
        errlist = errors

        attrs = T.unsafe(self).class.validatable_attributes
        attrs.each_key do |name|
          val = public_send(name)
          next unless val
          next if val.valid?

          result = false
          val.errors.each do |err|
            errlist.import(err, attribute: "#{name}.#{err.attribute}")
          end
        end

        result
      end

    end
  end
end

module Shale
  class Attribute # rubocop:disable Style/Documentation
    sig { returns(T::Boolean) }
    def validatable?
      Boolean(type.is_a?(Class) && type < ::ActiveModel::Validations)
    end
  end
end
