import React from 'react'
import renderer from 'react-test-renderer'

import 'folioTestSetup'

import AtomInput from '../AtomInput'

describe('AtomInput', () => {
  it.each([
    [['slot-1'], 'slot-2'],
    [['slot-1', 'slot-2', 'slot-3'], undefined]
  ])('initializes only an available option when used values are %j', (usedValues, expectedValue) => {
    const onValueChange = jest.fn()
    const atom = {
      errors: {},
      record: {
        lodashId: 'new',
        data: {},
        meta: {
          structure: {
            slot_key: {
              type: 'collection',
              collection: ['slot-1', 'slot-2', 'slot-3'].map((value) => [value, value]),
              unique_values_within_root: true
            }
          }
        }
      }
    }

    renderer.act(() => {
      renderer.create(
        <AtomInput
          atom={atom}
          field='slot_key'
          index={0}
          onChange={() => {}}
          onValueChange={onValueChange}
          rootAtoms={usedValues.map((value) => ({ lodashId: value, data: { slot_key: value } }))}
        />
      )
    })

    if (expectedValue) {
      expect(onValueChange).toHaveBeenCalledWith(0, expectedValue, 'slot_key')
    } else {
      expect(onValueChange).not.toHaveBeenCalled()
    }
  })

  it('keeps the current unique value and hides values used by other root atoms', () => {
    const structure = {
      slot_key: {
        type: 'collection',
        collection: [
          ['Slot 1', 'slot-1'],
          ['Slot 2', 'slot-2'],
          ['Slot 3', 'slot-3']
        ],
        unique_values_within_root: true
      }
    }
    const atom = {
      errors: {},
      record: {
        lodashId: 'current',
        data: { slot_key: 'slot-2' },
        meta: { structure }
      }
    }
    const rootAtoms = [
      { lodashId: 'other', data: { slot_key: 'slot-1' } },
      { lodashId: 'current', data: { slot_key: 'slot-2' } }
    ]

    const component = renderer.create(
      <AtomInput
        atom={atom}
        field='slot_key'
        index={0}
        onChange={() => {}}
        onValueChange={() => {}}
        rootAtoms={rootAtoms}
      />
    )

    expect(component.root.findAllByType('option').map(({ props }) => props.value)).toEqual([
      'slot-2',
      'slot-3'
    ])
  })
})
