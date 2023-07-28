# frozen_string_literal: true

class Folio::Ui::AtomsCell < Folio::UiCell
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

  def sites_tabs_href(site)
    controller.folio.folio_ui_atoms_url(host: site.env_aware_domain, only_path: false)
  end

  def images
    @images ||= begin
      ary = Folio::File::Image.tagged_with("folio-ui-atoms").to_a

      if ary.size < 5
        ary = Folio::File::Image.tagged_with("unsplash").to_a

        if ary.size < 5
          ary += Folio::File::Image.first(5 - ary.size).to_a
        end
      end

      ary
    end
  end

  def documents
    @documents ||= begin
      ary = Folio::File::Document.tagged_with("folio-ui-atoms").to_a

      if ary.size < 5
        ary += Folio::File::Document.first(5 - ary.size).to_a
      end

      ary
    end
  end

  def placements
    @placements ||= begin
      h = {
        nil: Folio::Page.new,
      }

      require "faker"

      sorted_yaml = YAML.load_file(self.class.data_path).sort_by do |data|
        klass = data["type"].constantize
        I18n.transliterate(klass.model_name.human)
      end.sort_by do |data|
        klass = data["type"].constantize
        klass.console_insert_row
      end

      sorted_yaml.each do |data|
        attrs = data.dup

        attrs = handle_attributes(attrs)

        attrs.delete("_showcase")
        attrs.delete("_separate")
        attrs.delete("_placement_type")
        molecule = attrs.delete("_molecule").presence || 1

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

        if attrs["article"] == true
          blog_article_klass = "#{::Rails.application.class.name.deconstantize}::Blog::Article".constantize

          attrs["article"] = blog_article_klass.ordered
                                               .published
                                               .first
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

        attrs.each do |key, value|
          if value == true
            if association_klasses = attrs["type"].constantize::ASSOCIATIONS[key.to_sym]
              if association_klasses.is_a?(Hash)
                association_klasses = association_klasses[:klasses]
              end

              record = association_klasses.first.constantize.last

              if record
                attrs[key] = record
              else
                attrs.delete(key)
              end
            end
          end
        end

        if h[data["_placement_type"]].blank?
          h[data["_placement_type"]] = (data["_placement_type"] || "Folio::Page").constantize.new
        end

        molecule.times do
          atom = h[data["_placement_type"]].atoms.build(attrs)
          atom.data["_placement_type"] = data["_placement_type"] || "Folio::Page"
          atom.data["_showcase"] = data["_showcase"]
        end

        if data["_separate"]
          h[data["_placement_type"]].atoms.build({ type: nil })
        end
      end

      h
    end
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
    # to be overriden in project
    attrs
  end

  def cell_options(obj = {})
    (obj || {}).merge(folio_ui_atoms_showcase: true)
  end
end
