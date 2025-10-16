# frozen_string_literal: true

require 'test_helper'
require 'active_model'
require 'active_model/validations'

class Shale::BuilderTest < ::Minitest::Test
  should 'have a version number' do
    refute_nil ::Shale::Builder::VERSION
  end

  class TestAmountType < ::Shale::Mapper
    include ::Shale::Builder
    include ::ActiveModel::Validations
    include ::Shale::Builder::NestedValidations

    attribute :value, ::Shale::Type::Float
    attribute :currency, ::Shale::Type::String

    validates :value, presence: true
  end

  class TestTransactionResponseType < ::Shale::Mapper
    include ::Shale::Builder

    attribute :cvv_code, ::Shale::Type::String
    attribute :amount, TestAmountType
    attribute :success, ::Shale::Type::Boolean
    attribute :aux, ::Shale::Type::Value, return_type: Integer
  end

  class TestTransactionType < ::Shale::Mapper
    include ::Shale::Builder
    include ::ActiveModel::Validations
    include ::Shale::Builder::NestedValidations

    attribute :cvv_code, ::Shale::Type::String
    attribute :amount, TestAmountType

    validates :cvv_code, presence: true
    validates :amount, presence: true
  end

  class TestClientDataType < ::Shale::Mapper
    include ::Shale::Builder
    include ::Shale::Builder::AssignedAttributes

    attribute :first_name, ::Shale::Type::String
    attribute :last_name, ::Shale::Type::String
    attribute :email, ::Shale::Type::String

    alias_attribute :name, :first_name

    hsh do
      map :first_name, to: :first_name
      map :name, to: :first_name
      map :last_name, to: :last_name
      map :email, to: :email
    end
  end

  class TestEnhancedTransactionType < TestTransactionType
    attribute :client_data, TestClientDataType
  end

  class TestMultipleClientTransactionType < TestTransactionType
    attribute :clients, TestClientDataType, collection: true
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


  should 'correctly handle attribute aliases' do
    obj = TestClientDataType.new
    assert_nil obj.first_name
    assert_nil obj.name

    obj.first_name = 'foo'
    assert_equal 'foo', obj.first_name
    assert_equal 'foo', obj.name

    obj.name = 'bar'
    assert_equal 'bar', obj.first_name
    assert_equal 'bar', obj.name
  end

  should 'record assigned attributes' do
    obj = TestClientDataType.new
    assert_equal 0, obj.assigned_attribute_names.length

    obj.name = 'foo'
    assert_equal Set[:first_name], obj.assigned_attribute_names

    obj.email = 'bar'
    assert_equal Set[:first_name, :email], obj.assigned_attribute_names

    obj = TestClientDataType.from_hash({ name: 'foo', email: 'bar' })
    assert_equal 'foo', obj.first_name
    assert_equal 'bar', obj.email
    assert_equal 2, obj.assigned_attribute_names.length
    assert_equal Set[:first_name, :email], obj.assigned_attribute_names

    obj = TestClientDataType.new(first_name: 'foo', email: 'bar')
    assert_equal 'foo', obj.first_name
    assert_equal 'bar', obj.email
    assert_equal 0, obj.assigned_attribute_names.length
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
      'amount'   => {
        'value'    => 123.10,
        'currency' => 'PLN',
      },
    }
    assert test_object.transaction.is_a?(TestTransactionType)
    assert_equal expected, test_object.transaction.to_hash
  end


  should 'build an object and validate it' do
    obj = TestTransactionType.build do |t|
      t.amount do |a|
        a.currency = 'USD'
      end
    end

    assert_equal false, obj.valid?
    errs = obj.errors.entries
    assert_equal 2, errs.length

    err = errs[0]
    assert_equal :cvv_code, err.attribute
    assert_equal :blank, err.type

    err = errs[1]
    assert_equal :'amount.value', err.attribute
    assert_equal :blank, err.type
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

  should 'build an object with a collection attribute' do
    obj = TestMultipleClientTransactionType.build do |t|
      t.cvv_code = '321'
      t.amount do |a|
        a.value = 45.0
        a.currency = 'USD'
      end
      t.clients do |c|
        c.first_name = 'Mateusz'
        c.last_name = 'Gobbins'
        c.email = 'mat.gobbins@example.com'
      end
      t.clients do |c|
        c.first_name = 'Michal'
        c.last_name = 'Zapow'
        c.email = 'mich.zapow@example.com'
      end
    end

    assert obj.is_a?(TestTransactionType)
    assert_equal '321', obj.cvv_code
    assert obj.amount.is_a?(TestAmountType)
    assert_equal 45.0, obj.amount.value
    assert_equal 'USD', obj.amount.currency
    assert obj.clients.is_a?(::Array), "Should be and Array, got: #{obj.clients.class.inspect}"
    assert_equal 2, obj.clients.length

    cli = obj.clients.first
    assert_equal 'Mateusz', cli.first_name
    assert_equal 'Gobbins', cli.last_name
    assert_equal 'mat.gobbins@example.com', cli.email

    cli = obj.clients.last
    assert_equal 'Michal', cli.first_name
    assert_equal 'Zapow', cli.last_name
    assert_equal 'mich.zapow@example.com', cli.email
  end

  should 'build an object through the alt DSL' do
    obj = TestTransactionType.build do |t|
      t.cvv_code = '321'
      t.amount = TestAmountType.new(
        value:    45.0,
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
