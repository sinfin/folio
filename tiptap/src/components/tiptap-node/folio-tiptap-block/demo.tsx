import * as React from "react"
import { EditorContent, useEditor } from "@tiptap/react"
import { StarterKit } from "@tiptap/starter-kit"
import { FolioTiptapBlockExtension } from "./folio-tiptap-block-extension"
import { FolioTiptapBlockButton } from "@/components/tiptap-ui/folio-tiptap-block-button"
import { Button } from "@/components/tiptap-ui-primitive/button"
import { Toolbar, ToolbarGroup } from "@/components/tiptap-ui-primitive/toolbar"
import "./folio-tiptap-block.scss"

const demoContent = `
<h1>FolioTiptapBlock Demo</h1>
<p>This demo showcases the FolioTiptapBlock plugin. Try the following:</p>
<ul>
  <li>Click the "Add Folio Block" button in the toolbar</li>
  <li>Fill out the configuration dialog</li>
  <li>Watch the block load content from the mock API</li>
  <li>Click on existing blocks to edit them</li>
</ul>
<p>Click the button below to add a pre-configured hero block:</p>
`

export const FolioTiptapBlockDemo: React.FC = () => {
  const editor = useEditor({
    extensions: [
      StarterKit,
      FolioTiptapBlockExtension.configure({
        apiUrl: '/api/folio-blocks',
        onError: (error) => {
          console.error('Folio block error:', error)
        },
        onSuccess: (html) => {
          console.log('Folio block loaded successfully:', html.slice(0, 100) + '...')
        },
      }),
    ],
    content: demoContent,
  })

  const addSampleHeroBlock = () => {
    if (!editor) return
    
    editor
      .chain()
      .focus()
      .setFolioTiptapBlock({
        title: 'Welcome Hero',
        blockType: 'hero',
        content: 'Transform your workflow with our amazing platform. Join thousands of satisfied customers today.',
      })
      .run()
  }

  const addSampleGalleryBlock = () => {
    if (!editor) return
    
    editor
      .chain()
      .focus()
      .setFolioTiptapBlock({
        title: 'Project Gallery',
        blockType: 'gallery',
        content: 'Showcase of our latest work and creative projects.',
      })
      .run()
  }

  const addSampleTestimonialBlock = () => {
    if (!editor) return
    
    editor
      .chain()
      .focus()
      .setFolioTiptapBlock({
        title: 'Customer Reviews',
        blockType: 'testimonial',
        content: 'This platform has revolutionized how we manage our projects. The interface is intuitive and the features are exactly what we needed.',
      })
      .run()
  }

  const addSampleCTABlock = () => {
    if (!editor) return
    
    editor
      .chain()
      .focus()
      .setFolioTiptapBlock({
        title: 'Get Started Today',
        blockType: 'cta',
        content: 'Ready to transform your workflow? Join our community of successful teams.',
      })
      .run()
  }

  const clearEditor = () => {
    if (!editor) return
    editor.chain().focus().clearContent().run()
  }

  const resetToDemo = () => {
    if (!editor) return
    editor.chain().focus().setContent(demoContent).run()
  }

  if (!editor) {
    return <div>Loading editor...</div>
  }

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '20px' }}>
      <h2 style={{ marginBottom: '20px', color: '#1e293b' }}>
        FolioTiptapBlock Plugin Demo
      </h2>
      
      <div style={{ marginBottom: '20px' }}>
        <Toolbar style={{ position: 'relative', marginBottom: '10px' }}>
          <ToolbarGroup>
            <FolioTiptapBlockButton editor={editor} />
          </ToolbarGroup>
        </Toolbar>
        
        <div style={{ 
          display: 'flex', 
          gap: '8px', 
          flexWrap: 'wrap',
          marginBottom: '10px'
        }}>
          <Button onClick={addSampleHeroBlock} data-style="ghost">
            Add Hero Block
          </Button>
          <Button onClick={addSampleGalleryBlock} data-style="ghost">
            Add Gallery Block
          </Button>
          <Button onClick={addSampleTestimonialBlock} data-style="ghost">
            Add Testimonial Block
          </Button>
          <Button onClick={addSampleCTABlock} data-style="ghost">
            Add CTA Block
          </Button>
        </div>
        
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button onClick={resetToDemo} data-style="ghost">
            Reset Demo
          </Button>
          <Button onClick={clearEditor} data-style="ghost">
            Clear All
          </Button>
        </div>
      </div>

      <div style={{ 
        border: '2px solid #e2e8f0',
        borderRadius: '8px',
        minHeight: '400px',
        padding: '20px',
        backgroundColor: '#ffffff'
      }}>
        <EditorContent 
          editor={editor}
          style={{ outline: 'none' }}
        />
      </div>

      <div style={{ 
        marginTop: '20px', 
        padding: '16px', 
        backgroundColor: '#f8fafc', 
        borderRadius: '6px',
        fontSize: '14px',
        color: '#64748b'
      }}>
        <h4 style={{ margin: '0 0 8px', color: '#374151' }}>
          Demo Instructions:
        </h4>
        <ul style={{ margin: '0', paddingLeft: '20px' }}>
          <li>Use the toolbar button to create a new block from scratch</li>
          <li>Use the preset buttons to add pre-configured blocks</li>
          <li>Click on any block to edit its configuration</li>
          <li>The mock API simulates a 1-second delay</li>
          <li>Check the browser console for API call logs</li>
        </ul>
      </div>
    </div>
  )
}

export default FolioTiptapBlockDemo