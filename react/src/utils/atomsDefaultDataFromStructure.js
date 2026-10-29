export default function atomsDefaultDataFromStructure (structure, existingAtoms = [], values) {
  const data = { ...values }

  for (const structureKey of Object.keys(structure)) {
    const field = structure[structureKey]
    const firstAvailableValues = field && field.first_available_values
    const dv = field && field.default_values

    if (Array.isArray(firstAvailableValues)) {
      const usedValues = existingAtoms.map((atom) => {
        const record = atom.record || atom
        return record.data && record.data[structureKey]
      })
      const currentValue = data[structureKey]
      const value = firstAvailableValues.includes(currentValue) && !usedValues.includes(currentValue)
        ? currentValue
        : firstAvailableValues.find((candidate) => !usedValues.includes(candidate))

      if (value === undefined) return null

      data[structureKey] = value
    } else if (values === undefined && typeof dv === 'string') {
      data[structureKey] = dv
    }
  }

  return data
}
