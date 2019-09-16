import React from 'react'
import { connect } from 'react-redux'

import { makeFilesLoadingSelector, makeFilesForListSelector } from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'
import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import FileList from 'components/FileList'
import Loader from 'components/Loader'
import Card from 'components/Card'

class IndexMode extends LazyLoadCheckingComponent {
  render () {
    if (this.props.filesLoading) return <Loader />
    const fileTypeIsImage = this.props.filesKey === 'images'

    return (
      <Uploader filesKey={this.props.filesKey}>
        <Card
          filters={<FileFilter filesKey={this.props.filesKey} fileTypeIsImage={fileTypeIsImage} />}
        >
          <UploadTagger filesKey={this.props.filesKey} />

          <FileList
            files={this.props.filesForList}
            fileTypeIsImage={fileTypeIsImage}
            displayAsThumbs={this.props.displayAsThumbs}
            link
            dropzoneTrigger
          />
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filesLoading: makeFilesLoadingSelector(props.filesKey)(state),
  filesForList: makeFilesForListSelector(props.filesKey)(state),
  displayAsThumbs: displayAsThumbsSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(IndexMode)
