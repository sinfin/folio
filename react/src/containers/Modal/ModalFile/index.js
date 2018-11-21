import React, { Fragment } from 'react'

import TagsInput from 'components/TagsInput';

export default ({ modal, onTagsChange }) => (
  <Fragment>
    <h3>{modal.file.file_name}</h3>

    <div className="form-group string optional file_tag_list">
      <label className="control-label string optional">
        {window.FolioConsole.translations.tagsLabel}
      </label>

      <TagsInput
        value={modal.newTags || modal.file.tags}
        options={modal.file.tags}
        onTagsChange={onTagsChange}
      />

      <small className="form-text">
        {window.FolioConsole.translations.tagsHint}
      </small>
    </div>
  </Fragment>
)
