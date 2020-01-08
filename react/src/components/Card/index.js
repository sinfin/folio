import React from 'react'

function Card ({ highlighted, header, filters, children }) {
  return (
    <div className={`card ${highlighted ? 'card--highlighted' : ''}`}>
      {header && (
        <div className='card-header'>{header}</div>
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
