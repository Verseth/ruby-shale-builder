# typed: true
# frozen_string_literal: true

require 'shale'
require 'booleans'
require 'bigdecimal'
begin
  require 'shale/builder'
rescue LoadError
end

module Tapioca
  module Compilers
    class Shale < Tapioca::Dsl::Compiler
      extend T::Sig
      ConstantType = type_member { { fixed: T.class_of(::Shale::Mapper) } }

      class << self
        extend T::Sig

        # @override
        #: -> T::Enumerable[Module]
        def gather_constants
          # Collect all the classes that inherit from Shale::Mapper
          all_classes.select { |c| c < ::Shale::Mapper }
        end
      end

      SHALE_ATTRIBUTE_MODULE = 'ShaleAttributeMethods'

      # @override
      #: -> void
      def decorate
        # Create a RBI definition for each class that inherits from Shale::Mapper
        root.create_path(constant) do |klass|
          has_shale_builder = includes_shale_builder(constant)
          mod = klass.create_module(SHALE_ATTRIBUTE_MODULE)
          klass.create_include(SHALE_ATTRIBUTE_MODULE)
          # For each attribute defined in the class
          attribute_names = constant.attributes.keys.sort
          attribute_names.each do |attribute_name|
            attribute = constant.attributes[attribute_name] #: ::Shale::Attribute
            if (type = attribute.return_type)
              return_type = type
              nilable = true
            else
              return_type, nilable = shale_type_to_sorbet_return_type(attribute)
            end
            comments = [] #: T::Array[RBI::Comment]
            if shale_builder_defined? && attribute.doc
              comments << RBI::Comment.new(T.must(attribute.doc))
            end

            if attribute.collection?
              getter_without_block_type = wrap_nilable_type(wrap_array_type(return_type))
            elsif nilable
              getter_without_block_type = wrap_nilable_type(return_type)
            else
              getter_without_block_type = return_type.to_s
            end

            if (type = attribute.return_type || attribute.setter_type)
              setter_type = type
              nilable = true
            else
              setter_type, nilable = shale_type_to_sorbet_setter_type(attribute)
            end
            if attribute.collection?
              setter_type_str = wrap_nilable_type(wrap_array_type(setter_type))
            elsif nilable
              setter_type_str = wrap_nilable_type(setter_type)
            else
              setter_type_str = setter_type.to_s
            end

            attribute.all_names.each do |name|
              name_str = name.to_s
              if has_shale_builder && attribute.type < ::Shale::Mapper
                generate_mapper_getter(mod, name_str, return_type, getter_without_block_type, comments)
              else
                mod.create_method(name_str, return_type: getter_without_block_type, comments: comments)
              end

              # setter
              mod.create_method(
                "#{name_str}=",
                parameters: [create_param('value', type: setter_type_str)],
                return_type: setter_type_str,
                comments: comments,
              )
            end
          end
        end

      end

      #: (untyped type) -> String
      def wrap_nilable_type(type)
        return "T.nilable(#{type})" if type != T.untyped

        T.unsafe(type).to_s
      end

      #: (untyped type) -> String
      def wrap_array_type(type)
        "T::Array[#{type}]"
      end

      #: (RBI::Scope mod, String method_name, Object type, String getter_without_block_type, Array[RBI::Comment] comments) -> void
      def generate_mapper_getter(mod, method_name, type, getter_without_block_type, comments)
        if mod.respond_to?(:create_sig)
          mod = T.unsafe(mod)
          # for tapioca < 0.16.0
          sigs = [] #: Array[RBI::Sig]

          # simple getter
          sigs << mod.create_sig(
            parameters: {
              block: 'NilClass',
            },
            return_type: getter_without_block_type,
          )
          # getter with block
          sigs << mod.create_sig(
            parameters: {
              block: "T.proc.params(arg0: #{type}).void"
            },
            return_type: type.to_s
          )
          mod.create_method_with_sigs(
            method_name,
            sigs: sigs,
            comments: comments,
            parameters: [
              RBI::BlockParam.new('block'),
            ],
          )

          mod.create_method_with_sigs(
            "memo_#{method_name}",
            sigs: [
              mod.create_sig(
                parameters: {
                  block: "T.proc.params(arg0: #{type}).void"
                },
                return_type: type.to_s
              )
            ],
            comments: [
              RBI::Comment.new("Version of `#{method_name}` that memoizes the previous object if it was already present.\n"),
              *comments,
            ],
            parameters: [
              RBI::BlockParam.new('block'),
            ],
          )
        else
          # for tapioca >= 0.16.0
          mod.create_method(method_name, comments: comments) do |method|
            method.add_block_param('block')

            method.add_sig do |sig|
              sig.add_param('block', 'NilClass')
              sig.return_type = getter_without_block_type
            end

            method.add_sig do |sig|
              sig.add_param('block', "T.proc.params(arg0: #{type}).void")
              sig.return_type = type.to_s
            end
          end

          mod.create_method(
            "memo_#{method_name}",
            comments: [
              RBI::Comment.new("Version of `#{method_name}` that memoizes the previous object if it was already present.\n"),
              *comments,
            ],
          ) do |method|
            method.add_block_param('block')

            method.add_sig do |sig|
              sig.add_param('block', "T.proc.params(arg0: #{type}).void")
              sig.return_type = type.to_s
            end
          end
        end
      end

      private

      #: (Class klass) -> bool?
      def includes_shale_builder(klass)
        return false unless defined?(::Shale::Builder)

        klass < ::Shale::Builder
      end

      #: -> bool
      def shale_builder_defined? = Boolean(defined?(::Shale::Builder))

      # Maps Shale return types to Sorbet types
      SHALE_RETURN_TYPES_MAP = {
        ::Shale::Type::Value    => T.untyped,
        ::Shale::Type::String   => String,
        ::Shale::Type::Float    => Float,
        ::Shale::Type::Integer  => Integer,
        ::Shale::Type::Time     => Time,
        ::Shale::Type::Date     => Date,
        ::Shale::Type::Boolean  => T::Boolean,
      }.tap do |h|
        h[::Shale::Type::Decimal] = BigDecimal if defined?(::Shale::Type::Decimal)
      end.freeze #: Hash[Class, Object]

      # Maps Shale setter types to Sorbet types
      SHALE_SETTER_TYPES_MAP = {
        ::Shale::Type::Value    => T.untyped,
        ::Shale::Type::String   => String,
        ::Shale::Type::Float    => Float,
        ::Shale::Type::Integer  => Integer,
        ::Shale::Type::Time     => Time,
        ::Shale::Type::Date     => Date,
        ::Shale::Type::Boolean  => Object,
      }.tap do |h|
        if defined?(::Shale::Type::Decimal)
          h[::Shale::Type::Decimal] = T.any(BigDecimal, String, Float, Integer, NilClass)
        end
      end.freeze #: Hash[Class, Object]

      #: (::Shale::Attribute attribute) -> [Object, bool]
      def shale_type_to_sorbet_return_type(attribute)
        return_type = SHALE_RETURN_TYPES_MAP[attribute.type]
        return complex_shale_type_to_sorbet_return_type(attribute) unless return_type
        return return_type, false if attribute.collection? || return_type.is_a?(Module) && attribute.default.is_a?(return_type)

        [return_type, true]
      end

      #: (::Shale::Attribute attribute) -> [Object, bool]
      def complex_shale_type_to_sorbet_return_type(attribute)
        return attribute.type, true unless attribute.type.respond_to?(:return_type)

        return_type_string = attribute.type.return_type.to_s
        [return_type_string, false]
      end

      #: (::Shale::Attribute attribute) -> [Object, bool]
      def shale_type_to_sorbet_setter_type(attribute)
        setter_type = SHALE_SETTER_TYPES_MAP[attribute.type]
        return complex_shale_type_to_sorbet_setter_type(attribute) unless setter_type
        return setter_type, false if attribute.collection? || setter_type.is_a?(Module) && attribute.default.is_a?(setter_type)

        [setter_type, true]
      end

      #: (::Shale::Attribute attribute) -> [Object, bool]
      def complex_shale_type_to_sorbet_setter_type(attribute)
        if attribute.type.respond_to?(:setter_type)
          setter_type_string = attribute.type.setter_type
          [setter_type_string, false]
        elsif attribute.type.respond_to?(:return_type)
          return_type_string = attribute.type.return_type
          [return_type_string, false]
        else
          [attribute.type, true]
        end
      end

    end
  end
end
