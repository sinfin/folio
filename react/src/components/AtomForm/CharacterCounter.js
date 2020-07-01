import React from 'react'

export default function CharacterCounter ({ value, hasHint }) {
  let count = 0
  if (value && value.length) count = value.length

  return (
    <span className='f-c-string-input-character-counter small'>
      <span className='f-c-string-input-character-counter__current'>{count}</span>
      {' '}
      {window.FolioConsole.translations.shortForCharacter}
    </span>
  )
}
