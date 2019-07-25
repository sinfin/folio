import atomsReducer, {
  initialState,
  setAtomsData,
  updateAtomValue,
  updateAtomType
} from '../atoms'

import { SINGLE_LOCALE_ATOMS, MULTI_LOCALE_ATOMS } from 'constants/tests/atoms'

describe('atomsReducer', () => {
  describe('single locale', () => {
    let state

    beforeEach(() => {
      state = atomsReducer(initialState, setAtomsData(SINGLE_LOCALE_ATOMS))
    })

    it('setAtomsData', () => {
      expect(state.namespace).toEqual('page')
      expect(state.atoms.atoms.length).toEqual(3)
    })

    it('updateAtomValue', () => {
      expect(state.atoms.atoms[0].data.content).not.toEqual('foo')
      const newSingleState = atomsReducer(state, updateAtomValue('atoms', 0, 'content', 'foo'))
      expect(newSingleState.atoms.atoms[0].data.content).toEqual('foo')
    })

    it('updateAtomType', () => {
      state = atomsReducer(state, updateAtomValue('atoms', 0, 'content', 'foo'))
      expect(state.atoms.atoms[0].type).not.toEqual('Atom::PageReferenceWithRichtext')
      const newSingleState = atomsReducer(state, updateAtomType('atoms', 0, 'Atom::PageReferenceWithRichtext', { content: 'foo' }))
      expect(newSingleState.atoms.atoms[0].type).toEqual('Atom::PageReferenceWithRichtext')
      expect(newSingleState.atoms.atoms[0].data.content).toEqual('foo')
    })
  })

  describe('multiple locales', () => {
    let state

    beforeEach(() => {
      state = atomsReducer(initialState, setAtomsData(MULTI_LOCALE_ATOMS))
    })

    it('setAtomsData', () => {
      expect(state.namespace).toEqual('page')
      expect(Object.keys(state.atoms).length).toEqual(2)
      expect(state.atoms.cs_atoms.length).toEqual(3)
      expect(state.atoms.en_atoms.length).toEqual(3)
    })

    it('updateAtomValue', () => {
      expect(state.atoms.cs_atoms[0].data.content).not.toEqual('foo')
      expect(state.atoms.en_atoms[0].data.content).not.toEqual('foo')
      const newMultiState = atomsReducer(state, updateAtomValue('cs_atoms', 0, 'content', 'foo'))
      expect(newMultiState.atoms.cs_atoms[0].data.content).toEqual('foo')
      expect(newMultiState.atoms.en_atoms[0].data.content).not.toEqual('foo')
    })

    it('updateAtomType', () => {
      state = atomsReducer(state, updateAtomValue('cs_atoms', 0, 'content', 'foo'))
      expect(state.atoms.cs_atoms[0].type).not.toEqual('Atom::PageReferenceWithRichtext')
      expect(state.atoms.en_atoms[0].type).not.toEqual('Atom::PageReferenceWithRichtext')
      const newMultiState = atomsReducer(state, updateAtomType('cs_atoms', 0, 'Atom::PageReferenceWithRichtext', { content: 'foo' }))
      expect(newMultiState.atoms.cs_atoms[0].type).toEqual('Atom::PageReferenceWithRichtext')
      expect(newMultiState.atoms.cs_atoms[0].data.content).toEqual('foo')
      expect(newMultiState.atoms.en_atoms[0].type).not.toEqual('Atom::PageReferenceWithRichtext')
    })
  })
})
