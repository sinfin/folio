# frozen_string_literal: true

class Folio::Ui::AtomsCell < Folio::ApplicationCell
  def show
    if File.exist?(self.class.data_path)
      render
    else
      "<p>Create #{self.class.data_path} first.</p>"
    end
  end

  def self.data_path
    ::Rails.root.join("data/atoms_showcase.yml")
  end

  def page
    require "faker"

    @page = Folio::Page.new

    images = Folio::Image.tagged_with("unsplash").to_a
    images = Folio::Image.last(5).to_a if images.blank?
    documents = Folio::Document.limit(5).to_a

    sorted_yaml = YAML.load_file(self.class.data_path).sort_by do |data|
      klass = data["type"].constantize
      I18n.transliterate(klass.model_name.human)
    end.sort_by do |data|
      klass = data["type"].constantize
      klass.console_insert_row
    end

    sorted_yaml.each do |data|
      attrs = data.dup

      attrs.delete("_showcase")

      if attrs["cover"]
        if attrs["cover"].is_a?(Numeric)
          attrs["cover"] = images[attrs["cover"]] || images.sample
        else
          attrs["cover"] = images.sample
        end
      end

      attrs["documents"] = documents if attrs["documents"]

      if attrs["images"]
        attrs["images"] = images.shuffle
      end

      if attrs["article"]
        if attrs["article"] == 2
          attrs["article"] = articles[1]
        else
          attrs["article"] = articles[0]
        end
      end

      attrs.each do |key, value|
        if value == true
          if association_definition = attrs["type"].constantize::ASSOCIATIONS[key.to_sym]
            record = association_definition.first.constantize.last
            if record
              attrs[key] = record
            else
              attrs.delete(key)
            end
          end
        end
      end

      attrs["title"] = Faker::Hipster.sentence if attrs["title"] == true

      %w[description text].each do |key|
        attrs[key] = Faker::Hipster.paragraph if attrs[key] == true
      end

      %w[content].each do |key|
        if attrs[key] == true
          attrs[key] = "<p>#{Faker::Hipster.paragraph}</p>"
        elsif attrs[key] == "long"
          attrs[key] = 3.times.map { "<p>#{Faker::Hipster.paragraph}</p>" }.join("")
        end
      end

      attrs = handle_attributes(attrs)

      atom = @page.atoms.build(attrs)
      atom.data["_showcase"] = data["_showcase"]

      atom
    end

    @page
  end

  def container_class_name_for_atom(atom)
    if atom.class.console_insert_row > 1
      "px-h"
    else
      "container-fluid"
    end
  end

  def classname_prefix
    @classname_prefix ||= ::Rails.application.class.name[0].downcase
  end

  def handle_attributes(attrs)
    attrs
  end

  def cell_options(obj = {})
    (obj || {}).merge(folio_ui_atoms_showcase: true)
  end
end
