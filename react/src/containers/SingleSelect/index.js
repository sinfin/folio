import React from 'react'
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

class SingleSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    if (this.props.selectFile) {
      this.props.selectFile(this.props.fileType, file)
    }
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />

    return this.props.filesStatus.loading ? <Loader standalone /> : (
      <Uploader fileType={this.props.fileType} filesUrl={this.props.filesUrl} reactType={this.props.reactType}>
        <FileFilter fileType={this.props.fileType} filesUrl={this.props.filesUrl} taggable={this.props.taggable} />
        <UploadTagger fileType={this.props.fileType} taggable={this.props.taggable} />

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
