import React from 'react'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
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
        <FolioConsoleUiButton
          href={editURL}
          variant='secondary'
          icon='edit'
        />

        {node.destroy_url && <FolioConsoleUiButton
          icon='delete'
          variant='danger'
          data-confirm={window.FolioConsole.translations.removePrompt}
          data-method='delete'
          href={node.destroy_url}
        />}
      </div>
    </AncestryItemWrap>
  )
}

export default AncestryItem
