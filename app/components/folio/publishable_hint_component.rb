# frozen_string_literal: true

class Folio::PublishableHintComponent < Folio::ApplicationComponent
  def initialize(model:, hint: nil)
    @model = model
    @hint = hint
  end

  def render?
    @model && forced_or_unpublished?
  end

  private

  attr_reader :model

  def forced_or_unpublished?
    @model == true || !@model.published?
  end

  def default_hint
    if controller.params[Folio::Publishable::PREVIEW_PARAM_NAME]
      t(".preview_token_hint")
    else
      t(".hint")
    end
  end

  def options
    { hint: @hint }
  end
end
