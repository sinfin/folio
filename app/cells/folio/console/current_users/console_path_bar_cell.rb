# frozen_string_literal: true

class Folio::Console::CurrentUsers::ConsolePathBarCell < Folio::ConsoleCell
  def show
    render if model && can_now?(:access_console)
  end

  def other_user_at_path
    return false unless can_now?(:access_console)
    return @other_user_at_path unless @other_user_at_path.nil?
    @other_user_at_path = Folio::User.currently_editing_path(request.path).where.not(id: current_user.id).first || false
  end

  def hidden?
    other_user_at_path == false
  end

  def name
    if other_user_at_path
      other_user_at_path.to_label
    end
  end
end
