import 'folioTestSetup'

import combineAtoms from 'utils/combineAtoms'

describe('atomsReducer', () => {
  it('works for splice to 0', () => {
    const hash = {
      oldAtoms: ['a', 'b'],
      newAtoms: ['c'],
      formAction: 'splice',
      indices: [0, 1],
      edit: false
    }

    expect(combineAtoms(hash)).toEqual(['c', 'a', 'b'])
  })

  it('works for splice to 1', () => {
    const hash = {
      oldAtoms: ['a', 'b'],
      newAtoms: ['c'],
      formAction: 'splice',
      indices: [1, 2],
      edit: false
    }

    expect(combineAtoms(hash)).toEqual(['a', 'c', 'b'])
  })

  it('works for splice to 2', () => {
    const hash = {
      oldAtoms: ['a', 'b'],
      newAtoms: ['c'],
      formAction: 'splice',
      indices: [2, 3],
      edit: false
    }

    expect(combineAtoms(hash)).toEqual(['a', 'b', 'c'])
  })

  it('works for prepend', () => {
    const hash = {
      oldAtoms: ['a', 'b'],
      newAtoms: ['c'],
      formAction: 'prepend'
    }

    expect(combineAtoms(hash)).toEqual(['c', 'a', 'b'])
  })

  it('works for append', () => {
    const hash = {
      oldAtoms: ['a', 'b'],
      newAtoms: ['c'],
      formAction: 'append'
    }

    expect(combineAtoms(hash)).toEqual(['a', 'b', 'c'])
  })
})
