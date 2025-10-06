(() => {
  const setData = (data) => {
    console.log('setData', data)
  }

  window.addEventListener('message', (e) => {
    if (e.origin !== window.origin) return
    if (!e.data) return

    switch (e.data.type) {
      case 'f-embed:set-data':
        setData(e.data.folioEmbedData)
        break
    }
  })

  window.parent.postMessage({ type: 'f-embed:javascript-evaluated' }, window.origin)
})()
