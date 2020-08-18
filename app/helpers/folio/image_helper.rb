# frozen_string_literal: true

module Folio::ImageHelper
  def img_tag_retina(normal, retina, options = {})
    retina_multiplier = options.delete(:retina_multiplier) || 2
    options[:srcset] = "#{normal} 1x, #{retina} #{retina_multiplier}x"
    image_tag normal, options
  end

  def img_tag_retina_static(path, options = {})
    split_path = path.split(".")
    retina_path = split_path.first(split_path.size - 1).join(".") + "@2x." + split_path.last

    normal = image_path(path)
    retina = image_path(retina_path)

    img_tag_retina normal, retina, options
  end

  def dummy_image_url(variant)
    "http://dummyimage.com/#{variant}/FFF/000.png&text=TODO: Vybrat a nahrát v consoli"
  end

  def image_from(placement, normal_variant, options = {})
    retina_multiplier = options.delete(:retina_multiplier) || 2
    retina_variant = normal_variant.gsub(/\d+/) { |n| n.to_i * retina_multiplier }

    if placement.is_a?(Folio::FilePlacement::Base)
      file = placement.file
    else
      file = placement
    end

    normal = file.thumb(normal_variant).url
    retina = file.thumb(retina_variant).url

    img_tag_retina(normal,
                   retina,
                   options.reverse_merge(
                     alt: placement.try(:alt) || "",
                     title: placement.try(:title),
                     retina_multiplier: retina_multiplier,
                   ))
  end

  def lazy_image(normal, retina = nil, options = {})
    retina_multiplier = options.delete(:retina_multiplier) || 2
    lazyload_class = options.delete(:lazyload_class) || "folio-lazyload"

    options["data-src"] = normal
    if retina
      options["data-srcset"] = "#{normal} 1x, #{retina} #{retina_multiplier}x"
    end

    if options[:alt].present?
      options["data-alt"] = options.delete(:alt)
    end

    options[:alt] = ""
    options[:class] = "#{lazyload_class} #{options[:class] || ''}"
    options[:style] = "visibility: hidden; #{options[:style] || ''}"

    image_tag "", options
  end

  def lazy_image_from(placement, normal_variant, options = {})
    retina_multiplier = options.delete(:retina_multiplier) || 2
    retina_variant = normal_variant.gsub(/\d+/) { |n| n.to_i * retina_multiplier }

    if placement.is_a?(Folio::FilePlacement::Base)
      file = placement.file
    else
      file = placement
    end

    normal = file.thumb(normal_variant).url
    retina = file.thumb(retina_variant).url

    lazy_image(normal,
               retina,
               options.reverse_merge(
                 alt: placement.try(:alt) || "",
                 title: placement.try(:title),
                 retina_multiplier: retina_multiplier,
               ))
  end
end
