import React from 'react'

import MultiAttachmentsSelect from './MultiAttachmentsSelect'

export default function MultiAttachments ({ atom, index, openFileModal }) {
  return (
    <React.Fragment>
      {atom.record.meta.attachments.map((attachmentType) => (
        attachmentType.plural ? (
          <div className='mt-4 position-relative z-index-1' key={attachmentType.key}>
            <MultiAttachmentsSelect
              attachmentType={attachmentType}
              atom={atom}
              index={index}
              openFileModal={openFileModal}
            />
          </div>
        ) : null
      ))}
    </React.Fragment>
  )
}
