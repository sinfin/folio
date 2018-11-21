import React from 'react'
import { connect } from 'react-redux'

import { filteredFilesSelector } from 'ducks/filters'
import { placementTypeSelector } from 'ducks/app'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';
import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { File } from 'components/File'
import Loader from 'components/Loader'

import SingleSelectWrap from './styled/SingleSelectWrap'
import SingleSelectScroll from './styled/SingleSelectScroll'

class SingleSelect extends LazyLoadCheckingComponent {
  selectFile (file) {
    if (this.props.selectFile) {
      this.props.selectFile(file)
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  render () {
    const { files, placementType } = this.props
    if (files.loading) return <Loader />

    return (
      <SingleSelectWrap>
        <FileFilter />

        <SingleSelectScroll>
          <Uploader showUploading>
            {files.selectable.map((file) => (
              <File
                attachmentable={files.attachmentable}
                placementType={placementType}
                file={file}
                key={file.file_id}
                onClick={() => this.selectFile(file)}
                selected={false}
                singleSelect
              />
            ))}
          </Uploader>
        </SingleSelectScroll>
      </SingleSelectWrap>
    )
  }
}

const mapStateToProps = (state) => ({
  files: filteredFilesSelector(state),
  placementType: placementTypeSelector(state),
})

export default connect(mapStateToProps, null)(SingleSelect)
