export function tableName(projectSlug: string, stage: string): string {
  return `${projectSlug}-${stage}`;
}
