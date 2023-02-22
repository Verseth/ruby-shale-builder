# frozen_string_literal: true

require 'test_helper'

class Shale::BuilderTest < ::Minitest::Test
  should 'have a version number' do
    refute_nil ::Shale::Builder::VERSION
  end

  class TestAmountType < ::Shale::Mapper
    include ::Shale::Builder

    attribute :value, ::Shale::Type::Float
    attribute :currency, ::Shale::Type::String
  end

  class TestTransactionResponseType < ::Shale::Mapper
    include ::Shale::Builder

    attribute :cvv_code, ::Shale::Type::String
    attribute :amount, TestAmountType
    attribute :success, ::Shale::Type::Boolean
  end

  class TestTransactionType < ::Shale::Mapper
    include ::Shale::Builder

    attribute :cvv_code, ::Shale::Type::String
    attribute :amount, TestAmountType
  end

  class TestClientDataType < ::Shale::Mapper
    include ::Shale::Builder

    attribute :first_name, ::Shale::Type::String
    attribute :last_name, ::Shale::Type::String
    attribute :email, ::Shale::Type::String
  end

  class TestEnhancedTransactionType < TestTransactionType
    attribute :client_data, TestClientDataType
  end

  context 'inheritance' do
    should 'correctly set up a class after inheriting' do
      mod_parent = TestTransactionType.builder_methods_module
      mod_child = TestEnhancedTransactionType.builder_methods_module
      assert mod_parent.is_a?(::Module)
      assert mod_child.is_a?(::Module)
      assert !mod_child.equal?(mod_parent)
      assert TestTransactionType.include?(mod_parent)
      assert !TestTransactionType.include?(mod_child)
      assert TestEnhancedTransactionType.include?(mod_child)
      assert TestEnhancedTransactionType.include?(mod_parent)
      assert_equal %i[amount], mod_parent.instance_methods
      assert_equal %i[client_data], mod_child.instance_methods
    end

    should 'correctly build an instance of a subclass' do
      obj = TestEnhancedTransactionType.build do |t|
        t.cvv_code = '321'
        t.amount do |a|
          a.value = 45.0
          a.currency = 'USD'
        end
        t.client_data do |c|
          c.first_name = 'Dupa'
          c.last_name = 'Kret'
          c.email = 'something@example.com'
        end
      end

      assert obj.is_a?(TestEnhancedTransactionType)
      assert_equal '321', obj.cvv_code
      assert obj.amount.is_a?(TestAmountType)
      assert_equal 45.0, obj.amount.value
      assert_equal 'USD', obj.amount.currency
      assert obj.client_data.is_a?(TestClientDataType)
      assert_equal 'Dupa', obj.client_data.first_name
      assert_equal 'Kret', obj.client_data.last_name
      assert_equal 'something@example.com', obj.client_data.email
    end
  end


  should 'correctly set up a class after including' do
    mod = TestTransactionType.builder_methods_module
    assert mod.is_a?(::Module)
    assert TestTransactionType.include?(mod)
    assert_equal %i[amount], mod.instance_methods
  end

  should 'not define a new method for an attribute when it is a primitive' do
    test_subclass = ::Class.new(::Shale::Mapper)
    test_subclass.include ::Shale::Builder

    mod = test_subclass.builder_methods_module
    assert !mod.instance_methods.include?(:type)

    test_subclass.attribute :type, ::Shale::Type::String
    assert !mod.instance_methods.include?(:type)
    test_subclass.new.type do |_|
      assert false
    end
  end

  should 'define a new method for an attribute when it is a complex type' do
    test_subclass = ::Class.new(::Shale::Mapper)
    test_subclass.include ::Shale::Builder

    mod = test_subclass.builder_methods_module
    assert !mod.instance_methods.include?(:transaction)

    test_subclass.attribute :transaction, TestTransactionType
    assert mod.instance_methods.include?(:transaction)

    test_object = test_subclass.new
    assert_nil test_object.transaction

    test_object.transaction do |t|
      t.cvv_code = '123'
      t.amount do |a|
        a.value = 123.10
        a.currency = 'PLN'
      end
    end

    expected = {
      'cvv_code' => '123',
      'amount' => {
        'value' => 123.10,
        'currency' => 'PLN'
      }
    }
    assert test_object.transaction.is_a?(TestTransactionType)
    assert_equal expected, test_object.transaction.to_hash
  end

  should 'build an object through the DSL' do
    obj = TestTransactionType.build do |t|
      t.cvv_code = '321'
      t.amount do |a|
        a.value = 45.0
        a.currency = 'USD'
      end
    end

    assert obj.is_a?(TestTransactionType)
    assert_equal '321', obj.cvv_code
    assert obj.amount.is_a?(TestAmountType)
    assert_equal 45.0, obj.amount.value
    assert_equal 'USD', obj.amount.currency
  end

  should 'build an object through the alt DSL' do
    obj = TestTransactionType.build do |t|
      t.cvv_code = '321'
      t.amount = TestAmountType.new(
        value: 45.0,
        currency: 'USD'
      )
    end

    assert obj.is_a?(TestTransactionType)
    assert_equal '321', obj.cvv_code
    assert obj.amount.is_a?(TestAmountType)
    assert_equal 45.0, obj.amount.value
    assert_equal 'USD', obj.amount.currency
  end

  should 'raise an error when a nonexistent attribute is accessed' do
    assert_raises ::NoMethodError do
      TestTransactionType.build do |t|
        t.cvv_code = '321'
        t.amount do |a|
          a.value = 45.0
          a.inexistent_method = 3
        end
      end
    end
  end

end
