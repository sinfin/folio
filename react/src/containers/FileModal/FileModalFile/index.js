import React from 'react'
import { FormGroup, Label, Input } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import { makeConfirmed } from 'utils/confirmed'

import TagsInput from 'components/TagsInput'
import ThumbnailSizes from 'components/ThumbnailSizes'
import FileUsage from 'components/FileUsage'

import MainImage from './styled/MainImage'
import FileEditInput from './styled/FileEditInput'

export default ({ formState, uploadNewFileInstead, onValueChange, deleteFile, fileModal, onTagsChange, closeFileModal, saveModal, updateThumbnail, tags }) => {
  const isImage = fileModal.filesKey === 'images'
  let download = fileModal.file.attributes.file_name
  if (download.indexOf('.') === -1) { download = undefined }

  const indestructible = !!fileModal.file.attributes.file_placements_count
  const notAllowedCursor = indestructible ? 'cursor-not-allowed' : ''
  const onDeleteClick = indestructible ? undefined : makeConfirmed(() => deleteFile(fileModal.file))

  const onEditClick = (e) => {
    if (!window.confirm(window.FolioConsole.translations.confirmation)) {
      e.preventDefault()
    }
  }

  return (
    <div className='modal-content'>
      <div className='modal-header'>
        <strong className='modal-title'>{fileModal.file.attributes.file_name}</strong>
        <button type='button' className='close' onClick={closeFileModal}>×</button>
      </div>

      <div className='modal-body'>
        <div className={isImage ? 'row' : undefined}>
          {isImage && (
            <div className='col-lg-7 mb-3'>
              <div className='d-flex align-items-center justify-content-center' style={{ backgroundColor: fileModal.file.attributes.dominant_color }}>
                <MainImage src={fileModal.file.attributes.source_url} />
              </div>

              <div className='mt-2 small'>{fileModal.file.attributes.file_width}×{fileModal.file.attributes.file_height} px</div>
            </div>
          )}
          <div className={isImage ? 'col-lg-5 mb-3' : undefined}>
            <div className='d-flex flex-wrap mb-2'>
              <a
                href={fileModal.file.attributes.source_url}
                className='btn btn-secondary mr-2 mb-2'
                target='_blank'
                rel='noopener noreferrer'
                download={download}
              >
                <span className='fa fa-download mr-0 mr-sm-2' />
                <span className='d-none d-sm-inline'>{window.FolioConsole.translations.downloadOriginal}</span>
              </a>

              <div className='btn btn-secondary mr-2 mb-2 position-relative overflow-hidden'>
                <span className='fa fa-edit mr-0 mr-sm-2' />
                <span className='d-none d-sm-inline'>{window.FolioConsole.translations.replace}</span>

                <FileEditInput type='file' onClick={onEditClick} onChange={(e) => uploadNewFileInstead(e.target.files[0])} />
              </div>

              <button
                className={`btn btn-danger mb-2 ${notAllowedCursor}`}
                type='button'
                onClick={onDeleteClick}
                disabled={indestructible}
                title={indestructible ? window.FolioConsole.translations.indestructibleFile : undefined}
              >
                <span className='fa fa-trash-alt mr-0 mr-sm-2' />
                <span className='d-none d-sm-inline font-weight-bold'>{window.FolioConsole.translations.destroy}</span>
              </button>
            </div>

            <FormGroup>
              <Label>{window.FolioConsole.translations.fileAuthor}</Label>
              <Input
                value={formState.author || ''}
                onChange={(e) => onValueChange('author', e.currentTarget.value)}
              />
            </FormGroup>

            <div className='form-group string optional file_tag_list'>
              <label className='control-label string optional'>
                {window.FolioConsole.translations.tagsLabel}
              </label>

              <TagsInput
                value={formState.tags}
                options={tags}
                onTagsChange={onTagsChange}
                submit={saveModal}
              />

              <small className='form-text'>
                {window.FolioConsole.translations.tagsHint}
              </small>
            </div>

            <FormGroup>
              <Label>{window.FolioConsole.translations.fileDescription}</Label>
              <TextareaAutosize
                name='description'
                value={formState.description || ''}
                onChange={(e) => onValueChange('description', e.currentTarget.value)}
                type='text'
                className='form-control'
                rows={3}
                async
              />
            </FormGroup>

            <button type='button' className='btn btn-primary px-4' onClick={saveModal}>
              {window.FolioConsole.translations.save}
            </button>
          </div>
        </div>

        <div className={isImage ? 'row mt-3' : 'mt-3'}>
          {isImage && (
            <div className='col-lg-7 mb-3'>
              <ThumbnailSizes file={fileModal.file} updateThumbnail={updateThumbnail} />
            </div>
          )}

          <div className={isImage ? 'col-lg-5 mb-3' : undefined}>
            <FileUsage file={fileModal.file} />
          </div>
        </div>
      </div>

      {(fileModal.updating || fileModal.uploadingNew) && <span className='folio-loader' />}
    </div>
  )
}
