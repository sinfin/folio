import React from 'react'
import renderer from 'react-test-renderer'

import 'folioTestSetup'

import Field from '../Field'

const buildAtom = (selectionMode) => ({
  errors: {},
  record: {
    data: {
      selection_mode: selectionMode,
      newsletter_codes: '[]'
    },
    meta: {
      structure: {
        newsletter_codes: {
          type: 'string',
          label: 'Newsletters',
          visible_if: { selection_mode: 'manual' }
        }
      }
    }
  }
})

describe('AtomForm Field', () => {
  it('honors visible_if configuration', () => {
    const component = renderer.create(
      <Field
        atom={buildAtom('random')}
        field='newsletter_codes'
        index={0}
        onChange={() => {}}
        onValueChange={() => {}}
        startSplittingAtom={() => {}}
      />
    )

    expect(component.root.findByType('div').props.hidden).toEqual(true)

    component.update(
      <Field
        atom={buildAtom('manual')}
        field='newsletter_codes'
        index={0}
        onChange={() => {}}
        onValueChange={() => {}}
        startSplittingAtom={() => {}}
      />
    )

    expect(component.root.findByType('div').props.hidden).toEqual(false)
  })
})
