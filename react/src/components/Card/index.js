import React from 'react'

import HeaderUploadButton from './HeaderUploadButton'

function Card ({ highlighted, header, headerUpload, filters, children }) {
  return (
    <div className={`card ${highlighted ? 'card--highlighted' : ''}`}>
      {header && (
        <div className='card-header card-header--flexy'>
          {header}
          {headerUpload && <HeaderUploadButton />}
        </div>
      )}

      {filters ? (
        <div className='list-group list-group-flush'>
          <div className='list-group-item bg-100'>
            {filters}
          </div>
        </div>
      ) : null}

      <div className='card-body'>{children}</div>
    </div>
  )
}

export default Card
