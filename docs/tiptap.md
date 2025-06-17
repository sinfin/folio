# Tiptap

This chapter describes the Tiptap editor implementation in Folio.

## Structure

The aim is to provide a basic rich text editor and an advanced block editor. Since we need application-specific styles, we use iframes and the application layout.

- new input type `TiptapInput` inherits from `SimpleForm::Inputs::StringInput`,
  - can be used as `f.input :attribute, as: :tiptap`
  - binds `f-input-tiptap` stimulus and adds HTML using the simple form `:custom_html` component
  - HTML consists of a loader and an iframe pointing towards action `rich_text` or `block` action of `Folio::TiptapController`
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

We use window messages extensively to communicate between the iframe and the parent window.

- The input stimulus sends a `f-input-tiptap:start` message to the iframe window to try and initialize with JSON data from the hidden input.
  - If the javascript is initialized, it starts the editor.
  - If it's not, nothing happens.
- The iframe finishes loading the javascript and sends a `f-tiptap:javascript-evaluated` message to the top window to let the input know that the javascript has been evaluated.
- The input handles the message and sends a `f-input-tiptap:start` message to the iframe window to try and initialize with JSON data from the hidden input.
- The editor initializes with the JSON data from the window message and sends a `f-tiptap:created` message containing the content and editor height.
- Any time the editor content is updated, it sends a `f-tiptap:updated` message containing the new content and editor height.

## Development

Tiptap development happens in the `tiptap` directory. It's developed as a separate Vite app that is built using `npm run build`. That produces `folio-tiptap.css` and `folio-tiptap.js` in `tiptap/dist/assets` which are in the assets pipeline path.

To develop, run `npm install` and `npm run dev` in the `tiptap` directory. That starts a http://localhost:5173/ server.

In case you need to develop folio-specific integrations, you can set the `FOLIO_TIPTAP_DEV=1` ENV value and  start the rails server (i.e. `FOLIO_TIPTAP_DEV=1 r s`). That uses the http://localhost:5173/ server instead of the `Folio::TiptapController` as the iframe src.
