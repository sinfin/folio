import React from 'react'
import { SortableElement } from 'react-sortable-hoc'

import filePlacementInputName from '../utils/filePlacementInputName';

const FilePlacement = ({ filePlacement, attachmentable, placementType, position, unselectFilePlacement }) => (
  <div onClick={() => unselectFilePlacement(filePlacement)}>
    {filePlacement.file.file_name}

    <input
      type='hidden'
      name={filePlacementInputName('id', filePlacement, attachmentable, placementType)}
      value={filePlacement.id || ''}
    />

    <input
      type='hidden'
      name={filePlacementInputName('file_id', filePlacement, attachmentable, placementType)}
      value={filePlacement.file_id}
    />

    <input
      type='hidden'
      name={filePlacementInputName('position', filePlacement, attachmentable, placementType)}
      value={position}
    />
  </div>
)

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
