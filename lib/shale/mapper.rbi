# typed: true
# frozen_string_literal: true

class Shale::Mapper
  sig { params(block: T.proc.bind(Shale::Mapping::Dict).void).void }
  def json(&block); end

  sig { params(block: T.proc.bind(Shale::Mapping::Dict).void).void }
  def hsh(&block); end

  sig { params(block: T.proc.bind(Shale::Mapping::Dict).void).void }
  def yaml(&block); end

  sig { params(block: T.proc.bind(Shale::Mapping::Dict).void).void }
  def toml(&block); end

  sig { params(block: T.proc.bind(Shale::Mapping::Dict).void).void }
  def csv(&block); end

  sig { params(block: T.proc.bind(Shale::Mapping::Xml).void).void }
  def xml(&block); end
end
