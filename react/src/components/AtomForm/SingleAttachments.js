import React from 'react'

import SingleSelectTrigger from 'components/SingleSelectTrigger'

export default function SingleAttachments ({ attachments, atom, remove, index }) {
  return (
    <div className='d-flex'>
      {attachments.map((attachmentType) => (
        attachmentType.plural ? null : (
          <SingleSelectTrigger
            key={attachmentType.key}
            attachmentType={attachmentType}
            data={atom[attachmentType.key]}
            index={index}
            remove={() => remove(index, attachmentType.key)}
          />
        )
      ))}
    </div>
  )
}
