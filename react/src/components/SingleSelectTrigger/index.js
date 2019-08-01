import React from 'react'

import SingleSelectTriggerWrap from './styled/SingleSelectTriggerWrap'

function SingleSelectTrigger ({ data, attachmentType }) {
  const isDocument = attachmentType.file_type === 'Folio::Document'

  return (
    <SingleSelectTriggerWrap className='form-group folio-console-react-picker folio-console-react-picker--single'>
      <label className='folio-console-react-picker__label'>{attachmentType.label}</label>

      {data ? (
        <div className='folio-console-react-picker__files'>
          <div className='folio-console-thumbnail folio-console-thumbnail--image'>
            <div className='folio-console-thumbnail__inner'>
              <div className='folio-console-thumbnail__img-wrap'>

                {isDocument ? (
                  data.file.file_name
                ) : (
                  <img
                    src={data.file.thumb}
                    className='folio-console-thumbnail__img'
                    alt={data.file.file_name}
                  />
                )}

                <div className='folio-console-hover-destroy'>
                  <i className='fa fa-edit' />
                  <i className='fa fa-times-circle' />
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <p>nope</p>
      )}
    </SingleSelectTriggerWrap>
  )
}

export default SingleSelectTrigger
