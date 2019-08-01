import atomsReducer, {
  initialState,
  setAtomsData,
  updateFormAtomType,
  updateFormAtomValue,
  newAtom,
  editAtom,
  removeAtom,
  saveFormAtom,
  moveAtomToIndex,
  updateFormAtomAttachments,
  removeFormAtomAttachment
} from '../atoms'

import { SINGLE_LOCALE_ATOMS, MULTI_LOCALE_ATOMS } from 'constants/tests/atoms'

describe('atomsReducer', () => {
  let state

  beforeEach(() => {
    state = atomsReducer(initialState, setAtomsData(SINGLE_LOCALE_ATOMS))
  })

  it('setAtomsData', () => {
    expect(state.namespace).toEqual('page')
    expect(state.atoms['atoms'].length).toEqual(3)
  })

  it('setAtomsData multiple', () => {
    state = atomsReducer(initialState, setAtomsData(MULTI_LOCALE_ATOMS))
    expect(state.namespace).toEqual('page')
    expect(Object.keys(state.atoms).length).toEqual(2)
    expect(state.atoms.cs_atoms.length).toEqual(3)
    expect(state.atoms.en_atoms.length).toEqual(3)
  })

  it('updateFormAtomType', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    expect(state.form.atom.type).not.toEqual('Dummy::Atom::DaVinci')
    const newState = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    expect(newState.form.atom.type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.form.atom.meta.structure.date).toBeTruthy()
    expect(newState.form.atom.data.content).toEqual('foo')
  })

  it('updateFormAtomValue', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    expect(state.form.atom.type).toEqual('Folio::Atom::Text')
    expect(state.form.atom.data.content).not.toEqual('bar')
    const newState = atomsReducer(state, updateFormAtomValue('content', 'bar'))
    expect(newState.form.atom.type).toEqual('Folio::Atom::Text')
    expect(newState.form.atom.data.content).toEqual('bar')
  })

  it('newAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, newAtom('atoms', 0, 'Dummy::Atom::DaVinci'))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.atom.type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.form.atom.timestamp).toBeTruthy()
    expect(newState.form.edit).toEqual(false)
  })

  it('editAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, editAtom('atoms', 0))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.atom.id).toEqual(1)
    expect(newState.form.edit).toEqual(true)
  })

  it('removeAtom', () => {
    // TODO test non-persisted atom
    const firstId = state.atoms['atoms'][0].id
    expect(state.atoms['atoms'].length).toEqual(3)
    expect(state.destroyedIds['atoms']).toEqual([])
    const newState = atomsReducer(state, removeAtom('atoms', 0))
    expect(newState.atoms['atoms'].length).toEqual(2)
    expect(newState.destroyedIds['atoms']).toEqual([firstId])
  })

  it('saveFormAtom - from new', () => {
    state = atomsReducer(state, newAtom('atoms', 0, 'Dummy::Atom::DaVinci'))
    state = atomsReducer(state, updateFormAtomValue('text', 'text'))
    const ids = [0, 1].map((i) => {
      const atom = state.atoms['atoms'][i]
      expect(atom._destroy).toEqual(undefined)
      expect(atom.timestamp).toEqual(undefined)
      expect(atom.id).toBeTruthy()
      expect(atom.type).not.toEqual('Dummy::Atom::DaVinci')
      return atom.id
    })
    expect(state.atoms['atoms'].length).toEqual(3)
    const newState = atomsReducer(state, saveFormAtom())
    expect(newState.atoms['atoms'].length).toEqual(4)
    expect(newState.atoms['atoms'][0].type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.atoms['atoms'][0].id).toEqual(undefined)
    expect(newState.atoms['atoms'][0].timestamp).toBeTruthy()

    const newIndices = [1, 2]
    newIndices.forEach((newIndex, index) => {
      const oldId = ids[index]
      const atom = newState.atoms['atoms'][newIndex]
      expect(atom._destroy).toEqual(undefined)
      expect(atom.timestamp).toEqual(undefined)
      expect(atom.type).not.toEqual('Dummy::Atom::DaVinci')
      expect(atom.id).toEqual(oldId)
    })
  })

  it('saveFormAtom - from edit with id', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    const oldId = state.form.atom.id
    expect(oldId).toEqual(1)
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    expect(state.atoms['atoms'][0]._destroy).toEqual(undefined)
    expect(state.atoms['atoms'][1].type).not.toEqual('Dummy::Atom::DaVinci')
    expect(state.atoms['atoms'][1].data.content).not.toEqual('foo')
    expect(state.atoms['atoms'][1].id).toBeTruthy()
    expect(state.atoms['atoms'][1].timestamp).toEqual(undefined)
    expect(state.atoms['atoms'].length).toEqual(3)

    const newState = atomsReducer(state, saveFormAtom())
    expect(newState.atoms['atoms'].length).toEqual(3)
    expect(newState.destroyedIds['atoms']).toEqual([oldId])
    expect(newState.atoms['atoms'][0].type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.atoms['atoms'][0].data.content).toEqual('foo')
    expect(newState.atoms['atoms'][0].id).toEqual(undefined)
    expect(newState.atoms['atoms'][0].timestamp).toBeTruthy()
  })

  it('saveFormAtom - from edit without id', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    expect(state.form.atom.id).toEqual(1)
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    expect(state.atoms['atoms'][0]._destroy).toEqual(undefined)
    expect(state.atoms['atoms'][1].type).not.toEqual('Dummy::Atom::DaVinci')
    expect(state.atoms['atoms'][1].data.content).not.toEqual('foo')
    expect(state.atoms['atoms'][1].id).toBeTruthy()
    expect(state.atoms['atoms'][1].timestamp).toEqual(undefined)
    expect(state.atoms['atoms'].length).toEqual(3)

    const newState = atomsReducer(state, saveFormAtom())
    expect(newState.atoms['atoms'].length).toEqual(3)
    expect(newState.atoms['atoms'][0].type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.atoms['atoms'][0].data.content).toEqual('foo')
    expect(newState.atoms['atoms'][0].id).toEqual(undefined)
    expect(newState.atoms['atoms'][0].timestamp).toBeTruthy()
  })

  it('moveAtomToIndex', () => {
    expect(state.atoms['atoms'][0].id).toEqual(1)
    expect(state.atoms['atoms'][1].id).toEqual(2)
    const newState = atomsReducer(state, moveAtomToIndex('atoms', 1, 0))
    expect(newState.atoms['atoms'][0].id).toEqual(2)
    expect(newState.atoms['atoms'][1].id).toEqual(1)
  })

  it('updateFormAtomAttachments, removeFormAtomAttachment', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci'))
    expect(state.form.atom.cover_placement_attributes).toEqual(undefined)
    const data = {
      file_id: 1,
      file: { id: 1 }
    }
    const newState = atomsReducer(state, updateFormAtomAttachments('cover_placement_attributes', data))
    expect(newState.form.atom.cover_placement_attributes).toEqual(data)

    const finalState = atomsReducer(newState, removeFormAtomAttachment('cover_placement_attributes'))
    expect(finalState.form.atom.cover_placement_attributes).toEqual(undefined)
  })
})
