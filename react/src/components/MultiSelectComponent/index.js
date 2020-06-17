import React from 'react'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import Card from 'components/Card'
import FileList from 'components/FileList'
import FilePlacementList from 'components/FilePlacementList'
import fileTypeIsImage from 'utils/fileTypeIsImage'

class MultiSelectComponent extends LazyLoadCheckingComponent {
  componentWillMount () {
    if (this.props.shouldLoadFiles &&
        !this.props.filesStatus.loaded &&
        !this.props.filesStatus.loading &&
        this.props.fileType) {
      this.props.getFiles(this.props.fileType)
    }
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />
    const fileTypeIsImageResult = fileTypeIsImage(this.props.fileType)

    return (
      <Uploader fileType={this.props.fileType}>
        <Card
          highlighted
          header={window.FolioConsole.translations[`selected${this.props.fileType}`]}
          className='f-c-multi-select-component__card f-c-multi-select-component__card--placements'
        >
          <FilePlacementList
            filePlacements={this.props.filePlacements}
            onSortEnd={this.props.onSortEnd}
            onAltChange={this.props.onAltChange}
            onTitleChange={this.props.onTitleChange}
            unselectFilePlacement={this.props.unselectFilePlacement}
            fileTypeIsImage={fileTypeIsImageResult}
            fileType={this.props.fileType}
            nested={this.props.nested}
            openFileModal={this.props.openFileModal}
          />
        </Card>

        <Card
          header={window.FolioConsole.translations[`available${this.props.fileType}`]}
          headerUpload
          filters={<FileFilter fileType={this.props.fileType} fileTypeIsImage={fileTypeIsImageResult} />}
          className='f-c-multi-select-component__card f-c-multi-select-component__card--files'
        >
          <UploadTagger fileType={this.props.fileType} nested={this.props.nested} />

          {this.props.filesStatus.loading ? <Loader standalone /> : (
            <FileList
              files={this.props.unselectedFilesForList}
              fileTypeIsImage={fileTypeIsImage}
              displayAsThumbs={this.props.displayAsThumbs}
              onClick={this.props.selectFile}
              pagination={this.props.filesPagination}
              changeFilesPage={this.props.changeFilesPage}
              fileType={this.props.fileType}
              selecting='multiple'
              openFileModal={this.props.openFileModal}
              dropzoneTrigger
            />
          )}
        </Card>
      </Uploader>
    )
  }
}

export default MultiSelectComponent
