# frozen_string_literal: true

class Folio::Atom::ImageCell < FolioCell
  include Folio::ImageHelper

  def show
    return nil if model.cover.blank?
    image(model.cover)
  end

  def image(img)
    img_tag_retina(img.thumb('700x700').url,
                   img.thumb('1400x1400').url,
                   alt: '')
  end
end
