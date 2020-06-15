import React from 'react'
import { connect } from 'react-redux'

import {
  getFiles,
  makeFilesStatusSelector,
  makeUnselectedFilesForListSelector,
  makeFilesPaginationSelector,
  changeFilesPage
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
    this.props.dispatch(selectFile(this.props.filesKey, file))
  }

  unselectFilePlacement = (filesKey, filePlacement) => {
    this.props.dispatch(unselectFilePlacement(filesKey, filePlacement))
  }

  onSortEnd = ({ oldIndex, newIndex }) => {
    this.props.dispatch(onSortEnd(this.props.filesKey, oldIndex, newIndex))
  }

  onTitleChange = (filePlacement, title) => {
    this.props.dispatch(changeTitle(this.props.filesKey, filePlacement, title))
  }

  onAltChange = (filePlacement, alt) => {
    this.props.dispatch(changeAlt(this.props.filesKey, filePlacement, alt))
  }

  getFiles = () => {
    this.props.dispatch(getFiles(this.props.filesKey))
  }

  changeFilesPage = (page) => {
    this.props.dispatch(changeFilesPage(this.props.filesKey, page))
  }

  openFileModal = (file) => {
    this.props.dispatch(openFileModal(this.props.filesKey, file))
  }

  render () {
    return (
      <MultiSelectComponent
        filesKey={this.props.filesKey}
        filesStatus={this.props.filesStatus}
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
        shouldLoadFiles
      />
    )
  }
}

const mapStateToProps = (state, props) => ({
  filePlacements: makeFilePlacementsSelector(props.filesKey)(state),
  filesStatus: makeFilesStatusSelector(props.filesKey)(state),
  unselectedFilesForList: makeUnselectedFilesForListSelector(props.filesKey)(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: makeFilesPaginationSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
