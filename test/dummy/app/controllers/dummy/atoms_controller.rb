# frozen_string_literal: true

class Dummy::AtomsController < ApplicationController
  before_action :only_allow_superusers

  def show
    @root_data = YAML.load_file(Rails.root.join("data/atoms_showcase.yml"))

    if params[:atom]
      @atom_klass = params[:atom].safe_constantize

      if @atom_klass && @atom_klass < Folio::Atom::Base && atom_data = @root_data["atoms"][@atom_klass.to_s]
        @atom_data = atom_data.map do |hash|
          attrs = attrs_from_hash(hash)

          if @atom_klass.molecule?
            count = attrs.delete(:_count) || 1
            [attrs, Array.new(count) { @atom_klass.new(attrs) }]
          else
            [attrs, [@atom_klass.new(attrs)]]
          end
        end

        add_breadcrumb "Atoms", dummy_atoms_path
        add_breadcrumb dummy_atoms_path(atom: @atom_klass)
      else
        redirect_to dummy_atoms_path
        nil
      end
    else
      @atom_classes_data = @root_data["atoms"].keys.map do |class_name|
        klass = class_name.constantize
        { klass:, label: klass.model_name.human }
      end.sort_by { |h| h[:label] }
    end
  end

  private
    def only_allow_superusers
      authenticate_account!

      unless current_account.has_role?(:superuser)
        redirect_to root_path
      end
    end

    def images_for_attrs
      @images_for_attrs ||= (Folio::File::Image.tagged_with("unsplash").limit(10).presence || Folio::File::Image.limit(10)).to_a
    end

    def attrs_from_hash(hash)
      attrs = hash.deep_symbolize_keys

      if attrs[:cover] == true
        attrs[:cover] = images_for_attrs.sample
      end

      if attrs[:images] == true
        attrs[:images] = images_for_attrs
      end

      @root_data["values_for_true"].symbolize_keys.each do |key, value|
        if attrs[key] == true
          attrs[key] = value
        end
      end

      attrs
    end
end
