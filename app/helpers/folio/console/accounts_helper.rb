# frozen_string_literal: true

module Folio
  module Console::AccountsHelper
    def active_account_select
      opts = [ ["Aktivní", 1], ["Neaktivní", 0]]
      selected = filter_params[:by_is_active]
      select_tag :by_is_active,
                 options_for_select(opts, selected),
                 class: "form-control",
                 include_blank: false
    end
  end
end
