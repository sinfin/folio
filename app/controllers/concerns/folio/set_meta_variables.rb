# frozen_string_literal: true

module Folio::SetMetaVariables
  extend ActiveSupport::Concern

  def set_meta_variables(instance, mappings = {})
    m = {
      title: :to_label,
      image: :cover,
      description: :perex,
      meta_title: :meta_title,
      meta_description: :meta_description,
    }.merge(mappings)

    if ::Rails.application.config.folio_use_og_image
      if image = instance.try(m[:image]).presence
        @og_image = image.thumb(Folio::OG_IMAGE_DIMENSIONS).url
      end
    end

    title = instance.try(m[:title]).presence
    og_title = instance.try(m[:meta_title]).presence
    @public_page_title = og_title || title

    description = instance.try(m[:description]).presence
    og_description = instance.try(m[:meta_description]).presence
    @public_page_description = og_description || description

    if @public_page_description.present?
      @public_page_description = ActionView::Base.full_sanitizer.sanitize(@public_page_description, tags: [])
    end
  end
end
