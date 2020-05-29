import React from 'react'

import AncestryItemWrap from './styled/AncestryItemWrap'

function AncestryItem ({ node }) {
  const editURL = node.valid ? node.url : `${node.url}?prevalidate=1`

  return (
    <AncestryItemWrap invalid={!node.valid}>
      {node.valid ? null : (
        <span className='text-danger mi mr-2'>warning</span>
      )}

      <a href={editURL} className='mr-h'>{node.to_label}</a>

      <div className='f-c-index-actions'>
        <a // eslint-disable-line
          className='btn btn-secondary fa fa-edit'
          href={editURL}
        />

        {node.destroy_url && <a // eslint-disable-line
          className='btn btn-danger fa fa-trash-alt'
          data-confirm={window.FolioConsole.translations.removePrompt}
          data-method='delete'
          href={node.destroy_url}
        />}
      </div>
    </AncestryItemWrap>
  )
}

export default AncestryItem
