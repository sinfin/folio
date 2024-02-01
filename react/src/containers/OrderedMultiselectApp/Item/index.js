import React from 'react'
import { makeConfirmed } from 'utils/confirmed'

import FolioUiIcon from 'components/FolioUiIcon'

function Item ({ path, node, remove }) {
  return (
    <div className='f-c-r-ordered-multiselect-app__item'>
      {node.label}

      <FolioUiIcon
        class='text-danger f-c-r-ordered-multiselect-app__item-destroy'
        name='delete'
        height={16}
        onClick={makeConfirmed(() => remove(node))}
      />
    </div>
  )
}

export default Item
