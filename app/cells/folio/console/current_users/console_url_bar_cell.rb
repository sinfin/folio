# frozen_string_literal: true

class Folio::Console::CurrentUsers::ConsoleUrlBarCell < Folio::ConsoleCell
  def show
    render if model && can_now?(:access_console)
  end

  def other_user_at_url
    return false unless can_now?(:access_console)
    return @other_user_at_url unless @other_user_at_url.nil?
    @other_user_at_url = Folio::User.currently_editing_url(request.url).where.not(id: Folio::Current.user.id).first || false
  end

  def hidden?
    other_user_at_url == false
  end

  def name
    if other_user_at_url
      other_user_at_url.to_label
    end
  end
end
