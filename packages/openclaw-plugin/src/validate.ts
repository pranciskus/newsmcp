export function nonEmptyString(value: unknown, name: string): string {
  const s = typeof value === "string" ? value.trim() : "";
  if (!s) {
    throw new Error(`${name} must be a non-empty string`);
  }
  return s;
}

export function optionalString(value: unknown): string | undefined {
  if (value == null) return undefined;
  const s = typeof value === "string" ? value.trim() : "";
  return s || undefined;
}

export function optionalPositiveInt(
  value: unknown,
  name: string,
): number | undefined {
  if (value == null) return undefined;
  const n = Number(value);
  if (!Number.isInteger(n) || n < 1) {
    throw new Error(
      `${name} must be a positive integer, got: ${String(value)}`,
    );
  }
  return n;
}

export function enumValue<T extends string>(
  value: unknown,
  allowed: readonly T[],
  name: string,
  fallback: T,
): T {
  if (value == null) return fallback;
  const s = String(value);
  if (!allowed.includes(s as T)) {
    throw new Error(`${name} must be one of: ${allowed.join(", ")}. Got: ${s}`);
  }
  return s as T;
}
