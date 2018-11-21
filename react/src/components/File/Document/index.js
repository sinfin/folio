import React from 'react'

import numberToHumanSize from 'utils/numberToHumanSize'

import DocumentProgress from './DocumentProgress';

const Document = ({ file, link }) => (
  <tr className="folio-console-file-table__tr">
    <td className="folio-console-file-table__td folio-console-file-table__td--first">
      <DocumentProgress progress={file.progress} />

      {link ? (
        <a href={file.edit_path}>{file.file_name}</a>
      ) : file.file_name}
    </td>
    <td className="folio-console-file-table__td">{file.tags}</td>
    <td className="folio-console-file-table__td">{numberToHumanSize(file.file_size)}</td>
    <td className="folio-console-file-table__td">{file.extension}</td>
  </tr>
)

export default Document
