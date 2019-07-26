import atomsReducer, {
  initialState,
  setAtomsData,
  updateFormAtomType,
  updateFormAtomValue,
  newAtom,
  editAtom,
  saveFormAtom
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
    const newState = atomsReducer(state, updateFormAtomType('Atom::PageReferenceWithRichtext', { content: 'foo' }))
    expect(newState.form.atom.type).toEqual('Atom::PageReferenceWithRichtext')
    expect(newState.form.atom.meta.structure.model).toBeTruthy()
    expect(newState.form.atom.data.content).toEqual('foo')
  })

  it('updateFormAtomValue', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    expect(state.form.atom.data.content).not.toEqual('bar')
    const newState = atomsReducer(state, updateFormAtomValue('content', 'bar'))
    expect(newState.form.atom.data.content).toEqual('bar')
  })

  it('newAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, newAtom('atoms', 0, 'Atom::PageReferenceWithRichtext'))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.atom.type).toEqual('Atom::PageReferenceWithRichtext')
    expect(newState.form.atom.timestamp).toBeTruthy()
  })

  it('editAtom', () => {
    expect(state.form.rootKey).toEqual(null)
    const newState = atomsReducer(state, editAtom('atoms', 0))
    expect(newState.form.rootKey).toEqual('atoms')
    expect(newState.form.atom.id).toEqual(3)
  })

  it('saveFormAtom', () => {
    state = atomsReducer(state, editAtom('atoms', 0))
    state = atomsReducer(state, updateFormAtomType('Atom::PageReferenceWithRichtext', { content: 'foo' }))
    const newState = atomsReducer(state, saveFormAtom())
    expect(state.atoms['atoms'][0].type).not.toEqual('Atom::PageReferenceWithRichtext')
    expect(state.atoms['atoms'][0].data.content).not.toEqual('foo')
    expect(newState.atoms['atoms'][0].type).toEqual('Atom::PageReferenceWithRichtext')
    expect(newState.atoms['atoms'][0].data.content).toEqual('foo')
  })
})
