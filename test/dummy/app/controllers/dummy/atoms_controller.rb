# frozen_string_literal: true

class Dummy::AtomsController < ApplicationController
  before_action :only_allow_superusers

  def show
    @root_data = YAML.load_file(Rails.root.join("data/atoms_showcase.yml"))

    add_breadcrumb t("activerecord.models.folio/atom", count: 2), dummy_atoms_path

    if params[:atom]
      @atom_klass = params[:atom].safe_constantize

      if @atom_klass &&
         @atom_klass < Folio::Atom::Base &&
         (atom_data = @root_data["atoms"][@atom_klass.to_s]) &&
         @atom_klass.valid_for_site_class?(Folio::Current.site.class)
        atom_data_src = atom_data

        if params[:screenshot]
          @screenshot = true

          hash_for_screenshot = atom_data.find { |hash| hash["_screenshot"] }
          atom_data_src = [hash_for_screenshot || atom_data.first]
        end

        @atom_data ||= atom_data_src.map do |hash|
          attrs = attrs_from_hash(hash)

          if @atom_klass.molecule?
            count = attrs.delete(:_count) || 1

            secondary = (attrs.delete(:_atoms) || []).map do |hash|
              Folio::Atom::Base.new(hash)
            end

            [attrs, Array.new(count) { @atom_klass.new(attrs) } + secondary]
          else
            [attrs, [@atom_klass.new(attrs)]]
          end
        end

        add_breadcrumb @atom_klass.model_name.human, dummy_atoms_path(atom: @atom_klass)
      else
        redirect_to dummy_atoms_path
        nil
      end
    else
      hash = {}

      @root_data["atoms"].keys.each do |class_name|
        klass = class_name.constantize

        if klass.valid_for_site_class?(Folio::Current.site.class)
          hash[klass.console_insert_row] ||= []
          hash[klass.console_insert_row] << { klass:, label: klass.model_name.human }
        end
      end

      @atom_classes_data = []

      hash.to_a.sort_by(&:first).each do |_console_insert_row, array|
        @atom_classes_data += array.sort_by { |h| ActiveSupport::Inflector.transliterate(h[:label]) }
      end
    end
  end

  private
    def only_allow_superusers
      return if params[:atom] && params[:screenshot]

      authenticate_user!

      return if Folio::Current.user.can_now?(:display_ui)

      redirect_to root_path
    end

    def images_for_attrs
      @images_for_attrs ||= (Folio::File::Image.tagged_with("unsplash").limit(10).presence || Folio::File::Image.limit(10)).to_a
    end

    def videos_for_attrs
      @videos_for_attrs ||= Folio::File::Video.limit(10).to_a
    end

    def documents_for_attrs
      @documents_for_attrs ||= Folio::File::Document.limit(10).presence.to_a
    end

    def attrs_from_hash(hash)
      attrs = hash ? hash.deep_symbolize_keys.without(:_screenshot) : {}

      if attrs[:cover] == true
        attrs[:cover] = images_for_attrs.sample
      end

      if attrs[:images] == true
        attrs[:images] = images_for_attrs
      elsif attrs[:images].is_a?(Numeric)
        attrs[:images] = images_for_attrs.first(attrs[:images])
      end

      if attrs[:video_cover] == true
        attrs[:video_cover] = videos_for_attrs.sample
      end

      if attrs[:documents] == true
        attrs[:documents] = documents_for_attrs
      elsif attrs[:documents].is_a?(Numeric)
        attrs[:documents] = documents_for_attrs.first(attrs[:documents])
      end

      @root_data["values_for_true"].symbolize_keys.each do |key, value|
        if attrs[key] == true
          attrs[key] = value
        end
      end

      attrs
    end
end
