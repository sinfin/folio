import React from 'react'

import FolioConsoleFilePicker from 'components/FolioConsoleFilePicker'

export default function SingleAttachments ({ index, attachments, atom, usageRecord, updateFormAtomAttachment, removeFormAtomAttachment }) {
  return (
    <React.Fragment>
      {attachments.map((attachmentType) => (
        attachmentType.plural ? null : (
          <FolioConsoleFilePicker
            key={attachmentType.key}
            attachmentType={attachmentType}
            usageRecord={usageRecord}
            file={atom[attachmentType.key] ? atom[attachmentType.key].file : undefined}
            update={(file) => updateFormAtomAttachment(index, attachmentType.key, file)}
            remove={() => removeFormAtomAttachment(index, attachmentType.key)}
          />
        )
      ))}
    </React.Fragment>
  )
}
