import React from 'react'

import MultiSelect from 'containers/MultiSelect'
import fileTypeToKey from 'utils/fileTypeToKey'

export default function MultiAttachments ({ attachments }) {
  return (
    <React.Fragment>
      {attachments.map((attachmentType) => (
        attachmentType.plural ? (
          <div className='mt-4' key={attachmentType.key}>
            <MultiSelect
              filesKey={fileTypeToKey(attachmentType['file_type'])}
              shouldLoadFiles
            />
          </div>
        ) : null
      ))}
    </React.Fragment>
  )
}
