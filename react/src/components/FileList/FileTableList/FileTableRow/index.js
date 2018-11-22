import React from 'react'

import numberToHumanSize from 'utils/numberToHumanSize'
import Tags from 'components/Tags'

import FileTableRowProgress from './FileTableRowProgress';

const FileTableRow = ({ file, link }) => {
  return (
  <tr className="folio-console-file-table__tr">
    <td className="folio-console-file-table__td folio-console-file-table__td--first">
      <FileTableRowProgress progress={file.progress} />

      {link ? (
        <a href={file.edit_path}>{file.file_name}</a>
      ) : file.file_name}
    </td>
    <td className="folio-console-file-table__td">
      <Tags file={file} />
    </td>
    <td className="folio-console-file-table__td">{numberToHumanSize(file.file_size)}</td>
    <td className="folio-console-file-table__td">{file.extension}</td>
  </tr>
)}

export default FileTableRow
