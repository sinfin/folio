import React from 'react'
import { connect } from 'react-redux'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'
import {
  getFiles,
  makeFilesLoadedSelector,
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
import { displayAsThumbsSelector } from 'ducks/display'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import Card from 'components/Card'
import FileList from 'components/FileList'
import FilePlacementList from 'components/FilePlacementList'

class MultiSelect extends LazyLoadCheckingComponent {
  selectFile = (file) => {
    this.props.dispatch(selectFile(this.props.filesKey, file))
  }

  componentWillMount () {
    if (this.props.shouldLoadFiles &&
        !this.props.filesLoading &&
        !this.props.filesLoaded &&
        this.props.filesKey) {
      this.props.dispatch(getFiles(this.props.filesKey))
    }
  }

  unselectFilePlacement = (filesKey, filePlacement) => {
    this.props.dispatch(unselectFilePlacement(filesKey, filePlacement))
  }

  onSortEnd = ({ oldIndex, newIndex }) => this.props.dispatch(onSortEnd(this.props.filesKey, oldIndex, newIndex))

  onTitleChange = (filePlacement, title) => this.props.dispatch(changeTitle(this.props.filesKey, filePlacement, title))

  onAltChange = (filePlacement, alt) => this.props.dispatch(changeAlt(this.props.filesKey, filePlacement, alt))

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />
    const fileTypeIsImage = this.props.filesKey === 'images'

    return (
      <Uploader filesKey={this.props.filesKey}>
        <Card
          highlighted
          header={window.FolioConsole.translations[`selected${this.props.filesKey}`]}
        >
          <FilePlacementList
            filePlacements={this.props.filePlacements}
            onSortEnd={this.onSortEnd}
            onAltChange={this.onAltChange}
            onTitleChange={this.onTitleChange}
            unselectFilePlacement={this.unselectFilePlacement}
            fileTypeIsImage={fileTypeIsImage}
            filesKey={this.props.filesKey}
          />
        </Card>

        <Card
          header={window.FolioConsole.translations[`available${this.props.filesKey}`]}
          filters={<FileFilter filesKey={this.props.filesKey} fileTypeIsImage={fileTypeIsImage} />}
        >
          <UploadTagger filesKey={this.props.filesKey} />

          {this.props.filesStatus.loading ? <Loader standalone /> : (
            <FileList
              files={this.props.unselectedFilesForList}
              fileTypeIsImage={fileTypeIsImage}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.selectFile}
              pagination={this.props.filesPagination}
              changeFilesPage={(page) => this.props.dispatch(changeFilesPage(this.props.filesKey, page))}
              selecting='multiple'
              dropzoneTrigger
            />
          )}
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filePlacements: makeFilePlacementsSelector(props.filesKey)(state),
  filesLoaded: makeFilesLoadedSelector(props.filesKey)(state),
  filesStatus: makeFilesStatusSelector(props.filesKey)(state),
  unselectedFilesForList: makeUnselectedFilesForListSelector(props.filesKey)(state),
  displayAsThumbs: displayAsThumbsSelector(state),
  filesPagination: makeFilesPaginationSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
