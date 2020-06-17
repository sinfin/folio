import React from 'react'

import DropzoneTrigger from './DropzoneTrigger'
import FileTableHeader from './FileTableHeader'
import FileTableRow from './FileTableRow'

class FileTableList extends React.Component {
  state = { enabledMassSelect: false }

  toggleMassSelect = () => {
    let newValue = !this.state.enabledMassSelect
    if (this.props.massSelectVisible) newValue = true
    this.setState({ ...this.state, enabledMassSelect: newValue })
  }

  render () {
    const {
      fileType,
      filesUrl,
      files,
      dropzoneTrigger,
      openFileModal,
      fileTypeIsImage,
      onClick,
      massSelect
    } = this.props

    const classNames = ['f-c-file-table']
    const wrapClassNames = ['f-c-file-table-wrap']

    if (fileTypeIsImage) {
      classNames.push('f-c-file-table--image')
      wrapClassNames.push('f-c-file-table-wrap--image')
    } else {
      classNames.push('f-c-file-table--document')
      wrapClassNames.push('f-c-file-table-wrap--document')
    }

    if (this.state.enabledMassSelect && massSelect) {
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
            <FileTableHeader
              fileType={fileType}
              fileTypeIsImage={fileTypeIsImage}
              massSelect={this.state.enabledMassSelect && massSelect}
            />

            {files.map((file) => (
              <FileTableRow
                key={file.id}
                fileType={fileType}
                filesUrl={filesUrl}
                file={file}
                openFileModal={openFileModal}
                fileTypeIsImage={fileTypeIsImage}
                onClick={onClick}
                massSelect={this.state.enabledMassSelect && massSelect}
              />
            ))}
          </div>
        </div>

        {files.length > 1 && (
          <div className='text-center mt-4 mb-n2'>
            <button type='button' className='btn btn-light btn-sm' onClick={this.toggleMassSelect}>
              Hromadný výběr
            </button>
          </div>
        )}
      </div>
    )
  }
}

export default FileTableList
