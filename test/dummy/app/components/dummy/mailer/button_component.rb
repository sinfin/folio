# frozen_string_literal: true

class Dummy::Mailer::ButtonComponent < ApplicationComponent
  def initialize(label:, href:, type: nil, size: nil)
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

  # [width, height, font-size]
  def dimensions
    case size
    when :sm
      %w[135 34 12]
    when :md
      %w[150 40 14]
    end
  end

  def vml_start_code
    code = '<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="' + @href + '" style="height:' + dimensions[1] + "px;v-text-anchor:middle;width:" + dimensions[0] + 'px;" arcsize="60% "'
    code += type == "primary" ? 'stroke="f" fillcolor="#000000">' : 'strokecolor="#000000" fillcolor="#f5f5f5">'
    code += "<w:anchorlock/>"
    code += type == "primary" ? "<center>" : '<center style="color:#000000;font-family:sans-serif;font-size:' + dimensions[2] + 'px;font-weight:bold;">' + @label + "</center></v:roundrect>"

    code.html_safe
  end

  def vml_end_code
    "</center></v:roundrect>".html_safe
  end
end
