import React from 'react'

import FileUploadProgress from 'components/FileUploadProgress'
import FileThumbnailHover from './FileThumbnailHover'
import FileThumbnailMassCheckbox from './FileThumbnailMassCheckbox'
import FileHoverButtons from 'components/FileHoverButtons'
import Picture from 'components/Picture'

const FileThumbnail = ({ file, fileType, onClick, openFileModalOnClick, selecting, massSelect, massSelectVisible, openFileModal }) => {
  if (file._destroying) return null

  let className = 'f-c-file-list__file'
  const persistedOnClick = !file.attributes.uploading && onClick
  const persistedWrapOnClick = !file.attributes.uploading && openFileModalOnClick
    ? () => openFileModal(file)
    : undefined

  if (file.attributes.freshlyUploaded) {
    className = 'f-c-file-list__file f-c-file-list__file--fresh'
  } else if (file.attributes.uploading) {
    className = 'f-c-file-list__file f-c-file-list__file--uploading'
  }

  return (
    <div
      className={className}
    >
      <div className='f-c-file-list__img-wrap' style={{ background: file.attributes.dominant_color }} onClick={persistedWrapOnClick}>
        {(file.attributes.thumb || file.attributes.dataThumbnail) && (
          <Picture
            file={file}
            className='f-c-file-list__picture'
            imageClassName='f-c-file-list__img'
            alt={file.attributes.file_name}
            lazyload
          />
        )}
      </div>

      <FileUploadProgress progress={file.attributes.progress} />

      {massSelect ? (
        <React.Fragment>
          <FileThumbnailMassCheckbox
            select={massSelect}
            visible={massSelectVisible}
            file={file}
          />

          {file.attributes.file_placements_size ? (
            <div className='f-c-file-list__file-placements-count'>
              {file.attributes.file_placements_size}
            </div>
          ) : null}
        </React.Fragment>
      ) : (
        <React.Fragment>
          <FileThumbnailHover
            progress={file.attributes.progress}
            onClick={persistedOnClick}
            file={file}
            selecting={selecting}
          />
        </React.Fragment>
      )}

      {!file.attributes.uploading && <FileHoverButtons edit onEdit={() => { openFileModal(file) }} />}
    </div>
  )
}

export default FileThumbnail
