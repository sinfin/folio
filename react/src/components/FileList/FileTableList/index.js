import React from 'react'

import DropzoneTrigger from './DropzoneTrigger'
import FileTableRow from './FileTableRow'

const FileTableList = ({
  filesKey,
  files,
  dropzoneTrigger,
  openInModal,
  fileTypeIsImage,
  onClick,
  massSelect,
  massSelectVisible
}) => {
  const classNames = ['f-c-file-table']
  const wrapClassNames = ['f-c-file-table-wrap']

  if (fileTypeIsImage) {
    classNames.push('f-c-file-table--image')
    wrapClassNames.push('f-c-file-table-wrap--image')
  } else {
    classNames.push('f-c-file-table--document')
    wrapClassNames.push('f-c-file-table-wrap--document')
  }

  if (massSelect) {
    wrapClassNames.push('f-c-file-table-wrap--mass-select')
  }

  if (onClick) {
    classNames.push('f-c-file-table--hover')
  }

  return (
    <div className={wrapClassNames.join(' ')}>
      {dropzoneTrigger && <DropzoneTrigger colSpan={fileTypeIsImage ? 5 : 4} />}

      <div className={classNames.join(' ')}>
        <div className='f-c-file-table__tbody'>
          {files.map((file) => (
            <FileTableRow
              key={file.id}
              filesKey={filesKey}
              file={file}
              openInModal={openInModal}
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
