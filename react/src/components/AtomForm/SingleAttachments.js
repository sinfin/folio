import React from 'react'

import SingleSelectTrigger from 'components/SingleSelectTrigger'

export default function SingleAttachments ({ attachments, atom, remove }) {
  return (
    <div className='d-flex'>
      {attachments.map((attachmentType) => (
        attachmentType.plural ? null : (
          <SingleSelectTrigger
            key={attachmentType.key}
            attachmentType={attachmentType}
            data={atom[attachmentType.key]}
            remove={() => remove(attachmentType.key)}
          />
        )
      ))}
    </div>
  )
}
