import React from 'react'

export default function FolioPlayer ({ file }) {
  return (
    <div
      className='f-player'
      data-controller='f-player'
      data-file={JSON.stringify(file)}
    />
  )
}
