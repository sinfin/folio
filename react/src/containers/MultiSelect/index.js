import React from 'react'
import { connect } from 'react-redux'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';
import {
  selectFile,
  unselectFile,
  onSortEnd,
  filesLoadingSelector,
  filesForListSelector,
} from 'ducks/files'
import { placementTypeSelector, fileTypeIsImageSelector } from 'ducks/app'
import { filteredFilesSelector } from 'ducks/filters'
import { displayAsThumbsSelector } from 'ducks/display'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { File, UploadingFile, DropzoneTrigger } from 'components/File'
import Loader from 'components/Loader'
import Card from 'components/Card'
import FileList from 'components/FileList'
import FilePlacementList from 'components/FilePlacementList';

class MultiSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    this.props.dispatch(selectFile(file))
  }

  render() {
    const { files, dispatch, placementType, fileTypeIsImage } = this.props
    if (files.loading) return <Loader />

    const headerKey = fileTypeIsImage ? 'Images' : 'Documents'

    return (
      <Uploader>
        <Card
          highlighted
          header={window.FolioConsole.translations[`selected${headerKey}`]}
        >
          <FilePlacementList
            items={files.selected}
            attachmentable={files.attachmentable}
            placementType={placementType}
            onSortEnd={({ oldIndex, newIndex }) => dispatch(onSortEnd(oldIndex, newIndex))}
            onClick={(file) => dispatch(unselectFile(file))}
          />
        </Card>

        <Card
          header={window.FolioConsole.translations[`available${headerKey}`]}
          filters={<FileFilter />}
        >
          <FileList
            files={this.props.filesForList}
            fileTypeIsImage={this.props.fileTypeIsImage}
            displayAsThumbs={this.props.displayAsThumbs}
            onClick={this.selectFile}
            dropzoneTrigger
          />
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  files: filteredFilesSelector(state),
  placementType: placementTypeSelector(state),
  filesLoading: filesLoadingSelector(state),
  filesForList: filesForListSelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
  displayAsThumbs: displayAsThumbsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
