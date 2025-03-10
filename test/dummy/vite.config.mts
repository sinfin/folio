import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import sassGlobImports from 'vite-plugin-sass-glob-import'

export default defineConfig({
  plugins: [
    sassGlobImports(),
    ViteRails(),
  ],
  resolve: {
    alias: {
      "@app-components": process.env.APP_COMPONENTS_PATH,
      "@folio-root": process.env.FOLIO_ROOT_PATH,
      "@folio-images": process.env.FOLIO_IMAGES_PATH,
      "@folio-stylesheets": process.env.FOLIO_STYLESHEETS_PATH,
      "@folio-javascripts": process.env.FOLIO_JAVASCRIPTS_PATH,
      "@folio-components": process.env.FOLIO_COMPONENTS_PATH,
    },
  },
  server: {
    fs: {
      allow: [
        process.env.APP_COMPONENTS_PATH,
        process.env.FOLIO_ROOT_PATH,
        process.env.FOLIO_IMAGES_PATH,
        process.env.FOLIO_STYLESHEETS_PATH,
        process.env.FOLIO_JAVASCRIPTS_PATH,
        process.env.FOLIO_COMPONENTS_PATH,
      ],
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern',
      },
    },
  },
})
