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
          if (i === indices[0]) {
            atoms = [...atoms, ...newAtoms]
          } else {
            atoms.push(atom)
          }
        })
      } else {
        if (oldAtoms.length === indices[0]) {
          atoms = [...oldAtoms, ...newAtoms]
        } else {
          oldAtoms.forEach((atom, i) => {
            if (i === indices[0]) {
              atoms = [...atoms, ...newAtoms, atom]
            } else {
              atoms.push(atom)
            }
          })
        }
      }
    }
  }

  return atoms
}
