# frozen_string_literal: true

class Folio::Publishable::HintComponent < Folio::ApplicationComponent
  def initialize(record: nil, force: false, hint: nil)
    @record = record
    @force = force
    @hint = hint
  end

  def render?
    return true if @force
    return false if @record.blank?
    return false if @record.published?
    true
  end

  def default_hint
    if controller.params[Folio::Publishable::PREVIEW_PARAM_NAME]
      t(".preview_token_hint")
    else
      t(".hint")
    end
  end
end
