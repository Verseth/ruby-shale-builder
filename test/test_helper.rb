# frozen_string_literal: true

$LOAD_PATH.unshift ::File.expand_path('../lib', __dir__)
require 'shale/builder'
require 'shale/builder/nested_validations'
require 'shale/builder/assigned_attributes'

require 'minitest/autorun'
require 'shoulda-context'
require 'byebug'
