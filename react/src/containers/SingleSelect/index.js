import React from 'react'
import { connect } from 'react-redux'

import { placementTypeSelector, fileTypeIsImageSelector } from 'ducks/app'
import { filesLoadingSelector, filesForListSelector } from 'ducks/files'
import { displayAsThumbsSelector } from 'ducks/display'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';
import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import Loader from 'components/Loader'
import FileList from 'components/FileList'

import SingleSelectWrap from './styled/SingleSelectWrap'
import SingleSelectScroll from './styled/SingleSelectScroll'

class SingleSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    if (this.props.selectFile) {
      this.props.selectFile(file)
    } else if (window.folioConsoleInsertImage) {
      window.folioConsoleInsertImage(file)
    }
  }

  render () {
    if (this.props.filesLoading) return <Loader />

    return (
      <SingleSelectWrap>
        <FileFilter />

        <SingleSelectScroll>
          <Uploader>
            <FileList
              files={this.props.filesForList}
              fileTypeIsImage={this.props.fileTypeIsImage}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.selectFile}
              overflowingParent
              dropzoneTrigger
            />
{/*
            {files.selectable.map((file) => (
              <File
                attachmentable={files.attachmentable}
                placementType={placementType}
                file={file}
                key={file.file_id}
                onClick={() => this.selectFile(file)}
                selected={false}
                singleSelect
              />
            ))}
*/}
          </Uploader>
        </SingleSelectScroll>
      </SingleSelectWrap>
    )
  }
}

const mapStateToProps = (state) => ({
  placementType: placementTypeSelector(state),
  filesLoading: filesLoadingSelector(state),
  filesForList: filesForListSelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
  displayAsThumbs: displayAsThumbsSelector(state),
})

export default connect(mapStateToProps, null)(SingleSelect)
