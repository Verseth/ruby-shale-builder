# frozen_string_literal: true
# typed: true

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
  module Builder
    extend T::Helpers

    class << self
      extend T::Sig

      # Gets called after including this module in a module or class.
      sig { params(mod: Module).void }
      def included(mod)
        mod.extend ClassMethods
        Builder.prepare_mod(mod)
      end

      # Prepares the received module or class
      # for dynamic method definition.
      sig { params(mod: Module).void }
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

      sig { params(subclass: Class).void }
      def inherited(subclass)
        super
        Builder.prepare_mod(subclass)
      end

      # Contains overridden getter methods for attributes
      # with complex types (so that they accept a block for building)
      sig { returns(Module) }
      attr_reader :builder_methods_module

      sig { params(_block: T.proc.params(arg0: T.attached_class).void).returns(T.attached_class) }
      def build(&_block)
        body = new
        yield(body)

        body
      end

      sig { abstract.returns(T.attached_class) }
      def new; end

      sig { abstract.returns(T::Hash[Symbol, Shale::Attribute]) }
      def attributes; end

      sig do
        params(
          name: T.any(String, Symbol),
          type: Class,
          collection: T::Boolean,
          default: T.nilable(Proc),
          doc: T.nilable(String),
          kwargs: Object,
          block: T.nilable(T.proc.void),
        ).void
      end
      def attribute(name, type, collection: false, default: nil, doc: nil, **kwargs, &block)
        super(name, type, collection: collection, default: default, **kwargs, &block)
        attributes[name.to_sym]&.doc = doc # add doc to the attribute
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

    end

    mixes_in_class_methods(ClassMethods)

  end
end
