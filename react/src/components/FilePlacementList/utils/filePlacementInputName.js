export default (name, attachmentable, placementType) => (
  `${attachmentable || 'node'}[${placementType || 'file_placements'}_attributes][][${name}]`
)
