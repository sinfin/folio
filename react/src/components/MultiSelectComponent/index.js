import React from 'react'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import Card from 'components/Card'
import FileList from 'components/FileList'
import FilePlacementList from 'components/FilePlacementList'

class MultiSelectComponent extends LazyLoadCheckingComponent {
  componentWillMount () {
    if (this.props.shouldLoadFiles &&
        !this.props.filesStatus.loaded &&
        !this.props.filesStatus.loading &&
        this.props.filesKey) {
      this.props.getFiles(this.props.filesKey)
    }
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />
    const fileTypeIsImage = this.props.filesKey === 'images'

    return (
      <Uploader filesKey={this.props.filesKey}>
        <Card
          highlighted
          header={window.FolioConsole.translations[`selected${this.props.filesKey}`]}
          className='f-c-multi-select-component__card f-c-multi-select-component__card--placements'
        >
          <FilePlacementList
            filePlacements={this.props.filePlacements}
            onSortEnd={this.props.onSortEnd}
            onAltChange={this.props.onAltChange}
            onTitleChange={this.props.onTitleChange}
            unselectFilePlacement={this.props.unselectFilePlacement}
            fileTypeIsImage={fileTypeIsImage}
            filesKey={this.props.filesKey}
            nested={this.props.nested}
          />
        </Card>

        <Card
          header={window.FolioConsole.translations[`available${this.props.filesKey}`]}
          headerUpload
          filters={<FileFilter filesKey={this.props.filesKey} fileTypeIsImage={fileTypeIsImage} />}
          className='f-c-multi-select-component__card f-c-multi-select-component__card--files'
        >
          <UploadTagger filesKey={this.props.filesKey} nested={this.props.nested} />

          {this.props.filesStatus.loading ? <Loader standalone /> : (
            <FileList
              files={this.props.unselectedFilesForList}
              fileTypeIsImage={fileTypeIsImage}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.props.selectFile}
              pagination={this.props.filesPagination}
              changeFilesPage={this.props.changeFilesPage}
              filesKey={this.props.filesKey}
              selecting='multiple'
              dropzoneTrigger
            />
          )}
        </Card>
      </Uploader>
    )
  }
}

export default MultiSelectComponent
