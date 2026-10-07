# frozen_string_literal: true

class Folio::Console::File::PublicAssetsController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::PublicAsset"

  prepend_before_action :require_public_assets_enabled

  private
    def require_public_assets_enabled
      head :not_found unless Rails.application.config.folio_public_assets_enabled
    end
end
