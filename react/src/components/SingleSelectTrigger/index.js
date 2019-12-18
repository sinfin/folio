import React from 'react'
import { Button } from 'reactstrap'

import { EVENT_NAME } from 'containers/ModalSelect/ModalSingleSelect/constants'
import { FILE_TRIGGER_EVENT } from 'containers/Atoms/constants'
import SingleSelectTriggerWrap from './styled/SingleSelectTriggerWrap'

function triggerModal (fileType, data) {
  window.jQuery(document).trigger(`${EVENT_NAME}/${fileType}`, [data])
}

function SingleSelectTrigger ({ data, attachmentType, remove, index }) {
  const isDocument = attachmentType.file_type === 'Folio::Document'
  const trigger = () => {
    const d = {
      index,
      triggerEvent: FILE_TRIGGER_EVENT,
      attachmentKey: attachmentType.key
    }
    triggerModal(attachmentType.file_type, d)
  }

  const present = data && !data._destroy

  return (
    <SingleSelectTriggerWrap className='form-group folio-console-react-picker folio-console-react-picker--single'>
      <label className='folio-console-react-picker__label'>{attachmentType.label}</label>

      {present ? (
        <div className='folio-console-react-picker__files'>
          <div className='folio-console-thumbnail folio-console-thumbnail--image'>
            <div className='folio-console-thumbnail__inner'>
              <div className='folio-console-thumbnail__img-wrap'>

                {isDocument ? (
                  data.file.attributes.file_name
                ) : (
                  <img
                    src={data.file.attributes.thumb}
                    className='folio-console-thumbnail__img'
                    alt={data.file.attributes.file_name}
                  />
                )}

                <div className='folio-console-hover-destroy'>
                  <i className='fa fa-edit' onClick={trigger} />
                  <i className='fa fa-times-circle' onClick={remove} />
                </div>
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
