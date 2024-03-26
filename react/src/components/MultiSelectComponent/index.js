import React from 'react'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import UploadTagger from 'containers/UploadTagger'
import Loader from 'components/Loader'
import FileList from 'components/FileList'
import FilePlacementList from 'components/FilePlacementList'

const I18N = {
  cs: {
    available_document: 'Dostupné dokumenty',
    available_image: 'Dostupné obrázky',
    available_video: 'Dostupná videa',
    available_audio: 'Dostupná audia',
    selected_document: 'Vybrané dokumenty',
    selected_image: 'Vybrané obrázky',
    selected_video: 'Vybraná videa',
    selected_audio: 'Vybraná audia'
  },
  en: {
    available_document: 'Available documents',
    available_image: 'Available images',
    available_video: 'Available videos',
    available_audio: 'Available audios',
    selected_document: 'Selected documents',
    selected_image: 'Selected images',
    selected_video: 'Selected videos',
    selected_audio: 'Selected audios'
  }
}

class MultiSelectComponent extends LazyLoadCheckingComponent {
  componentDidMount () {
    if (this.props.shouldLoadFiles &&
        !this.props.filesStatus.loaded &&
        !this.props.filesStatus.loading &&
        this.props.fileType) {
      this.props.getFiles(this.props.fileType)
    }
  }

  render () {
    if (!this.props.filesStatus.loaded) return <Loader />

    return (
      <Uploader fileType={this.props.fileType} filesUrl={this.props.filesUrl} reactType={this.props.reactType}>
        <h2>{window.Folio.i18n(I18N, `selected_${this.props.reactType}`)}</h2>

        <FilePlacementList
          filePlacements={this.props.filePlacements}
          onSortEnd={this.props.onSortEnd}
          onAltChange={this.props.onAltChange}
          onTitleChange={this.props.onTitleChange}
          unselectFilePlacement={this.props.unselectFilePlacement}
          fileTypeIsImage={this.props.fileTypeIsImage}
          fileType={this.props.fileType}
          nested={this.props.nested}
          openFileModal={this.props.openFileModal}
        />

        <h2>{window.Folio.i18n(I18N, `available_${this.props.reactType}`)}</h2>

        <FileFilter fileType={this.props.fileType} filesUrl={this.props.filesUrl} fileTypeIsImage={this.props.fileTypeIsImage} className='f-c-anti-container-fluid f-c-anti-container-fluid--padded' />

        <UploadTagger fileType={this.props.fileType} nested={this.props.nested} taggable={this.props.taggable} />

        {this.props.filesStatus.loading ? <Loader standalone /> : (
          <FileList
            files={this.props.unselectedFilesForList}
            fileTypeIsImage={this.props.fileTypeIsImage}
            displayAsThumbs={this.props.displayAsThumbs}
            onClick={this.props.selectFile}
            pagination={this.props.filesPagination}
            changeFilesPage={this.props.changeFilesPage}
            fileType={this.props.fileType}
            filesUrl={this.props.filesUrl}
            selecting='multiple'
            openFileModal={this.props.openFileModal}
            dropzoneTrigger
          />
        )}
      </Uploader>
    )
  }
}

export default MultiSelectComponent
