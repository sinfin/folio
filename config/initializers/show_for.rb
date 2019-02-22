# frozen_string_literal: true

require 'show_for'

# Use this setup block to configure all options available in ShowFor.
ShowFor.setup do |config|
  # The tag which wraps show_for calls.
  config.show_for_tag = :div

  # The DOM class set for show_for tag. Default is nil
  config.show_for_class = 'f-c-show-for__row'

  # The tag which wraps each attribute/association call. Default is :p.
  config.wrapper_tag = :div

  # The DOM class set for the wrapper tag. Default is :wrapper.
  config.wrapper_class = 'f-c-show-for__cell'

  # The tag used to wrap each label. Default is :strong.
  config.label_tag = :div

  # The DOM class of each label tag. Default is :label.
  config.label_class = 'f-c-show-for__label'

  # The tag used to wrap each content (value). Default is nil.
  config.content_tag = :div

  # The DOM class of each content tag. Default is :content.
  config.content_class = 'f-c-show-for__content'

  # The DOM class set for blank content tags. Default is "blank".
  # config.blank_content_class = 'f-c-show-for__content '\
  #                              'f-c-show-for__content--blank'

  # Skip blank attributes instead of generating with a default message. Default is false.
  # config.skip_blanks = true

  # The separator between label and content. Default is "<br />".
  config.separator = ''

  # The tag used to wrap collections. Default is :ul.
  config.collection_tag = :div

  # The DOM class set for the collection tag. Default is :collection.
  config.collection_class = 'f-c-show-for__collection'

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

class ShowFor::Builder
  def featured_toggle
    toggle(:featured)
  end

  def published_toggle
    toggle(:published)
  end

  def position_controls
    attribute(:position) do
      template.cell('folio/console/index/position_buttons', object).show
                                                                   .html_safe
    end
  end

  def type
    attribute(:type) do
      object.class.model_name.human
    end
  end

  def email(attr)
    attribute(attr) do
      if object.persisted?
        template.mail_to(object.public_send(attr), nil)
      end
    end
  end

  def edit_link(attr = nil, &block)
    resource_link(attr, [:edit, :console, object], &block)
  end

  def show_link(attr = nil, &block)
    resource_link(attr, [:console, object], &block)
  end

  def locale_flag
    attribute(:locale) do
      template.country_flag(object.locale) if object.locale
    end
  end

  def visit
    attribute(:visit) do
      if object.persisted?
        if object.visit.present?
          template.link_to(object.visit.to_label,
                           template.controller.url_for([:console, object.visit]))
        end
      end
    end
  end

  def actions(*act)
    attribute('') do
      if object.persisted?
        template.cell('folio/console/index/actions',
                      object,
                      actions: act).show.try(:html_safe)
      end
    end
  end

  private

    def resource_link(attr, url_for_args)
      attribute(attr) do
        if object.persisted?
          if block_given?
            content = yield(object)
          elsif attr == :type
            content = object.class.model_name.human
          else
            content = object.public_send(attr)
          end

          url = template.controller.url_for(url_for_args)
          template.link_to(content, url)
        end
      end
    end

    def toggle(attr)
      attribute(attr) do
        if object.persisted?
          template.cell('folio/console/boolean_toggle',
                        object,
                        attribute: attr).show.try(:html_safe)
        end
      end
    end
end
