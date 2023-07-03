const prependAtoms = (newAtoms, oldAtoms) => [...newAtoms, ...oldAtoms]

const appendAtoms = (newAtoms, oldAtoms) => [...oldAtoms, ...newAtoms]

export default function combineAtoms ({ oldAtoms, newAtoms, formAction, indices, edit }) {
  let atoms = []

  switch (formAction) {
    case 'prepend':
      atoms = prependAtoms(newAtoms, oldAtoms)
      break
    case 'append':
      atoms = appendAtoms(newAtoms, oldAtoms)
      atoms = [...oldAtoms, ...newAtoms]
      break
    default: {
      if (edit) {
        oldAtoms.forEach((atom, i) => {
          if (i === indices[0]) {
            atoms = [...atoms, ...newAtoms]
          } else if (indices.indexOf(i) === -1) {
            atoms.push(atom)
          }
        })
      } else {
        if (oldAtoms.length === indices[0]) {
          atoms = appendAtoms(newAtoms, oldAtoms)
        } else if (indices[0] === 0) {
          atoms = prependAtoms(newAtoms, oldAtoms)
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
