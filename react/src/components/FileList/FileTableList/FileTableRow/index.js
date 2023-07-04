import React from 'react'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'containers/Tags'
import Picture from 'components/Picture'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import FileUploadProgress from 'components/FileUploadProgress'

const FileTableRow = ({
  file,
  fileType,
  filesUrl,
  openFileModal,
  fileTypeIsImage,
  onClick,
  massSelect,
  readOnly
}) => {
  if (file._destroying) return null

  let className = 'f-c-file-table__tr'

  let persistedOnClick

  if (!file.attributes.uploading) {
    if (massSelect) {
      persistedOnClick = (e) => massSelect(file, !file.massSelected)
    } else if (onClick) {
      persistedOnClick = () => onClick(file)
    }
  }

  if (file.attributes.freshlyUploaded) {
    className = 'f-c-file-table__tr f-c-file-table__tr--fresh'
  } else if (file.attributes.uploading) {
    className = 'f-c-file-table__tr f-c-file-table__tr--uploading'
  }

  let download = file.attributes.file_name
  if (download.indexOf('.') === -1) { download = undefined }

  return (
    <div
      className={className}
      onClick={persistedOnClick}
    >
      {massSelect && (
        <div className='f-c-file-table__td f-c-file-table__td--mass-select'>
          {file.attributes.uploading ? null : (
            <input
              type='checkbox'
              checked={file.massSelected || false}
              onChange={persistedOnClick}
              className='f-c-file-table__mass-select-checkbox'
            />
          )}
        </div>
      )}

      {fileTypeIsImage ? (
        <div className='f-c-file-table__td f-c-file-table__td--image py-0'>
          <FileUploadProgress progress={file.attributes.progress} progressText={file.attributes.progressText} />

          <div className='f-c-file-table__img-wrap'>
            {(file.attributes.thumb || file.attributes.dataThumbnail) && (
              <Picture
                file={file}
                imageClassName='f-c-file-table__img'
                lazyload={{ height: 50, once: true, overflow: true }}
              />
            )}
          </div>
        </div>
      ) : (
        <div className='f-c-file-table__td f-c-file-table__td--extension'>
          <FileUploadProgress progress={file.attributes.progress} progressText={file.attributes.progressText} />
          <span className='f-c-file-table__extension'>{file.attributes.extension}</span>
        </div>
      )}

      <div className='f-c-file-table__td f-c-file-table__td--main'>
        {onClick ? file.attributes.file_name : (
          <span onClick={() => openFileModal(file)} className='cursor-pointer'>{file.attributes.file_name}</span>
        )}
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--size'>
        <div className='f-c-file-table__td-min-height'>
          {file.attributes.uploading && file.attributes.progress === 100 ? null : numberToHumanSize(file.attributes.file_size)}
        </div>
      </div>

      {massSelect && (
        <div className='f-c-file-table__td f-c-file-table__td--extension'>
          {file.attributes.file_placements_size ? (
            <div className='f-c-file-table__file-placements-count'>
              {file.attributes.file_placements_size}
            </div>
          ) : null}
        </div>
      )}

      <div className='f-c-file-table__td f-c-file-table__td--tags'>
        <Tags file={file} fileType={fileType} filesUrl={filesUrl} />
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--actions'>
        {file.attributes.uploading ? null : (
          <React.Fragment>
            {openFileModal ? (
              <span
                onClick={(e) => { e.stopPropagation(); openFileModal(file) }}
                className={`btn fa ${readOnly ? 'btn-light fa-eye' : 'btn-secondary fa-edit'}`}
                rel='noopener noreferrer'
              />
            ) : undefined}

            <FolioConsoleUiButton
              href={file.attributes.source_url}
              class='ml-2'
              target='_blank'
              rel='noopener noreferrer'
              download={download}
              icon='download'
            />
          </React.Fragment>
        )}
      </div>
    </div>
  )
}

export default FileTableRow
