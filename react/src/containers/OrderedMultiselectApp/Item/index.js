import React from 'react'
import { makeConfirmed } from 'utils/confirmed'

function Item ({ path, node, remove }) {
  return (
    <div className='f-c-r-ordered-multiselect-app__item'>
      {node.label}

      <span
        className='text-danger fa fa-trash-alt f-c-r-ordered-multiselect-app__item-destroy'
        onClick={makeConfirmed(() => remove(node))}
      />
    </div>
  )
}

export default Item
