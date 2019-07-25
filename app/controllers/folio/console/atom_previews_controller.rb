# frozen_string_literal: true

class Folio::Console::AtomPreviewsController < Folio::Console::BaseController
  layout 'folio/console/atom_previews'

  def show
    @atoms = Folio::Atom::Base.where(id: params[:ids])
  end

  def preview
    @atoms = atom_params.require(:cs_atoms_attributes).map do |attrs|
      attrs['type'].constantize.new(attrs.to_h.without('id'))
    end
    render :show, layout: false
  end

  private

    def atom_params
      params.permit(atoms_strong_params)
    end
end
