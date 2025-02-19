# frozen_string_literal: true

# bring back rails methods removed in 0.1.1

Cell::ViewModel.class_eval do
  def with_output_buffer(block_buffer=Cell::ViewModel::OutputBuffer.new)
    @output_buffer, old_buffer = block_buffer, @output_buffer
    yield
    @output_buffer = old_buffer
    block_buffer
  end

  def capture(*args)
    value = nil
    buffer = with_output_buffer { value = yield(*args) }
    return buffer.to_s if buffer.size > 0
    value # this applies for "Beachparty" string-only statements.
  end

  # From FormTagHelper. why do they escape every possible string? why?
  def form_tag_in_block(html_options, &block)
    content = capture(&block)
    form_tag_with_body(html_options, content)
  end

  def form_tag_with_body(html_options, content)
    "#{form_tag_html(html_options)}" << content.to_s << "</form>"
  end

  def form_tag_html(html_options)
    extra_tags = extra_tags_for_form(html_options)
    "#{tag(:form, html_options, true) + extra_tags}"
  end

  def tag(name = nil, options = nil, open = false, escape = true)
    super(name, options, open, true)
  end

  def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
    super(name, content_or_options_with_block, options, false, &block)
  end

  def concat(string)
    @output_buffer << string
    self
  end
end
