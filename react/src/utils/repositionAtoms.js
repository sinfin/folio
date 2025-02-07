export default function repositionAtoms (atoms) {
  return atoms.map((atom, i) => {
    return {
      ...atom,
      position: i
    }
  })
}
