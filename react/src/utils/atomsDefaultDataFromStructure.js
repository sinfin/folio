export default function atomsDefaultDataFromStructure (structure) {
  const data = {}

  Object.keys(structure).forEach((structureKey) => {
    const dv = structure[structureKey] && structure[structureKey].default_values

    if (typeof dv === 'string') {
      data[structureKey] = dv
    }
  })

  return data
}
