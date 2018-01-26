import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'

import { filteredFilesSelector } from 'ducks/filters'

import FileFilter from 'containers/FileFilter'
import { File } from 'components/File'
import Loader from 'components/Loader'

import SingleSelectWrap from './SingleSelectWrap'
import SingleSelectScroll from './SingleSelectScroll'

class MultiSelect extends Component {
  componentWillReceiveProps (nextProps) {
    if (nextProps.files.selectable.length !== this.props.files.selectable.length) {
      forceCheck()
    }
  }

  selectFile (file) {
    if (window.folioConsoleInsertImage) {
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
          {files.selectable.map((file) => (
            <File
              file={file}
              key={file.file_id}
              onClick={() => this.selectFile(file)}
              selected={false}
              singleSelect
            />
          ))}
        </SingleSelectScroll>
      </SingleSelectWrap>
    )
  }
}

const mapStateToProps = (state) => ({
  files: filteredFilesSelector(state),
})

export default connect(mapStateToProps, null)(MultiSelect)
