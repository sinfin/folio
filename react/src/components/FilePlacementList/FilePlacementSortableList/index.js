import React from 'react'
import { SortableContainer } from 'react-sortable-hoc'

import FilePlacementSortableItem from '../FilePlacementSortableItem';

const FilePlacementSortableList = SortableContainer(({
  attachmentable,
  placementType,
  items,
  onClick,
}) => (
  <div>
    {items.map((file, index) => (
      <FilePlacementSortableItem
        key={file.file_id}
        attachmentable={attachmentable}
        placementType={placementType}
        index={index}
        file={file}
        onClick={onClick}
        position={index}
      />
    ))}
  </div>
))

export default FilePlacementSortableList
