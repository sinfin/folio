import React from 'react'
import { connect } from 'react-redux'

import {
  makeFilesStatusSelector,
  makeFilesForListSelector,
  makeFilesPaginationSelector,
  changeFilesPage,
  massSelect,
  makeFilesReactTypeIsImageSelector
} from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'
import { openFileModal } from 'ducks/fileModal'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import FileMassActions from 'containers/FileMassActions'

import FileList from 'components/FileList'
import Loader from 'components/Loader'
import Card from 'components/Card'

class IndexMode extends LazyLoadCheckingComponent {
  openFileModal = (file) => {
    this.props.dispatch(openFileModal(this.props.fileType, this.props.filesUrl, file))
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />

    return (
      <div className='mt-n3'>
        <Uploader fileType={this.props.fileType} filesUrl={this.props.filesUrl}>
          <Card
            filters={<FileFilter fileType={this.props.fileType} filesUrl={this.props.filesUrl} fileTypeIsImage={this.props.fileTypeIsImage} taggable={this.props.taggable} />}
          >
            <UploadTagger fileType={this.props.fileType} taggable={this.props.taggable} />

            <FileMassActions fileType={this.props.fileType} filesUrl={this.props.filesUrl} />

            {this.props.filesStatus.loading ? <Loader standalone /> : (
              <FileList
                files={this.props.filesForList}
                fileTypeIsImage={this.props.fileTypeIsImage}
                displayAsThumbs={this.props.displayAsThumbs}
                pagination={this.props.filesPagination}
                changeFilesPage={(page) => this.props.dispatch(changeFilesPage(this.props.fileType, this.props.filesUrl, page))}
                massSelect={(file, select) => this.props.dispatch(massSelect(this.props.fileType, file, select))}
                massSelectVisible={this.props.filesStatus.massSelecting}
                fileType={this.props.fileType}
                filesUrl={this.props.filesUrl}
                readOnly={this.props.readOnly}
                openFileModal={this.openFileModal}
                openFileModalOnClick
                dropzoneTrigger
              />
            )}
          </Card>
        </Uploader>
      </div>
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

export default connect(mapStateToProps, mapDispatchToProps)(IndexMode)
