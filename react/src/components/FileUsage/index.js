import React from 'react'
import { unescape } from 'lodash'

function FileUsage ({ file, updateThumbnail }) {
  const count = file.attributes.some_file_placements.length
  let hasMoreText = null

  if (count > 0 && file.attributes.file_placements_count && count < file.attributes.file_placements_count) {
    hasMoreText = unescape(window.FolioConsole.translations.paginationInfo).replace('%{from}', 1).replace('%{to}', count).replace('%{count}', file.attributes.file_placements_count)
  }

  return (
    <React.Fragment>
      <h4 className='mt-0'>{window.FolioConsole.translations.usage}</h4>

      {count > 0 ? (
        <div>
          <ul className='list-unstyled small mt-h'>
            {file.attributes.some_file_placements.map((filePlacement) => (
              <li key={filePlacement.id}>
                {filePlacement.url ? (
                  <a href={filePlacement.url} target='_blank' rel='noopener noreferrer'>{filePlacement.label}</a>
                ) : filePlacement.label}
              </li>
            ))}
          </ul>

          {hasMoreText && (
            <div className='small mt-2' dangerouslySetInnerHTML={{ __html: hasMoreText }} />
          )}
        </div>
      ) : (
        <p className='mt-h small'>{window.FolioConsole.translations.paginationEmpty}</p>
      )}
    </React.Fragment>
  )
}

export default FileUsage
