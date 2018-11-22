import React from 'react'
import { SortableContainer } from 'react-sortable-hoc'

import FilePlacementSortableItem from '../FilePlacementSortableItem';

const FilePlacementSortableList = SortableContainer(({
  filePlacements,
  unselectFilePlacement,
}) => (
  <div>
    {filePlacements.selected.map((filePlacement, index) => (
      <FilePlacementSortableItem
        key={[filePlacement.file_id, filePlacement.id].join('-')}
        attachmentable={filePlacements.attachmentable}
        placementType={filePlacements.placementType}
        index={index}
        filePlacement={filePlacement}
        unselectFilePlacement={unselectFilePlacement}
        position={index}
      />
    ))}
  </div>
))

export default FilePlacementSortableList
