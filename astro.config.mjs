import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import { viteStaticCopy } from 'vite-plugin-static-copy';

export default defineConfig({
  // The 'site' property is required for sitemap and RSS URL resolution
  site: 'https://your-portfolio-domain.com',
  integrations: [sitemap()],
  vite: {
    plugins: [
      tailwindcss(),
      viteStaticCopy({
        targets: [
          {
            // Path to your root folder relative to astro.config.mjs
            src: 'manuals/*',
            // Copies files directly into the root of your final build folder
            dest: './'
          }
        ]
      })
    ]
  },
});
