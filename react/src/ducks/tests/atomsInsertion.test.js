import 'folioTestSetup'

import atomsReducer, {
  addAtomToForm,
  editAtoms,
  initialState,
  newAtoms,
  setAtomsData,
  updateFormAtomType,
  updateFormAtomValue
} from '../atoms'

const atomType = 'Folio::Atom::Slots'
const plainType = 'Folio::Atom::Text'
const slots = ['slot-1', 'slot-2', 'slot-3']

const buildState = (usedSlots) => atomsReducer(initialState, setAtomsData({
  structures: {
    [plainType]: { structure: {} },
    [atomType]: {
      molecule: 'folio/molecule/slots',
      structure: {
        slot: { first_available_values: slots },
        title: { default_values: 'Default title' }
      }
    }
  },
  atoms: {
    atoms: usedSlots.map((slot, index) => ({
      id: index + 1,
      type: atomType,
      data: { slot }
    }))
  }
}))

describe('atom insertion constraints', () => {
  it('assigns a free value when changing the atom type without changing unrelated fields', () => {
    let state = buildState(['slot-1'])
    state = atomsReducer(state, newAtoms('atoms', 'append', [1], plainType))
    state = atomsReducer(state, updateFormAtomType(atomType, { content: 'Keep me' }))

    expect(state.form.atoms[0].record.data).toEqual({ slot: 'slot-2', content: 'Keep me' })
  })

  it('does not change the atom type when every allowed value is used', () => {
    let state = buildState(slots)
    state = atomsReducer(state, newAtoms('atoms', 'append', [3], plainType))

    expect(atomsReducer(state, updateFormAtomType(atomType, {}))).toBe(state)
  })

  it('preserves the edited atom value when changing type even if every position is occupied', () => {
    let state = buildState(slots)
    state = atomsReducer(state, editAtoms('atoms', [2]))
    state = atomsReducer(state, updateFormAtomType(atomType, { slot: 'slot-3' }))

    expect(state.form.atoms[0].record.data.slot).toEqual('slot-3')
  })

  it('replaces an occupied copied value when changing type', () => {
    let state = buildState(['slot-1'])
    state = atomsReducer(state, newAtoms('atoms', 'append', [1], plainType))
    state = atomsReducer(state, updateFormAtomType(atomType, { slot: 'slot-1' }))

    expect(state.form.atoms[0].record.data.slot).toEqual('slot-2')
  })

  it('counts root atoms and new form atoms when adding to a molecule', () => {
    let state = buildState(['slot-1'])
    state = atomsReducer(state, newAtoms('atoms', 'append', [1], atomType))
    state = atomsReducer(state, addAtomToForm(atomType))

    expect(state.form.atoms.map(({ record }) => record.data.slot)).toEqual(['slot-2', 'slot-3'])
    expect(atomsReducer(state, addAtomToForm(atomType))).toBe(state)
  })

  it('uses unsaved form values instead of the original values when adding to an edited molecule', () => {
    let state = buildState(['slot-1', 'slot-2'])
    state = atomsReducer(state, editAtoms('atoms', [1]))
    state = atomsReducer(state, updateFormAtomValue(0, 'slot', 'slot-3'))
    state = atomsReducer(state, addAtomToForm(atomType))

    expect(state.form.atoms.map(({ record }) => record.data.slot)).toEqual(['slot-3', 'slot-2'])
    expect(atomsReducer(state, addAtomToForm(atomType))).toBe(state)
  })
})
