/**
 * Sanitized Engram plugin template.
 *
 * This is conceptual guidance for a future reviewed OpenCode plugin. It does
 * not connect to a real database in tests and contains no personal paths.
 */

export type NoiseGateDecision = "useful" | "noise" | "secret";

export interface MemoryCandidate {
  projectId: string;
  title: string;
  content: string;
  containsSecretLikeText?: boolean;
}

export interface RecentSessionPack {
  goal: string;
  accomplishments: string[];
  decisions: string[];
  nextSteps: string[];
}

export function noiseGate(candidate: MemoryCandidate): NoiseGateDecision {
  if (candidate.containsSecretLikeText) return "secret";
  if (!candidate.title.trim() || !candidate.content.trim()) return "noise";
  return "useful";
}

export function memContextGuidance(query: string): string {
  return `Retrieve minimal project-relevant memory for: ${query}`;
}

export function f4cScore(input: { relevance: number; recency: number; typePriority: number }): number {
  return input.relevance * 0.5 + input.recency * 0.3 + input.typePriority * 0.2;
}

export function buildRecentSessionPack(pack: RecentSessionPack): RecentSessionPack {
  return {
    goal: pack.goal,
    accomplishments: [...pack.accomplishments],
    decisions: [...pack.decisions],
    nextSteps: [...pack.nextSteps]
  };
}

export const projectBoundaryGuidance = {
  secretExclusion: "Never persist tokens, private data, real databases, or logs.",
  projectBoundary: "Prefer exact project matches and avoid cross-project contamination.",
  placeholders: ["${ENGRAM_DB_PATH}", "${OPENCODE_CONFIG_DIR}", "${PROJECT_ROOT}"]
};

export default function configureEngramTemplate() {
  return {
    name: "engram-template",
    mode: "template-only",
    writesRealDatabaseInTests: false
  };
}
