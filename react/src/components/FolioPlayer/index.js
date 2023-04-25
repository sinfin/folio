import React from 'react'

export default function FolioPlayer ({ file }) {
  return (
    <div
      className='f-player'
      data-controller='f-player'
      data-f-player-src-value={file.attributes.source_url}
      data-f-player-title-value={file.attributes.file_name}
      data-f-player-author-value={file.attributes.author}
    />
  )
}
