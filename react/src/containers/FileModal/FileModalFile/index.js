import React from 'react'

import TagsInput from 'components/TagsInput'
import ThumbnailSizes from 'components/ThumbnailSizes'

import MainImage from './styled/MainImage'

export default ({ fileModal, onTagsChange, closeFileModal, saveModal, updateThumbnail, tags }) => {
  const isImage = fileModal.filesKey === 'images'
  let download = fileModal.file.attributes.file_name
  if (download.indexOf('.') === -1) { download = undefined }

  return (
    <div className='modal-content'>
      <div className='modal-header'>
        <strong className='modal-title'>{fileModal.file.attributes.file_name}</strong>
        <button type='button' className='close' onClick={closeFileModal}>×</button>
      </div>

      <div className='modal-body mb-n3'>
        <div className={isImage ? 'row' : undefined}>
          {isImage && (
            <div className='col-lg-7 mb-3'>
              <div className='d-flex align-items-center justify-content-center' style={{ backgroundColor: fileModal.file.attributes.dominant_color }}>
                <MainImage src={fileModal.file.attributes.source_url} />
              </div>

              <div className='mt-2 small'>{fileModal.file.attributes.file_width}×{fileModal.file.attributes.file_height} px</div>

              <ThumbnailSizes file={fileModal.file} updateThumbnail={updateThumbnail} />
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

              <button className='btn btn-secondary mr-2 mb-2' type='button'>
                <span className='fa fa-edit mr-0 mr-sm-2' />
                <span className='d-none d-sm-inline'>{window.FolioConsole.translations.replace}</span>
              </button>

              <button className='btn btn-danger mb-2' type='button'>
                <span className='fa fa-trash-alt mr-0 mr-sm-2' />
                <span className='d-none d-sm-inline font-weight-bold'>{window.FolioConsole.translations.destroy}</span>
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

            <button type='button' className='btn btn-primary px-4' onClick={saveModal}>
              {window.FolioConsole.translations.save}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
