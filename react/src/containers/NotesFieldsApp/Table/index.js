import React from 'react'

import DueDate from './DueDate'

import FolioUiIcon from 'components/FolioUiIcon'

export default function Table ({
  notesForTable,
  editNote,
  removeNote,
  toggleClosedAt,
  currentlyEditting,
  currentlyEdittingUniqueId,
  changeDueDate
}) {
  return (
    <div className='f-c-r-notes-fields-app-table'>
      {notesForTable.map((note) => (
        <div
          className={`f-c-r-notes-fields-app-table__row ${currentlyEdittingUniqueId && currentlyEdittingUniqueId === note.uniqueId ? 'f-c-r-notes-fields-app-table__row--being-editted' : ''}`}
          key={note.uniqueId}
        >
          <input
            type='checkbox'
            className='f-c-r-notes-fields-app-table__checkbox mr-3'
            checked={note.attributes.closed_at !== null}
            onChange={() => toggleClosedAt(note)}
          />

          <div
            className='f-c-r-notes-fields-app-table__content mr-3'
            dangerouslySetInnerHTML={{ __html: note.attributes.content.replace(/\n/g, '<br>') }}
            onClick={() => editNote(note)}
          />

          <DueDate
            className='f-c-r-notes-fields-app-table__action mr-2'
            dueAt={note.attributes.due_at}
            onChange={(dueAt) => changeDueDate(note, dueAt)}
          />

          <FolioUiIcon
            class='f-c-r-notes-fields-app-table__action'
            name='edit'
            onClick={() => editNote(note)}
          />

          <FolioUiIcon
            class='f-c-r-notes-fields-app-table__action text-danger'
            name='close'
            onClick={() => removeNote(note)}
          />
        </div>
      ))}
    </div>
  )
}
