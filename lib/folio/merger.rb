# frozen_string_literal: true

class Folio::Merger
  attr_accessor :original,
                :duplicate,
                :klass,
                :targets

  def initialize(original, duplicate, klass: nil)
    @original = original
    @duplicate = duplicate
    @klass = klass || default_klass
    @targets = {}

    structure.each do |row|
      key = row.is_a?(Hash) ? row[:key] : row
      @targets[key] = 'original'
    end
  end

  def atoms
    nil
  end

  def default_klass
    self.class.parent
  end
end
