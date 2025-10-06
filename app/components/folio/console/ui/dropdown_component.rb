# frozen_string_literal: true

class Folio::Console::Ui::DropdownComponent < Folio::Console::ApplicationComponent
  def initialize(links:, menu_align: :left, button: nil)
    @links = links
    @menu_align = menu_align
    @button = button
  end

  private
    def cell_content_for_link(link)
      data = if link[:modal]
        modal_hash = stimulus_modal_toggle(@modal).merge({
          "toggle" => "modal",
          "target" => @modal,
          "bs-toggle" => "modal",
          "bs-target" => @modal,
        })

        if link[:data]
          stimulus_merge(link[:data], modal_hash)
        else
          modal_hash
        end
      else
        link[:data]
      end

      cell("folio/console/ui/with_icon",
           link[:label],
           href: link[:href],
           class: "dropdown-item #{"f-c-index-actions__link--disabled" if link[:disabled]}",
           icon: link[:icon],
           icon_options: { height: 18 }.merge(link[:icon_options] || {}),
           block: true,
           data:,
           title: link[:title])
    end

    def trigger_class_name
      if content?
        "f-c-ui-dropdown__trigger--with-content"
      elsif @button
        "f-c-ui-dropdown__trigger--with-button"
      else
        "f-c-ui-dropdown__trigger--without-content"
      end
    end

    def trigger_button
      class_name = if @button[:class_name]
        "#{@button[:class_name]} dropdown-toggle f-c-ui-dropdown__trigger f-c-ui-dropdown__trigger--button"
      else
        "dropdown-toggle f-c-ui-dropdown__trigger f-c-ui-dropdown__trigger--button"
      end

      data = if @button[:data]
        stimulus_merge(@button[:data], { bs_toggle: "dropdown" })
      else
        { bs_toggle: "dropdown" }
      end

      aria = if @button[:aria].is_a?(Hash)
        @button[:aria].merge({ expanded: "false", haspopup: "true" })
      else
        { expanded: "false", haspopup: "true" }
      end

      render(Folio::Console::Ui::ButtonComponent.new(**@button,
                                                     class_name:,
                                                     data:,
                                                     aria:))
    end
end
