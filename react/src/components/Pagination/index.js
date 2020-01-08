import React from 'react'
import { Pagination, PaginationItem, PaginationLink } from 'reactstrap'
import { unescape } from 'lodash'

import DisplayButtons from 'containers/DisplayButtons'

import PaginationWrap from './styled/PaginationWrap'

const makeOnClick = (number, changeFilesPage) => (e) => {
  e.preventDefault()
  e.stopPropagation()
  changeFilesPage(number)
}

function paginationInfo (pagination) {
  if (pagination.count === 0) {
    return window.FolioConsole.translations.paginationEmpty
  } else {
    return unescape(window.FolioConsole.translations.paginationInfo).replace('%{from}', pagination.from).replace('%{to}', pagination.to).replace('%{count}', pagination.count)
  }
}

function PaginationComponent ({ changeFilesPage, pagination, setCardsDisplay, setThumbsDisplay, display, fileTypeIsImage }) {
  const active = pagination.page
  const min = 1
  const max = pagination.pages

  const next = Math.min(max, active + 1)
  const prev = Math.max(min, active - 1)
  const numbers = [min]

  for (let i = active - 3; i < active + 3; i++) {
    if (i > min && i < max && numbers.indexOf(i) === -1) {
      if ((i === active - 3) && i > min + 1) {
        numbers.push('a')
      }

      numbers.push(i)

      if ((i === active + 2) && i + 1 < max) {
        numbers.push('b')
      }
    }
  }

  if (numbers.indexOf(max) === -1) {
    numbers.push(max)
  }

  return (
    <PaginationWrap single={max === 1}>
      <div className='f-c-pagination d-flex flex-wrap align-items-center pb-0 flex-grow-1'>
        <div
          className='mr-auto my-2 pr-g small'
          dangerouslySetInnerHTML={{ __html: paginationInfo(pagination) }}
        />

        {max !== 1 && (
          <div className='my-2'>
            <div className='pagy-bootstrap-nav pagination'>
              <Pagination>
                <PaginationItem disabled={prev === active}>
                  <PaginationLink href={`#${prev}`} onClick={makeOnClick(prev, changeFilesPage)}>{window.FolioConsole.translations['paginationPrev']}</PaginationLink>
                </PaginationItem>

                {numbers.map((number) => (
                  <PaginationItem key={number} active={number === active}>
                    {number === 'a' || number === 'b' ? (
                      <PaginationLink style={{ pointerEvents: 'none' }}>...</PaginationLink>
                    ) : (
                      <PaginationLink href={`#${number}`} onClick={makeOnClick(number, changeFilesPage)}>{number}</PaginationLink>
                    )}
                  </PaginationItem>
                ))}

                <PaginationItem disabled={next === active}>
                  <PaginationLink href={`#${next}`} onClick={makeOnClick(next, changeFilesPage)}>{window.FolioConsole.translations['paginationNext']}</PaginationLink>
                </PaginationItem>
              </Pagination>
            </div>
          </div>
        )}
      </div>

      {fileTypeIsImage && (
        <div className='ml-g'>
          <DisplayButtons
            display={display}
            setCardsDisplay={setCardsDisplay}
            setThumbsDisplay={setThumbsDisplay}
          />
        </div>
      )}
    </PaginationWrap>
  )
}

export default PaginationComponent
