import React from 'react'
import { connect } from 'react-redux'

import { fileTypeIsImageSelector } from 'ducks/app'
import { uploadsSelector } from 'ducks/uploads'
import { filesLoadingSelector, filesForListSelector } from 'ducks/files'
import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { LinkFile } from 'components/File'
import FileList from 'components/FileList'
import Loader from 'components/Loader'
import Card from 'components/Card'

class IndexMode extends LazyLoadCheckingComponent {
  render () {
    if (this.props.filesLoading) return <Loader />

    return (
      <Uploader>
        <Card
          filters={<FileFilter />}
        >
          <FileList
            files={this.props.filesForList}
            fileTypeIsImage={this.props.fileTypeIsImage}
            dropzoneTrigger
          />
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  filesLoading: filesLoadingSelector(state),
  filesForList: filesForListSelector(state, LinkFile),
  uploads: uploadsSelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(IndexMode)
