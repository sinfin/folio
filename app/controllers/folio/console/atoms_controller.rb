# frozen_string_literal: true

class Folio::Console::AtomsController < Folio::Console::BaseController
  include Rails.application.routes.url_helpers

  layout "folio/console/atoms"

  before_action :set_layout_stylesheet_path

  def index
  end

  def preview
    @atoms = {}

    (Folio::Current.site.locales + [nil]).each do |locale|
      key = locale ? "#{locale}_atoms_attributes" : "atoms_attributes"
      atoms = atom_params[key]
      next if atoms.nil?
      @atoms[locale] = []

      position = 0

      atoms.sort_by { |h| h["position"] || 0 }.each_with_index do |attrs, i|
        next if attrs["destroyed"]
        next if attrs["_destroy"]
        props = attrs.to_h
                     .without("id", "placement_id")
                     .merge(placement: attrs[:placement_type].constantize.new,
                            position: position += 1)

        atom = attrs["type"].constantize
                            .new(props)

        # check if atom is valid here, will check atom.errors in the previews cell
        atom.valid?

        @atoms[locale] << atom
      end
    end

    @atoms.each do |key, atoms|
      @atoms[key] = Folio::Atom.atoms_in_molecules(atoms)
    end

    if params[:class_name].present?
      @klass = params[:class_name].constantize

      @default_locale = @klass.atom_default_locale_from_params(params[:settings])
      @settings = {}

      hash = if @klass.method(:atom_settings_from_params).arity == 1
        @klass.atom_settings_from_params(params[:settings])
      else
        @klass.atom_settings_from_params(params[:settings], { request:, current_user: Folio::Current.user, current_site: Folio::Current.site })
      end

      hash.each do |locale, data|
        @settings[locale] ||= {}
        data.each do |h|
          html = cell(h[:cell_name], h[:model], h[:options] || {}).show
          @settings[locale][h[:key]] = html
        end
      end
    else
      @default_locale = I18n.default_locale
      @settings = {}
    end

    @non_interactive ||= params[:audited_audit_active] == "1"

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

    render json: res, root: false
  end

  def default_url_options
    if Folio::Current.site.locales.size > 1
      { locale: I18n.locale }
    else
      {}
    end
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

    def set_layout_stylesheet_path
      @layout_stylesheet_path = Folio.atoms_previews_stylesheet_path(site: Folio::Current.site,
                                                                     class_name: params[:class_name])
    end
end
