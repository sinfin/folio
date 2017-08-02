module Folio::IconHelper
  include FontAwesome::Rails::IconHelper

  def featured_icon(bool)
    if bool
      fa_icon('star')
    end
  end

  def eye_icon(bool)
    if bool
      fa_icon('eye')
    else
      fa_icon('eye-slash')
    end
  end

  def on_off_icon(bool)
    if bool
      fa_icon('toggle-on')
    else
      fa_icon('toggle-off')
    end
  end
end
