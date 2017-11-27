# frozen_string_literal: true

class SavingFolioCell < FolioCell
  include ERB::Util

  def hidden_options
    remember_option_keys.map do |opt|
      value = options[opt]
      next unless value
      %{<input type="hidden" name="cell_options[#{opt}]" value="#{html_escape(value)}">}
    end.compact.join('')
  end
end
