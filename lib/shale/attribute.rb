# typed: true
# frozen_string_literal: true

require 'shale'

module Shale
  class Attribute # rubocop:disable Style/Documentation
    extend T::Sig

    # Contains the documentation comment for the shale attribute
    # in a Ruby String.
    sig { returns(T.nilable(String)) }
    attr_accessor :doc

    # Contains the documentation comment for the shale attribute
    # in a Ruby String.
    sig { returns(T.nilable(T::Array[Symbol])) }
    attr_accessor :aliases

    sig { returns(T::Array[Symbol]) }
    def all_names
      names = [name]
      aliases = self.aliases
      return names unless aliases

      names + aliases
    end
  end
end
