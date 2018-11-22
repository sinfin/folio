import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import FileTableRow from './FileTableRow';

const FileTableList = ({ files, dropzoneTrigger, link, fileTypeIsImage }) => (
  <div className='folio-console-file-table-wrap'>
    <table className='table table-hover folio-console-file-table'>
      <tbody>
        {files.map(({ key, ...file }) => (
          <FileTableRow
            key={key}
            link={link}
            fileTypeIsImage={fileTypeIsImage}
            {...file}
          />
        ))}

        {dropzoneTrigger && <DropzoneTrigger colSpan={fileTypeIsImage ? 5 : 4} />}
      </tbody>
    </table>
  </div>
)

export default FileTableList
