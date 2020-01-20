import React from 'react'
import LazyLoad from 'react-lazyload'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'containers/Tags'

import FileUploadProgress from 'components/FileUploadProgress'

const FileTableRow = ({
  file,
  filesKey,
  link,
  fileTypeIsImage,
  onClick,
  massSelect
}) => {
  let className = 'f-c-file-table__tr'
  const persistedOnClick = !file.attributes.uploading && onClick

  if (file.attributes.freshlyUploaded) {
    className = 'f-c-file-table__tr f-c-file-table__tr--fresh'
  } else if (file.attributes.uploading) {
    className = 'f-c-file-table__tr f-c-file-table__tr--uploading'
  }

  return (
    <div
      className={className}
      onClick={persistedOnClick ? () => onClick(file) : undefined}
    >
      {massSelect && (
        <div className='f-c-file-table__td f-c-file-table__td--mass-select pl-0'>
          <input
            type='checkbox'
            checked={file.massSelected || false}
            onChange={(e) => massSelect(file, !file.massSelected)}
            className='f-c-file-table__mass-select-checkbox'
          />
        </div>
      )}

      {fileTypeIsImage && (
        <div className='f-c-file-table__td f-c-file-table__td--image py-0'>
          <FileUploadProgress progress={file.attributes.progress} />

          <div className='f-c-file-table__img-wrap'>
            {file.attributes.thumb && (
              <a
                href={file.attributes.source_image}
                target='_blank'
                className='f-c-file-table__img-a'
                rel='noopener noreferrer'
                onClick={(e) => e.stopPropagation()}
              >
                <LazyLoad height={50} once overflow>
                  <img src={file.attributes.thumb} className='f-c-file-table__img' alt='' />
                </LazyLoad>
              </a>
            )}
          </div>
        </div>
      )}

      <div className='f-c-file-table__td f-c-file-table__td--main'>
        {fileTypeIsImage ? null : <FileUploadProgress progress={file.attributes.progress} />}

        {(link && file.links) ? (
          <a
            href={file.links.edit}
            onClick={(e) => e.stopPropagation()}
          >
            {file.attributes.file_name}
          </a>
        ) : file.attributes.file_name}
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--size'>
        {file.attributes.extension}, {numberToHumanSize(file.attributes.file_size)}
      </div>

      {massSelect && (
        <div className='f-c-file-table__td f-c-file-table__td--extension'>
          {file.attributes.file_placements_count ? (
            <div className='f-c-file-table__file-placements-count'>
              {file.attributes.file_placements_count}
            </div>
          ) : null}
        </div>
      )}

      <div className='f-c-file-table__td text-lg-right'>
        <Tags file={file} filesKey={filesKey} />
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--actions pr-0'>
        {(link && file.links) ? (
          <a // eslint-disable-line
            href={file.links.edit}
            target='_blank'
            className='btn btn-secondary fa fa-edit'
            rel='noopener noreferrer'
          />
        ) : undefined}
      </div>
    </div>
  )
}

export default FileTableRow
