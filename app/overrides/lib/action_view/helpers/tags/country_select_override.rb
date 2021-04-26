# frozen_string_literal: true

ActionView::Helpers::Tags::CountrySelect.class_eval do
  def render
    if @options[:atom_setting]
      @html_options ||= {}
      @html_options[:class] ||= []
      @html_options[:class] << "f-c-js-atoms-placement-setting"
      @html_options["data-atom-setting"] = @options[:atom_setting]
    end

    select_content_tag(country_option_tags, @options, @html_options)
  end
end
