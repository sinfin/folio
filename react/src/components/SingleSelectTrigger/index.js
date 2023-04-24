import React from 'react'
import { Button } from 'reactstrap'

import { EVENT_NAME } from 'containers/ModalSelect/ModalSingleSelect/constants'
import { FILE_TRIGGER_EVENT } from 'containers/Atoms/constants'
import FileHoverButtons from 'components/FileHoverButtons'
import SingleSelectTriggerWrap from './styled/SingleSelectTriggerWrap'
import Picture from 'components/Picture'

function triggerModal (fileType, data) {
  window.jQuery(document).trigger(`${EVENT_NAME}/${fileType}`, [data])
}

function SingleSelectTrigger ({ data, attachmentType, openFileModal, remove, index }) {
  const present = data && !data._destroy
  const filesUrl = attachmentType.files_url
  const asImage = present && data.file.attributes.human_type === 'image'
  const fileType = attachmentType.file_type

  const trigger = () => {
    const d = {
      index,
      triggerEvent: FILE_TRIGGER_EVENT,
      attachmentKey: attachmentType.key
    }
    triggerModal(attachmentType.file_type, d)
  }

  return (
    <SingleSelectTriggerWrap className='form-group folio-console-react-picker folio-console-react-picker--single'>
      <label className='folio-console-react-picker__label'>{attachmentType.label}</label>

      {present ? (
        <div className='folio-console-react-picker__files'>
          <div className='folio-console-thumbnail folio-console-thumbnail--image'>
            <div className='folio-console-thumbnail__inner'>
              <div className='folio-console-thumbnail__img-wrap cursor-pointer' onClick={trigger}>
                {asImage ? (
                  <Picture
                    file={data.file}
                    imageClassName='folio-console-thumbnail__img'
                    alt={data.file.attributes.file_name}
                  />
                ) : (
                  <strong className='folio-console-thumbnail__title'>
                    {data.file.attributes.file_name}
                  </strong>
                )}

                <FileHoverButtons
                  edit
                  onEdit={() => openFileModal(fileType, filesUrl, data.file)}
                  destroy
                  onDestroy={remove}
                />
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div>
          <Button color='success' onClick={trigger} className='px-3'>
            {window.FolioConsole.translations.add}
          </Button>
        </div>
      )}
    </SingleSelectTriggerWrap>
  )
}

export default SingleSelectTrigger
