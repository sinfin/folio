# frozen_string_literal: true

class Folio::Console::CurrentAccounts::ConsolePathBarCell < Folio::ConsoleCell
  def show
    render if model && current_account
  end

  def other_account_at_path
    return false unless current_account
    return @other_account_at_path unless @other_account_at_path.nil?
    @other_account_at_path = Folio::Account.currently_editing_path(request.path).where.not(id: current_account.id).first || false
  end

  def hidden?
    other_account_at_path == false
  end

  def name
    if other_account_at_path
      other_account_at_path.to_label
    end
  end
end
