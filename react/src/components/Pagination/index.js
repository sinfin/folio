import React from 'react'
import { unescape } from 'lodash'

import DisplayButtons from 'containers/DisplayButtons'

import PaginationWrap from './styled/PaginationWrap'

const makeOnClick = (number, changePage) => (e) => {
  e.preventDefault()
  e.stopPropagation()
  changePage(number)
}

function paginationInfo (pagination) {
  if (pagination.count === 0) {
    return window.FolioConsole.translations.paginationEmpty
  } else {
    return unescape(window.FolioConsole.translations.paginationInfo).replace('%{from}', pagination.from).replace('%{to}', pagination.to).replace('%{count}', pagination.count)
  }
}

function PaginationComponent ({ changePage, pagination, setCardsDisplay, setThumbsDisplay, display, fileTypeIsImage }) {
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

  const prevActive = prev !== active
  const nextActive = next !== active

  return (
    <PaginationWrap single={max === 1} className='d-sm-flex'>
      <div className='f-c-pagination d-md-flex flex-wrap align-items-center pb-0 flex-grow-1'>
        <div
          className='mr-md-auto my-2 pr-md-g small text-center text-md-left'
          dangerouslySetInnerHTML={{ __html: paginationInfo(pagination) }}
        />

        {max !== 1 && (
          <div className='my-2'>
            <div className='f-c-pagination__nav'>
              <div className={`f-c-pagination__page f-c-pagination__page--with-ico ${prevActive ? 'f-c-pagination__page--disabled' : ''}`}>
                {prevActive ? (
                  <a href='#1' onClick={makeOnClick(1, changePage)}>
                    <span className='f-c-pagination__ico fa fa-fast-backward' />
                  </a>
                ) : (
                  <span className='f-c-pagination__ico fa fa-fast-backward' />
                )}
              </div>

              <div className={`f-c-pagination__page f-c-pagination__page--with-ico ${prevActive ? 'f-c-pagination__page--disabled' : ''}`}>
                {prevActive ? (
                  <a href={`#${prev}`} onClick={makeOnClick(prev, changePage)}>
                    <span className='f-c-pagination__ico fa fa-step-backward' />
                  </a>
                ) : (
                  <span className='f-c-pagination__ico fa fa-step-backward' />
                )}
              </div>

              {numbers.map((number) => (
                <div className={`f-c-pagination__page f-c-pagination__page--page ${number === active ? 'f-c-pagination__page--current' : ''} ${(number === 'a' || number === 'b') ? 'f-c-pagination__page--gap' : ''}`} key={number}>
                  {number === 'a' || number === 'b' ? (
                    <span>&hellip;</span>
                  ) : (
                    number === active ? number : (
                      <a href={`#${number}`} onClick={makeOnClick(number, changePage)}>
                        {number}
                      </a>
                    )
                  )}
                </div>
              ))}

              <div className={`f-c-pagination__page f-c-pagination__page--with-ico ${nextActive ? 'f-c-pagination__page--disabled' : ''}`}>
                {nextActive ? (
                  <a href={`#${next}`} onClick={makeOnClick(next, changePage)}>
                    <span className='f-c-pagination__ico fa fa-step-forward' />
                  </a>
                ) : (
                  <span className='f-c-pagination__ico fa fa-step-forward' />
                )}
              </div>

              <div className={`f-c-pagination__page f-c-pagination__page--with-ico ${nextActive ? 'f-c-pagination__page--disabled' : ''}`}>
                {nextActive ? (
                  <a href='#1' onClick={makeOnClick(max, changePage)}>
                    <span className='f-c-pagination__ico fa fa-fast-forward' />
                  </a>
                ) : (
                  <span className='f-c-pagination__ico fa fa-fast-forward' />
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {fileTypeIsImage && (
        <div className='ml-auto mr-auto ml-sm-g mr-sm-0 text-center my-2 my-sm-0'>
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
