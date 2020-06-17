import React from 'react'
import { connect } from 'react-redux'

import {
  makeFilesStatusSelector,
  makeFilesForListSelector,
  makeFilesPaginationSelector,
  changeFilesPage,
  massSelect
} from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'
import { openFileModal } from 'ducks/fileModal'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'
import fileTypeIsImage from 'utils/fileTypeIsImage'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import FileMassActions from 'containers/FileMassActions'

import FileList from 'components/FileList'
import Loader from 'components/Loader'
import Card from 'components/Card'

class IndexMode extends LazyLoadCheckingComponent {
  openFileModal = (file) => {
    this.props.dispatch(openFileModal(this.props.filesKey, file))
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />
    const fileTypeIsImageResult = fileTypeIsImage(this.props.filesKey)

    return (
      <div className='mt-n3'>
        <Uploader filesKey={this.props.filesKey}>
          <Card
            filters={<FileFilter filesKey={this.props.filesKey} fileTypeIsImage={fileTypeIsImageResult} />}
          >
            <UploadTagger filesKey={this.props.filesKey} />

            <FileMassActions filesKey={this.props.filesKey} filesUrl={this.props.filesUrl} />

            {this.props.filesStatus.loading ? <Loader standalone /> : (
              <FileList
                files={this.props.filesForList}
                fileTypeIsImage={fileTypeIsImageResult}
                displayAsThumbs={this.props.displayAsThumbs}
                pagination={this.props.filesPagination}
                changeFilesPage={(page) => this.props.dispatch(changeFilesPage(this.props.filesKey, page))}
                massSelect={(file, select) => this.props.dispatch(massSelect(this.props.filesKey, file, select))}
                massSelectVisible={this.props.filesStatus.massSelecting}
                filesKey={this.props.filesKey}
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
  filesStatus: makeFilesStatusSelector(props.filesKey)(state),
  filesForList: makeFilesForListSelector(props.filesKey)(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: makeFilesPaginationSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(IndexMode)
