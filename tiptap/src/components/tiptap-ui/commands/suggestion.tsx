import { computePosition } from '@floating-ui/dom'
import { ReactRenderer } from '@tiptap/react'

import { CommandsList } from './commands-list'

const defaultItems = [
  {
    title: 'Heading 1',
    command: ({ editor, range }) => {
      editor.chain().focus().deleteRange(range).setNode('heading', { level: 1 }).run()
    },
  },
  {
    title: 'Heading 2',
    command: ({ editor, range }) => {
      editor.chain().focus().deleteRange(range).setNode('heading', { level: 2 }).run()
    },
  },
  {
    title: 'Bold',
    command: ({ editor, range }) => {
      editor.chain().focus().deleteRange(range).setMark('bold').run()
    },
  },
  {
    title: 'Italic',
    command: ({ editor, range }) => {
      editor.chain().focus().deleteRange(range).setMark('italic').run()
    },
  },
]

export const suggestion = {
  items: ({ editor, query }) => {
    return defaultItems
      .filter(item => item.title.toLowerCase().startsWith(query.toLowerCase()))
      .slice(0, 5)
  },

  allowSpaces: false,

  render: () => {
    let component

    function repositionComponent(clientRect) {
      if (!component || !component.element) {
        return
      }

      const virtualElement = {
        getBoundingClientRect() {
          return clientRect
        },
      }

      computePosition(virtualElement, component.element, {
        placement: 'bottom-start',
      }).then(pos => {
        Object.assign(component.element.style, {
          left: `${pos.x}px`,
          top: `${pos.y}px`,
          position: pos.strategy === 'fixed' ? 'fixed' : 'absolute',
        })
      })
    }

    return {
      onStart: props => {
        component = new ReactRenderer(CommandsList, {
          props,
          editor: props.editor,
        })

        console.log('suggestion onStart', component)
        document.body.appendChild(component.element)
        repositionComponent(props.clientRect())
      },

      onUpdate(props) {
        console.log('suggestion onUpdate', component)
        component.updateProps(props)
        repositionComponent(props.clientRect())
      },

      onKeyDown(props) {
        console.log('suggestion onKeyDown', component)
        if (props.event.key === 'Escape') {
          document.body.removeChild(component.element)
          component.destroy()

          return true
        }

        return component.ref?.onKeyDown(props)
      },

      onExit() {
        console.log('suggestion onExit', component)
        if (!component) return

        if (document.body.contains(component.element)) {
          document.body.removeChild(component.element)
        }
        component.destroy()
      },
    }
  },
}

export default suggestion;
