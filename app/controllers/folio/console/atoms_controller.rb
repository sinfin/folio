# frozen_string_literal: true

class Folio::Console::AtomsController < Folio::Console::BaseController
  include Rails.application.routes.url_helpers

  layout 'folio/console/atoms'

  def index
  end

  def preview
    @atoms = {}

    (I18n.available_locales + [nil]).each do |locale|
      key = locale ? "#{locale}_atoms_attributes" : 'atoms_attributes'
      atoms = atom_params[key]
      next if atoms.nil?
      @atoms[locale] = []
      atoms.each do |attrs|
        next if attrs['destroyed']
        next if attrs['_destroy']
        props = attrs.to_h
                     .without('id', 'placement_id')
                     .merge(placement: attrs[:placement_type].constantize.new)
        @atoms[locale] << attrs['type'].constantize
                                       .new(props)
      end
    end

    @atoms.each do |key, atoms|
      @atoms[key] = Folio::Atom.atoms_in_molecules(atoms)
    end

    if params[:class_name].present?
      @klass = params[:class_name].constantize
      @settings = {}

      @klass.atom_settings_from_params(params[:settings])
            .each do |locale, data|
        @settings[locale] ||= {}
        data.each do |h|
          html = cell(h[:cell_name], h[:model], h[:options] || {}).show
          @settings[locale][h[:key]] = html
        end
      end
    else
      @settings = {}
    end

    render :preview, layout: false
  end

  def placement_preview
    klass = params.require(:klass).safe_constantize
    if klass < ActiveRecord::Base && klass.new.respond_to?(:atoms)
      @non_interactive = true
      @atoms = {
        I18n.locale => klass.find(params[:id]).atoms_in_molecules || [],
      }
      render :preview
    else
      fail ActionController::ParameterMissing, :klass
    end
  end

  def validate
    res = params.require(:atoms)
                .map do |raw|
                  p = raw.permit(*atom_validation_params)
                  atom = p[:type].constantize.new(p)
                  atom.placement = atom.placement_type.constantize.new

                  if atom.valid?
                    { valid: true }
                  else
                    { valid: false,
                      errors: atom.errors.messages,
                      messages: atom.errors.full_messages }
                  end
                end

    render json: res
  end

  def default_url_options
    { locale: I18n.locale }
  end

  private
    def atom_params
      params.permit(atoms_strong_params)
    end

    def atom_validation_params
      [
        :type,
        :position,
        :placement_type,
        :placement_id,
        :_destroy,
        *file_placements_strong_params,
        *Folio::Atom.strong_params,
      ]
    end
end
