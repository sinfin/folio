import React from 'react'

export default function FolioPlayer ({ file }) {
  return (
    <div
      className={`f-player f-player--${file.attributes.human_type}`}
      data-controller='f-player'
      data-file={JSON.stringify(file)}
    />
  )
}
