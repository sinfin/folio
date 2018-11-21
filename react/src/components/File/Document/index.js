import React from 'react'

const Document = ({ file }) => (
  <tr className="folio-console-file-table__tr">
    <td className="folio-console-file-table__td folio-console-file-table__td--first">{file.file_name}</td>
    <td className="folio-console-file-table__td">{file.extension}</td>
    <td className="folio-console-file-table__td">{file.file_size}</td>
    <td className="folio-console-file-table__td">{file.tags}</td>
  </tr>
)

export default Document
