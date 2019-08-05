# frozen_string_literal: true

class Folio::Console::AtomsController < Folio::Console::BaseController
  layout 'folio/console/atoms'

  def index
    @atoms = Folio::Atom::Base.ordered
                              .where(id: params[:ids])
                              .to_a
                              .group_by(&:locale)
  end

  def preview
    @atoms = {}

    I18n.available_locales + [nil].each do |locale|
      key = locale ? "#{locale}_atoms_attributes" : 'atoms_attributes'
      atoms = atom_params[key]
      next if atoms.blank?
      @atoms[locale] = []
      atoms.each do |attrs|
        next if attrs['destroyed']
        next if attrs['_destroy']
        @atoms[locale] << attrs['type'].constantize
                                       .new(attrs.to_h.without('id'))
      end
    end

    render :index, layout: false
  end

  def validate
    atom = params.require(:type)
                 .constantize
                 .new(atom_validation_params)
    atom.placement = atom.placement_type.constantize.new

    if atom.valid?
      render json: { valid: true }
    else
      render json: { valid: false,
                     errors: atom.errors.messages,
                     messages: atom.errors.full_messages }
    end
  end

  private

    def atom_params
      params.permit(atoms_strong_params)
    end

    def atom_validation_params
      params.permit(:type,
                    :position,
                    :placement_type,
                    :placement_id,
                    :_destroy,
                    *file_placements_strong_params,
                    *Folio::Atom.strong_params)
    end
end
