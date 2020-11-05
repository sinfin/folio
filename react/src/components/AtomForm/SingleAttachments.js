import React from 'react'

import SingleSelectTrigger from 'components/SingleSelectTrigger'
import SingleAttachmentsWrap from './styled/SingleAttachmentsWrap'

export default function SingleAttachments ({ attachments, atom, remove, index, openFileModal }) {
  return (
    <SingleAttachmentsWrap>
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
    </SingleAttachmentsWrap>
  )
}
