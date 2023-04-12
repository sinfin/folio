import React from 'react'
import { connect } from 'react-redux'

import {
  getFiles,
  makeFilesStatusSelector,
  makeUnselectedFilesForListSelector,
  makeFilesPaginationSelector,
  changeFilesPage,
  makeFilesReactTypeIsImageSelector
} from 'ducks/files'
import {
  selectFile,
  unselectFilePlacement,
  onSortEnd,
  changeTitle,
  changeAlt,
  makeFilePlacementsSelector
} from 'ducks/filePlacements'
import { openFileModal } from 'ducks/fileModal'
import { displayAsThumbsSelector } from 'ducks/display'

import MultiSelectComponent from 'components/MultiSelectComponent'

class MultiSelect extends React.PureComponent {
  selectFile = (file) => {
    this.props.dispatch(selectFile(this.props.fileType, file))
  }

  unselectFilePlacement = (fileType, filePlacement) => {
    this.props.dispatch(unselectFilePlacement(fileType, filePlacement))
  }

  onSortEnd = ({ oldIndex, newIndex }) => {
    this.props.dispatch(onSortEnd(this.props.fileType, oldIndex, newIndex))
  }

  onTitleChange = (filePlacement, title) => {
    this.props.dispatch(changeTitle(this.props.fileType, filePlacement, title))
  }

  onAltChange = (filePlacement, alt) => {
    this.props.dispatch(changeAlt(this.props.fileType, filePlacement, alt))
  }

  getFiles = () => {
    this.props.dispatch(getFiles(this.props.fileType))
  }

  changeFilesPage = (page) => {
    this.props.dispatch(changeFilesPage(this.props.fileType, this.props.filesUrl, page))
  }

  openFileModal = (file) => {
    this.props.dispatch(openFileModal(this.props.fileType, this.props.filesUrl, file))
  }

  render () {
    return (
      <MultiSelectComponent
        fileType={this.props.fileType}
        filesStatus={this.props.filesStatus}
        filesUrl={this.props.filesUrl}
        fileTypeIsImage={this.props.fileTypeIsImage}
        getFiles={this.getFiles}
        filePlacements={this.props.filePlacements}
        onSortEnd={this.onSortEnd}
        onAltChange={this.onAltChange}
        onTitleChange={this.onTitleChange}
        unselectFilePlacement={this.unselectFilePlacement}
        unselectedFilesForList={this.props.unselectedFilesForList}
        displayAsThumbs={this.props.displayAsThumbs}
        selectFile={this.selectFile}
        filesPagination={this.props.filesPagination}
        changeFilesPage={this.changeFilesPage}
        openFileModal={this.openFileModal}
        shouldLoadFiles={!this.props.inModal}
        taggable={this.props.taggable}
      />
    )
  }
}

const mapStateToProps = (state, props) => ({
  filePlacements: makeFilePlacementsSelector(props.fileType)(state),
  filesStatus: makeFilesStatusSelector(props.fileType)(state),
  unselectedFilesForList: makeUnselectedFilesForListSelector(props.fileType)(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: makeFilesPaginationSelector(props.fileType)(state),
  fileTypeIsImage: makeFilesReactTypeIsImageSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
