# frozen_string_literal: true

class Dummy::HomeController < ApplicationController
  def index
    @page = Dummy::Page::Homepage.instance(fail_on_missing: false)
    set_meta_variables(@page) if @page
  end

  def dropzone
  end

  def lead_form
  end

  def gallery
    images = Folio::File::Image.where("file_width > 100").limit(15)

    @atoms = {
      "REGULAR #{images.size}" => Dummy::Atom::Images.new(images:),
      "REGULAR 2" => Dummy::Atom::Images.new(images: images.first(2)),
      "REGULAR 1" => Dummy::Atom::Images.new(images: images.first(1)),
      "GRID #{images.size}" => Dummy::Atom::Images.new(images:, same_width: true),
      "GRID 2" => Dummy::Atom::Images.new(images: images.where("file_width >= 570").first(2), same_width: true),
      "GRID 1" => Dummy::Atom::Images.new(images: images.where("file_width >= 570").first(1), same_width: true),
    }
  end
end
