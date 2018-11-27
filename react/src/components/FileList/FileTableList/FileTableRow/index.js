import React from 'react'
import LazyLoad from 'react-lazyload'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'components/Tags'

import FileUploadProgress from 'components/FileUploadProgress';

const FileTableRow = ({ file, link, fileTypeIsImage, overflowingParent, onClick }) => {
  let className = 'folio-console-file-table__tr'

  if (file.freshlyUploaded) {
    className = 'folio-console-file-table__tr folio-console-file-table__tr--fresh'
  }

  return (
    <div
      className={className}
      onClick={onClick ? () => onClick(file) : undefined}
    >
      {fileTypeIsImage && (
        <div className='folio-console-file-table__td folio-console-file-table__td--image'>
          <FileUploadProgress progress={file.progress} />

          <div className='folio-console-file-table__img-wrap'>
            {file.thumb && (
              <a
                href={file.source_image}
                target='_blank'
                className='folio-console-file-table__img-a'
                rel='noopener noreferrer'
                onClick={(e) => e.stopPropagation()}
              >
                <LazyLoad height={50} once overflow={overflowingParent}>
                  <img src={file.thumb} className='folio-console-file-table__img' alt='' />
                </LazyLoad>
              </a>
            )}
          </div>
        </div>
      )}

      <div className='folio-console-file-table__td folio-console-file-table__td--main'>
        {fileTypeIsImage ? null : <FileUploadProgress progress={file.progress} />}

        {link ? (
          <a
            href={file.edit_path}
            onClick={(e) => e.stopPropagation()}
          >
            {file.file_name}
          </a>
        ) : file.file_name}
      </div>
      <div className='folio-console-file-table__td folio-console-file-table__td--tags'>
        <Tags file={file} />
      </div>
      <div className='folio-console-file-table__td folio-console-file-table__td--size'>{numberToHumanSize(file.file_size)}</div>
      <div className='folio-console-file-table__td folio-console-file-table__td--extension'>{file.extension}</div>
    </div>
  )
}

export default FileTableRow
