import React from 'react'
import { SortableElement } from 'react-sortable-hoc'
import { File } from 'components/File'

const FilePlacement = ({ file, attachmentable, placementType, position, selected }) => {
  const inputPrefix = `${attachmentable || 'node'}[${placementType || 'file_placements'}_attributes][]`

  return (
    <div>
      {file.file_name}

      {file.id && <input type='hidden' name={`${inputPrefix}[id]`} value={file.id} />}
      <input type='hidden' name={`${inputPrefix}[file_id]`} value={file.file_id} />
      <input type='hidden' name={`${inputPrefix}[position]`} value={position} />
      <input type='hidden' name={`${inputPrefix}[_destroy]`} value={selected ? 0 : 1} />
    </div>
  )
}

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
