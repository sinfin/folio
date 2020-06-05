import React from 'react'

import TagsInput from 'components/TagsInput'

export default ({ fileModal, onTagsChange, closeFileModal, saveModal, tags }) => {
  const isImage = fileModal.filesKey === 'images'
  let download = fileModal.file.attributes.file_name
  if (download.indexOf('.') === -1) { download = undefined }

  return (
    <div className='modal-content'>
      <div className='modal-header'>
        <strong className='modal-title'>{fileModal.file.attributes.file_name}</strong>
        <button type='button' className='close' onClick={closeFileModal}>×</button>
      </div>

      <div className='modal-body'>
        <div className={isImage ? 'row' : undefined}>
          {isImage && (
            <div className='col-lg-7' />
          )}
          <div className={isImage ? 'col-lg-5' : undefined}>
            <div className='d-flex flex-wrap mb-3'>
              <a
                href={fileModal.file.attributes.source_url}
                className='btn btn-secondary mr-sm-2'
                target='_blank'
                rel='noopener noreferrer'
                download={download}
              >
                <span className='fa fa-download' />
                {window.FolioConsole.translations.downloadOriginal}
              </a>

              <button className='btn btn-secondary mr-sm-2' type='button'>
                <span className='fa fa-edit' />
                {window.FolioConsole.translations.replace}
              </button>

              <button className='btn btn-danger font-weight-bold1' type='button'>
                <span className='fa fa-trash-alt' />
                {window.FolioConsole.translations.destroy}
              </button>
            </div>

            <div className='form-group string optional file_tag_list'>
              <label className='control-label string optional'>
                {window.FolioConsole.translations.tagsLabel}
              </label>

              <TagsInput
                value={fileModal.newTags || fileModal.file.attributes.tags}
                options={tags}
                onTagsChange={onTagsChange}
                submit={saveModal}
              />

              <small className='form-text'>
                {window.FolioConsole.translations.tagsHint}
              </small>
            </div>
          </div>
        </div>
      </div>

      <div className='modal-footer'>
        <button type='button' className='btn btn-secondary' onClick={closeFileModal}>
          {window.FolioConsole.translations.cancel}
        </button>

        <button type='button' className='btn btn-primary' onClick={saveModal}>
          {window.FolioConsole.translations.save}
        </button>
      </div>
    </div>
  )
}
