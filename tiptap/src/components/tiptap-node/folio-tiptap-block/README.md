# FolioTiptapBlock Plugin

A custom TipTap node extension that creates dynamic content blocks that load HTML from an API.

## Features

- 🎯 **Interactive Dialog**: Opens a configuration dialog when inserted or clicked
- 🔄 **API Integration**: Loads HTML content from configurable API endpoints
- 📱 **Responsive Design**: Works seamlessly on desktop and mobile
- 🎨 **Multiple Block Types**: Supports various predefined block types (hero, gallery, testimonial, etc.)
- ⚡ **Loading States**: Shows loading indicators and error handling
- 🔧 **Configurable**: Fully customizable API URLs and block attributes

## Installation

The plugin consists of several components that work together:

1. **Extension**: `FolioTiptapBlockExtension` - The core TipTap node
2. **Component**: `FolioTiptapBlock` - React component for rendering the block
3. **Dialog**: `FolioTiptapBlockDialog` - Configuration dialog
4. **Button**: `FolioTiptapBlockButton` - Toolbar button for insertion

## Usage

### Basic Setup

```tsx
import { useEditor } from '@tiptap/react'
import { StarterKit } from '@tiptap/starter-kit'
import { FolioTiptapBlockExtension } from '@/components/tiptap-node/folio-tiptap-block'

const editor = useEditor({
  extensions: [
    StarterKit,
    FolioTiptapBlockExtension.configure({
      apiUrl: '/api/folio-blocks',
      onError: (error) => console.error('Block error:', error),
      onSuccess: (html) => console.log('Block loaded:', html),
    }),
  ],
})
```

### Adding to Toolbar

```tsx
import { FolioTiptapBlockButton } from '@/components/tiptap-ui/folio-tiptap-block-button'

<Toolbar>
  <ToolbarGroup>
    <FolioTiptapBlockButton />
  </ToolbarGroup>
</Toolbar>
```

### Programmatic Insertion

```tsx
// Insert a new block
editor.chain().focus().setFolioTiptapBlock({
  title: 'My Block',
  blockType: 'hero',
  content: 'Custom content'
}).run()
```

## Configuration Options

### Extension Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apiUrl` | `string` | `'/api/folio-blocks'` | Base API URL for loading content |
| `onError` | `function` | `undefined` | Callback for API errors |
| `onSuccess` | `function` | `undefined` | Callback for successful API calls |

### Block Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `title` | `string` | Display title for the block |
| `content` | `string` | Additional content or configuration |
| `blockType` | `string` | Type of block (hero, gallery, testimonial, etc.) |
| `apiUrl` | `string` | Override API URL for this specific block |

## Block Types

The plugin supports several predefined block types:

- **hero**: Hero sections with title, content, and CTA buttons
- **gallery**: Image gallery grids
- **testimonial**: Customer testimonials with quotes
- **cta**: Call-to-action sections
- **feature**: Feature highlights with icons
- **custom**: Fully customizable blocks

## API Integration

### Expected API Response

The API should return JSON with the following structure:

```json
{
  "html": "<div class=\"folio-block\">...</div>",
  "success": true,
  "error": null
}
```

### API Request

The extension sends a request with the block attributes:

```javascript
// Example request payload
{
  "title": "Hero Section",
  "content": "Welcome to our platform",
  "blockType": "hero",
  "apiUrl": "/api/folio-blocks"
}
```

### Mock Implementation

For development, the plugin includes a mock API that generates sample HTML based on block type:

```tsx
const mockApiCall = async (attributes: FolioTiptapBlockAttributes): Promise<ApiResponse> => {
  // Simulates API delay
  await new Promise(resolve => setTimeout(resolve, 1000))
  
  // Returns mock HTML based on blockType
  return {
    html: generateMockHTML(attributes),
    success: true
  }
}
```

## Styling

Import the required CSS:

```scss
@import '@/components/tiptap-node/folio-tiptap-block/folio-tiptap-block.scss';
```

### CSS Variables

Customize the appearance using CSS variables:

```css
:root {
  --tiptap-primary-color: #3b82f6;
  --tiptap-border-color: #e2e8f0;
  --tiptap-background-color: #ffffff;
  --tiptap-text-color: #1e293b;
  --tiptap-muted-foreground: #64748b;
  --tiptap-muted-background: #f8fafc;
  --tiptap-destructive-color: #ef4444;
}
```

## Workflow

1. **Insertion**: User clicks the toolbar button or uses keyboard shortcut
2. **Dialog Opens**: Configuration dialog appears with form fields
3. **Configuration**: User fills in title, block type, and content
4. **API Call**: Plugin calls API with block attributes
5. **Loading State**: Shows spinner while waiting for response
6. **Content Display**: Renders returned HTML in the editor
7. **Editing**: Clicking the block reopens the dialog for modifications
8. **Reload**: Dialog save triggers new API call to refresh content

## Error Handling

The plugin handles various error states:

- **Network Errors**: Shows retry button and error message
- **Invalid Responses**: Displays appropriate error feedback
- **Missing Configuration**: Prevents API calls until required fields are filled
- **Validation Errors**: Highlights invalid form fields

## Accessibility

- Proper ARIA labels and roles
- Keyboard navigation support
- Focus management in dialogs
- Screen reader friendly error messages

## Development

### File Structure

```
folio-tiptap-block/
├── folio-tiptap-block-extension.ts    # TipTap node extension
├── folio-tiptap-block.tsx             # Main React component
├── folio-tiptap-block-dialog.tsx      # Configuration dialog
├── folio-tiptap-block.scss            # Component styles
├── folio-tiptap-block-dialog.scss     # Dialog styles
├── index.tsx                          # Exports
└── README.md                          # Documentation
```

### Extending Block Types

To add new block types, update the mock API function and add corresponding CSS:

```tsx
case 'newBlockType':
  mockHtml = `
    <div class="folio-block folio-block-new">
      <h3>${title || 'New Block'}</h3>
      <p>${content || 'New block content'}</p>
    </div>
  `
  break
```

## License

This plugin is part of the Folio TipTap editor suite.