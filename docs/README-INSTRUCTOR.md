# Instructor Guide: Astro Workshop

Welcome to the Astro Workshop template repository! This guide provides an overview of the repository structure, the available branches, and how to effectively use them during your instructional sessions.

## What is this Repository?

This repository contains a progressive, 7-phase workshop designed to teach modern web development using **Astro**. The workshop guides students through building a production-grade content platform from scratch, covering advanced topics such as:

* Directory architecture and separated concerns
* Content Collections with Zod schema validation
* Dynamic routing and unified type safety
* External data fetching with custom content loaders
* Performance optimizations (conditional client-side JavaScript loading)
* Styling (Tailwind CSS v4) and Asset Delivery (Vite Static Copy)
* Production readiness (ESLint configuration and SEO)

## What are the Branches?

To facilitate a smooth learning experience, the repository is split into multiple git branches. Each branch corresponds to a specific phase of the workshop and contains the *completed code up to that point*.

* **`main`**: The base branch (contains the initial Astro setup before any phase work begins).
* **`phase-1`**: **Project Setup & Directory Spaces** (Includes the base empty folder structure).
* **`phase-2`**: **Defining the Content Schema** (Includes `src/content.config.ts` using Zod).
* **`phase-3`**: **The Data Pipeline & Dynamic Routing** (Includes routing templates `index.astro` and `[...id].astro`).
* **`phase-4`**: **Extending with Custom Content Loaders** (Includes external `authors` REST API loader).
* **`phase-5`**: **Dynamic Performance & Asset Optimization** (Includes conditional script loading for Mermaid/Chart.js).
* **`phase-6`**: **Styling, Asset Delivery & SEO** (Includes Tailwind v4, Sitemap, and Vite static copy).
* **`phase-7`**: **Production Readiness, Linting & Homepages** (Includes ESLint config and the root `index.astro` homepage).

## How to use them in a Workshop

These branches allow students to work at their own pace without falling behind. Here is how you can use them in a live or self-paced workshop setting:

### 1. Following Along (The Happy Path)

Students start on `main` (or run `npm create astro@latest` themselves) and manually write code as you teach through each phase.

### 2. Catching Up / Bypassing Setup

If a student joins late, encounters an unfixable bug, or falls behind during a specific phase, they can quickly catch up by checking out the branch corresponding to the phase they want to start working on.

For example, if you are about to teach **Phase 4**, a student who is behind can run:

```bash
# Stash any broken local work
git stash

# Jump directly to the completed state of Phase 3, ready to begin Phase 4
git checkout phase-3
```

Now they have the exact folder structure and code needed to participate in Phase 4 alongside the rest of the class.

### 3. Solution Verification

Students can use the branches to verify their work. After completing Phase 2 on their own, they can run `git diff phase-2` to see how their implementation differs from the official workshop solution.

---

**Tip for Instructors:** Make sure students install dependencies (`npm install`) after switching branches, as some phases introduce new packages (like `tailwindcss` or `eslint`).
