# Tiptap

This chapter describes the Tiptap editor implementation in Folio. The aim is to provide a basic rich text editor and an advanced block editor.

## Usage

Simple rich text editor:

```rb
f.input :content_json, as: :tiptap
```

Block editor:

```rb
f.input :content_json, as: :tiptap, block: true
```

## Structure

Since we need application-specific styles, we use iframes and the application layout.

- new input type `TiptapInput` inherits from `SimpleForm::Inputs::StringInput`,
  - can be used as `f.input :attribute, as: :tiptap`
  - binds `f-input-tiptap` stimulus and adds HTML using the simple form `:custom_html` component
  - HTML consists of a loader and an iframe pointing towards action `rich_text` or `block` action of `Folio::TiptapController` based on the `block` option
- controller `Folio::TiptapController`
  - inherits from `ApplicationController` and uses application layout in order to use application styles and javascripts
  - defines actions `rich_text` and `block` which render a single `div` to be used
  - sets a `@folio_tiptap = true` flag to be used in the layout to only yield the content without headers, footer, etc.
- application layout must handle the `@folio_tiptap` flag to only yield the content without header, footer, etc.
  - example:
    ```slim
    - if @folio_tiptap
      = yield
    - else
      = render(Folio::StructuredData::BodyComponent.new(record: @record_for_meta_variables,
                                                        breadcrumbs: @breadcrumbs_on_rails))

      = render(Dummy::Ui::HeaderComponent.new)

      = yield
    ```

## Implementation

### Communication between iframe and parent window

We use window messages extensively to communicate between the iframe and the parent window.

- The input stimulus sends a `f-input-tiptap:start` message to the iframe window to try and initialize with JSON data from the hidden input. Available custom folio tiptap nodes are specified in it as well.
  - If the javascript is initialized, it starts the editor via `window.Folio.Tiptap.init` defined in `main.tsx`.
  - If it's not, nothing happens.
- The iframe finishes loading the javascript and sends a `f-tiptap:javascript-evaluated` message to the top window to let the input know that the javascript has been evaluated.
- The input handles the message and sends a `f-input-tiptap:start` message to the iframe window to try and initialize with JSON data from the hidden input.
- The editor initializes with the JSON data from the window message and sends a `f-tiptap:created` message containing the content and editor height.
- Any time the editor content is updated, it sends a `f-tiptap:updated` message containing the new content and editor height.
- Any time the editor height changes, it sends a `f-tiptap-editor:resized` message containing the new height.

### Editor types

There are two types - **rich text** with basic editing functionality and **block** for advanced editing with more nodes including custom `folioTiptapNode`. Each editor type is tailored for different use cases:

  - **Rich Text Editor**:
    Provides a familiar WYSIWYG editing experience with basic formatting options such as bold, italic, underline, lists, links, and headings. This mode is ideal for simple content fields where users need to format text without complex layouts or embedded components. Usage:

    ```rb
    f.input :content_json, as: :tiptap
    ```

  - **Block Editor**:
    Offers advanced editing capabilities, allowing users to compose content using a variety of nodes. In addition to standard text formatting, users can insert and rearrange custom nodes, such as tables, task lists or application-specific `folioTiptapNode` nodes rendering rails view components. Usage:

    ```rb
    f.input :content_json, as: :tiptap, block: true
    ```

### Data structure

Tiptap content is stored as JSON following the ProseMirror document schema. The structure consists of:

- **Root document**: Contains `type: "doc"` and a `content` array
- **Nodes**: Each node has a `type` and may contain `content` (child nodes) and `attrs` (attributes)
- **Marks**: Formatting like bold, italic stored as `marks` array within text nodes
- **Custom nodes**: Application-specific nodes using `folioTiptapNode` type

**Basic structure example:**
```json
{
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "Hello, ",
          "marks": [{ "type": "bold" }]
        },
        {
          "type": "text",
          "text": "world!"
        }
      ]
    }
  ]
}
```

**Custom Folio nodes structure:**
```json
{
  "type": "folioTiptapNode",
  "attrs": {
    "version": 1,
    "type": "MyApp::CustomNode",
    "data": {
      "title": "Custom Content",
      "image_id": 123
    }
  }
}
```

## Custom Node Implementation

Folio provides a powerful system for creating custom Tiptap nodes that integrate seamlessly with Rails models and view components.

### Node Definition

Custom nodes inherit from `Folio::Tiptap::Node` and use the `tiptap_node` class method to define their structure:

```rb
class MyApp::CustomNode < Folio::Tiptap::Node
  tiptap_node structure: {
    title: :string,
    description: :text,
    content: :rich_text,
    image: :image,
    documents: :documents,
    category: { class_name: "Category" },
    reports: { class_name: "Report", has_many: true }
  }
end
```

### Supported Attribute Types

The `Node` models are defined by calling `tiptap_node` method which uses the `Folio::Tiptap::NodeBuilder` and supports various attribute types:

- **`:string`, `:text`**: Basic text attributes
- **`:rich_text`**: JSON-stored rich text content (nested Tiptap structure)
- **`:url_json`**: URL with metadata (href, title, target, etc.)
- **`:image`, `:document`, `:audio`, `:video`**: Single Folio file attachments
- **`:images`, `:documents`**: Multiple Folio file attachments
- **`{ class_name: "Model" }`**: belongs_to relationship
- **`{ class_name: "Model", has_many: true }`**: has_many relationship

### File Attachments

File attachments are handled through Folio's file system:

```rb
# Single image
image: :image          # Creates image_id attribute + image_placement methods

# Multiple documents
documents: :documents  # Creates document_ids attribute + document_placements methods

# The builder automatically creates compatible methods for Folio Console UI:
# - File picker integration
# - Placement management
```

### Model Relationships

Custom nodes can reference other models:

```rb
# belongs_to relationship
category: { class_name: "Category" }  # Creates category_id + category methods

# has_many relationship
tags: { class_name: "Tag", has_many: true }  # Creates tag_ids + tags methods

# Usage in the node:
node.category_id = 1
node.category    # => Category.find(1)
node.tag_ids = [1, 2, 3]
node.tags       # => Tag.where(id: [1, 2, 3])
```

### Data Conversion

The `to_tiptap_node_hash` method converts the node to Tiptap format:

```rb
node.to_tiptap_node_hash
# => {
#      "type" => "folioTiptapNode",
#      "attrs" => {
#        "version" => 1,
#        "type" => "MyApp::CustomNode",
#        "data" => {
#          "title" => "My Title",
#          "image_id" => 123
#        }
#      }
#    }
```

### View Components

Each custom node should have a corresponding view component:

```rb
# For MyApp::CustomNode, create:
class MyApp::CustomNodeComponent < ViewComponent::Base
  def initialize(node:)
    @node = node
  end
end
```

The component is automatically resolved using the `view_component_class` method.

## Custom Node Rendering Process

The `folioTiptapNode` rendering system provides seamless integration between the Tiptap editor and Rails view components through a message-passing architecture.

### Rendering Flow

1. **Node Display**: When a `folioTiptapNode` appears in the editor, the `FolioTiptapNode` React component is rendered
2. **Render Request**: The component sends a `f-tiptap-node:render` message to the parent window with node attributes
3. **API Call**: The parent window makes a request to `Folio::Console::Api::TiptapController#render_nodes`
4. **Server Rendering**: The controller creates node instances and renders them using their view components
5. **HTML Response**: The rendered HTML is sent back via `f-input-tiptap:render-nodes` message
6. **Display**: The React component receives the HTML and displays it using `dangerouslySetInnerHTML`

### Message Communication

The system uses several window messages for communication:

```js
// From React component to parent window
{
  type: "f-tiptap-node:render",
  uniqueId: 123,
  attrs: {
    version: 1,
    type: "MyApp::CustomNode",
    data: { title: "Hello" }
  }
}

// From parent window to React component
{
  type: "f-input-tiptap:render-nodes",
  nodes: [{
    unique_id: 123,
    html: "<div>Rendered content...</div>"
  }]
}
```

### Edit Overlay Integration

When editing a node:

1. Edit button click sends `f-tiptap-node:click` message with node attributes
2. Parent window opens an overlay (using `Folio::Console::Tiptap::OverlayComponent` in the context of the console application outside of iframe) with the node's edit form
3. Form submission sends `f-c-tiptap-overlay:saved` message back
4. React component updates its attributes and re-renders

### API Controller Details

The `Folio::Console::Api::TiptapController` handles the `render_nodes` action, which creates node instances from the provided attributes and renders them via `Folio::Console::Tiptap::RenderNodesJsonComponent` using their associated view components, returning a JSON with HTML paired by node uniqueId that can be directly inserted into the editor.


## Development

Tiptap development happens in the `tiptap` directory. It's developed as a separate Vite app that is built using `npm run build`. That produces `folio-tiptap.css` and `folio-tiptap.js` in `tiptap/dist/assets` which are in the assets pipeline path.

To develop, run `npm install` and `npm run dev` in the `tiptap` directory. That starts a http://localhost:5173/ server.

In case you need to develop folio-specific integrations, you can set the `FOLIO_TIPTAP_DEV=1` ENV value and  start the rails server (i.e. `FOLIO_TIPTAP_DEV=1 r s`). That uses the http://localhost:5173/ server instead of the `Folio::TiptapController` as the iframe src.
