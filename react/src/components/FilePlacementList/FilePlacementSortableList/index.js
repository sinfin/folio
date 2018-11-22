import React from 'react'
import { SortableContainer } from 'react-sortable-hoc'

import FilePlacementSortableItem from '../FilePlacementSortableItem';

const FilePlacementSortableList = SortableContainer(({
  filePlacements,
  unselectFilePlacement,
  fileTypeIsImage,
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
      />
    ))}
  </div>
))

export default FilePlacementSortableList
