import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import FileTableRow from './FileTableRow';

const FileTableList = ({ files, dropzoneTrigger, link, fileTypeIsImage, overflowingParent, onClick }) => {
  let classNames = ['folio-console-file-table']

  if (fileTypeIsImage) {
    classNames.push('folio-console-file-table--image')
  } else {
    classNames.push('folio-console-file-table--document')
  }

  if (onClick) {
    classNames.push('folio-console-file-table--hover')
  }

  return (
    <div className='folio-console-file-table-wrap'>
      {dropzoneTrigger && <DropzoneTrigger colSpan={fileTypeIsImage ? 5 : 4} />}

      <div className={classNames.join(' ')}>
        <div className='folio-console-file-table__tbody'>
          {files.map((file) => (
            <FileTableRow
              key={file.id}
              file={file}
              link={link}
              fileTypeIsImage={fileTypeIsImage}
              overflowingParent={overflowingParent}
              onClick={onClick}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

export default FileTableList
