# frozen_string_literal: true

class Folio::Console::Api::SiteUserLinksController < Folio::Console::Api::BaseController
  folio_console_controller_for "Folio::SiteUserLink"

  def set_locked
    flash = if @site_user_link.update(locked: params.require(:site_user_link)[:locked])
      if @site_user_link.locked?
        @site_user_link.user.sign_out_everywhere!

        { success: t(".success/locked") }
      else
        { success: t(".success/unlocked") }
      end
    else
      if @site_user_link.locked?
        { error: t(".error/still_locked") }
      else
        { error: t(".error/still_unlocked") }
      end
    end

    render_record(@site_user_link, flash:)
  end
end
