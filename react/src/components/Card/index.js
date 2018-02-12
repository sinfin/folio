import React from 'react'

function Card ({ highlighted, header, filters, children }) {
  return (
    <div className={`card ${highlighted ? 'card-active' : ''}`}>
      {header && (
        <div className='card-header'>{header}</div>
      )}

      {filters ? (
        <div className='list-group list-group-flush'>
          <div className='list-group-item'>
            {filters}
          </div>
        </div>
      ) : null}

      <div className='card-body'>{children}</div>
    </div>
  )
}

export default Card
