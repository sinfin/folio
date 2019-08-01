import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import { fileTypeIsImageSelector } from 'ducks/app'
import { makeFilesLoadingSelector, makeFilesForListSelector } from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'
import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import FileList from 'components/FileList'
import ModalScroll from 'components/ModalScroll'

class SingleSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    if (this.props.selectFile) {
      this.props.selectFile(file)
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  renderHeader () {
    return (
      <Fragment>
        <FileFilter />
        <UploadTagger filesKey={this.props.filesKey} />
      </Fragment>
    )
  }

  render () {
    if (this.props.filesLoading) return <Loader />

    return (
      <ModalScroll
        header={this.renderHeader()}
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

const mapStateToProps = (state, props) => ({
  filesLoading: makeFilesLoadingSelector(props.filesKey)(state),
  filesForList: makeFilesForListSelector(props.filesKey)(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
  displayAsThumbs: displayAsThumbsSelector(state)
})

export default connect(mapStateToProps, null)(SingleSelect)
