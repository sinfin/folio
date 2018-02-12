import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'

import { uploadsSelector } from 'ducks/uploads'
import { filteredFilesSelector } from 'ducks/filters'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { File, UploadingFile, DropzoneTrigger } from 'components/File'
import Loader from 'components/Loader'
import Card from 'components/Card'

class IndexMode extends Component {
  componentWillReceiveProps (nextProps) {
    if (nextProps.files.selectable.length !== this.props.files.selectable.length) {
      forceCheck()
    }
  }

  render() {
    const { files, uploads } = this.props
    if (files.loading) return <Loader />

    return (
      <Uploader>
        <Card
          filters={<FileFilter />}
        >
          {files.selectable.map((file) => (
            <File
              file={file}
              key={file.file_id}
              onClick={console.log}
              selected={false}
            />
          ))}
          {uploads.records.map((upload, index) => (
            <UploadingFile
              upload={upload}
              key={upload.id}
            />
          ))}

          <DropzoneTrigger />
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  files: filteredFilesSelector(state),
  uploads: uploadsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(IndexMode)
