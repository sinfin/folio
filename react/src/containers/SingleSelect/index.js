import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import {
  makeFilesStatusSelector,
  makeFilesForListSelector,
  makeFilesPaginationSelector,
  changeFilesPage,
  makeFilesReactTypeIsImageSelector
} from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'
import { openFileModal } from 'ducks/fileModal'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'
import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import FileList from 'components/FileList'
import ModalScroll from 'components/ModalScroll'
import ModalTitleAndUpload from 'components/ModalTitleAndUpload'

class SingleSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    if (this.props.selectFile) {
      this.props.selectFile(this.props.fileType, file)
    }
  }

  renderHeader () {
    return (
      <Fragment>
        {this.props.inModal && <ModalTitleAndUpload fileType={this.props.fileType} fileTypeIsImage={this.props.fileTypeIsImage} />}
        <FileFilter fileType={this.props.fileType} filesUrl={this.props.filesUrl} taggable={this.props.taggable} />
        <UploadTagger fileType={this.props.fileType} taggable={this.props.taggable} />
      </Fragment>
    )
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />

    return (
      <ModalScroll
        header={this.renderHeader()}
      >
        {this.props.filesStatus.loading ? <Loader standalone /> : (
          <Uploader fileType={this.props.fileType} filesUrl={this.props.filesUrl}>
            <FileList
              files={this.props.filesForList}
              fileTypeIsImage={this.props.fileTypeIsImage}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.selectFile}
              pagination={this.props.filesPagination}
              changeFilesPage={(page) => this.props.dispatch(changeFilesPage(this.props.fileType, this.props.filesUrl, page))}
              openFileModal={(file) => this.props.dispatch(openFileModal(this.props.fileType, this.props.filesUrl, file))}
              fileType={this.props.fileType}
              filesUrl={this.props.filesUrl}
              selecting='single'
              taggable={this.props.taggable}
              dropzoneTrigger
            />
          </Uploader>
        )}
      </ModalScroll>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filesStatus: makeFilesStatusSelector(props.fileType)(state),
  filesForList: makeFilesForListSelector(props.fileType)(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: makeFilesPaginationSelector(props.fileType)(state),
  fileTypeIsImage: makeFilesReactTypeIsImageSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(SingleSelect)
