import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import { makeFilesStatusSelector, makeFilesForListSelector, makeFilesPaginationSelector, changeFilesPage } from 'ducks/files'
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
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  renderHeader () {
    return (
      <Fragment>
        {this.props.inModal && <ModalTitleAndUpload fileType={this.props.fileType} />}
        <FileFilter fileType={this.props.fileType} filesUrl={this.props.filesUrl} />
        <UploadTagger fileType={this.props.fileType} />
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
              fileTypeIsImage={this.props.fileType === 'Folio::Image'}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.selectFile}
              pagination={this.props.filesPagination}
              changeFilesPage={(page) => this.props.dispatch(changeFilesPage(this.props.fileType, page))}
              openFileModal={(file) => this.props.dispatch(openFileModal(this.props.fileType, file))}
              fileType={this.props.fileType}
              selecting='single'
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
  filesPagination: makeFilesPaginationSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(SingleSelect)
