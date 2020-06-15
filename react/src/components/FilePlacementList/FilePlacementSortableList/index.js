import React from 'react'
import { SortableContainer } from 'react-sortable-hoc'

import FilePlacementSortableItem from '../FilePlacementSortableItem'

const FilePlacementSortableList = SortableContainer(({
  filePlacements,
  unselectFilePlacement,
  fileTypeIsImage,
  onTitleChange,
  onAltChange,
  openFileModal,
  move,
  filesKey,
  nested
}) => (
  <div className='f-c-file-placement-list'>
    {filePlacements.selected.map((filePlacement, index) => (
      <FilePlacementSortableItem
        key={[filePlacement.file_id, filePlacement.id].join('-')}
        attachmentable={filePlacements.attachmentable}
        placementType={filePlacements.placementType}
        index={index}
        filePlacement={filePlacement}
        unselectFilePlacement={unselectFilePlacement}
        onTitleChange={onTitleChange}
        onAltChange={onAltChange}
        openFileModal={openFileModal}
        position={index}
        fileTypeIsImage={fileTypeIsImage}
        move={move}
        isFirst={index === 0}
        isLast={index === filePlacement.length - 1}
        filesKey={filesKey}
        nested={nested}
      />
    ))}
  </div>
))

export default FilePlacementSortableList
