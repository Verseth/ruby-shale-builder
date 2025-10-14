# Shale::Builder

This addon to the [shale](https://github.com/kgiszczak/shale) Ruby gem adds a simple yet powerful builder DSL.

It also adds support for sorbet and tapioca in shale.
This gem includes a custom tapioca DSL compiler designed for shale.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add shale-builder

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install shale-builder

## Usage

### TLDR

Build your [shale](https://github.com/kgiszczak/shale) classes like a boss.

```rb
transaction = Transaction.build do |t|
    t.cvv_code = '123'
    t.amount do |a|
        a.value = 2.3
        a.currency = 'PLN'
    end
    t.payment_instrument do |p|
        p.number = '4242424242424242'
        p.expiration_year = 2045
        p.expiration_month = 12
    end
end
```

### Build method

This gem adds a module named `Shale::Builder`. It's meant to be included
in subclasses of `Shale::Mapper` to provide an easier way of building
instances.

You can use it like that:

```rb
require 'shale/builder'

class Amount < Shale::Mapper
    include Shale::Builder

    attribute :value, Shale::Type::Float
    attribute :currency, Shale::Type::String
end
```

Now instead of creating an instance like that:

```rb
amount = Amount.new(value: 2.3, currency: 'PLN')
```

You can do it like that:

```rb
amount = Amount.build do |a|
    a.value = 2.3
    a.currency = 'PLN'
end
```

### Building nested objects

It's kind of pointless when you've got a flat structure.
It really shines when nested objects come into play.

Let's say that you've got a structure like this:

```rb
class Amount < Shale::Mapper
    include Shale::Builder

    attribute :value, Shale::Type::Float
    attribute :currency, Shale::Type::String
end

class PaymentInstrument < Shale::Mapper
    include Shale::Builder

    attribute :number, Shale::Type::String
    attribute :expiration_year, ::Shale::Type::Integer
    attribute :expiration_month, ::Shale::Type::Integer
end

class Transaction < Shale::Mapper
    include Shale::Builder

    attribute :cvv_code, Shale::Type::String
    attribute :amount, Amount
    attribute :payment_instrument, PaymentInstrument
end
```

Normally you would instantiate it like that:

```rb
transaction = Transaction.new(
    cvv_code: '123',
    amount: Amount.new(
        value: 2.3,
        currency: 'PLN'
    ),
    payment_instrument: PaymentInstrument.new(
        number: '4242424242424242',
        expiration_year: 2045,
        expiration_month: 12
    )
)
```

It's really repetitive and it makes it hard to
modify the values of certain attributes or omit them
conditionally.

This gem provides a better way:

```rb
transaction = Transaction.build do |t|
    t.cvv_code = '123'
    t.amount do |a|
        a.value = 2.3
        a.currency = 'PLN'
    end
    t.payment_instrument do |p|
        p.number = '4242424242424242'
        p.expiration_year = 2045
        p.expiration_month = 12
    end
end
```

That's possible because the getters of attributes with
non-primitive types have been overridden to accept blocks.
When a block is given to such a getter, it instantiates an empty object
of its type and yields it to the block.

### Collections

Whenever you call a getter with a block for a collection attribute, the built object will be appended to the array.

Let's define a schema like this.

```rb
class Client < Shale::Mapper
    include Shale::Builder

    attribute :first_name, Shale::Type::String
    attribute :last_name, Shale::Type::String
    attribute :email, Shale::Type::String
end

class Transaction < Shale::Mapper
    include Shale::Builder

    attribute :clients, Client, collection: true
end
```

You can easily build add new clients to the collection like so:

```rb
transaction = Transaction.build do |t|
  # this will be added as the first element of the collection
  t.clients do |c|
    c.first_name = 'Foo'
    c.last_name = 'Bar'
  end

  # this will be added as the second element of the collection
  t.clients do |c|
    c.first_name = 'Grant'
    c.last_name = 'Taylor'
  end
end

p transaction.clients
# [
#    #<Client:0x00000001066c2828 @first_name="Foo", @last_name="Bar", @email=nil>,
#    #<Client:0x00000001066c24b8 @first_name="Grant", @last_name="Taylor", @email=nil>
# ]
```

### Conditional building

This DSL makes it extremely easy to build nested
objects conditionally.

```rb
transaction = Transaction.build do |t|
    t.cvv_code = '123'
    t.amount do |a|
        a.value = 2.3 if some_flag?
        a.currency = 'PLN'
    end
    t.payment_instrument do |p|
        p.number = '4242424242424242'
        if some_condition?
            p.expiration_year = 2045
            p.expiration_month = 12
        end
    end
end
```

### Nested Validations

There is an additional module `Shale::Builder::NestedValidations` that provides
support for seamless nested validations using `ActiveModel`.

In order to load it do:

```rb
require 'shale/builder/nested_validations'
```

Then you can use it like so

```rb
class AmountType < ::Shale::Mapper
    include ::Shale::Builder
    include ::ActiveModel::Validations
    include ::Shale::Builder::NestedValidations

    attribute :value, ::Shale::Type::Float
    attribute :currency, ::Shale::Type::String

    validates :value, presence: true
end

class TransactionType < ::Shale::Mapper
    include ::Shale::Builder
    include ::ActiveModel::Validations
    include ::Shale::Builder::NestedValidations

    attribute :cvv_code, ::Shale::Type::String
    attribute :amount, AmountType

    validates :cvv_code, presence: true
    validates :amount, presence: true
end

obj = TransactionType.build do |t|
    t.amount do |a|
        a.currency = 'USD'
    end
end

obj.valid? #=> false
obj.errors #=> #<ActiveModel::Errors [#<ActiveModel::Error attribute=cvv_code, type=blank, options={}>, #<ActiveModel::NestedError attribute=amount.value, type=blank, options={}>]>
obj.errors.messages #=> {cvv_code: ["can't be blank"], "amount.value": ["can't be blank"]}
```

You MUST include `ActiveModel::Validations` before `Shale::Builder::NestedValidations`.

### Attribute aliases

You can easily create aliases for attributes using `alias_attribute`

Then you can use it like so

```rb
require 'shale/builder'

class Amount < Shale::Mapper
    include Shale::Builder

    attribute :value, Shale::Type::Float
    attribute :currency, Shale::Type::String

    alias_attribute :val, :value
end

a = Amount.build do |a|
    a.val = 3.2
end

a.val #=> 3.2
a.value #=> 3.2
```

### Sorbet support

Shale-builder adds support for sorbet and tapioca.

You can leverage an additional `doc` keyword argument in `attribute` definitions.
It will be used to generate a comment in the RBI file.

```rb
require 'shale/builder'

class Amount < Shale::Mapper
    include Shale::Builder

    attribute :value, Shale::Type::Float
    attribute :currency, Shale::Type::String, doc: <<~DOC
        This is some custom documentation that can be used by sorbet.
        It will be used by the tapioca DSL compiler
        to generate the RBI documentation for this attribute.
    DOC
end
```

If you use sorbet and run `bundle exec tapioca dsl` you'll get the following RBI file.

```rb
# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Amount`.
# Please instead update this file by running `bin/tapioca dsl Amount`.

class Amount
  include ShaleAttributeMethods

  module ShaleAttributeMethods
    sig { returns(T.nilable(Float)) }
    def value; end

    sig { params(value: T.nilable(Float)).returns(T.nilable(Float)) }
    def value=(value); end

    # This is some custom documentation that can be used by sorbet.
    # It will be used by the tapioca DSL compiler
    # to generate the RBI documentation for this attribute.
    sig { returns(T.nilable(String)) }
    def currency; end

    # This is some custom documentation that can be used by sorbet.
    # It will be used by the tapioca DSL compiler
    # to generate the RBI documentation for this attribute.
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def currency=(value); end
  end
end
```

#### Primitive types

If you define custom primitive types in Shale by inheriting from `Shale::Type::Value`
you can describe the return type of the getter of the field that uses this primitive type by defining the `return_type` method that returns a sorbet type.

```rb
def self.return_type = T.nilable(String)
```

You can also describe the accepted argument type in the setter by defining the `setter_type` method that returns a sorbet type.

```rb
def self.setter_type = T.any(String, Float, Integer)
```

Here is a full example.

```rb
# typed: true
require 'shale/builder'

# Cast from XML string to BigDecimal.
# And from BigDecimal to XML string.
class BigDecimalShaleType < Shale::Type::Value
    class << self
        extend T::Sig

        # the return type of the field that uses this class as its type
        def return_type = T.nilable(BigDecimal)
        # the type of the argument given to a setter of the field
        # that uses this class as its type
        def setter_type = T.any(BigDecimal, String, NilClass)

        # Decode from XML.
        sig { params(value: T.any(BigDecimal, String, NilClass)).returns(T.nilable(BigDecimal)) }
        def cast(value)
            return if value.nil?

            BigDecimal(value)
        end

        # Encode to XML.
        #
        # @param value: Value to convert to XML
        sig { params(value: T.nilable(BigDecimal)).returns(T.nilable(String)) }
        def as_xml_value(value)
            return if value.nil?

            value.to_s('F')
        end
    end
end

class Amount < Shale::Mapper
    include Shale::Builder

    # `value` uses BigDecimalShaleType as its type
    attribute :value, BigDecimalShaleType
end
```

After running `bundle exec tapioca dsl` you'll get the following RBI file.

```rb
# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Amount`.
# Please instead update this file by running `bin/tapioca dsl Amount`.

class Amount
  include ShaleAttributeMethods

  module ShaleAttributeMethods
    sig { returns(T.nilable(::BigDecimal)) }
    def value; end

    sig { params(value: T.nilable(T.any(::BigDecimal, ::String))).returns(T.nilable(T.any(::BigDecimal, ::String))) }
    def value=(value); end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Verseth/ruby-shale-builder.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
