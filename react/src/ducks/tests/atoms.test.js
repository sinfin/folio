import atomsReducer, {
  initialState,
  setAtomsData,
  updateFormAtomType,
  updateFormAtomValue,
  newAtom,
  editAtom,
  removeAtom,
  saveFormAtom,
  moveAtomToIndex
} from '../atoms'

import { SINGLE_LOCALE_ATOMS, MULTI_LOCALE_ATOMS } from 'constants/tests/atoms'

describe('atomsReducer', () => {
  let state

  beforeEach(() => {
    state = atomsReducer(initialState, setAtomsData(SINGLE_LOCALE_ATOMS))
  })

  it('setAtomsData', () => {
    expect(state.namespace).toEqual('page')
    expect(state.atoms.atoms.length).toEqual(3)
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
  })

  it('editAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, editAtom('atoms', 0))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.atom.id).toEqual(1)
  })

  it('removeAtom', () => {
    // TODO test non-persisted atom
    expect(state.atoms.atoms[0]._destroy).toEqual(undefined)
    const newState = atomsReducer(state, removeAtom('atoms', 0))
    expect(newState.atoms.atoms[0]._destroy).toEqual(true)
  })

  it('saveFormAtom', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    state = atomsReducer(state, updateFormAtomType('Dummy::Atom::DaVinci', { content: 'foo' }))
    const newState = atomsReducer(state, saveFormAtom())
    expect(state.atoms['atoms'][0].type).not.toEqual('Dummy::Atom::DaVinci')
    expect(state.atoms['atoms'][0].data.content).not.toEqual('foo')
    expect(newState.atoms['atoms'][0].type).toEqual('Dummy::Atom::DaVinci')
    expect(newState.atoms['atoms'][0].data.content).toEqual('foo')
  })

  it('moveAtomToIndex', () => {
    expect(state.atoms.atoms[0].id).toEqual(1)
    expect(state.atoms.atoms[1].id).toEqual(2)
    const newState = atomsReducer(state, moveAtomToIndex('atoms', 1, 0))
    expect(newState.atoms.atoms[0].id).toEqual(2)
    expect(newState.atoms.atoms[1].id).toEqual(1)
  })
})
