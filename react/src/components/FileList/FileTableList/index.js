import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import FileTableRow from './FileTableRow';

const FileTableList = ({ files, dropzoneTrigger, link }) => (
  <div className='folio-console-file-table-wrap'>
    <table className='table table-hover folio-console-file-table'>
      <tbody>
        {files.map(({ Component, files }) => {
          return files.map(({ key, ...file }) => (
            <FileTableRow
              key={key}
              link={link}
              {...file}
            />
          ))
        })}

        {dropzoneTrigger && <DropzoneTrigger />}
      </tbody>
    </table>
  </div>
)

export default FileTableList
