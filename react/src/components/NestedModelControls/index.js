import React from 'react'

import { makeConfirmed } from 'utils/confirmed'

const NestedModelControls = ({ moveUp, moveDown, remove, vertical }) => {
  let btnGroupClassName = 'btn-group mr-3'

  if (vertical) {
    btnGroupClassName = 'btn-group btn-group-vertical align-items-center'
  }

  const destroyButton = (
    <button
      className='btn btn-danger fa fa-times'
      type='button'
      onClick={makeConfirmed(remove)}
    />
  )

  return (
    <div className='folio-console-nested-model-controls'>
      {(moveUp && moveDown) && (
        <div className={btnGroupClassName}>
          <button
            className='btn btn-outline-secondary fa fa-arrow-up'
            type='button'
            onClick={moveUp}
          />

          <button
            className='btn btn-outline-secondary fa fa-arrow-down'
            type='button'
            onClick={moveDown}
          />

          {vertical && destroyButton}
        </div>
      )}

      {!vertical && destroyButton}
    </div>
  )
}

export default NestedModelControls
