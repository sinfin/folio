import React from 'react'

import { makeConfirmed } from 'utils/confirmed';

const NestedModelControls = ({ moveUp, moveDown, remove }) => (
  <div className='folio-console-nested-model-controls'>
    {(moveUp && moveDown) && (
      <div className='btn-group mr-3'>
        <button
          className='btn btn-outline-secondary'
          type='button'
          onClick={moveUp}
        >
          <i className='fa fa-arrow-up'></i>
        </button>

        <button
          className='btn btn-outline-secondary'
          type='button'
          onClick={moveDown}
        >
          <i className='fa fa-arrow-down'></i>
        </button>
      </div>
    )}

    <button
     className='btn btn-danger fa fa-times'
     type='button'
     onClick={makeConfirmed(remove)}
    />
  </div>
)

export default NestedModelControls
