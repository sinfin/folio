import React from 'react'
import { SortableElement } from 'react-sortable-hoc'
import { File } from 'components/File'

const SortableItem = SortableElement(({ file,
                                        position,
                                        onClick,
                                        attachmentable,
                                        placementType }) => {
  return (
    <File
      file={file}
      key={file.file_id}
      onClick={() => onClick(file)}
      position={position}
      attachmentable={attachmentable}
      placementType={placementType}
      selected
    />
  )
})

export default SortableItem
