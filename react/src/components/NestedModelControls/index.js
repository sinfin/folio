import React from 'react'

import { makeConfirmed } from 'utils/confirmed'
import FolioConsoleUiButtons from 'components/FolioConsoleUiButtons'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

const NestedModelControls = ({ moveUp, moveDown, remove, edit, vertical, handleClassName }) => {
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

  let className = 'f-c-nested-model-controls'

  if (vertical) className += ` ${className}--vertical`

  return (
    <FolioConsoleUiButtons className={className}>
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

      {handleClassName && (
        <FolioConsoleUiButton
          className={handleClassName}
          icon='arrow_up_down'
          variant='tertiary'
          tag='span'
        />
      )}
    </FolioConsoleUiButtons>
  )
}

export default NestedModelControls
