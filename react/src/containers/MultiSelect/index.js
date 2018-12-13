import React from 'react'
import { connect } from 'react-redux'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';
import {
  filesLoadingSelector,
  unselectedFilesForListSelector,
} from 'ducks/files'
import {
  selectFile,
  unselectFilePlacement,
  onSortEnd,
  changeTitle,
  changeAlt,
  filePlacementsSelector,
} from 'ducks/filePlacements'
import { fileTypeIsImageSelector } from 'ducks/app'
import { displayAsThumbsSelector } from 'ducks/display'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import Card from 'components/Card'
import FileList from 'components/FileList'
import FilePlacementList from 'components/FilePlacementList';

class MultiSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    this.props.dispatch(selectFile(file))
  }

  unselectFilePlacement = (filePlacements) => {
    this.props.dispatch(unselectFilePlacement(filePlacements))
  }

  onSortEnd = ({ oldIndex, newIndex }) => this.props.dispatch(onSortEnd(oldIndex, newIndex))
  onTitleChange = (filePlacement, title) => this.props.dispatch(changeTitle(filePlacement, title))
  onAltChange = (filePlacement, alt) => this.props.dispatch(changeAlt(filePlacement, alt))

  render() {
    if (this.props.filesLoading) return <Loader />

    const headerKey = this.props.fileTypeIsImage ? 'Images' : 'Documents'

    return (
      <Uploader>
        <Card
          highlighted
          header={window.FolioConsole.translations[`selected${headerKey}`]}
        >
          <FilePlacementList
            filePlacements={this.props.filePlacements}
            onSortEnd={this.onSortEnd}
            onAltChange={this.onAltChange}
            onTitleChange={this.onTitleChange}
            unselectFilePlacement={this.unselectFilePlacement}
            fileTypeIsImage={this.props.fileTypeIsImage}
          />
        </Card>

        <Card
          header={window.FolioConsole.translations[`available${headerKey}`]}
          filters={<FileFilter />}
        >
          <UploadTagger />

          <FileList
            files={this.props.unselectedFilesForList}
            fileTypeIsImage={this.props.fileTypeIsImage}
            displayAsThumbs={this.props.displayAsThumbs}
            onClick={this.selectFile}
            selecting='multiple'
            dropzoneTrigger
          />
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  filePlacements: filePlacementsSelector(state),
  filesLoading: filesLoadingSelector(state),
  unselectedFilesForList: unselectedFilesForListSelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
  displayAsThumbs: displayAsThumbsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
