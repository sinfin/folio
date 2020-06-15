import React from 'react'

const FileHoverButtons = ({ destroy, edit, onDestroy, onEdit }) => {
  return (
    <React.Fragment>
      {destroy && (
        <button
          type='button'
          className='f-c-file-list__file-btn f-c-file-list__file-btn--destroy btn btn-danger fa fa-times'
          onClick={(e) => { e.stopPropagation(); onDestroy() }}
        />
      )}

      {edit && (
        <button
          type='button'
          className='f-c-file-list__file-btn f-c-file-list__file-btn--edit btn btn-secondary fa fa-edit'
          onClick={(e) => { e.stopPropagation(); onEdit() }}
        />
      )}
    </React.Fragment>
  )
}

export default FileHoverButtons
