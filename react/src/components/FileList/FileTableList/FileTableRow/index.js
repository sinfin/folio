import React from 'react'
import LazyLoad from 'react-lazyload'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'components/Tags'

import FileUploadProgress from 'components/FileUploadProgress'

const FileTableRow = ({ file, link, fileTypeIsImage, onClick }) => {
  let className = 'folio-console-file-table__tr'
  const persistedOnClick = !file.attributes.uploading && onClick

  if (file.attributes.freshlyUploaded) {
    className = 'folio-console-file-table__tr folio-console-file-table__tr--fresh'
  } else if (file.attributes.uploading) {
    className = 'folio-console-file-table__tr folio-console-file-table__tr--uploading'
  }

  return (
    <div
      className={className}
      onClick={persistedOnClick ? () => onClick(file) : undefined}
    >
      {fileTypeIsImage && (
        <div className='folio-console-file-table__td folio-console-file-table__td--image'>
          <FileUploadProgress progress={file.attributes.progress} />

          <div className='folio-console-file-table__img-wrap'>
            {file.attributes.thumb && (
              <a
                href={file.attributes.source_image}
                target='_blank'
                className='folio-console-file-table__img-a'
                rel='noopener noreferrer'
                onClick={(e) => e.stopPropagation()}
              >
                <LazyLoad height={50} once overflow>
                  <img src={file.attributes.thumb} className='folio-console-file-table__img' alt='' />
                </LazyLoad>
              </a>
            )}
          </div>
        </div>
      )}

      <div className='folio-console-file-table__td folio-console-file-table__td--main'>
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
      <div className='folio-console-file-table__td folio-console-file-table__td--tags'>
        <Tags file={file} />
      </div>
      <div className='folio-console-file-table__td folio-console-file-table__td--size'>{numberToHumanSize(file.attributes.file_size)}</div>
      <div className='folio-console-file-table__td folio-console-file-table__td--extension'>{file.attributes.extension}</div>
    </div>
  )
}

export default FileTableRow
