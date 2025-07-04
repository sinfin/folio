import React from 'react'
import { FormGroup, Label, Input } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import { makeConfirmed } from 'utils/confirmed'

import TagsInput from 'components/TagsInput'
import ThumbnailSizes from 'components/ThumbnailSizes'
import FileUsage from 'components/FileUsage'
import PrettyTags from 'components/PrettyTags'
import AutocompleteInput from 'components/AutocompleteInput'
import FolioPlayer from 'components/FolioPlayer'
import FolioConsoleUiButtons from 'components/FolioConsoleUiButtons'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import FolioUiIcon from 'components/FolioUiIcon'

import { fileFieldAutocompleteUrl } from 'constants/urls'

import AdditionalHtmlFromApi from './AdditionalHtmlFromApi'

import MainImage from './styled/MainImage'
import MainImageOuter from './styled/MainImageOuter'
import MainImageInner from './styled/MainImageInner'
import FileEditInput from './styled/FileEditInput'

export default ({ formState, uploadNewFileInstead, onValueChange, deleteFile, fileModal, onTagsChange, closeFileModal, saveModal, updateThumbnail, destroyThumbnail, readOnly, changeFilePlacementsPage, canDestroyFiles, taggable, autoFocusField }) => {
  const file = fileModal.file
  const isImage = file.attributes.human_type === 'image'
  const isAudio = file.attributes.human_type === 'audio'
  const isVideo = file.attributes.human_type === 'video'
  let download = file.attributes.file_name
  if (download.indexOf('.') === -1) { download = undefined }

  let indestructible = !!file.attributes.file_placements_size

  if (indestructible && !fileModal.filePlacements.loading && fileModal.filePlacements.records.length === 0) {
    indestructible = false
  }

  const notAllowedCursor = indestructible ? 'cursor-not-allowed' : ''
  const onDeleteClick = indestructible ? undefined : makeConfirmed(() => deleteFile(file))

  const onEditClick = (e) => {
    if (!window.confirm(window.FolioConsole.translations.confirmation)) {
      e.preventDefault()
    }
  }

  const additionalFields = file.attributes.file_modal_additional_fields

  return (
    <div className='modal-content'>
      <div className='modal-header'>
        <h3 className='modal-title'>{file.attributes.file_name}</h3>

        <button className='f-c-modal__close' type='button' onClick={closeFileModal}>
          <FolioUiIcon name='close' class='f-c-modal__close-icon' />
        </button>
      </div>

      <div className='modal-body'>
        <div className={(isImage || isVideo) ? 'row' : undefined}>
          {(isImage || isVideo) && (
            <div className='col-lg-6 mb-3'>
              {isImage ? (
                <div>
                  <MainImageOuter>
                    <div style={{ paddingTop: `${100 * file.attributes.file_height / file.attributes.file_width}%` }} />

                    <MainImageInner>
                      <MainImage src={file.attributes.source_url} />
                    </MainImageInner>
                  </MainImageOuter>

                  <div className='mt-2 small'>{file.attributes.file_width}×{file.attributes.file_height} px</div>
                </div>
              ) : (
                <div>
                  <div className='form-group'><FolioPlayer file={file} /></div>

                  <AdditionalHtmlFromApi apiUrl={file.attributes.additional_html_api_url} />
                </div>
              )}
            </div>
          )}
          <div className={(isImage || isVideo) ? 'col-lg-6 mb-3' : undefined}>
            <FolioConsoleUiButtons className='mb-3'>
              <FolioConsoleUiButton
                href={file.attributes.source_url}
                variant='secondary'
                target='_blank'
                rel='noopener noreferrer'
                download={download}
                icon='download'
                label={window.FolioConsole.translations.downloadOriginal}
              />

              {(canDestroyFiles && !readOnly) && (
                <FolioConsoleUiButton
                  class='overflow-hidden position-relative'
                  icon='edit'
                  variant='warning'
                  label={window.FolioConsole.translations.replace}
                >
                  <FileEditInput type='file' onClick={onEditClick} onChange={(e) => uploadNewFileInstead(e.target.files[0])} />
                </FolioConsoleUiButton>
              )}

              {(canDestroyFiles && !readOnly) && (
                <FolioConsoleUiButton
                  class={notAllowedCursor}
                  onClick={onDeleteClick}
                  disabled={indestructible}
                  title={indestructible ? window.FolioConsole.translations.indestructibleFile : undefined}
                  variant='danger'
                  icon='delete'
                  label={window.FolioConsole.translations.destroy}
                />
              )}
            </FolioConsoleUiButtons>

            <p>ID: {file.attributes.id}</p>

            {file.attributes.imported_from_photo_archive && (
              <p>{window.FolioConsole.translations.importedFromPhotoArchive}</p>
            )}

            <p className='mb-1'>{window.FolioConsole.translations.state}:</p>

            <div className='f-c-state mb-3'>
              <div className='f-c-state__state'>
                <div className={`f-c-state__state-square f-c-state__state-square--color-${file.attributes.aasm_state_color}`} />
                {file.attributes.aasm_state_human}
              </div>
            </div>

            {isAudio && <div className='form-group'><FolioPlayer file={file} /></div>}

            {
              ['author', 'attribution_source', 'attribution_source_url', 'attribution_copyright', 'attribution_licence'].map((field) => (
                <FormGroup key={field}>
                  <Label className='form-label'>{window.FolioConsole.translations[`file/${field}`]}</Label>

                  {readOnly ? (
                    formState[field] ? <p className='m-0'>{formState[field]}</p> : <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
                  ) : (
                    <AutocompleteInput
                      value={formState[field] || ''}
                      onChange={(e) => onValueChange(field, e.currentTarget.value)}
                      name={field}
                      url={fileFieldAutocompleteUrl(field)}
                    />
                  )}
                </FormGroup>
              ))
            }

            <FormGroup>
              <Label className='form-label'>{window.FolioConsole.translations.fileDescription}</Label>
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

            {
              isImage && (
                <FormGroup>
                  <Label className='form-label'>Alt</Label>
                  {readOnly ? (
                    formState.alt ? <p className='m-0'>{formState.alt}</p> : <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
                  ) : (
                    <Input
                      name='alt'
                      value={formState.alt || ''}
                      onChange={(e) => onValueChange('alt', e.currentTarget.value)}
                      className='form-control'
                      autoFocus={autoFocusField === 'alt'}
                    />
                  )}
                </FormGroup>
              )
            }

            {taggable && (
              <div className='form-group string optional file_tag_list'>
                <label className='form-label string optional'>
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
                      dataTestId='file-tags'
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
            )}

            {additionalFields.map((additionalField) => (
              <FormGroup key={additionalField.name}>
                <Label className='form-label'>{additionalField.label}</Label>
                {readOnly ? (
                  <p className='m-0'>{formState[additionalField.name]}</p>
                ) : (
                  additionalField.type === 'text' ? (
                    <TextareaAutosize
                      name={additionalField.name}
                      value={formState[additionalField.name]}
                      onChange={(e) => onValueChange(additionalField.name, e.currentTarget.value)}
                      type='text'
                      className='form-control'
                      rows={3}
                      maxRows={10}
                      async
                    />
                  ) : (
                    additionalField.type === 'select' ? (
                      <Input
                        value={formState[additionalField.name]}
                        onChange={(e) => onValueChange(additionalField.name, e.currentTarget.value)}
                        name={additionalField.name}
                        type='select'
                        className='select'
                      >
                        {additionalField.collection.map((opt) => (
                          <option value={opt[1]} key={opt[1] || '_blank'}>
                            {opt[0]}
                          </option>
                        ))}
                      </Input>

                    ) : (
                      <Input
                        value={formState[additionalField.name]}
                        onChange={(e) => onValueChange(additionalField.name, e.currentTarget.value)}
                        name={additionalField.name}
                      />
                    )
                  )
                )}
              </FormGroup>
            ))}

            {
              isImage && (
                <FormGroup>
                  <Label className='form-label'>{window.FolioConsole.translations.fileDefaultGravity}</Label>
                  {readOnly ? (
                    <p className='m-0'>{formState.default_gravity}</p>
                  ) : (
                    <Input
                      value={formState.default_gravity || file.attributes.default_gravities_for_select[0][1]}
                      onChange={(e) => onValueChange('default_gravity', e.currentTarget.value)}
                      name='default_gravity'
                      type='select'
                      className='select'
                    >
                      {file.attributes.default_gravities_for_select.map((opt) => (
                        <option value={opt[1]} key={opt[1]}>
                          {opt[0]}
                        </option>
                      ))}
                    </Input>
                  )}
                </FormGroup>
              )
            }

            {
              typeof file.attributes.preview_duration === 'number' && (
                <FormGroup>
                  <Label className='form-label'>{window.FolioConsole.translations.filePreviewDuration}</Label>
                  {readOnly ? (
                    <p className='m-0'>{formState.preview_duration}</p>
                  ) : (
                    <Input
                      value={formState.preview_duration || 30}
                      onChange={(e) => onValueChange('preview_duration', e.currentTarget.value)}
                      name='preview_duration'
                      type='number'
                    />
                  )}
                </FormGroup>
              )
            }

            {readOnly ? (
              formState.sensitiveContent ? <p>{window.FolioConsole.translations.fileSensitiveContent}</p> : null
            ) : (
              <FormGroup>
                <FormGroup check>
                  <Label className='form-label' check>
                    <Input
                      type='checkbox'
                      name='sensitive_content'
                      onChange={(e) => onValueChange('sensitive_content', e.currentTarget.checked)}
                      checked={formState.sensitive_content}
                    />
                    {' '}
                    {window.FolioConsole.translations.fileSensitiveContent}
                  </Label>
                </FormGroup>
              </FormGroup>
            )}

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
              <ThumbnailSizes
                file={file}
                updateThumbnail={updateThumbnail}
                destroyThumbnail={destroyThumbnail}
              />
            </div>
          )}

          <div className={isImage ? 'col-lg-5 mb-3' : undefined}>
            <FileUsage filePlacements={fileModal.filePlacements} changeFilePlacementsPage={changeFilePlacementsPage} />
          </div>
        </div>
      </div>

      {file.attributes.bottom_html_api_url ? (
        <div className="modal-body">
          <AdditionalHtmlFromApi apiUrl={file.attributes.bottom_html_api_url} />
        </div>
      ) : null}

      {(fileModal.updating || fileModal.uploadingNew) && <span className='folio-loader' />}
    </div>
  )
}
