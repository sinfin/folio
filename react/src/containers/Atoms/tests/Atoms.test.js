import React from 'react'
import renderer from 'react-test-renderer'
import { Atoms } from '../'
import AtomForm from 'components/AtomForm'

import atomsReducer, {
  atomsSelector,
  atomTypesSelector,
  initialState,
  setAtomsData
} from 'ducks/atoms'

import { SINGLE_LOCALE_ATOMS, MULTI_LOCALE_ATOMS } from 'constants/tests/atoms'

describe('Atoms', () => {
  it('single locale', () => {
    const state = { atoms: atomsReducer(initialState, setAtomsData(SINGLE_LOCALE_ATOMS)) }
    const props = {
      dispatch: () => {},
      atoms: atomsSelector(state),
      atomTypes: atomTypesSelector(state)
    }

    const component = renderer.create(<Atoms {...props} />)
    const atomForms = component.root.findAllByType(AtomForm)
    expect(atomForms.length).toEqual(3)
  })

  it('multiple locales', () => {
    const state = { atoms: atomsReducer(initialState, setAtomsData(MULTI_LOCALE_ATOMS)) }
    const props = {
      dispatch: () => {},
      atoms: atomsSelector(state),
      atomTypes: atomTypesSelector(state)
    }

    const component = renderer.create(<Atoms {...props} />)
    const atomForms = component.root.findAllByType(AtomForm)
    expect(atomForms.length).toEqual(2 * 3)
  })
})
