# frozen_string_literal: true

require 'shale'

require_relative 'builder/version'

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
    class << self
      # Gets called after including this module in a module or class.
      #
      # @param mod [Module, Class]
      # @return [void]
      def included(mod)
        mod.extend ClassMethods
        Builder.prepare_mod(mod)
      end

      # Prepares the received module or class
      # for dynamic method definition.
      #
      # @param mod [Module, Class]
      # @return [void]
      def prepare_mod(mod)
        builder_methods_module = ::Module.new
        mod.instance_variable_set :@builder_methods_module, builder_methods_module
        mod.include builder_methods_module
      end
    end

    # Class methods provided by `Shale::Builder`
    module ClassMethods
      # @param subclass [Class]
      # @return [void]
      def inherited(subclass)
        super
        Builder.prepare_mod(subclass)
      end

      # Contains overridden getter methods for attributes
      # with complex types (so that they accept a block for building)
      #
      # @return [Module]
      attr_reader :builder_methods_module

      # @return [Class, nil]
      attr_accessor :request_class

      # @yieldparam [self]
      # @return [self]
      def build
        body = new
        yield(body)

        body
      end

      # @param name [String, Symbol]
      # @param type [Class]
      # @return [void]
      def attribute(name, type, *args, collection: false, **kwargs, &block)
        super
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

  end
end
