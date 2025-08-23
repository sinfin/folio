import React, { Component } from 'react'
import { connect } from 'react-redux'
import { uniqueId } from 'lodash'

import ReactModal from 'react-modal'

import { updateFile, deleteFile, updatedFiles } from 'ducks/files'
import {
  updateFileThumbnail,
  destroyFileThumbnail,
  closeFileModal,
  fileModalSelector,
  uploadNewFileInstead,
  uploadNewFileInsteadSuccess,
  uploadNewFileInsteadFailure,
  updatedFileModalFile,
  markModalFileAsUpdating,
  changeFilePlacementsPage,
  extractMetadata
} from 'ducks/fileModal'

import FileModalFile from './FileModalFile'

ReactModal.setAppElement('body')

class FileModal extends Component {
  state = {}

  constructor (props) {
    super(props)

    if (props.fileModal.file) {
      const newState = {
        author: props.fileModal.file.attributes.author,
        attribution_source: props.fileModal.file.attributes.attribution_source,
        attribution_source_url: props.fileModal.file.attributes.attribution_source_url,
        attribution_copyright: props.fileModal.file.attributes.attribution_copyright,
        attribution_licence: props.fileModal.file.attributes.attribution_licence,
        default_gravity: props.fileModal.file.attributes.default_gravity,
        alt: props.fileModal.file.attributes.alt,
        description: props.fileModal.file.attributes.description,
        preview_duration: props.fileModal.file.attributes.preview_duration,
        sensitive_content: props.fileModal.file.attributes.sensitive_content,
        tags: props.fileModal.file.attributes.tags,
        // IPTC Core metadata fields
        headline: props.fileModal.file.attributes.headline,
        creator: props.fileModal.file.attributes.creator || [],
        caption_writer: props.fileModal.file.attributes.caption_writer,
        credit_line: props.fileModal.file.attributes.credit_line,
        source: props.fileModal.file.attributes.source,
        copyright_notice: props.fileModal.file.attributes.copyright_notice,
        copyright_marked: props.fileModal.file.attributes.copyright_marked,
        usage_terms: props.fileModal.file.attributes.usage_terms,
        rights_usage_info: props.fileModal.file.attributes.rights_usage_info,
        keywords: props.fileModal.file.attributes.keywords || [],
        intellectual_genre: props.fileModal.file.attributes.intellectual_genre,
        subject_codes: props.fileModal.file.attributes.subject_codes || [],
        scene_codes: props.fileModal.file.attributes.scene_codes || [],
        event: props.fileModal.file.attributes.event,
        category: props.fileModal.file.attributes.category,
        urgency: props.fileModal.file.attributes.urgency,
        persons_shown: props.fileModal.file.attributes.persons_shown || [],
        persons_shown_details: props.fileModal.file.attributes.persons_shown_details || [],
        organizations_shown: props.fileModal.file.attributes.organizations_shown || [],
        location_created: props.fileModal.file.attributes.location_created || [],
        location_shown: props.fileModal.file.attributes.location_shown || [],
        sublocation: props.fileModal.file.attributes.sublocation,
        city: props.fileModal.file.attributes.city,
        state_province: props.fileModal.file.attributes.state_province,
        country: props.fileModal.file.attributes.country,
        country_code: props.fileModal.file.attributes.country_code,
        // Technical metadata (read-only)
        camera_make: props.fileModal.file.attributes.camera_make,
        camera_model: props.fileModal.file.attributes.camera_model,
        lens_info: props.fileModal.file.attributes.lens_info,
        capture_date: props.fileModal.file.attributes.capture_date,
        gps_latitude: props.fileModal.file.attributes.gps_latitude,
        gps_longitude: props.fileModal.file.attributes.gps_longitude,
        orientation: props.fileModal.file.attributes.orientation,
        file_metadata_extracted_at: props.fileModal.file.attributes.file_metadata_extracted_at
      }

      props.fileModal.file.attributes.file_modal_additional_fields.forEach((field) => {
        newState[field.name] = field.value
      })

      this.state = newState
    } else {
      this.state = {
        author: null,
        attribution_source: null,
        attribution_source_url: null,
        attribution_copyright: null,
        attribution_licence: null,
        default_gravity: '',
        alt: null,
        description: null,
        preview_duration: 30,
        sensitive_content: false,
        tags: []
      }
    }
  }

  componentDidMount () {
    this.listenOnMessageBus()
  }

  componentWillUnmount () {
    this.stopListeningOnMessageBus()
  }

  componentDidUpdate (prevProps) {
    if (this.props.fileModal.file) {
      if (!prevProps.fileModal.file || (prevProps.fileModal.updating && this.props.fileModal.updating === false)) {
        const newState = {
          author: this.props.fileModal.file.attributes.author,
          attribution_source: this.props.fileModal.file.attributes.attribution_source,
          attribution_source_url: this.props.fileModal.file.attributes.attribution_source_url,
          attribution_copyright: this.props.fileModal.file.attributes.attribution_copyright,
          attribution_licence: this.props.fileModal.file.attributes.attribution_licence,
          alt: this.props.fileModal.file.attributes.alt,
          default_gravity: this.props.fileModal.file.attributes.default_gravity,
          description: this.props.fileModal.file.attributes.description,
          preview_duration: this.props.fileModal.file.attributes.preview_duration,
          sensitive_content: this.props.fileModal.file.attributes.sensitive_content,
          tags: this.props.fileModal.file.attributes.tags
        }

        this.props.fileModal.file.attributes.file_modal_additional_fields.forEach((field) => {
          newState[field.name] = field.value
        })

        this.setState({
          ...this.state,
          ...newState
        })
      }
    }
  }

  listenOnMessageBus () {
    if (!window.Folio.MessageBus.callbacks) return

    this.messageBusCallbackKey = `Folio::GenerateThumbnailJob-react-files-app-file-modal-${uniqueId()}`

    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (msg) => {
      if (!msg) return
      if (!this.props.fileModal.file) return

      if (msg.type === 'Folio::S3::CreateFileJob' && msg.data.file) {
        if (Number(msg.data.file.id) === Number(this.props.fileModal.file.id)) {
          if (msg.data.type === 'replace-success') {
            this.props.dispatch(updatedFileModalFile(msg.data.file))
            this.props.dispatch(updatedFiles(this.props.fileModal.fileType, [msg.data.file]))
            this.props.dispatch(uploadNewFileInsteadSuccess(msg.data.file))
          } else if (msg.data.type === 'replace-failure') {
            window.FolioConsole.Flash.alert(msg.data.errors.join('<br>'))
            this.props.dispatch(uploadNewFileInsteadFailure(this.props.fileModal.file))
          }
        }
      }
    }
  }

  stopListeningOnMessageBus () {
    delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
    this.messageBusCallbackKey = null
  }

  saveModal = () => {
    const { fileModal } = this.props

    this.props.dispatch(markModalFileAsUpdating(fileModal.file))
    this.props.dispatch(updateFile(this.props.fileModal.fileType, this.props.fileModal.filesUrl, fileModal.file, this.state))
  }

  closeFileModal = () => {
    this.props.dispatch(closeFileModal())
  }

  updateThumbnail = (thumbKey, params) => {
    this.props.dispatch(updateFileThumbnail(this.props.fileModal.fileType,
      this.props.fileModal.filesUrl,
      this.props.fileModal.file,
      thumbKey,
      params))
  }

  destroyThumbnail = (thumbKey, thumb) => {
    this.props.dispatch(destroyFileThumbnail(
      this.props.fileModal.fileType,
      this.props.fileModal.filesUrl,
      this.props.fileModal.file,
      thumbKey,
      thumb
    ))
  }

  deleteFile = (file) => {
    this.closeFileModal()
    this.props.dispatch(deleteFile(this.props.fileModal.fileType, this.props.fileModal.filesUrl, file))
  }

  uploadNewFileInstead = (fileIo) => {
    this.props.dispatch(uploadNewFileInstead(this.props.fileModal.fileType, this.props.fileModal.filesUrl, this.props.fileModal.file, fileIo))
  }

  changeFilePlacementsPage = (page) => {
    this.props.dispatch(changeFilePlacementsPage(this.props.fileModal.file, page))
  }

  onTagsChange = (tags) => {
    this.setState({ ...this.state, tags })
  }

  onValueChange = (key, value) => {
    this.setState({ ...this.state, [key]: value })
  }

  extractMetadata = () => {
    this.props.dispatch(extractMetadata(this.props.fileModal.fileType, this.props.fileModal.filesUrl, this.props.fileModal.file))
  }

  render () {
    const { fileModal, readOnly, canDestroyFiles, taggable } = this.props
    const isOpen = fileModal.file !== null

    return (
      <ReactModal
        isOpen={isOpen}
        onRequestClose={this.closeFileModal}
        className='ReactModal ReactModal--FileModal'
      >
        {fileModal.file && (
          <FileModalFile
            fileModal={fileModal}
            taggable={taggable}
            onTagsChange={this.onTagsChange}
            saveModal={this.saveModal}
            closeFileModal={this.closeFileModal}
            updateThumbnail={this.updateThumbnail}
            destroyThumbnail={this.destroyThumbnail}
            canDestroyFiles={canDestroyFiles}
            deleteFile={this.deleteFile}
            uploadNewFileInstead={this.uploadNewFileInstead}
            onValueChange={this.onValueChange}
            formState={this.state}
            changeFilePlacementsPage={this.changeFilePlacementsPage}
            readOnly={readOnly}
            autoFocusField={fileModal.autoFocusField}
            extractMetadata={this.extractMetadata}
            isExtractingMetadata={fileModal.extractingMetadata}
          />
        )}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state, props) => ({
  fileModal: fileModalSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileModal)
