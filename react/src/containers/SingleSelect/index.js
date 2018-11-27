import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import { fileTypeIsImageSelector } from 'ducks/app'
import { filesLoadingSelector, filesForListSelector } from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';
import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import FileList from 'components/FileList'
import ModalScroll from 'components/ModalScroll';

class SingleSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    if (this.props.selectFile) {
      this.props.selectFile(file)
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  renderFixed () {
    return (
      <Fragment>
        <FileFilter />
        <UploadTagger />
      </Fragment>
    )
  }

  render () {
    if (this.props.filesLoading) return <Loader />

    return (
      <ModalScroll
        fixed={this.renderFixed()}
      >
        <Uploader>
          <FileList
            files={this.props.filesForList}
            fileTypeIsImage={this.props.fileTypeIsImage}
            displayAsThumbs={this.props.displayAsThumbs}
            onClick={this.selectFile}
            selecting='single'
            overflowingParent
            dropzoneTrigger
          />
        </Uploader>
      </ModalScroll>
    )
  }
}

const mapStateToProps = (state) => ({
  filesLoading: filesLoadingSelector(state),
  filesForList: filesForListSelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
  displayAsThumbs: displayAsThumbsSelector(state),
})

export default connect(mapStateToProps, null)(SingleSelect)
