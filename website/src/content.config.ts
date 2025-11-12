// Astro v5 Content Collections Configuration
// Defines type-safe schemas for all documentation collections

import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// AI Guidelines Collection - Constitutional requirements and agent instructions
const aiGuidelines = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/ai-guidelines' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    author: z.string(),
    tags: z.array(z.string()),
    targetAudience: z.enum(['all', 'claude', 'gemini', 'developers']).optional(),
    constitutional: z.boolean().optional(),
  }),
});

// User Guide Collection - End-user documentation
const userGuide = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/user-guide' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    author: z.string(),
    tags: z.array(z.string()),
    order: z.number().optional(), // For manual ordering
  }),
});

// Developer Collection - Technical documentation
const developer = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/developer' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    author: z.string(),
    tags: z.array(z.string()),
    techStack: z.array(z.string()).optional(),
    difficulty: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  }),
});

export const collections = {
  'ai-guidelines': aiGuidelines,
  'user-guide': userGuide,
  'developer': developer,
};
