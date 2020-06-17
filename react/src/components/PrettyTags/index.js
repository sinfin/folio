import React from 'react'

function PrettyTags ({ tags }) {
  return (
    <div className='f-c-pretty-tags'>
      {tags.map((tag) => (
        <span className='f-c-pretty-tags__tag' key={tag}>
          {tag}
        </span>
      ))}
    </div>
  )
}

export default PrettyTags
