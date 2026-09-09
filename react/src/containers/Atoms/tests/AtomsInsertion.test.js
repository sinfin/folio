import React from 'react'
import renderer from 'react-test-renderer'

import 'folioTestSetup'

import { Atoms } from '../'
import AtomForm from 'components/AtomForm'
import AtomInput from 'components/AtomForm/AtomInput'
import atomsReducer, {
  addAtomToForm,
  atomsSelector,
  atomTypesSelector,
  editAtoms,
  initialState,
  newAtoms,
  setAtomsData,
  updateFormAtomValue
} from 'ducks/atoms'

jest.mock('components/AtomForm', () => () => null)

const atomType = 'Folio::Atom::Slots'
const plainType = 'Folio::Atom::Text'
const slots = ['slot-1', 'slot-2', 'slot-3']
const buildState = (usedSlots) => atomsReducer(initialState, setAtomsData({
  structures: {
    [plainType]: { structure: {}, attachments: [], associations: {} },
    [atomType]: {
      attachments: [],
      associations: {},
      structure: {
        slot: {
          type: 'collection',
          collection: slots.map((value) => [value, value]),
          first_available_values: slots,
          first_available_values_limit_message: 'No free positions',
          unique_values_within_root: true
        }
      }
    }
  },
  destroyedIds: { atoms: [] },
  atoms: { atoms: usedSlots.map((slot) => ({ type: atomType, data: { slot } })) }
}))

const renderForm = (atoms, dispatch = jest.fn()) => renderer.create(
  <Atoms atoms={atomsSelector({ atoms })} atomTypes={atomTypesSelector({ atoms })} dispatch={dispatch} />
).root.findByType(AtomForm).props

describe('Atoms insertion controls', () => {
  afterEach(() => jest.restoreAllMocks())

  it.each(['updateFormAtomType', 'addAtom'])('explains an exhausted limit for %s', (action) => {
    const alert = jest.spyOn(window, 'alert').mockImplementation(() => {})
    const dispatch = jest.fn()
    let state = buildState(slots)
    state = atomsReducer(state, newAtoms('atoms', 'append', [3], plainType))
    const form = renderForm(state, dispatch)

    form[action](atomType, {})

    expect(dispatch).not.toHaveBeenCalled()
    expect(alert).toHaveBeenCalledWith('No free positions')
  })

  it.each([false, true])('filters options using unsaved form edits (with new sibling: %s)', (addSibling) => {
    let state = buildState(['slot-1', 'slot-2'])
    state = atomsReducer(state, editAtoms('atoms', [1]))
    state = atomsReducer(state, updateFormAtomValue(0, 'slot', 'slot-3'))
    if (addSibling) state = atomsReducer(state, addAtomToForm(atomType))
    const form = renderForm(state)

    const input = renderer.create(
      <AtomInput
        atom={form.form.atoms[0]}
        rootAtoms={form.rootAtoms}
        field='slot'
        index={0}
        onChange={() => {}}
        onValueChange={() => {}}
      />
    )

    expect(input.root.findAllByType('option').map(({ props }) => props.value)).toEqual(
      addSibling ? ['slot-3'] : ['slot-2', 'slot-3']
    )
  })
})
