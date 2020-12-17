import React from 'react'
import { connect } from 'react-redux'

import { fileTypeIsImageSelector } from 'ducks/app'
import { filesLoadingSelector, filesForListSelector, filesPaginationSelector, changeFilesPage } from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'
import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
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
          <UploadTagger />

          <FileList
            files={this.props.filesForList}
            fileTypeIsImage={this.props.fileTypeIsImage}
            displayAsThumbs={this.props.displayAsThumbs}
            pagination={this.props.filesPagination}
            changeFilesPage={(page) => this.props.dispatch(changeFilesPage(page))}
            link
            dropzoneTrigger
          />
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  filesLoading: filesLoadingSelector(state),
  filesForList: filesForListSelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: filesPaginationSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(IndexMode)
