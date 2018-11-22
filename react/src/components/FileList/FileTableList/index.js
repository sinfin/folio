import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import FileTableRow from './FileTableRow';

const FileTableList = ({ files, dropzoneTrigger, link, fileTypeIsImage, overflowingParent, onClick }) => (
  <div className='folio-console-file-table-wrap'>
    <table className={`table folio-console-file-table ${onClick ? 'table-hover' : ''}`}>
      <tbody>
        {files.map(({ key, ...file }) => (
          <FileTableRow
            key={key}
            link={link}
            fileTypeIsImage={fileTypeIsImage}
            overflowingParent={overflowingParent}
            onClick={onClick}
            {...file}
          />
        ))}

        {dropzoneTrigger && <DropzoneTrigger colSpan={fileTypeIsImage ? 5 : 4} />}
      </tbody>
    </table>
  </div>
)

export default FileTableList
