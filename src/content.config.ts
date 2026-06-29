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
