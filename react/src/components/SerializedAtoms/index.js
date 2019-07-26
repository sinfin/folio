import React from 'react'

function SerializedAtom ({ atom, index, namespace }) {
  const prefix = `${namespace}[${index + 1}]`
  const { data, destroyed, id, meta, type } = atom

  return (
    <div>
      {id && <input type='hidden' name={`${prefix}[id]`} value={id} />}
      {destroyed ? <input type='hidden' name={`${prefix}[_destroy]`} value='1' /> : (
        <React.Fragment>
          <input type='hidden' name={`${prefix}[position]`} value={index + 1} />
          <input type='hidden' name={`${prefix}[type]`} value={type} />
          {Object.keys(meta.structure).map((key) => (
            <input key={key} type='hidden' name={`${prefix}[${key}]`} value={data[key]} />
          ))}
        </React.Fragment>
      )}
    </div>
  )
}

function SerializedAtoms ({ atoms, namespace }) {
  return (
    <div hidden>
      {atoms.map((atom, index) => (
        <SerializedAtom
          key={atom.id || atom.timestamp}
          atom={atom}
          index={index}
          namespace={namespace}
        />
      ))}
    </div>
  )
}

export { SerializedAtom }
export default SerializedAtoms
