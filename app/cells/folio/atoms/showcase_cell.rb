# frozen_string_literal: true

class Folio::Atoms::ShowcaseCell < Folio::ApplicationCell
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
    documents = Folio::Document.limit(5).to_a
    # articles = Mmspektrum::Article.ordered.limit(3).to_a
    # issue = Mmspektrum::Issue.ordered.offset(5).first
    # serial = Mmspektrum::Serial.joins(:cover_placement).first
    # serial ||= Mmspektrum::Serial.published.last
    # menu = Mmspektrum::Menu::Navigation.last

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
      attrs["cover"] = images[0] if attrs["cover"]
      attrs["documents"] = documents if attrs["documents"]
      attrs["images"] = images if attrs["images"]

      if attrs["article"]
        if attrs["article"] == 2
          attrs["article"] = articles[1]
        else
          attrs["article"] = articles[0]
        end
      end

      attrs["main_article"] = articles[0] if attrs["main_article"]
      attrs["article_1"] = articles[1] if attrs["article_1"]
      attrs["article_2"] = articles[2] if attrs["article_2"]

      attrs["issue"] = issue if attrs["issue"]
      attrs["serial"] = serial if attrs["serial"]
      attrs["menu"] = menu if attrs["menu"]

      attrs["title"] = Faker::Hipster.sentence if attrs["title"] == true

      %w[description].each do |key|
        attrs[key] = Faker::Hipster.paragraph if attrs[key] == true
      end

      %w[content].each do |key|
        attrs[key] = "<p>#{Faker::Hipster.paragraph}</p>" if attrs[key] == true
      end

      atom = @page.atoms.build(attrs)
      atom.data["_showcase"] = data["_showcase"]
      atom
    end

    @page
  end

  def container_class_name_for_atom(atom)
    if atom.model_name.human.include?("Homepage")
      "px-h"
    else
      "container-fluid"
    end
  end
end
