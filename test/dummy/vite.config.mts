import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import sassGlobImports from 'vite-plugin-sass-glob-import'

export default defineConfig({
  plugins: [
    ViteRails(),
    sassGlobImports(),
  ],
  resolve: {
    alias: {
      "@app-components": process.env.APP_COMPONENTS_PATH,
      "@app-vendor": process.env.APP_VENDOR_PATH,
      "@folio-root": process.env.FOLIO_ROOT_PATH,
      "@folio-images": process.env.FOLIO_IMAGES_PATH,
      "@folio-stylesheets": process.env.FOLIO_STYLESHEETS_PATH,
      "@folio-javascripts": process.env.FOLIO_JAVASCRIPTS_PATH,
      "@folio-cells": process.env.FOLIO_CELLS_PATH,
      "@folio-components": process.env.FOLIO_COMPONENTS_PATH,
      "@folio-vendor": process.env.FOLIO_VENDOR_PATH,
    },
  },
  server: {
    fs: {
      allow: [
        process.env.APP_COMPONENTS_PATH,
        process.env.APP_VENDOR_PATH,
        process.env.FOLIO_ROOT_PATH,
        process.env.FOLIO_IMAGES_PATH,
        process.env.FOLIO_STYLESHEETS_PATH,
        process.env.FOLIO_JAVASCRIPTS_PATH,
        process.env.FOLIO_CELLS_PATH,
        process.env.FOLIO_COMPONENTS_PATH,
        process.env.FOLIO_VENDOR_PATH,
      ],
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern',
        quietDeps: true,
        silenceDeprecations: ["import", "global-builtin", "mixed-decls"]
      },
    },
  },
})
