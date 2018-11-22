import React from 'react'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'components/Tags'

import FileTableRowProgress from './FileTableRowProgress';

const FileTableRow = ({ file, link, fileTypeIsImage }) => {
  return (
  <tr className='folio-console-file-table__tr'>
    {fileTypeIsImage && (
      <td className='folio-console-file-table__td folio-console-file-table__td--image'>
        <FileTableRowProgress progress={file.progress} />

        <div className='folio-console-file-table__img-wrap'>
          {file.thumb && (
            <a href={file.source_image} target='_blank' className='folio-console-file-table__img-a'>
              <img src={file.thumb} className='folio-console-file-table__img' />
            </a>
          )}
        </div>
      </td>
    )}

    <td className='folio-console-file-table__td folio-console-file-table__td--main'>
      {fileTypeIsImage ? null : <FileTableRowProgress progress={file.progress} />}

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
)}

export default FileTableRow
