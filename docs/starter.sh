#!/bin/bash

PROJECT_NAME="my-astro-portfolio"

echo "Starting comprehensive Astro project scaffold..."

# 1. Initialize the Astro Project
echo "Initializing Astro project in ./${PROJECT_NAME}..."
npm create astro@latest ${PROJECT_NAME} . --template empty --typescript strict --install --git --yes

# Navigate into the newly created project directory
cd ${PROJECT_NAME} || exit

# 2. Install Additional Dependencies
echo "Installing required NPM packages..."
npm install tailwindcss @tailwindcss/vite @astrojs/sitemap vite-plugin-static-copy
npm install -D eslint typescript-eslint eslint-plugin-astro @eslint/js

# 3. Create the complete directory structure
echo "Creating project directories..."
mkdir -p src/content/{ai-projects,code-projects,id-projects}
mkdir -p src/pages/[collection]
mkdir -p src/layouts
mkdir -p src/components
mkdir -p src/styles
mkdir -p manuals

# 4. Write Configuration Files
echo "Writing configuration files..."

cat << 'EOF' > astro.config.mjs
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import { viteStaticCopy } from 'vite-plugin-static-copy';

export default defineConfig({
  site: 'https://your-portfolio-domain.com',
  integrations: [sitemap()],
  vite: {
    plugins: [
      tailwindcss(),
      viteStaticCopy({
        targets: [
          {
            src: 'manuals/*',
            dest: './'
          }
        ]
      })
    ]
  },
});
EOF

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

cat << 'EOF' > src/content.config.ts
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const projectSchema = z.object({
  title: z.string().catch('Untitled Project'),
  author: z.string().optional().default('Carlos'),
  date: z.coerce.date().catch(() => new Date()),
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

const manuals = defineCollection({
  loader: glob({ pattern: '**/[^_]*.{html,pdf}', base: './manuals' }),
  schema: z.object({
    title: z.string().default('Manual'),
  }),
});

export const collections = {
  'ai-projects': aiProjects,
  'code-projects': codeProjects,
  'id-projects': idProjects,
  'manuals': manuals,
};
EOF

# 5. Write Layout and Component Files
echo "Writing base layouts and components..."

cat << 'EOF' > src/styles/global.css
@import "tailwindcss";
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

# 6. Write Route Templates
echo "Writing dynamic routing pages..."

cat << 'EOF' > src/pages/index.astro
---
import Welcome from '../components/Welcome.astro';
import Layout from '../layouts/Layout.astro';
---
<Layout>
  <Welcome />
</Layout>
EOF

cat << 'EOF' > src/pages/[collection]/index.astro
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

cat << 'EOF' > src/pages/[collection]/[...id].astro
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

# 7. Create Placeholders for Data Verification
echo "Generating test data..."

cat << 'EOF' > src/content/ai-projects/hello-world.md
---
title: "Hello AI World"
date: 2026-06-28
desc: "This is my first AI project file."
---
# Welcome
This is the content of your first AI project.
EOF

cat << 'EOF' > manuals/sample-manual.html
<!DOCTYPE html>
<html>
<head><title>Sample Manual</title></head>
<body><h1>Legacy Documentation</h1></body>
</html>
EOF

echo "✅ Scaffold complete! Navigate to ./${PROJECT_NAME} and run 'npm run dev' to start the server."