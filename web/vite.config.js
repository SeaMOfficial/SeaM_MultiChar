import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

// CEF applies a CORS check to crossorigin-tagged assets that the nui:// scheme
// need not satisfy, and Vite adds the attribute by default. Stripping it here
// means a rebuild cannot quietly reintroduce a blank menu.
const stripCrossorigin = {
  name: 'strip-crossorigin',
  enforce: 'post',
  transformIndexHtml(html) {
    return html.replace(/ crossorigin/g, '');
  },
};

export default defineConfig({
  plugins: [svelte(), stripCrossorigin],
  base: './', // cef loads off nui://, not a web root
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    assetsInlineLimit: 1024 * 1024, // inline the woff2 so there's no path for cef to miss
    chunkSizeWarningLimit: 1200,
  },
});
