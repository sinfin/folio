export default function repositionAtoms (atoms) {
  return atoms.map((atom, i) => ({
    ...atom,
    position: i
  }))
}
