# frozen_string_literal: true

class Folio::Merger
  attr_accessor :original,
                :duplicate,
                :klass,
                :targets

  def initialize(original, duplicate, klass:)
    @original = original
    @duplicate = duplicate
    @klass = klass
    @targets = {}

    structure.each do |row|
      @targets[row] = 'original'
    end
  end
end
