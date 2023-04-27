# frozen_string_literal: true

class Folio::PublishableHintCell < Folio::ApplicationCell
  def show
    render if model && forced_or_unpublished?
  end

  def forced_or_unpublished?
    model == true || !model.published?
  end

  def default_hint
    if controller.params[Folio::Publishable::PREVIEW_PARAM_NAME] == model.try(:preview_token)
      t(".preview_token_hint")
    else
      t(".hint")
    end
  end
end
