# frozen_string_literal: true

class Folio::Console::Addresses::ShowForModelComponent < Folio::Console::ApplicationComponent
  include ShowFor::Helper

  attr_reader :model, :options

  def initialize(model:, **options)
    @model = model
    @options = options
  end

  def cols
    [
      [Folio::Address::Primary, model.primary_address],
      [Folio::Address::Secondary, model.secondary_address],
    ]
  end

  def col_class
    options[:col_class] || "col-lg-4"
  end
end
