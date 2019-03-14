# frozen_string_literal: true

module Folio::SetMetaVariables
  extend ActiveSupport::Concern

  def set_meta_variables(instance, mappings = {})
    m = {
      title: :title,
      image: :cover,
      description: :perex,
      meta_title: :meta_title,
      meta_description: :meta_description,
    }.merge(mappings)

    if image = instance.try(m[:image]).presence
      @og_image = image.thumb(Folio::OG_IMAGE_DIMENSIONS).url
    end

    title = instance.try(m[:title]).presence
    og_title = instance.try(m[:meta_title]).presence
    @public_page_title = og_title || title

    description = instance.try(m[:description]).presence
    og_description = instance.try(m[:meta_description]).presence
    @public_page_description = og_description || description
  end
end
