import React from 'react'
import { FormGroup, Label } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import { makeConfirmed } from 'utils/confirmed'

import TagsInput from 'components/TagsInput'
import ThumbnailSizes from 'components/ThumbnailSizes'
import FileUsage from 'components/FileUsage'
import PrettyTags from 'components/PrettyTags'
import AutocompleteInput from 'components/AutocompleteInput'

import { AUTHOR_AUTOCOMPLETE_URL } from 'constants/urls'

import MainImage from './styled/MainImage'
import MainImageOuter from './styled/MainImageOuter'
import MainImageInner from './styled/MainImageInner'
import FileEditInput from './styled/FileEditInput'

export default ({ formState, uploadNewFileInstead, onValueChange, deleteFile, fileModal, onTagsChange, closeFileModal, saveModal, updateThumbnail, readOnly, changeFilePlacementsPage }) => {
  const file = fileModal.file
  const isImage = file.attributes.react_type === 'image'
  let download = file.attributes.file_name
  if (download.indexOf('.') === -1) { download = undefined }

  const indestructible = !!file.attributes.file_placements_size
  const notAllowedCursor = indestructible ? 'cursor-not-allowed' : ''
  const onDeleteClick = indestructible ? undefined : makeConfirmed(() => deleteFile(file))

  const onEditClick = (e) => {
    if (!window.confirm(window.FolioConsole.translations.confirmation)) {
      e.preventDefault()
    }
  }

  return (
    <div className='modal-content'>
      <div className='modal-header'>
        <strong className='modal-title'>{file.attributes.file_name}</strong>
        <button type='button' className='close' onClick={closeFileModal}>×</button>
      </div>

      <div className='modal-body'>
        <div className={isImage ? 'row' : undefined}>
          {isImage && (
            <div className='col-lg-7 mb-3'>
              <MainImageOuter>
                <div style={{
                  backgroundColor: file.attributes.dominant_color,
                  paddingTop: `${100 * file.attributes.file_height / file.attributes.file_width}%`
                }} />

                <MainImageInner>
                  <MainImage src={file.attributes.source_url} />
                </MainImageInner>
              </MainImageOuter>

              <div className='mt-2 small'>{file.attributes.file_width}×{file.attributes.file_height} px</div>
            </div>
          )}
          <div className={isImage ? 'col-lg-5 mb-3' : undefined}>
            <div className='d-flex flex-wrap mb-2'>
              <a
                href={file.attributes.source_url}
                className='btn btn-secondary mr-2 mb-2'
                target='_blank'
                rel='noopener noreferrer'
                download={download}
              >
                <span className='fa fa-download mr-0 mr-sm-2' />
                <span className='d-none d-sm-inline'>{window.FolioConsole.translations.downloadOriginal}</span>
              </a>

              {!readOnly && (
                <div className='btn btn-secondary mr-2 mb-2 position-relative overflow-hidden'>
                  <span className='fa fa-edit mr-0 mr-sm-2' />
                  <span className='d-none d-sm-inline'>{window.FolioConsole.translations.replace}</span>

                  <FileEditInput type='file' onClick={onEditClick} onChange={(e) => uploadNewFileInstead(e.target.files[0])} />
                </div>
              )}

              {!readOnly && (
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
              )}
            </div>

            <FormGroup>
              <Label>{window.FolioConsole.translations.fileAuthor}</Label>
              {readOnly ? (
                formState.author ? <p className='m-0'>{formState.author}</p> : <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
              ) : (
                <AutocompleteInput
                  value={formState.author || ''}
                  onChange={(e) => onValueChange('author', e.currentTarget.value)}
                  name='author'
                  url={AUTHOR_AUTOCOMPLETE_URL}
                />
              )}
            </FormGroup>

            <div className='form-group string optional file_tag_list'>
              <label className='control-label string optional'>
                {window.FolioConsole.translations.tagsLabel}
              </label>

              {readOnly ? (
                formState.tags.length ? (
                  <PrettyTags tags={formState.tags} />
                ) : (
                  <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
                )
              ) : (
                <React.Fragment>
                  <TagsInput
                    value={formState.tags}
                    onTagsChange={onTagsChange}
                    submit={saveModal}
                    noAutofocus
                  />

                  <small className='form-text'>
                    {window.FolioConsole.translations.tagsHint}
                  </small>
                </React.Fragment>
              )}
            </div>

            <FormGroup>
              <Label>{window.FolioConsole.translations.fileDescription}</Label>
              {readOnly ? (
                formState.description ? <p className='m-0'>{formState.description}</p> : <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
              ) : (
                <TextareaAutosize
                  name='description'
                  value={formState.description || ''}
                  onChange={(e) => onValueChange('description', e.currentTarget.value)}
                  type='text'
                  className='form-control'
                  rows={3}
                  async
                />
              )}
            </FormGroup>

            {!readOnly && (
              <button type='button' className='btn btn-primary px-4' onClick={saveModal}>
                {window.FolioConsole.translations.save}
              </button>
            )}
          </div>
        </div>

        <div className={isImage ? 'row mt-3' : 'mt-3'}>
          {isImage && (
            <div className='col-lg-7 mb-3'>
              <ThumbnailSizes file={file} updateThumbnail={updateThumbnail} />
            </div>
          )}

          <div className={isImage ? 'col-lg-5 mb-3' : undefined}>
            <FileUsage filePlacements={fileModal.filePlacements} changeFilePlacementsPage={changeFilePlacementsPage} />
          </div>
        </div>
      </div>

      {(fileModal.updating || fileModal.uploadingNew) && <span className='folio-loader' />}
    </div>
  )
}
