import React from 'react'

import { makeConfirmed } from 'utils/confirmed'

const NestedModelControls = ({ moveUp, moveDown, remove }) => (
  <div className='folio-console-nested-model-controls'>
    {(moveUp && moveDown) && (
      <div className='btn-group mr-3'>
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
