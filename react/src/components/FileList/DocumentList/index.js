import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import Document from 'components/File/Document';

const DocumentList = ({ files, fileTypeIsImage, dropzoneTrigger }) => (
  <div className='folio-console-file-table-wrap'>
    <table className='table folio-console-file-table'>
      <tbody>
        {files.map(({ Component, files }) => {
          return files.map(({ key, ...file }) => (
            <Document key={key} {...file} />
          ))
        })}

        {dropzoneTrigger && <DropzoneTrigger />}
      </tbody>
    </table>
  </div>
)

export default DocumentList
