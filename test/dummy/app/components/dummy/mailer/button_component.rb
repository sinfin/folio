# frozen_string_literal: true

class Dummy::Mailer::ButtonComponent < ApplicationComponent
  def initialize(label:, href: nil, type: nil, size: nil)
    @label = label
    @href = href
    @type = type
    @size = size
  end

  def type
    @type.to_s || "primary"
  end

  def size
    @size || :md
  end

  def label
    @label.present? ? @label : "Button label"
  end

  def mso_padding_start
    code = '<i style="mso-font-width:100%;mso-text-raise:100%" hidden>&emsp;</i><span style="mso-text-raise:50%;">'

    code.html_safe
  end

  def mso_padding_end
    code = '</span><i style="mso-font-width:100%;" hidden>&emsp;&#8203;</i>'

    code.html_safe
  end
end
