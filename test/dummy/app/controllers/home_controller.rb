# frozen_string_literal: true

class HomeController < ApplicationController
  def index
  end

  def dropzone
  end

  def lead_form
  end

  def gallery
    images = Folio::Image.where("file_width > 100").limit(15)

    @atoms = {
      "REGULAR #{images.size}" => Dummy::Atom::Images.new(images: images),
      "REGULAR 2" => Dummy::Atom::Images.new(images: images.first(2)),
      "REGULAR 1" => Dummy::Atom::Images.new(images: images.first(1)),
      "GRID #{images.size}" => Dummy::Atom::Images.new(images: images, same_width: true),
      "GRID 2" => Dummy::Atom::Images.new(images: images.where("file_width >= 570").first(2), same_width: true),
      "GRID 1" => Dummy::Atom::Images.new(images: images.where("file_width >= 570").first(1), same_width: true),
    }
  end
end
