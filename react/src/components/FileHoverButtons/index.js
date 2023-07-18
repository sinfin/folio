import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

const FileHoverButtons = ({ destroy, edit, onDestroy, onEdit }) => {
  return (
    <React.Fragment>
      {destroy && (
        <button
          type='button'
          className='f-c-file-list__file-btn f-c-file-list__file-btn--destroy'
          onClick={(e) => { e.stopPropagation(); onDestroy() }}
        >
          <FolioUiIcon name='close' />
        </button>
      )}

      {edit && (
        <button
          type='button'
          className='f-c-file-list__file-btn f-c-file-list__file-btn--edit'
          onClick={(e) => { e.stopPropagation(); onEdit() }}
        >
          <FolioUiIcon name='edit_box' />
        </button>
      )}
    </React.Fragment>
  )
}

export default FileHoverButtons
