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

  it('works for molecule splice middle', () => {
    const hash = {
      oldAtoms: ['a', 'b', 'c', 'c'],
      newAtoms: ['d', 'd'],
      formAction: 'splice',
      indices: [1],
      edit: false
    }

    expect(combineAtoms(hash)).toEqual(['a', 'd', 'd', 'b', 'c', 'c'])
  })

  it('works for molecule splice to almost the end', () => {
    const hash = {
      oldAtoms: ['a', 'b', 'c', 'c'],
      newAtoms: ['d', 'd'],
      formAction: 'splice',
      indices: [2, 3],
      edit: false
    }

    expect(combineAtoms(hash)).toEqual(['a', 'b', 'd', 'd', 'c', 'c'])
  })

  it('works for edit molecule splice', () => {
    const hash = {
      oldAtoms: ['a', 'b', 'c', 'c'],
      newAtoms: ['c', 'd'],
      formAction: 'splice',
      indices: [2, 3],
      edit: true
    }

    expect(combineAtoms(hash)).toEqual(['a', 'b', 'c', 'd'])
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
