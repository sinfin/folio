import React from 'react'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

const FileHoverButtons = ({ destroy, edit, onDestroy, onEdit }) => {
  return (
    <React.Fragment>
      {destroy && (
        <FolioConsoleUiButton
          type='button'
          class='f-c-file-list__file-btn f-c-file-list__file-btn--destroy'
          variant='danger'
          icon='close'
          onClick={(e) => { e.stopPropagation(); onDestroy() }}
        />
      )}

      {edit && (
        <FolioConsoleUiButton
          type='button'
          class='f-c-file-list__file-btn f-c-file-list__file-btn--edit'
          variant='secondary'
          icon='edit'
          onClick={(e) => { e.stopPropagation(); onEdit() }}
        />
      )}
    </React.Fragment>
  )
}

export default FileHoverButtons
