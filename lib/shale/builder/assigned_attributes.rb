# typed: true
# frozen_string_literal: true

require 'shale'
require 'booleans'

module Shale
  module Builder
    # Include in a class that already includes `Shale::Builder` to add support
    # for getting a list of attributes that have been assigned.
    #
    # @requires_ancestor: Object
    module AssignedAttributes
      extend T::Sig
      extend T::Helpers

      class << self
        extend T::Sig

        # Gets called after including this module in a module or class.
        #: (Module mod) -> void
        def included(mod)
          mod.extend ClassMethods
          AssignedAttributes.prepare_mod(mod)
        end

        # Prepares the received module or class
        # for dynamic method definition.
        #: (Module mod) -> void
        def prepare_mod(mod)
          assigned_attributes_methods_module = ::Module.new
          mod.instance_variable_set :@assigned_attributes_methods_module, assigned_attributes_methods_module
          mod.include assigned_attributes_methods_module
        end
      end

      # @requires_ancestor: singleton(Shale::Mapper)
      module ClassMethods
        extend T::Sig

        # Contains overridden getter methods for attributes
        # with complex types (so that they accept a block for building)
        #: Module
        attr_reader :assigned_attributes_methods_module

        #: (String | Symbol name, Class type, ?collection: bool, ?default: Proc?, ?doc: String?, **untyped kwargs) ?{ -> void } -> void
        def attribute(name, type, collection: false, default: nil, doc: nil, **kwargs, &block)
          super

          @assigned_attributes_methods_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{name}=(val)
              super
              return unless @__initialized

              self.assigned_attribute_names << #{name.to_sym.inspect}
            end
          RUBY
        end
      end
      mixes_in_class_methods ClassMethods

      # Returns a set of names of assigned shale attributes.
      #
      #: -> Set[Symbol]
      def assigned_attribute_names
        @assigned_attribute_names ||= Set.new
      end

      # Returns an array of shale attributes
      # that have been assigned.
      #
      #: -> Array[Shale::Attribute]
      def assigned_attributes
        klass = self.class #: as untyped
        assigned_attribute_names.map do |name|
          klass.attributes.fetch(name)
        end
      end

      # Returns an array of shale values
      # that have been assigned.
      #
      #: -> Array[Shale::Builder::Value]
      def assigned_values
        klass = self.class #: as untyped
        assigned_attribute_names.map do |name|
          attr = klass.attributes.fetch(name)
          Shale::Builder::Value.new(attr, public_send(attr.name))
        end
      end

    end
  end
end
