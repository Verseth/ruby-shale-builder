# Shale::Builder

This addon to the [shale](https://github.com/kgiszczak/shale) Ruby gem adds a simple yet powerful builder DSL.

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

class Transaction < ::Shale::Mapper
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Verseth/ruby-shale-builder.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
