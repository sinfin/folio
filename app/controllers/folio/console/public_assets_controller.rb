# frozen_string_literal: true

class Folio::Console::PublicAssetsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::PublicAsset"

  prepend_before_action :require_public_assets_enabled

  private
    def allowed_record_sites
      Rails.application.config.folio_shared_files_between_sites ? Folio::Site.all : super
    end

    def public_asset_params
      params.require(:public_asset).permit(:file)
    end

    def folio_console_params_with_site
      super.merge(created_by_folio_user: Folio::Current.user)
    end

    def index_filters
      { by_query: { as: :text, icon: :magnify }, created_by_current_user: { as: :boolean } }
    end

    def folio_console_collection_includes
      [:site]
    end

    def require_public_assets_enabled
      head :not_found unless Rails.application.config.folio_public_assets_enabled
    end
end
