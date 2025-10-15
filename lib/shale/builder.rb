# typed: true
# frozen_string_literal: true

require 'shale'
require 'sorbet-runtime'

require_relative 'builder/version'
require_relative 'attribute'

module Shale
  # It's meant to be included in subclasses of `Shale::Mapper`
  # to provide an easier way of building instances.
  #
  # Example:
  #
  #       require 'shale/builder'
  #
  #       class PaymentInstrument < Shale::Mapper
  #         include Shale::Builder
  #
  #         attribute :number, Shale::Type::String
  #         attribute :expiration_year, ::Shale::Type::Integer
  #         attribute :expiration_month, ::Shale::Type::Integer
  #       end
  #
  #       class Transaction < ::Shale::Mapper
  #         include Shale::Builder
  #
  #         attribute :cvv_code, Shale::Type::String
  #         attribute :payment_instrument, PaymentInstrument
  #       end
  #
  #       transaction = Transaction.build do |t|
  #           t.cvv_code = '123'
  #           t.payment_instrument do |p|
  #               p.number = '4242424242424242'
  #               p.expiration_year = 2045
  #               p.expiration_month = 12
  #           end
  #       end
  #
  # @requires_ancestor: Object
  module Builder
    extend T::Sig
    extend T::Helpers

    class << self
      extend T::Sig

      # Gets called after including this module in a module or class.
      #: (Module mod) -> void
      def included(mod)
        mod.extend ClassMethods
        Builder.prepare_mod(mod)
      end

      # Prepares the received module or class
      # for dynamic method definition.
      #: (Module mod) -> void
      def prepare_mod(mod)
        builder_methods_module = ::Module.new
        mod.instance_variable_set :@builder_methods_module, builder_methods_module
        mod.include builder_methods_module
      end
    end

    # Class methods provided by `Shale::Builder`
    module ClassMethods
      extend T::Sig
      extend T::Generic

      abstract!
      has_attached_class!

      #: (Class subclass) -> void
      def inherited(subclass)
        super
        Builder.prepare_mod(subclass)
      end

      # Contains overridden getter methods for attributes
      # with complex types (so that they accept a block for building)
      #: Module
      attr_reader :builder_methods_module

      #: { (instance arg0) -> void } -> instance
      def build(&_block)
        body = new
        yield(body)

        body
      end

      sig { abstract.params(props: T.anything).returns(T.attached_class) }
      def new(**props); end

      sig { abstract.returns(T::Hash[Symbol, Shale::Attribute]) }
      def attributes; end

      #: ((String | Symbol) name, Class type, ?collection: bool, ?default: Proc?, ?doc: String?, **Object kwargs) ?{ -> void } -> void
      def attribute(name, type, collection: false, default: nil, doc: nil, **kwargs, &block)
        super(name, type, collection:, default:, **kwargs, &block)
        if (attr_def = attributes[name.to_sym])
          attr_def.doc = doc
        end
        return unless type < ::Shale::Mapper

        if collection
          @builder_methods_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{name}                           # def clients
              return super unless block_given?    #   return super unless block_given?
                                                  #
              arr = self.#{name} ||= []           #   arr = self.clients ||= []
              object = #{type}.new                #   object = Client.new
              yield(object)                       #   yield(object)
              arr << object                       #   arr << object
              object                              #   object
            end                                   # end
          RUBY
          return
        end

        @builder_methods_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{name}                                   # def amount
            return super unless block_given?            #   return super unless block_given?
                                                        #
            object = #{type}.new                        #   object = Amount.new
            yield(object)                               #   yield(object)
            self.#{name} = object                       #   self.amount = object
          end                                           # end
        RUBY
      end

      # Create an alias for the getter and setter of an attribute.
      #: (Symbol new_name, Symbol old_name) -> void
      def alias_attribute(new_name, old_name)
        attr = attributes.fetch(old_name)
        (attr.aliases ||= []) << new_name

        builder_methods_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{new_name}
            #{old_name}
          end

          def #{new_name}=(val)
            self.#{old_name} = val
          end
        RUBY
      end

    end
    mixes_in_class_methods(ClassMethods)

    def initialize(*args, **kwargs, &block)
      super
      @__initialized = true
    end

    #: bool?
    attr_reader :__initialized

    # Returns an array of shale values
    # that have been assigned.
    #
    #: -> Array[Shale::Builder::Value]
    def attribute_values
      klass = self.class #: as untyped
      klass.attributes.map do |name, attr|
        Shale::Builder::Value.new(attr, public_send(name))
      end
    end

  end
end

require_relative 'builder/value'
