import React from 'react'
import { SortableContainer } from 'react-sortable-hoc'

import FilePlacementSortableItem from '../FilePlacementSortableItem';

const FilePlacementSortableList = SortableContainer(({
  filePlacements,
  unselectFilePlacement,
  fileTypeIsImage,
  move,
}) => (
  <div className='folio-console-file-placement-list'>
    {filePlacements.selected.map((filePlacement, index) => (
      <FilePlacementSortableItem
        key={[filePlacement.file_id, filePlacement.id].join('-')}
        attachmentable={filePlacements.attachmentable}
        placementType={filePlacements.placementType}
        index={index}
        filePlacement={filePlacement}
        unselectFilePlacement={unselectFilePlacement}
        position={index}
        fileTypeIsImage={fileTypeIsImage}
        move={move}
        isFirst={index === 0}
        isLast={index === filePlacement.length - 1}
      />
    ))}
  </div>
))

export default FilePlacementSortableList
