# frozen_string_literal: true

require "test_helper"

class AuditedPage < Folio::Page
  include Folio::Audited

  audited only: :title
end

class Folio::AuditedTest < ActiveSupport::TestCase
  def reconstruct_atoms_for(revision)
    revision.reconstruct_atoms.reject { |a| a.marked_for_destruction? }
  end

  test 'audited model & atoms' do
    # version 1
    @page = AuditedPage.create(title: 'v1')
    @page.atoms << Folio::Atom::Text.new(content: 'atom 1 v2')

    # version 2
    @page.update!(title: 'v2')
    @page.atoms << Folio::Atom::Text.new(content: 'atom 2 v2')

    # version 3
    @page.atoms.load
    @page.atoms.first.content = 'atom 1 v3'
    @page.atoms.second.content = 'atom 2 v3'
    @page.update!(title: 'v3')

    # version 4
    @page.update!(title: 'v4')
    @page.atoms.second.destroy

    # version 5
    @page.update!(title: 'v5')
    @page.atoms << Folio::Atom::Text.new(content: 'atom 3 v5')

    # revision version 1
    revision = @page.revisions.first
    atoms = reconstruct_atoms_for(revision)

    assert_equal 'v1', revision.title
    assert_equal 1, atoms.size
    assert_equal 2, @page.atoms.count

    # revision version 2
    revision = @page.revisions.second
    atoms = reconstruct_atoms_for(revision)

    assert_equal 'v2', revision.title
    assert_equal 'atom 1 v2', atoms.first.content
    assert_equal 'atom 2 v2', atoms.second.content
    assert_not_equal 'atom 1 v2', @page.atoms.first.content
    assert_not_equal 'atom 2 v2', @page.atoms.second.content

    # revision version 4
    revision = @page.revisions.fourth
    atoms = reconstruct_atoms_for(revision)

    assert_equal 'v4', revision.title
    assert_equal 1, atoms.size
    assert_equal 2, @page.atoms.count

    # restore v3
    revision = @page.audits.third.revision
    revision.reconstruct_atoms
    revision.save!

    @page.reload

    assert_equal 'v3', @page.title
    assert_equal 'atom 1 v3', @page.atoms.first.content
    assert_equal 'atom 2 v3', @page.atoms.second.content
  end
end
