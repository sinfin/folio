import React from 'react'
import ReactDOM from 'react-dom'
import renderer from 'react-test-renderer'

import 'folioTestSetup'
import '../../../../../app/cells/folio/ui/icon/icon'

import { Atoms } from '../'
import { SerializedAtom } from 'components/SerializedAtoms'

import atomsReducer, {
  atomsSelector,
  atomTypesSelector,
  initialState,
  setAtomsData,
  newAtoms,
  setFormValidationErrors
} from 'ducks/atoms'

import { SINGLE_LOCALE_ATOMS, MULTI_LOCALE_ATOMS } from 'constants/tests/atoms'

describe('Atoms', () => {
  let originalJQuery
  let containers

  beforeEach(() => {
    originalJQuery = window.jQuery
    containers = []
    window.jQuery = () => ({ on: () => {}, off: () => {} })
    window.FolioConsole.translations = { done: 'Done', errorNotification: 'Invalid atom' }
    window.Folio.Ui.Icon.svgSpritePath = '/icons.svg'
    window.Folio.Ui.Icon.defaultSizes = {
      close: { width: 24, height: 24 },
      plus: { width: 24, height: 24 }
    }
  })

  afterEach(() => {
    containers.forEach((container) => ReactDOM.unmountComponentAtNode(container))
    window.jQuery = originalJQuery
  })

  function newImageAtomState (usageRecord) {
    const data = {
      atoms: { atoms: [] },
      destroyedIds: { atoms: [] },
      namespace: 'page',
      usageRecord,
      structures: {
        'Dummy::Atom::Image': {
          title: 'Image',
          structure: {},
          associations: {},
          attachments: [{ key: 'cover_placement_attributes', file_type: 'Folio::File::Image', human_type: 'image', label: 'Image', plural: false }],
          form_layout: 'ATTACHMENTS'
        }
      }
    }
    const state = atomsReducer(initialState, setAtomsData(data))
    return atomsReducer(state, newAtoms('atoms', 'append', [], 'Dummy::Atom::Image'))
  }

  function renderAtoms (state, container = document.createElement('div')) {
    if (!containers.includes(container)) containers.push(container)
    ReactDOM.render(<Atoms dispatch={() => {}} atoms={state} atomTypes={atomTypesSelector({ atoms: state })} />, container)
    return container
  }

  it('passes the edited record context to a new image atom picker', () => {
    const container = renderAtoms(newImageAtomState('signed-published-record'))
    const picker = container.querySelector('.f-c-files-picker')

    expect(picker.getAttribute('data-f-c-files-picker-usage-record-value')).toEqual('signed-published-record')
  })

  it('keeps the edited record context when atom validation fails', () => {
    let state = newImageAtomState('signed-published-record')
    const container = renderAtoms(state)
    state = atomsReducer(state, setFormValidationErrors([{ valid: false, errors: { cover: ['blank'] }, messages: ['Missing image'] }]))
    renderAtoms(state, container)
    const picker = container.querySelector('.f-c-files-picker')

    expect(picker.getAttribute('data-f-c-files-picker-usage-record-value')).toEqual('signed-published-record')
  })

  it('does not borrow a record context from another atom editor', () => {
    renderAtoms(newImageAtomState('signed-published-record'))
    const container = renderAtoms(newImageAtomState())
    const picker = container.querySelector('.f-c-files-picker')

    expect(picker.hasAttribute('data-f-c-files-picker-usage-record-value')).toEqual(false)
  })

  it('single locale', () => {
    const state = { atoms: atomsReducer(initialState, setAtomsData(SINGLE_LOCALE_ATOMS)) }
    const props = {
      dispatch: () => {},
      atoms: atomsSelector(state),
      atomTypes: atomTypesSelector(state)
    }

    const component = renderer.create(<Atoms {...props} />)
    const atomForms = component.root.findAllByType(SerializedAtom)
    expect(atomForms.length).toEqual(6)
  })

  it('multiple locales', () => {
    const state = { atoms: atomsReducer(initialState, setAtomsData(MULTI_LOCALE_ATOMS)) }
    const props = {
      dispatch: () => {},
      atoms: atomsSelector(state),
      atomTypes: atomTypesSelector(state)
    }

    const component = renderer.create(<Atoms {...props} />)
    const atomForms = component.root.findAllByType(SerializedAtom)
    expect(atomForms.length).toEqual(2 * 6)
  })
})
