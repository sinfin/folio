import React from 'react'
import { SortableContainer } from 'react-sortable-hoc'

import SortableItem from '../SortableItem';

const SortableList = SortableContainer(({ attachmentable,
                                          placementType,
                                          items,
                                          onClick }) => {
  return (
    <div>
      {items.map((file, index) => (
        <SortableItem
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
  )
})

export default SortableList
