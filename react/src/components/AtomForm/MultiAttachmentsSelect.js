import React from 'react'
import { connect } from 'react-redux'

import {
  getFiles,
  makeFilesStatusSelector,
  makeFilesPaginationSelector,
  changeFilesPage,
  makeRawUnselectedFilesForListSelector
} from 'ducks/files'

import {
  atomFormPlacementsSelect,
  atomFormPlacementsUnselect,
  atomFormPlacementsSort,
  atomFormPlacementsChangeTitle,
  atomFormPlacementsChangeAlt
} from 'ducks/atoms'

import { displayAsThumbsSelector } from 'ducks/display'

import MultiSelectComponent from 'components/MultiSelectComponent'
import fileTypeToKey from 'utils/fileTypeToKey'

class MultiAttachmentsSelect extends React.PureComponent {
  getFiles = () => {
    this.props.dispatch(getFiles(this.props.filesKey))
  }

  changeFilesPage = (page) => {
    this.props.dispatch(changeFilesPage(this.props.filesKey, page))
  }

  onSortEnd = ({ oldIndex, newIndex }) => {
    this.props.dispatch(
      atomFormPlacementsSort(
        this.props.index,
        this.props.attachmentType.key,
        oldIndex,
        newIndex
      )
    )
  }

  onAltChange = (filePlacement, alt) => {
    this.props.dispatch(
      atomFormPlacementsChangeAlt(
        this.props.index,
        this.props.attachmentType.key,
        filePlacement,
        alt
      )
    )
  }

  onTitleChange = (filePlacement, title) => {
    this.props.dispatch(
      atomFormPlacementsChangeTitle(
        this.props.index,
        this.props.attachmentType.key,
        filePlacement,
        title
      )
    )
  }

  unselectFilePlacement = (_filesKey, filePlacement) => {
    this.props.dispatch(
      atomFormPlacementsUnselect(
        this.props.index,
        this.props.attachmentType.key,
        filePlacement
      )
    )
  }

  selectFile = (file) => {
    this.props.dispatch(
      atomFormPlacementsSelect(
        this.props.index,
        this.props.attachmentType.key,
        file
      )
    )
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
        shouldLoadFiles
      />
    )
  }
}

const mapStateToProps = (state, props) => {
  const filesKey = fileTypeToKey(props.attachmentType['file_type'])
  const filePlacements = {
    selected: [],
    deleted: [],
    attachmentable: 'foo',
    placementType: props.attachmentType.key.replace('_attributes', '')
  }
  const selectedFileIds = []

  return {
    filesKey,
    filesStatus: makeFilesStatusSelector(filesKey)(state),
    displayAsThumbs: displayAsThumbsSelector(state),
    filesPagination: makeFilesPaginationSelector(filesKey)(state),
    filePlacements,
    unselectedFilesForList: makeRawUnselectedFilesForListSelector(filesKey, selectedFileIds)(state)
  }
}

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export { MultiAttachmentsSelect }
export default connect(mapStateToProps, mapDispatchToProps)(MultiAttachmentsSelect)
