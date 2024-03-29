# frozen_string_literal: true

require "show_for"

# Use this setup block to configure all options available in ShowFor.
ShowFor.setup do |config|
  # The tag which wraps show_for calls.
  config.show_for_tag = :table

  # The DOM class set for show_for tag. Default is nil
  config.show_for_class = "table table-bordered f-c-show-for"

  # The tag which wraps each attribute/association call. Default is :p.
  config.wrapper_tag = :tr

  # The DOM class set for the wrapper tag. Default is :wrapper.
  config.wrapper_class = nil

  # The tag used to wrap each label. Default is :strong.
  config.label_tag = :td

  # The DOM class of each label tag. Default is :label.
  config.label_class = "small text-uppercase text-body text-nowrap f-c-show-for__label"

  # The tag used to wrap each content (value). Default is nil.
  config.content_tag = :td

  # The DOM class of each content tag. Default is :content.
  config.content_class = "f-c-show-for__content w-100"

  # The DOM class set for blank content tags. Default is "blank".
  config.blank_content_class = "blank text-muted"

  # Skip blank attributes instead of generating with a default message. Default is false.
  # config.skip_blanks = true

  # The separator between label and content. Default is "<br />".
  config.separator = ""

  # The tag used to wrap collections. Default is :ul.
  # config.collection_tag = :div

  # The DOM class set for the collection tag. Default is :collection.
  config.collection_class = nil

  # The default iterator to be used when invoking a collection/association.
  # config.default_collection_proc = lambda { |value| "<li>#{ERB::Util.h(value)}</li>".html_safe }

  # The default format to be used in I18n when localizing a Date/Time.
  config.i18n_format = :short

  # Whenever a association is given, the first method in association_methods
  # in which the association responds to is used to retrieve the association labels.
  config.association_methods = [ :to_label, :name, :title, :to_s ]

  # If you want to wrap the text inside a label (e.g. to append a semicolon),
  # specify label_proc - it will be automatically called, passing in the label text.
  # config.label_proc = lambda { |l| l + ":" }
end
