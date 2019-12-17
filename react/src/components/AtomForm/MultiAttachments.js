import React from 'react'

import MultiAttachmentsSelect from './MultiAttachmentsSelect'

export default function MultiAttachments ({ atom, index }) {
  return (
    <React.Fragment>
      {atom.record.meta.attachments.map((attachmentType) => (
        attachmentType.plural ? (
          <div className='mt-4' key={attachmentType.key}>
            <MultiAttachmentsSelect
              attachmentType={attachmentType}
              atom={atom}
              index={index}
            />
          </div>
        ) : null
      ))}
    </React.Fragment>
  )
}
