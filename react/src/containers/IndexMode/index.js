import React from 'react'
import { connect } from 'react-redux'

import { uploadsSelector } from 'ducks/uploads'
import { filteredFilesSelector } from 'ducks/filters'
import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { LinkFile, UploadingFile, DropzoneTrigger } from 'components/File'
import Loader from 'components/Loader'
import Card from 'components/Card'

class IndexMode extends LazyLoadCheckingComponent {
  render() {
    const { files, uploads } = this.props
    if (files.loading) return <Loader />

    return (
      <Uploader>
        <Card
          filters={<FileFilter />}
        >
          <DropzoneTrigger />

          {uploads.records.map((upload, index) => (
            <UploadingFile
              upload={upload}
              key={upload.id}
            />
          ))}

          {files.selectable.map((file) => (
            <LinkFile file={file} key={file.file_id} />
          ))}
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
