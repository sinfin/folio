import React from 'react'

import SingleSelectTrigger from 'components/SingleSelectTrigger'

export default function SingleAttachments ({ attachments, atom, remove, index, openFileModal }) {
  return (
    <React.Fragment>
      {attachments.map((attachmentType) => (
        attachmentType.plural ? null : (
          <SingleSelectTrigger
            key={attachmentType.key}
            attachmentType={attachmentType}
            data={atom[attachmentType.key]}
            index={index}
            remove={() => remove(index, attachmentType.key)}
            openFileModal={openFileModal}
          />
        )
      ))}
    </React.Fragment>
  )
}
