# typed: true
# frozen_string_literal: true

require 'shale'

module Shale
  class Attribute # rubocop:disable Style/Documentation
    extend T::Sig

    #: untyped
    attr_accessor :setter_type

    #: untyped
    attr_accessor :return_type

    # Contains the documentation comment for the shale attribute
    # in a Ruby String.
    #: String?
    attr_accessor :doc

    # Contains the documentation comment for the shale attribute
    # in a Ruby String.
    #: Array[Symbol]?
    attr_accessor :aliases

    #: -> Array[Symbol]
    def all_names
      names = [name]
      aliases = self.aliases
      return names unless aliases

      names + aliases
    end

    # Returns `true` if the attribute is handled by a shale mapper.
    #
    #: -> bool
    def mapper?
      type.is_a?(Class) && type < Shale::Mapper
    end

    # Returns `true` if the attribute is handled by a shale builder.
    #
    #: -> bool
    def builder?
      type.is_a?(Class) && type < Shale::Builder
    end
  end
end
