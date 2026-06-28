import 'folioTestSetup'

import filterOptions from '../filterOptions'

describe('filterOptions', () => {
  it('removes selected options by id or value', () => {
    const options = [
      { id: 1, value: 1, label: 'First' },
      { value: 2, label: 'Second' },
      { id: 3, value: 3, label: 'Third' }
    ]

    expect(filterOptions(options, [
      { value: 1 },
      { value: 2 }
    ])).toEqual([
      { id: 3, value: 3, label: 'Third' }
    ])
  })

  it('preserves groups and drops empty groups', () => {
    const options = [
      {
        label: 'First group',
        options: [
          { id: 1, value: 1, label: 'First' }
        ]
      },
      {
        label: 'Second group',
        options: [
          { id: 2, value: 2, label: 'Second' },
          { id: 3, value: 3, label: 'Third' }
        ]
      }
    ]

    expect(filterOptions(options, [
      { value: 1 },
      { value: 3 }
    ])).toEqual([
      {
        label: 'Second group',
        options: [
          { id: 2, value: 2, label: 'Second' }
        ]
      }
    ])
  })
})
