import React from 'react'

import { makeConfirmed } from 'utils/confirmed'
import FolioConsoleUiButtons from 'components/FolioConsoleUiButtons'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

const NestedModelControls = ({ moveUp, moveDown, remove, edit, vertical }) => {
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
    <FolioConsoleUiButtons className='f-c-nested-model-controls'>
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

      {editButton}
      {destroyButton}
    </FolioConsoleUiButtons>
  )
}

export default NestedModelControls
