import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://oraiopoli.com',
  output: 'static',
  build: {
    inlineStylesheets: 'auto'
  }
});

