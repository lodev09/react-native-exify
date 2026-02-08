/**
 * Error safe JSON.stringify
 */
export const json = (value?: unknown, space = 2): string => {
  try {
    return JSON.stringify(value, undefined, space);
  } catch {
    return String(value);
  }
};
