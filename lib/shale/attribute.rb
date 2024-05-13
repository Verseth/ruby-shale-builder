# frozen_string_literal: true
# typed: true

require 'shale'

module Shale
  class Attribute # rubocop:disable Style/Documentation
    extend T::Sig

    # Contains the documentation comment for the shale attribute
    # in a Ruby String.
    sig { returns(T.nilable(String)) }
    attr_accessor :doc
  end
end
