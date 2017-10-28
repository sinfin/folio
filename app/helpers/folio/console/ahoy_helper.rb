# frozen_string_literal: true

module Folio
  module Console::AhoyHelper
    def event_attributes_tooltip(event)
      txt = []
      event.attributes.except('id', 'visit_id', 'account_id').each do |k, v|
        txt << "#{k}: #{v}"
      end
      console_tooltip(icon: 'info-circle', title: 'Values') { txt.join('<br>').html_safe }
    end

    def parse_icon(icon_string)
      dictionary = {
        "macintosh": 'apple',
        "ipod": 'apple',
        "x11": 'linux',
        "iphone": 'apple',
        "ipad": 'apple',
        "chomeos": 'chrome',
        "compatible": 'exclamation-triangle',
        "internet explorer": 'internet-explorer'
      }
      dictionary.each do |k, v|
        icon_string = icon_string.downcase.gsub(k.to_s, v.to_s) unless icon_string.nil?
      end

      icon_string
    end

    def technology_icon(icon)
      raw "<i class=\"fa fa-#{parse_icon(icon)}\" aria-hidden=\"true\" alt=\"#{icon}\"></i>"
    end
  end
end
