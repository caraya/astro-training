#!/bin/bash
set -e

# Make sure we start from the initial commit
git checkout main
INITIAL_COMMIT=$(git rev-list --max-parents=0 HEAD)
git checkout $INITIAL_COMMIT

# Phase 1: Project Setup & Directory Spaces
git checkout -b phase-1

mkdir -p src/components
mkdir -p src/content/ai-projects
mkdir -p src/content/code-projects
mkdir -p src/content/id-projects
mkdir -p src/layouts
mkdir -p src/pages

touch src/components/.gitkeep
touch src/content/ai-projects/.gitkeep
touch src/content/code-projects/.gitkeep
touch src/content/id-projects/.gitkeep
touch src/layouts/.gitkeep
touch src/pages/.gitkeep

git add .
git commit -m "Phase 1: Project Setup & Directory Spaces"

# Phase 2: Defining the Content Schema (Zod)
git checkout -b phase-2

cat << 'EOF' > src/content.config.ts
import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { glob } from 'astro/loaders';

// Define a forgiving, flat schema that safely handles missing data
const projectSchema = z.object({
  title: z.string().catch('Untitled Project'),
  author: z.string().optional().default('Carlos'),
  date: z.coerce.date().catch(() => new Date()), // Converts string to native JS Date
  language: z.string().optional(),
  desc: z.string().optional(),
  draft: z.boolean().optional().default(false),
  baseline: z.boolean().optional().default(false),
  colorjs: z.boolean().optional().default(false),
  youtube: z.boolean().optional().default(false),
  vimeo: z.boolean().optional().default(false),
  mavo: z.boolean().optional().default(false),
  mermaid: z.boolean().optional().default(false),
});

const aiProjects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/ai-projects' }),
  schema: projectSchema,
});

const codeProjects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/code-projects' }),
  schema: projectSchema,
});

const idProjects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/id-projects' }),
  schema: projectSchema,
});

// Export all three collections explicitly
export const collections = {
  'ai-projects': aiProjects,
  'code-projects': codeProjects,
  'id-projects': idProjects,
};
EOF

git add src/content.config.ts
git commit -m "Phase 2: Defining the Content Schema (Zod)"

# Phase 3: The Data Pipeline & Dynamic Routing
git checkout -b phase-3

mkdir -p src/pages/\[collection\]
cat << 'EOF' > src/pages/\[collection\]/index.astro
---
// src/pages/[collection]/index.astro
import { getCollection } from 'astro:content';
import type { CollectionEntry } from 'astro:content';

// 1. Define a unified type alias to prevent TypeScript union collapse
type ProjectEntry =
  | CollectionEntry<'ai-projects'>
  | CollectionEntry<'code-projects'>
  | CollectionEntry<'id-projects'>;

export async function getStaticPaths() {
  const isDev = import.meta.env.DEV;
  // Use 'collection' nomenclature to match the filename parameters
  const uniqueCollections = ['ai-projects', 'code-projects', 'id-projects'] as const;

  let allProjects: ProjectEntry[] = [];

  if (isDev) {
    // Strict Mode: Catch frontmatter errors instantly during local dev
    const [ai, code, id] = await Promise.all([
      getCollection('ai-projects'),
      getCollection('code-projects'),
      getCollection('id-projects'),
    ]);
    allProjects = [...ai, ...code, ...id];
  } else {
    // Forgiving Mode: Keep the production build alive if one collection fails
    const results = await Promise.allSettled([
      getCollection('ai-projects'),
      getCollection('code-projects'),
      getCollection('id-projects'),
    ]);

    allProjects = results.flatMap((result) =>
      result.status === 'fulfilled' ? (result.value as ProjectEntry[]) : []
    );
  }

  // Safely filter out drafts using the flat schema
  const publicProjects = allProjects.filter((project) => !project.data.draft);

  return uniqueCollections.map((collection) => {
    const filteredProjects = publicProjects
      .filter((project) => project.collection === collection)
      .sort((a, b) => {
        // Safe Date to ISO string conversion for the Temporal API
        const dateA = a.data.date.toISOString().split('T')[0];
        const dateB = b.data.date.toISOString().split('T')[0];
        return Temporal.PlainDate.compare(
          Temporal.PlainDate.from(dateB),
          Temporal.PlainDate.from(dateA)
        );
      }) as ProjectEntry[];

    return {
      // The param key MUST be 'collection' to match the [collection] directory/file name
      params: { collection },
      props: { projects: filteredProjects },
    };
  });
}

interface Props {
  projects: ProjectEntry[];
}

// Destructure 'collection' to match the params returned by getStaticPaths
const { collection } = Astro.params;
const { projects } = Astro.props;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{collection.replace('-', ' ')}</title>
    <style>
      :root {
        --color-bg: #0f172a;
        --color-card-bg: #1e293b;
        --color-text: #f8fafc;
        --color-accent: #38bdf8;
        --color-muted: #94a3b8;
      }
      body {
        margin: 0;
        font-family: system-ui, -apple-system, sans-serif;
        background-color: var(--color-bg);
        color: var(--color-text);
        line-height: 1.6;
        padding: 4rem 1rem;
      }
      main {
        max-width: 800px;
        margin: 0 auto;
      }
      .back-link {
        color: var(--color-accent);
        text-decoration: none;
        display: inline-block;
        margin-bottom: 1.5rem;
        font-weight: 500;
        transition: transform 0.2s ease;
      }
      .back-link:hover {
        transform: translateX(-4px);
      }
      .title-section {
        border-bottom: 2px solid var(--color-card-bg);
        padding-bottom: 1.5rem;
        margin-bottom: 2.5rem;
      }
      .title-section h1 {
        font-size: 2.75rem;
        margin: 0 0 0.5rem 0;
        text-transform: capitalize;
      }
      .title-section p {
        color: var(--color-muted);
        margin: 0;
        font-size: 1.125rem;
      }
      .posts-grid {
        display: flex;
        flex-direction: column;
        gap: 1.75rem;
      }
      .post-card {
        background-color: var(--color-card-bg);
        border: 1px solid rgba(255, 255, 255, 0.05);
        padding: 1.75rem;
        border-radius: 12px;
        transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), border-color 0.2s ease;
      }
      .post-card:hover {
        transform: translateY(-2px);
        border-color: var(--color-accent);
      }
      .post-card h2 {
        margin: 0 0 0.75rem 0;
        font-size: 1.5rem;
      }
      .post-card h2 a {
        color: var(--color-text);
        text-decoration: none;
      }
      .post-card h2 a:hover {
        color: var(--color-accent);
      }
      .post-meta {
        font-size: 0.875rem;
        color: var(--color-muted);
        margin-bottom: 1rem;
        display: flex;
        gap: 0.5rem;
        align-items: center;
      }
      .post-description {
        margin: 0;
        color: var(--color-muted);
        font-size: 1rem;
      }
      .no-posts {
        text-align: center;
        padding: 4rem 2rem;
        background-color: var(--color-card-bg);
        border-radius: 12px;
        color: var(--color-muted);
      }
    </style>
  </head>
  <body>
    <main>
      <nav aria-label="Breadcrumb">
        <a href="/" class="back-link">&larr; Back to Home</a>
      </nav>
      <header class="title-section">
        <h1>{collection.replace('-', ' ')}</h1>
        <p>A collection of projects covering {collection.replace('-', ' ')} concepts, practices, and pipelines.</p>
      </header>
      {projects.length === 0 ? (
        <div class="no-posts">
          <p>No projects published in this collection yet.</p>
        </div>
      ) : (
        <section class="posts-grid" aria-label={`Projects in ${collection}`}>
          {projects.map((project) => {
            const projectDate = project.data.date.toISOString().split('T')[0];
            return (
              <article class="post-card">
                <h2>
                  <a href={`/${project.collection}/${project.id}`}>{project.data.title}</a>
                </h2>
                <div class="post-meta">
                  <span>By {project.data.author}</span>
                  <span>&bull;</span>
                  <time datetime={projectDate}>
                    {project.data.date.toLocaleDateString("en-US", { dateStyle: "long" })}
                  </time>
                </div>
                {project.data.desc && (
                  <p class="post-description">{project.data.desc}</p>
                )}
              </article>
            );
          })}
        </section>
      )}
    </main>
  </body>
</html>
EOF

cat << 'EOF' > src/pages/\[collection\]/\[...id\].astro
---
import { getCollection, render } from 'astro:content';
import type { CollectionEntry } from 'astro:content';

type ProjectEntry =
  | CollectionEntry<'ai-projects'>
  | CollectionEntry<'code-projects'>
  | CollectionEntry<'id-projects'>;

export async function getStaticPaths() {
  const isDev = import.meta.env.DEV;
  let allProjects: ProjectEntry[] = [];
  if (isDev) {
    const [ai, code, id] = await Promise.all([
      getCollection('ai-projects'),
      getCollection('code-projects'),
      getCollection('id-projects'),
    ]);
    allProjects = [...ai, ...code, ...id];
  } else {
    const results = await Promise.allSettled([
      getCollection('ai-projects'),
      getCollection('code-projects'),
      getCollection('id-projects'),
    ]);
    allProjects = results.flatMap((result) =>
      result.status === 'fulfilled' ? (result.value as ProjectEntry[]) : []
    );
  }

  const publicProjects = allProjects.filter((project) => !project.data.draft);

  return publicProjects.map((project) => ({
    params: {
      collection: project.collection,
      id: project.id,
    },
    props: { project },
  }));
}

interface Props {
  project: ProjectEntry;
}

const { project } = Astro.props;
const { Content } = await render(project);
const projectDate = project.data.date.toISOString().split('T')[0];
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{project.data.title}</title>
    <style>
      :root {
        --color-bg: #0f172a;
        --color-card-bg: #1e293b;
        --color-text: #f8fafc;
        --color-accent: #38bdf8;
        --color-muted: #94a3b8;
      }
      body {
        margin: 0;
        font-family: system-ui, -apple-system, sans-serif;
        background-color: var(--color-bg);
        color: var(--color-text);
        line-height: 1.6;
        padding: 4rem 1rem;
      }
      main {
        max-width: 800px;
        margin: 0 auto;
      }
      .back-link {
        color: var(--color-accent);
        text-decoration: none;
        display: inline-block;
        margin-bottom: 2rem;
        font-weight: 500;
        transition: transform 0.2s ease;
      }
      .back-link:hover {
        transform: translateX(-4px);
      }
      article {
        background-color: var(--color-card-bg);
        border: 1px solid rgba(255, 255, 255, 0.05);
        padding: 2.5rem;
        border-radius: 16px;
      }
      h1 {
        font-size: 3rem;
        margin: 0 0 1rem 0;
        line-height: 1.2;
      }
      .post-meta {
        color: var(--color-muted);
        display: flex;
        gap: 0.75rem;
        align-items: center;
        margin-bottom: 2.5rem;
        padding-bottom: 1.5rem;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      }
      .content {
        font-size: 1.125rem;
      }
      .content :global(h2) {
        color: var(--color-accent);
        margin-top: 2.5rem;
      }
      .content :global(a) {
        color: var(--color-accent);
        text-decoration: none;
      }
      .content :global(a:hover) {
        text-decoration: underline;
      }
    </style>
  </head>
  <body>
    <main>
      <a href={`/${project.collection}`} class="back-link">&larr; Back to {project.collection.replace('-', ' ')}</a>
      <article>
        <h1>{project.data.title}</h1>
        <div class="post-meta">
          <span>By {project.data.author}</span>
          <span>&bull;</span>
          <time datetime={projectDate}>
            {project.data.date.toLocaleDateString("en-US", { dateStyle: "long" })}
          </time>
        </div>
        <div class="content">
          <Content />
        </div>
      </article>
    </main>
  </body>
</html>
EOF

git add src/pages
git commit -m "Phase 3: The Data Pipeline & Dynamic Routing"

# Phase 4: Extending with Custom Content Loaders
git checkout -b phase-4

cat << 'EOF' > src/content.config.ts
import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { glob } from 'astro/loaders';

// Define a forgiving, flat schema that safely handles missing data
const projectSchema = z.object({
  title: z.string().catch('Untitled Project'),
  author: z.string().optional().default('Carlos'),
  date: z.coerce.date().catch(() => new Date()), // Converts string to native JS Date
  language: z.string().optional(),
  desc: z.string().optional(),
  draft: z.boolean().optional().default(false),
  baseline: z.boolean().optional().default(false),
  colorjs: z.boolean().optional().default(false),
  youtube: z.boolean().optional().default(false),
  vimeo: z.boolean().optional().default(false),
  mavo: z.boolean().optional().default(false),
  mermaid: z.boolean().optional().default(false),
});

const aiProjects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/ai-projects' }),
  schema: projectSchema,
});

const codeProjects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/code-projects' }),
  schema: projectSchema,
});

const idProjects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/id-projects' }),
  schema: projectSchema,
});

// Define an authors collection using a custom API loader
const authors = defineCollection({
  loader: {
    name: 'authors-api-loader',
    load: async ({ store }) => {
      // Fetch data from your external REST API
      const response = await fetch('https://jsonplaceholder.typicode.com/users');
      const users = await response.json();
      for (const user of users) {
        // Save each item to the Astro store using a unique ID
        store.set({
          id: user.username.toLowerCase(),
          data: {
            name: user.name,
            email: user.email,
            website: user.website,
          },
        });
      }
    }
  },
  // Validate the incoming API data to ensure type safety
  schema: z.object({
    name: z.string(),
    email: z.string().email(),
    website: z.string(),
  }),
});

// Export all collections explicitly
export const collections = {
  'ai-projects': aiProjects,
  'code-projects': codeProjects,
  'id-projects': idProjects,
  'authors': authors, // Make sure to export the external collection here
};
EOF

git add src/content.config.ts
git commit -m "Phase 4: Extending with Custom Content Loaders"

# Phase 5: Dynamic Performance & Asset Optimization
git checkout -b phase-5

# We insert the scripts at the end of the body in [...id].astro
sed -i '' '/<\/body>/i\
\
    <!-- 1. Conditional Diagram Rendering (Mermaid.js) -->\
    {project.data.mermaid && (\
      <script>\
        const renderDiagrams = async () => {\
          const { default: mermaid } = await import("mermaid");\
          mermaid.initialize({ startOnLoad: false, theme: "dark" });\
          await mermaid.run({\
            nodes: document.querySelectorAll(".mermaid-diagram"),\
          });\
        };\
        renderDiagrams();\
      </script>\
    )}\
\
    <!-- 2. Conditional Analytics Rendering (Chart.js) -->\
    {project.data.baseline && (\
      <script>\
        const initCharts = async () => {\
          const { Chart, registerables } = await import("chart.js");\
          Chart.register(...registerables);\
          // Initialize charts...\
        };\
        initCharts();\
      </script>\
    )}\
' src/pages/\[collection\]/\[...id\].astro

git add src/pages/\[collection\]/\[...id\].astro
git commit -m "Phase 5: Dynamic Performance & Asset Optimization"

# Phase 6: Styling, Asset Delivery & SEO
git checkout -b phase-6

npm install tailwindcss @tailwindcss/vite @astrojs/sitemap vite-plugin-static-copy

cat << 'EOF' > astro.config.mjs
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
EOF

mkdir -p src/styles
cat << 'EOF' > src/styles/global.css
@import "tailwindcss";
EOF

mkdir -p manuals
cat << 'EOF' > src/components/ManualsList.astro
---
// src/components/ManualsList.astro
import fs from 'node:fs/promises';
import path from 'node:path';

const manualsDir = './manuals';
let manualLinks: Array<{ url: string; title: string }> = [];

try {
  // Scan the root directory at build time
  const files = await fs.readdir(manualsDir);
  
  manualLinks = files
    .filter((file) => file.endsWith('.html') || file.endsWith('.pdf'))
    .map((file) => {
      const title = path.basename(file, path.extname(file)).replace(/-/g, ' ');
      return {
        // Maps exactly to the static copy destination structure
        url: `/${file}`,
        title: title.charAt(0).toUpperCase() + title.slice(1)
      };
    });
} catch (error) {
  console.warn('Manuals directory not found or empty.');
}
---

<section>
  <h2>Legacy Reference Manuals</h2>
  {manualLinks.length === 0 ? (
    <p>No manuals available.</p>
  ) : (
    <ul>
      {manualLinks.map((link) => (
        <li>
          <a href={link.url}>{link.title}</a>
        </li>
      ))}
    </ul>
  )}
</section>
EOF

git add astro.config.mjs src/styles package.json package-lock.json src/components manuals
git commit -m "Phase 6: Styling, Asset Delivery & SEO"

# Phase 7: Production Readiness, Linting & Homepages
git checkout -b phase-7

npm install -D eslint typescript-eslint eslint-plugin-astro @eslint/js

cat << 'EOF' > eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import eslintPluginAstro from 'eslint-plugin-astro';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  ...eslintPluginAstro.configs.recommended,
  ...eslintPluginAstro.configs['jsx-a11y-recommended'],
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    },
  }
);
EOF

cat << 'EOF' > src/components/Welcome.astro
---
---
<main style="max-width: 800px; margin: 0 auto; padding: 4rem 1rem;">
  <h1 style="font-size: 2.5rem; margin-bottom: 1rem;">Welcome to the Portfolio</h1>
  <p style="color: #94a3b8; margin-bottom: 2rem;">Explore the collections below:</p>
  <ul style="display: flex; gap: 1rem; list-style: none; padding: 0;">
    <li><a href="/ai-projects" style="color: #38bdf8;">AI Projects</a></li>
    <li><a href="/code-projects" style="color: #38bdf8;">Code Projects</a></li>
    <li><a href="/id-projects" style="color: #38bdf8;">ID Projects</a></li>
  </ul>
</main>
EOF

cat << 'EOF' > src/layouts/Layout.astro
---
import '../styles/global.css';
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Astro Portfolio</title>
  </head>
  <body class="bg-slate-900 text-slate-50 font-sans">
    <slot />
  </body>
</html>
EOF

cat << 'EOF' > src/pages/index.astro
---
import Welcome from '../components/Welcome.astro';
import Layout from '../layouts/Layout.astro';
---

<Layout>
  <Welcome />
</Layout>
EOF

git add eslint.config.mjs package.json package-lock.json src/components src/layouts src/pages/index.astro
git commit -m "Phase 7: Production Readiness, Linting & Homepages"

# Clean up back to main
git checkout temp-save
