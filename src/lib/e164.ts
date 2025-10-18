export function toE164Loose(input: string): string | null { return input?.startsWith('+') ? input : null; }
