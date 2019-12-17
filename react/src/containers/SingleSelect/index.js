import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import { makeFilesStatusSelector, makeFilesForListSelector, makeFilesPaginationSelector, changeFilesPage } from 'ducks/files'
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
      this.props.selectFile(this.props.filesKey, file)
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  renderHeader () {
    return (
      <Fragment>
        <FileFilter filesKey={this.props.filesKey} />
        <UploadTagger filesKey={this.props.filesKey} />
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
          <Uploader filesKey={this.props.filesKey}>
            <FileList
              files={this.props.filesForList}
              fileTypeIsImage={this.props.filesKey === 'images'}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.selectFile}
              pagination={this.props.filesPagination}
              changeFilesPage={(page) => this.props.dispatch(changeFilesPage(this.props.filesKey, page))}
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
  filesStatus: makeFilesStatusSelector(props.filesKey)(state),
  filesForList: makeFilesForListSelector(props.filesKey)(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: makeFilesPaginationSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(SingleSelect)
