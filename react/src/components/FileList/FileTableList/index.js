import React from 'react'

import DropzoneTrigger from './DropzoneTrigger'
import FileTableRow from './FileTableRow'

const FileTableList = ({
  filesKey,
  files,
  dropzoneTrigger,
  link,
  fileTypeIsImage,
  onClick,
  massSelect,
  massSelectVisible
}) => {
  const classNames = ['f-c-file-table']

  if (fileTypeIsImage) {
    classNames.push('f-c-file-table--image')
  } else {
    classNames.push('f-c-file-table--document')
  }

  if (onClick) {
    classNames.push('f-c-file-table--hover')
  }

  return (
    <div className='f-c-file-table-wrap'>
      {dropzoneTrigger && <DropzoneTrigger colSpan={fileTypeIsImage ? 5 : 4} />}

      <div className={classNames.join(' ')}>
        <div className='f-c-file-table__tbody'>
          {files.map((file) => (
            <FileTableRow
              key={file.id}
              filesKey={filesKey}
              file={file}
              link={link}
              fileTypeIsImage={fileTypeIsImage}
              onClick={onClick}
              massSelect={massSelect}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

export default FileTableList
