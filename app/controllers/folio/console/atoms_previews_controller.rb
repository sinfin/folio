# frozen_string_literal: true

class Folio::Console::AtomsPreviewsController < Folio::Console::BaseController
  layout 'folio/console/atoms_previews'

  def show
    @atoms = Folio::Atom::Base.where(id: params[:ids]).to_a.group_by(&:locale)
  end

  def preview
    @atoms = {}

    I18n.available_locales.each do |locale|
      atoms = atom_params["#{locale}_atoms_attributes"]
      next if atoms.blank?
      @atoms[locale] = []
      atoms.each do |attrs|
        next if attrs['_destroy']
        @atoms[locale] << attrs['type'].constantize
                                       .new(attrs.to_h.without('id'))
      end
    end

    render :show, layout: false
  end

  private

    def atom_params
      params.permit(atoms_strong_params)
    end
end
