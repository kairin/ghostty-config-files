import { defineCollection, z } from 'astro:content';

/**
 * Content Collections Configuration
 *
 * Defines content collections for documentation structure following
 * the repository refactoring specification (Feature 001).
 *
 * Structure:
 * - user-guide: User-facing documentation (installation, configuration, usage)
 * - ai-guidelines: AI assistant guidelines (modular extracts from AGENTS.md)
 * - developer: Developer documentation (architecture, contributing, testing)
 *
 * Constitutional Compliance:
 * - Separation of source (website/src/) from build output (docs-dist/)
 * - Shallow nesting (max 2 levels deep per FR-005)
 * - Clear audience segmentation
 */

// User Guide Collection Schema
const userGuideCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date().optional(),
    updatedDate: z.date().optional(),
    author: z.string().optional().default('Ghostty Configuration Files Team'),
    tags: z.array(z.string()).optional().default([]),
    order: z.number().optional(), // For manual ordering in navigation
  }),
});

// AI Guidelines Collection Schema
const aiGuidelinesCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date().optional(),
    updatedDate: z.date().optional(),
    author: z.string().optional().default('AI Integration Team'),
    tags: z.array(z.string()).optional().default(['ai', 'guidelines']),
    order: z.number().optional(),
    // AI-specific fields
    targetAudience: z.enum(['claude', 'gemini', 'all']).optional().default('all'),
    constitutional: z.boolean().optional().default(false), // Marks constitutional requirements
  }),
});

// Developer Documentation Collection Schema
const developerCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date().optional(),
    updatedDate: z.date().optional(),
    author: z.string().optional().default('Development Team'),
    tags: z.array(z.string()).optional().default(['development']),
    order: z.number().optional(),
    // Developer-specific fields
    techStack: z.array(z.string()).optional().default([]),
    difficulty: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  }),
});

// Export collections
export const collections = {
  'user-guide': userGuideCollection,
  'ai-guidelines': aiGuidelinesCollection,
  'developer': developerCollection,
};
