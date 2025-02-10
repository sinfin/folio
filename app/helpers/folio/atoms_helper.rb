# frozen_string_literal: true

module Folio::AtomsHelper
  BROKEN_DATA_KEY = :@folio_broken_atoms_data

  def atoms_rescue_lambda
    @atoms_rescue_lambda ||= lambda do |e, atom|
      if Rails.env.development? && ENV["FOLIO_DEBUG_ATOMS"]
        raise e
      end

      if controller_instance = try(:controller)
        folio_broken_atoms_data = controller_instance.instance_variable_get(BROKEN_DATA_KEY)
        folio_broken_atoms_data ||= []

        folio_broken_atoms_data << { atom:, error: e }

        controller_instance.instance_variable_set(BROKEN_DATA_KEY, folio_broken_atoms_data)
      end

      Sentry.capture_exception(e) if defined?(Sentry)
    end
  end

  def render_atom(atom, atom_options: {})
    if atom.class.component_class
      if self.is_a?(Folio::ApplicationCell)
        capture do
          render_view_component(atom.class.component_class.new(atom:, atom_options:),
                                rescue_lambda: lambda { |e| atoms_rescue_lambda.call(e, atom) })
        end
      else
        capture do
          render(atom.class.component_class.new(atom:, atom_options:))
        rescue StandardError => e
          atoms_rescue_lambda.call(e, atom)
        end
      end
    elsif atom.class.cell_name
      begin
        cell(atom.class.cell_name,
             atom,
             atom.cell_options.present? ? atom.cell_options.merge(atom_options) : atom_options).show
      rescue StandardError => e
        atoms_rescue_lambda.call(e, atom)
      end
    else
      render "folio/atoms/#{atom.partial_name}", data: atom
    end
  end

  def render_molecule(molecule, atoms, atom_options: {})
    if atoms.present?
      if molecule.is_a?(String)
        begin
          cell(molecule,
               atoms,
               atom_options).show
        rescue StandardError => e
          atoms_rescue_lambda.call(e, atoms.first)
        end
      elsif molecule < ViewComponent::Base
        if self.is_a?(Folio::ApplicationCell)
          capture do
            render_view_component(molecule.new(atoms:, atom_options:),
                                  rescue_lambda: lambda { |e| atoms_rescue_lambda.call(e, atoms.first) })
          end
        else
          capture do
            render(molecule.new(atoms:, atom_options:))
          rescue StandardError => e
            atoms_rescue_lambda.call(e, atoms)
          end
        end
      else
        begin
          cell(molecule.cell_name,
               atoms,
               molecule.cell_options.present? ? molecule.cell_options.merge(atom_options) : atom_options).show
        rescue StandardError => e
          atoms_rescue_lambda.call(e, atoms)
        end
      end
    end
  end

  def render_atoms(atoms, only: [], except: [], atom_options: {}, cover_placements: true)
    if cover_placements && !atom_options[:cover_placements]
      atom_options = atom_options.merge(cover_placements: cover_placements_for_atoms(atoms))
    end

    atoms.filter_map do |atom|
      next if only.present? && !only.include?(atom.class)
      next if except.present? && except.include?(atom.class)

      render_atom(atom, atom_options:)
    end.join("").html_safe
  end

  def render_atoms_in_molecules(atoms_in_molecules, only: [], except: [], atom_options: {}, cover_placements: true)
    if cover_placements
      atoms = []
      atoms_in_molecules.each { |_molecule, molecule_atoms| atoms += molecule_atoms }
      atom_options = atom_options.merge(cover_placements: cover_placements_for_atoms(atoms))
    end

    atoms_in_molecules.filter_map do |molecule, atoms|
      if only.present?
        atoms = atoms.select { |a| only.include?(a.class) }
      end

      if except.present?
        atoms = atoms.select { |a| except.exclude?(a.class) }
      end

      next if atoms.blank?

      if molecule.present?
        render_molecule(molecule, atoms, atom_options:)
      else
        render_atoms(atoms, atom_options:)
      end
    end.join("").html_safe
  end

  def cover_placements_for_atoms(atoms)
    placement = []

    atoms.each do |atom|
      if atom.class::ATTACHMENTS.include?(:cover)
        placement << atom
      end
    end

    if placement.present?
      Folio::FilePlacement::Cover.where(placement:)
                                 .includes(:file)
                                 .index_by(&:placement_id)
    else
      {}
    end
  end
end
