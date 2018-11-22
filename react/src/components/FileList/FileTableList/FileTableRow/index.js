import React from 'react'
import LazyLoad from 'react-lazyload'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'components/Tags'

import FileUploadProgress from 'components/FileUploadProgress';

const FileTableRow = ({ file, link, fileTypeIsImage }) => {
  return (
    <tr className='folio-console-file-table__tr'>
      {fileTypeIsImage && (
        <td className='folio-console-file-table__td folio-console-file-table__td--image'>
          <FileUploadProgress progress={file.progress} />

          <div className='folio-console-file-table__img-wrap'>
            {file.thumb && (
              <a href={file.source_image} target='_blank' className='folio-console-file-table__img-a'>
                <LazyLoad height={50} once overflow={false}>
                  <img src={file.thumb} className='folio-console-file-table__img' />
                </LazyLoad>
              </a>
            )}
          </div>
        </td>
      )}

      <td className='folio-console-file-table__td folio-console-file-table__td--main'>
        {fileTypeIsImage ? null : <FileUploadProgress progress={file.progress} />}

        {link ? (
          <a href={file.edit_path}>{file.file_name}</a>
        ) : file.file_name}
      </td>
      <td className='folio-console-file-table__td'>
        <Tags file={file} />
      </td>
      <td className='folio-console-file-table__td'>{numberToHumanSize(file.file_size)}</td>
      <td className='folio-console-file-table__td'>{file.extension}</td>
    </tr>
  )
}

export default FileTableRow
