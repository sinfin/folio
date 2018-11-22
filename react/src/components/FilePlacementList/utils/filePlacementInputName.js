export default function filePlacementInputName (name, filePlacement, attachmentable, placementType) {
  const idPart = filePlacement.id || filePlacement.selectedAt
  return `${attachmentable || 'node'}[${placementType || 'file_placements'}_attributes][${idPart}][${name}]`
}
