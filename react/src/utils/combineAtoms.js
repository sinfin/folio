export default function combineAtoms ({ oldAtoms, newAtoms, formAction, indices, edit }) {
  let atoms = []

  switch (formAction) {
    case 'prepend':
      atoms = [...newAtoms, ...oldAtoms]
      break
    case 'append':
      atoms = [...oldAtoms, ...newAtoms]
      break
    default: {
      if (edit) {
        oldAtoms.forEach((atom, i) => {
          if (indices.indexOf(i) === -1) {
            atoms.push(atom)
          } else if (i === indices[0]) {
            atoms = [...atoms, ...newAtoms]
          }
        })
      } else {
        oldAtoms.forEach((atom, i) => {
          if (indices.indexOf(i) === -1) {
            atoms.push(atom)
          } else if (i === indices[0]) {
            atoms = [...atoms, ...newAtoms, atom]
          }
        })
      }
    }
  }

  return atoms
}
