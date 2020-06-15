import React from 'react'

import { makeConfirmed } from 'utils/confirmed'

const NestedModelControls = ({ moveUp, moveDown, remove, edit, vertical }) => {
  let btnGroupClassName = 'btn-group mr-1'

  if (vertical) {
    btnGroupClassName = 'btn-group btn-group-vertical align-items-center'
  }

  const destroyButton = remove && (
    <button
      className='btn btn-danger fa fa-times'
      type='button'
      onClick={makeConfirmed(remove)}
    />
  )

  const editButton = edit && (
    <button
      className={`btn btn-secondary f-c-nested-model-controls__edit fa fa-edit ${vertical ? '' : 'mr-1'}`}
      type='button'
      onClick={edit}
    />
  )

  return (
    <div className='f-c-nested-model-controls'>
      <div className={btnGroupClassName}>
        {moveUp && (
          <button
            className='btn btn-outline-secondary fa fa-arrow-up'
            type='button'
            onClick={moveUp}
          />
        )}

        {moveDown && (
          <button
            className='btn btn-outline-secondary fa fa-arrow-down'
            type='button'
            onClick={moveDown}
          />
        )}

        {vertical && editButton}
        {vertical && destroyButton}
      </div>

      {!vertical && editButton}
      {!vertical && destroyButton}
    </div>
  )
}

export default NestedModelControls
