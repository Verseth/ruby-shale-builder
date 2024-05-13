# typed: true
# frozen_string_literal: true

require 'shale'
require 'booleans'
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

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          # Collect all the classes that inherit from Shale::Mapper
          all_classes.select { |c| c < ::Shale::Mapper }
        end
      end

      SHALE_ATTRIBUTE_MODULE = 'ShaleAttributeMethods'

      sig { override.void }
      def decorate
        # Create a RBI definition for each class that inherits from Shale::Mapper
        root.create_path(constant) do |klass|
          has_shale_builder = includes_shale_builder(constant)
          mod = klass.create_module(SHALE_ATTRIBUTE_MODULE)
          klass.create_include(SHALE_ATTRIBUTE_MODULE)
          # For each attribute defined in the class
          constant.attributes.each_value do |attribute|
            attribute = T.let(attribute, ::Shale::Attribute)
            non_nilable_type, nilable_type = shale_type_to_sorbet_type(attribute)
            type = nilable_type
            if attribute.collection?
              type = "T.nilable(T::Array[#{non_nilable_type}])"
            end
            comments = T.let([], T::Array[RBI::Comment])
            if shale_builder_defined? && attribute.doc
              comments << RBI::Comment.new(T.must(attribute.doc))
            end

            if has_shale_builder && attribute.type < ::Shale::Mapper
              sigs = T.let([], T::Array[RBI::Sig])
              # simple getter
              sigs << klass.create_sig(
                parameters: { block: 'NilClass' },
                return_type: type,
              )
              # getter with block
              sigs << klass.create_sig(
                parameters: { block: "T.proc.params(arg0: #{non_nilable_type}).void" },
                return_type: non_nilable_type
              )
              mod.create_method_with_sigs(
                attribute.name,
                sigs: sigs,
                comments: comments,
                parameters: [RBI::BlockParam.new('block')],
              )
            else
              mod.create_method(attribute.name, return_type: type, comments: comments)
            end

            # setter
            mod.create_method(
              "#{attribute.name}=",
              parameters: [create_param('value', type: type)],
              return_type: type,
              comments: comments,
            )
          end
        end

      end

      private

      sig { params(klass: Class).returns(T.nilable(T::Boolean)) }
      def includes_shale_builder(klass)
        return false unless defined?(::Shale::Builder)

        klass < ::Shale::Builder
      end

      sig { returns(T::Boolean) }
      def shale_builder_defined? = Boolean(defined?(::Shale::Builder))

      SHALE_TYPES_MAP = T.let(
        {
          ::Shale::Type::Value    => Object,
          ::Shale::Type::String   => String,
          ::Shale::Type::Float    => Float,
          ::Shale::Type::Integer  => Integer,
          ::Shale::Type::Time     => Time,
          ::Shale::Type::Date     => Date,
        }.freeze,
        T::Hash[Class, Class],
      )

      sig { params(attribute: ::Shale::Attribute).returns([String, String]) }
      def shale_type_to_sorbet_type(attribute)
        return_type = SHALE_TYPES_MAP[attribute.type]
        return complex_shale_type_to_sorbet_type(attribute) unless return_type
        return [T.must(return_type.name), T.must(return_type.name)] if attribute.collection? || attribute.default.is_a?(return_type)

        [T.must(return_type.name), "T.nilable(#{return_type.name})"]
      end

      sig { params(attribute: ::Shale::Attribute).returns([String, String]) }
      def complex_shale_type_to_sorbet_type(attribute)
        return [T.cast(attribute.type.to_s, String), "T.nilable(#{attribute.type})"] unless attribute.type.respond_to?(:return_type)

        return_type_string = attribute.type.return_type.to_s
        [return_type_string, return_type_string]
      end

    end
  end
end
