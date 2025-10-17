# typed: false
# frozen_string_literal: true

require 'shale'
require 'booleans'

module Shale
  module Builder
    # Include in a class that already includes `Shale::Builder` to add support
    # for nested ActiveModel validations.
    #
    # @requires_ancestor: Object
    module NestedValidations
      extend T::Sig
      extend T::Helpers

      # @requires_ancestor: singleton(Shale::Mapper)
      module ClassMethods
        extend T::Sig

        #: String
        attr_writer :nested_attr_name_separator

        #: -> String
        def nested_attr_name_separator
          return @nested_attr_name_separator if @nested_attr_name_separator

          s = superclass
          return @nested_attr_name_separator = s.nested_attr_name_separator if s < NestedValidations

          @nested_attr_name_separator = '.'
        end

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
        klass = self.class #: as untyped
        separator = klass.nested_attr_name_separator

        attrs = T.unsafe(self).class.validatable_attributes
        attrs.each_key do |name|
          val = public_send(name)
          next unless val
          next if val.valid?

          result = false
          val.errors.each do |err|
            errlist.import(err, attribute: "#{name}#{separator}#{err.attribute}")
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
