import React from 'react'

const FileThumbnailMassCheckbox = ({ select, visible, file }) => {
  let className = 'f-c-file-list__file-checkbox'
  if (visible) {
    className = `${className} f-c-file-list__file-checkbox--visible`
  }

  return (
    <div
      className={className}
      onClick={(e) => { e.preventDefault(); e.stopPropagation(); select(file, !file.massSelected) }}
    >
      <input
        type='checkbox'
        className='f-c-file-list__file-checkbox-input'
        checked={file.massSelected || false}
        readOnly
      />
    </div>
  )
}

export default FileThumbnailMassCheckbox
