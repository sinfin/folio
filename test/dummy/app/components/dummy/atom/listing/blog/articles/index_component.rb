# frozen_string_literal: true

class Dummy::Atom::Listing::Blog::Articles::IndexComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def before_render
    @page = @atom_options[:page] || current_page_singleton(Dummy::Page::Blog::Articles::Index, fail_on_missing: true)
  end
end
