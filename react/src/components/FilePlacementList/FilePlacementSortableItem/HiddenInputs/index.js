import React, { Fragment } from 'react'

import filePlacementInputName from '../../utils/filePlacementInputName'

const HiddenInputs = ({ filePlacement, attachmentable, placementType, position }) => (
  <Fragment>
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
  </Fragment>
)

export default HiddenInputs
