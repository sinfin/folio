import React from 'react'
import { SortableElement } from 'react-sortable-hoc'

import filePlacementInputName from '../utils/filePlacementInputName';

const FilePlacement = ({ filePlacement, attachmentable, placementType, position, selected }) => (
  <div>
    {filePlacement.file.file_name}

    {filePlacement.id && (
      <input
        type='hidden'
        name={filePlacementInputName('id', attachmentable, placementType)}
        value={filePlacement.id}
      />
    )}
    <input
      type='hidden'
      name={filePlacementInputName('file_id', attachmentable, placementType)}
      value={filePlacement.file_id}
    />
    <input
      type='hidden'
      name={filePlacementInputName('position', attachmentable, placementType)}
      value={position}
    />
  </div>
)

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
