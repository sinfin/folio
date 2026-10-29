import atomsDefaultDataFromStructure from '../atomsDefaultDataFromStructure'

describe('atomsDefaultDataFromStructure', () => {
  const structure = {
    title: { default_values: 'Default title' },
    slot: { first_available_values: ['slot-1', 'slot-2', 'slot-3'] }
  }

  it('uses the first value not present in existing atoms', () => {
    const existingAtoms = [
      { data: { slot: 'slot-1' } },
      { record: { data: { slot: 'slot-2' } } }
    ]

    expect(atomsDefaultDataFromStructure(structure, existingAtoms)).toEqual({
      title: 'Default title',
      slot: 'slot-3'
    })
  })

  it('returns null if every limited value is already used', () => {
    const existingAtoms = ['slot-1', 'slot-2', 'slot-3'].map((slot) => ({ data: { slot } }))

    expect(atomsDefaultDataFromStructure(structure, existingAtoms)).toEqual(null)
  })
})
