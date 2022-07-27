import React from 'react'

export default function CharacterCounter ({ value, hasHint }) {
  let count = 0
  if (value && value.length) count = value.length

  return (
    <span className='f-input-character-counter-wrap small'>
      <span className='f-input-character-counter-wrap__current'>{count}</span>
      {' '}
      {window.FolioConsole.translations.shortForCharacter}
    </span>
  )
}
