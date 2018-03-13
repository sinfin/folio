import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'

import { filteredFilesSelector } from 'ducks/filters'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { File } from 'components/File'
import Loader from 'components/Loader'

import SingleSelectWrap from './SingleSelectWrap'
import SingleSelectScroll from './SingleSelectScroll'

class SingleSelect extends Component {
  componentWillReceiveProps (nextProps) {
    if (nextProps.files.selectable.length !== this.props.files.selectable.length) {
      forceCheck()
    }
  }

  selectFile (file) {
    if (this.props.selectFile) {
      this.props.selectFile(file)
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  render () {
    const { files } = this.props
    if (files.loading) return <Loader />

    return (
      <SingleSelectWrap>
        <FileFilter />

        <SingleSelectScroll>
          <Uploader showUploading>
            {files.selectable.map((file) => (
              <File
                attachmentable={files.attachmentable}
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
})

export default connect(mapStateToProps, null)(SingleSelect)
