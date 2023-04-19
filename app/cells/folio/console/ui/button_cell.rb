# frozen_string_literal: true

class Folio::Console::Ui::ButtonCell < Folio::ConsoleCell
  def tag
    base = {
      tag: :button,
      type: model[:type] || :button,
      class: "f-c-ui-button btn btn-#{model[:variant]} #{model[:class]}",
      data: model[:data],
      name: model[:name],
      hidden: model[:hidden],
    }

    if model[:href]
      base[:tag] = :a
      base[:href] = model[:href]
    end

    base
  end
end
