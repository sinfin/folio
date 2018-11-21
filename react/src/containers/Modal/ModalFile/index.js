import React, { Fragment } from 'react'

import TagsInput from 'components/TagsInput';

export default ({ modal, onTagsChange, cancelModal, saveModal }) => (
  <div className='modal-content'>
    <div className='modal-header'>
      <strong className='modal-title'>{modal.file.file_name}</strong>
      <button type='button' className='close'>×</button>
    </div>

    <div className='modal-body'>
      <div className='form-group string optional file_tag_list'>
        <label className='control-label string optional'>
          {window.FolioConsole.translations.tagsLabel}
        </label>

        <TagsInput
          value={modal.newTags || modal.file.tags}
          options={modal.file.tags}
          onTagsChange={onTagsChange}
        />

        <small className='form-text'>
          {window.FolioConsole.translations.tagsHint}
        </small>
      </div>
    </div>

    <div className='modal-footer'>
      <button type='button' className='btn btn-secondary' onClick={cancelModal}>
        {window.FolioConsole.translations.cancel}
      </button>

      <button type='button' className='btn btn-primary' onClick={saveModal}>
        {window.FolioConsole.translations.save}
      </button>
    </div>
  </div>
)
