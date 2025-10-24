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

        #: -> Hash[Symbol, Shale::Attribute]
        def validatable_attributes
          @validatable_attributes ||= attributes.select do |_, val|
            val.validatable?
          end
        end

        #: -> Array[Symbol]
        def validatable_attribute_names
          validatable_attributes.keys
        end
      end
      mixes_in_class_methods ClassMethods

      #: -> Array[Symbol]
      def validatable_attribute_names
        self.class.validatable_attribute_names
      end

      #: -> String
      def nested_attr_name_separator
        self.class.nested_attr_name_separator
      end

      #: -> bool
      def valid?
        result = super

        validatable_attribute_names.each do |name|
          next unless name

          val = public_send(name)
          next unless val
          next if val.valid?

          result = false
          import_errors(name, val)
        end

        result
      end

      #: (Symbol | String, ActiveModel::Validations?) -> void
      def import_errors(name, obj)
        return unless obj

        errlist = errors
        separator = nested_attr_name_separator
        obj.errors.each do |err|
          errlist.import(err, attribute: "#{name}#{separator}#{err.attribute}")
        end
      end

    end
  end
end

module Shale
  class Attribute # rubocop:disable Style/Documentation
    #: -> bool
    def validatable?
      Boolean(type.is_a?(Class) && type < ::ActiveModel::Validations)
    end
  end
end
