import atomsReducer, {
  initialState,
  setAtomsData,
  updateFormAtomType,
  updateFormAtomValue,
  newAtoms,
  editAtoms,
  removeAtoms,
  saveFormAtoms,
  moveAtomsToIndex,
  updateFormAtomAttachments,
  removeFormAtomAttachment,
  validateAndSaveFormAtom,
  setFormValidationErrors,
  updateFormAtomAssociation,
  addAtomToForm,
  moveFormAtom,
  removeFormAtom
} from '../atoms'

import { SINGLE_LOCALE_ATOMS, MULTI_LOCALE_ATOMS } from 'constants/tests/atoms'

describe('atomsReducer', () => {
  let state

  beforeEach(() => {
    state = atomsReducer(initialState, setAtomsData(SINGLE_LOCALE_ATOMS))
  })

  it('setAtomsData', () => {
    expect(state.namespace).toEqual('page')
    expect(state.atoms['atoms'].length).toEqual(6)
  })

  it('setAtomsData multiple', () => {
    state = atomsReducer(initialState, setAtomsData(MULTI_LOCALE_ATOMS))
    expect(state.namespace).toEqual('page')
    expect(Object.keys(state.atoms).length).toEqual(2)
    expect(state.atoms.cs_atoms.length).toEqual(6)
    expect(state.atoms.en_atoms.length).toEqual(6)
  })

  it('updateFormAtomType', () => {
    state = atomsReducer(state, editAtoms('atoms', [0]))
    expect(state.form.atoms[0].type).not.toEqual('Dummy::Atom::DaVinci')
    expect(state.form.dirty).toEqual(false)
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    expect(state.form.dirty).toEqual(true)
    expect(state.form.atoms[0].record.type).toEqual('Dummy::Atom::DaVinci')
    expect(state.form.atoms[0].record.meta.structure.date).toBeTruthy()
    expect(state.form.atoms[0].record.data.content).toEqual('foo')

    state = atomsReducer(state, editAtoms('atoms', [3, 4, 5]))
    expect(state.form.atoms.length).toEqual(3)
    expect(state.form.atoms[0].type).not.toEqual('Dummy::Atom::DaVinci')
    expect(state.form.dirty).toEqual(false)
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    expect(state.form.dirty).toEqual(true)
    expect(state.form.atoms.length).toEqual(1)
    expect(state.form.atoms[0].record.type).toEqual('Dummy::Atom::DaVinci')
    expect(state.form.atoms[0].record.meta.structure.date).toBeTruthy()
    expect(state.form.atoms[0].record.data.content).toEqual('foo')
  })

  it('updateFormAtomValue', () => {
    state = atomsReducer(state, editAtoms('atoms', [0]))
    expect(state.form.atoms[0].record.type).toEqual('Folio::Atom::Text')
    expect(state.form.atoms[0].record.data.content).not.toEqual('bar')
    expect(state.form.dirty).toEqual(false)
    state = atomsReducer(state, updateFormAtomValue(0, 'content', 'bar'))
    expect(state.form.dirty).toEqual(true)
    expect(state.form.atoms[0].record.type).toEqual('Folio::Atom::Text')
    expect(state.form.atoms[0].record.data.content).toEqual('bar')
  })

  it('newAtoms', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, newAtoms('atoms', 'prepend', [0], 'Dummy::Atom::DaVinci'))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.action).toEqual('prepend')
    expect(newState.form.indices).toEqual([0])
    expect(newState.form.atoms.length).toEqual(1)
    expect(newState.form.atoms[0].record.type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.form.atoms[0].record.associations).toEqual({})
    expect(newState.form.atoms[0].record.timestamp).toBeTruthy()
    expect(newState.form.atoms[0].record.meta).toBeTruthy()
    expect(newState.form.edit).toEqual(false)
  })

  it('editAtoms', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, editAtoms('atoms', [0]))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.atoms.length).toEqual(1)
    expect(newState.form.atoms[0].record.id).toEqual(1)
    expect(newState.form.edit).toEqual(true)
  })

  it('removeAtoms', () => {
    // TODO test non-persisted atom
    const firstId = state.atoms['atoms'][0].id
    expect(state.atoms['atoms'].length).toEqual(6)
    expect(state.destroyedIds['atoms']).toEqual([])
    state = atomsReducer(state, removeAtoms('atoms', [0]))
    expect(state.atoms['atoms'].length).toEqual(5)
    expect(state.destroyedIds['atoms']).toEqual([firstId])

    state = atomsReducer(state, removeAtoms('atoms', [3, 4]))
    expect(state.atoms['atoms'].length).toEqual(3)
  })

  it('saveFormAtoms - from new', () => {
    state = atomsReducer(state, newAtoms('atoms', 'prepend', [0], 'Dummy::Atom::DaVinci'))
    state = atomsReducer(state, updateFormAtomValue(0, 'text', 'text'))
    const ids = [0, 1].map((i) => {
      const atom = state.atoms['atoms'][i]
      expect(atom.timestamp).toBeTruthy()
      expect(atom.id).toBeTruthy()
      expect(atom.type).not.toEqual('Dummy::Atom::DaVinci')
      return atom.id
    })
    expect(state.atoms['atoms'].length).toEqual(6)
    const newState = atomsReducer(state, saveFormAtoms())
    expect(newState.atoms['atoms'].length).toEqual(7)
    expect(newState.atoms['atoms'][0].type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.atoms['atoms'][0].id).toEqual(null)
    expect(newState.atoms['atoms'][0].timestamp).toBeTruthy()

    const newIndices = [1, 2]
    newIndices.forEach((newIndex, index) => {
      const oldId = ids[index]
      const atom = newState.atoms['atoms'][newIndex]
      expect(atom.timestamp).toBeTruthy()
      expect(atom.type).not.toEqual('Dummy::Atom::DaVinci')
      expect(atom.id).toEqual(oldId)
    })
  })

  it('saveFormAtoms - from edit', () => {
    state = atomsReducer(state, editAtoms('atoms', [0]))
    const oldId = state.form.atoms[0].record.id
    expect(oldId).toEqual(1)
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    expect(state.atoms['atoms'][0].type).not.toEqual('Dummy::Atom::DaVinci')
    expect(state.atoms['atoms'][0].data.content).not.toEqual('foo')
    expect(state.atoms['atoms'][0].id).toBeTruthy()
    expect(state.atoms['atoms'][0].timestamp).toBeTruthy()
    expect(state.atoms['atoms'].length).toEqual(6)
    expect(state.form.destroyedIds).toEqual([oldId])
    expect(state.destroyedIds['atoms']).toEqual([])

    state = atomsReducer(state, saveFormAtoms())
    expect(state.atoms['atoms'].length).toEqual(6)
    expect(state.atoms['atoms'][0].type).toEqual('Dummy::Atom::DaVinci')
    expect(state.atoms['atoms'][0].data.content).toEqual('foo')
    expect(state.atoms['atoms'][0].id).toEqual(null)
    expect(state.atoms['atoms'][0].timestamp).toBeTruthy()

    expect(state.destroyedIds['atoms']).toEqual([oldId])
  })

  it('saveFormAtoms - with filePlacements', () => {
    const filePlacements = {
      image_placement_attributes: [
        { id: 1, file_id: 1, title: 'foo' },
        { id: 2, file_id: 2, title: 'bar' }
      ]
    }
    expect(state.atoms['atoms'][0].type).not.toEqual('Dummy::Atom::Gallery')
    expect(state.atoms['atoms'][0]['image_placement_attributes']).toEqual(undefined)
    state = atomsReducer(state, newAtoms('atoms', 'prepend', [0], 'Dummy::Atom::Gallery'))
    state = atomsReducer(state, saveFormAtoms(filePlacements))
    expect(state.atoms['atoms'][0].type).toEqual('Dummy::Atom::Gallery')
    expect(state.atoms['atoms'][0]['image_placement_attributes']).toBeTruthy()
    expect(state.atoms['atoms'][0]['image_placement_attributes'].length).toEqual(2)
  })

  it('saveFormAtoms - last', () => {
    state = atomsReducer(state, newAtoms('atoms', 'splice', [3], 'Dummy::Atom::DaVinci'))
    state = atomsReducer(state, updateFormAtomValue(0, 'text', 'text'))
    expect(state.atoms['atoms'].length).toEqual(6)
    expect(state.atoms['atoms'][3].type).not.toEqual('Dummy::Atom::DaVinci')
    const newState = atomsReducer(state, saveFormAtoms())
    expect(newState.atoms['atoms'].length).toEqual(7)
    expect(newState.atoms['atoms'][3].type).toEqual('Dummy::Atom::DaVinci')
  })

  it('moveAtomsToIndex', () => {
    expect(state.atoms['atoms'][0].id).toEqual(1)
    expect(state.atoms['atoms'][1].id).toEqual(2)
    state = atomsReducer(state, moveAtomsToIndex('atoms', [1], 0, 'prepend'))
    expect(state.atoms['atoms'][0].id).toEqual(2)
    expect(state.atoms['atoms'][1].id).toEqual(1)

    let moveState = atomsReducer(state, moveAtomsToIndex('atoms', [3, 4, 5], 1, 'prepend'))
    expect(moveState.atoms['atoms'][0].id).toEqual(2)
    expect(moveState.atoms['atoms'][4].id).toEqual(1)

    moveState = atomsReducer(state, moveAtomsToIndex('atoms', [3, 4, 5], 0, 'append'))
    expect(moveState.atoms['atoms'][0].id).toEqual(2)
    expect(moveState.atoms['atoms'][4].id).toEqual(1)
  })

  // it('updateFormAtomAttachments, removeFormAtomAttachment', () => {
  //   state = atomsReducer(state, editAtoms('atoms', [0]))
  //   state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci'))
  //   expect(state.form.atom.cover_placement_attributes).toEqual(undefined)
  //   const data = {
  //     file_id: 1,
  //     file: { id: 1 }
  //   }
  //   const newState = atomsReducer(state, updateFormAtomAttachments('cover_placement_attributes', data))
  //   expect(newState.form.atom.cover_placement_attributes).toEqual(data)

  //   const finalState = atomsReducer(newState, removeFormAtomAttachment('cover_placement_attributes'))
  //   expect(finalState.form.atom.cover_placement_attributes).toEqual(undefined)
  // })

  it('validateAndSaveFormAtom', () => {
    state = atomsReducer(state, editAtoms('atoms', [0]))
    expect(state.form.atoms[0].validating).toEqual(false)
    state = atomsReducer(state, validateAndSaveFormAtom())
    expect(state.form.atoms[0].validating).toEqual(true)
  })

  it('setFormValidationErrors', () => {
    state = atomsReducer(state, editAtoms('atoms', [0]))
    state = atomsReducer(state, setFormValidationErrors({ 0: { valid: false, errors: { foo: 'bar' }, messages: ['Foo bar!'] } }))
    expect(state.form.atoms[0].errors).toEqual({ foo: 'bar' })
    expect(state.form.atoms[0].messages).toEqual(['Foo bar!'])
  })

  it('updateFormAtomAssociation', () => {
    const page = { id: 1, type: 'Folio::Page', label: 'O nás', value: 'Folio::Page -=- 1' }
    state = atomsReducer(state, newAtoms('atoms', 'prepend', [0], 'Dummy::Atom::DaVinci'))
    expect(state.form.atoms[0].record.associations['page']).toEqual(undefined)

    state = atomsReducer(state, updateFormAtomAssociation(0, 'page', page))
    expect(state.form.atoms[0].record.associations['page']).toEqual(page)
  })

  it('addAtomToForm', () => {
    expect(state.form.rootKey).toEqual(null)
    state = atomsReducer(state, editAtoms('atoms', [3, 4, 5]))
    expect(state.form.atoms.length).toEqual(3)
    state = atomsReducer(state, addAtomToForm('Dummy::Atom::Moleculable'))
    expect(state.form.atoms.length).toEqual(4)
  })

  it('moveFormAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    state = atomsReducer(state, editAtoms('atoms', [3, 4, 5]))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([4, 5, 6])
    state = atomsReducer(state, moveFormAtom(1, 0))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([5, 4, 6])

    state = atomsReducer(state, removeFormAtom(1))
    state = atomsReducer(state, removeFormAtom(1))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([5])
    state = atomsReducer(state, addAtomToForm('Dummy::Atom::Moleculable'))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([5, null])
    state = atomsReducer(state, moveFormAtom(1, 0))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([null, 5])
  })

  it('removeFormAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    state = atomsReducer(state, editAtoms('atoms', [3, 4, 5]))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([4, 5, 6])
    expect(state.form.destroyedIds).toEqual([])

    state = atomsReducer(state, removeFormAtom(1))
    expect(state.form.atoms.map((a) => a.record.id)).toEqual([4, 6])
    expect(state.form.destroyedIds).toEqual([5])
  })
})
