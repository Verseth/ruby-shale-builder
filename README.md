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

#### Overriding

By default if you call the builder method with a block a second time
it will override the previous object with a new one

```rb
transaction = Transaction.build do |t|
  t.amount do |a|
    a.value = 2.3
    a.currency = 'PLN'
  end
  t.amount do |a|
    a.value = 10
  end
end

transaction.amount.value #=> 10
transaction.amount.currency #=> nil
```

#### Memoization

You can change the behaviour of builder methods
so that they preserve existing objects when called a second time.
You do that by prepending the method name with `memo_`.

```rb
transaction = Transaction.build do |t|
  t.amount do |a|
    a.value = 2.3
    a.currency = 'PLN'
  end
  t.memo_amount do |a|
    a.value = 10
  end
end

transaction.amount.value #=> 10
transaction.amount.currency #=> 'PLN'
```

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

The attribute name separator can be changed like so:

```rb
class TransactionType < ::Shale::Mapper
  self.nested_attr_name_separator = ':'
end


obj = TransactionType.build do |t|
  t.amount do |a|
    a.currency = 'USD'
  end
end

obj.valid? #=> false
obj.errors #=> #<ActiveModel::Errors [#<ActiveModel::Error attribute=cvv_code, type=blank, options={}>, #<ActiveModel::NestedError attribute=amount:value, type=blank, options={}>]>
obj.errors.messages #=> {cvv_code: ["can't be blank"], "amount:value": ["can't be blank"]}
```

### Recording Assigned Attributes

There is an additional module `Shale::Builder::AssignedAttributes` that provides
support for recording which attributes have been assigned in a shale mapper object.

In order to load it do:

```rb
require 'shale/builder/assigned_attributes'
```

Then you can use it like so

```rb
class AmountType < ::Shale::Mapper
  include ::Shale::Builder
  include ::Shale::Builder::AssignedAttributes

  attribute :value, ::Shale::Type::Float
  attribute :currency, ::Shale::Type::String
end

obj = AmountType.new
obj.assigned_attribute_names #=> #<Set: {}>

obj.value = 3
obj.assigned_attribute_names #=> #<Set: {:value}>
obj.assigned_attributes #=> [#<Shale::Attribute:0x000000011e959b50 @collection=false, @default=nil, @doc=nil, @name=:value, @setter="value=", @type=Shale::Type::Float>]
obj.assigned_values #=> [#<Shale::Builder::Value:0x000000011d693318 @attribute=#<Shale::Attribute:0x000000011e959b50 @collection=false, @default=nil, @doc=nil, @name=:value, @setter="value=", @type=Shale::Type::Float>, @value=3.0>]
```

- `assigned_attribute_names` returns a set of attribute names
- `assigned_attributes` returns an array of attribute definitions
- `assigned_values` returns an array of `Shale::Builder::Value`, which contains the current value of an attribute and a reference to its definition

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

#### Parsing strings or other primitive values to shale objects

If you want to parse a primitive value like a string, integer, float etc
to a shale mapper object you can use a primitive shale type as a bridge.


By defining the `builder` method that returns a shale mapper class
of the parsed value, you can make this composite type usable with the builder DSL.

```rb
def self.builder = ResourceURI::Body
```

Here is a full example.

```rb
# typed: true
require 'shale/builder'

# Resource URI is a string serialization format eg. `"pan:4242424242424242;expiry=2027-04;cvc=123"`
# - schema is `"pan"`
# - id is `"4242424242424242"`
# - properties are:
#   - `expiry` is `"2027-04"`
#   - `cvc` is `"123"`
module ResourceURI
  class Properties < Shale::Type::Value
    class << self
      def return_type = T.nilable(T::Hash[String, String])
      def setter_type = T.any(T::Hash[String, String], NilClass)
      def builder = Hash

      # Decode from JSON.
      #
      #: (Hash[String, String]?) -> (Hash[String, String]?)
      def cast(value)
        value
      end

      # Encode to JSON.
      #
      #: (Hash[String, String]?, **untyped) -> (Hash[String, String]?)
      def as_json(value, **_)
        return if value.nil?

        value.as_json
      end
    end
  end

  class Body < Shale::Mapper
    include Shale::Builder

    attribute :schema, S::String, doc: <<~DOC
      required

      String identifying the resource.
    DOC

    attribute :id, S::String, doc: <<~DOC
      optional

      Main identifier of the resource.
    DOC

    attribute :properties, Properties, doc: <<~DOC
      optional

      Additional properties of the resource
    DOC

    #: -> String
    def to_resource_uri
      buf = String.new
      buf << schema
      buf << ':'
      buf << id if id

      properties.each do |hkey, hval|
        buf << ';'
        buf << hkey
        buf << '='
        buf << hval
      end

      buf
    end
  end

  class Type < Shale::Type::Value
    class << self
      def return_type = T.nilable(Body)
      def setter_type = T.any(Body, String, NilClass)
      def builder = Body

      # Decode from JSON.
      #
      #: (Body | String?) -> (Body?)
      def cast(value)
        return if value.nil?
        return value unless value.is_a?(String)

        hash = {}
        schema, rest = value.split(':', 2)
        if rest
          pairs = rest.split(';')
          id = pairs.shift
        end

        properties = T.unsafe(pairs).to_h { |str| str.split('=', 2) }
        hash = {
          'schema'     => schema,
          'id'         => id,
          'properties' => properties,
        }

        Body.from_hash(hash)
      end

      # Encode to JSON.
      #
      #: (Body | String?, **untyped) -> String?
      def as_json(value, **_)
        return value if value.nil?
        return value if value.is_a?(String)

        value.to_resource_uri
      end
      alias as_hash as_json
    end
  end
end

class Payment < Shale::Mapper
  include Shale::Builder

  attribute :account_uri, ResourceURI::Type
end

payment = Payment.build do |p|
  p.account_uri do |a|
    a.schema = 'pan'
    a.id = "4242424242424242"
    a.properties do |p|
      p['expiry'] = '2027-04'
      p['cvc'] = '123'
    end
  end
end

payment.to_json
#=> {"account_uri":"pan:4242424242424242;expiry=2027-04;cvc=123"}

payment = Payment.from_json('{"account_uri":"pan:4242424242424242;expiry=2027-04;cvc=123"}')
#=> #<Payment:0x00000001215413f8 @account_uri=#<ResourceURI::Body:0x00000001216aff28 @id="4242424242424242", @schema="pan", @properties={"expiry" => "2027-04", "cvc" => "123"}>>
```

After running `bundle exec tapioca dsl` you'll get the following RBI.

```rb
# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Amount`.
# Please instead update this file by running `bin/tapioca dsl Amount`.

class ResourceURI::Body
  include ShaleAttributeMethods

  module ShaleAttributeMethods
    # optional
    #
    # Main identifier of the resource.
    sig { returns(T.nilable(String)) }
    def id; end

    # optional
    #
    # Main identifier of the resource.
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def id=(value); end

    # Version of `properties` that memoizes the previous object if it was already present.
    # optional
    #
    # Additional properties of the resource
    sig { params(block: T.proc.params(arg0: Hash).void).returns(Hash) }
    def memo_properties(&block); end

    # optional
    #
    # Additional properties of the resource
    sig { params(block: NilClass).returns(T.nilable(T::Hash[::String, ::String])) }
    sig { params(block: T.proc.params(arg0: Hash).void).returns(Hash) }
    def properties(&block); end

    # optional
    #
    # Additional properties of the resource
    sig { params(value: T.nilable(T::Hash[::String, ::String])).returns(T.nilable(T::Hash[::String, ::String])) }
    def properties=(value); end

    # required
    #
    # String identifying the resource.
    sig { returns(T.nilable(String)) }
    def schema; end

    # required
    #
    # String identifying the resource.
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def schema=(value); end
  end
end

class Payment
  include ShaleAttributeMethods

  module ShaleAttributeMethods
    sig { params(block: NilClass).returns(T.nilable(::ResourceURI::Body)) }
    sig { params(block: T.proc.params(arg0: ResourceURI::Body).void).returns(ResourceURI::Body) }
    def account_uri(&block); end

    sig do
      params(
        value: T.nilable(T.any(::ResourceURI::Body, ::String))
      ).returns(T.nilable(T.any(::ResourceURI::Body, ::String)))
    end
    def account_uri=(value); end

    # Version of `account_uri` that memoizes the previous object if it was already present.
    sig { params(block: T.proc.params(arg0: ResourceURI::Body).void).returns(ResourceURI::Body) }
    def memo_account_uri(&block); end
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
