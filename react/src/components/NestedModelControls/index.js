import React from 'react'

import { makeConfirmed } from 'utils/confirmed'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

const NestedModelControls = ({ moveUp, moveDown, remove, edit, vertical }) => {
  let btnGroupClassName = 'btn-group mr-1'

  if (vertical) {
    btnGroupClassName = 'btn-group btn-group-vertical align-items-center'
  }

  const destroyButton = remove && (
    <FolioConsoleUiButton
      variant='danger'
      icon='close'
      onClick={makeConfirmed(remove)}
    />
  )

  const editButton = edit && (
    <FolioConsoleUiButton
      variant='secondary'
      class='f-c-nested-model-controls__edit'
      icon='edit'
      onClick={edit}
    />
  )

  return (
    <div className='f-c-nested-model-controls'>
      <div className={btnGroupClassName}>
        {moveUp && (
          <FolioConsoleUiButton
            variant='secondary'
            icon='arrow_up'
            onClick={moveUp}
          />
        )}

        {moveDown && (
          <FolioConsoleUiButton
            variant='secondary'
            icon='arrow_down'
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
