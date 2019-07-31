import React from 'react'

function SerializedAtom ({ atom, index, namespace, position }) {
  const prefix = `${namespace}[${index + 1}]`
  const { data, _destroy, id, meta, type } = atom

  return (
    <div>
      {id && <input type='hidden' name={`${prefix}[id]`} value={id} />}
      {_destroy ? <input type='hidden' name={`${prefix}[_destroy]`} value='1' /> : (
        <React.Fragment>
          <input type='hidden' name={`${prefix}[position]`} value={position} />
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
  let position = 0

  return (
    <div hidden>
      {atoms.map((atom, index) => {
        if (!atom._destroy) position++

        return (
          <SerializedAtom
            key={atom.id || atom.timestamp}
            atom={atom}
            index={index}
            position={atom._destroy ? undefined : position}
            namespace={namespace}
          />
        )
      })}
    </div>
  )
}

export { SerializedAtom }
export default SerializedAtoms
