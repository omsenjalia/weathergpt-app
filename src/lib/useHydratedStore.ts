/// Helper that hydrates a zustand store from persistence once, exposing
/// `hydrated` so screens can render an honest loading state instead of
/// flashing defaults.

import { useEffect, useState } from "react";

export function useHydrated(...flags: boolean[]): boolean {
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => {
    if (!hydrated && flags.length > 0 && flags.every(Boolean)) {
      setHydrated(true);
    }
  }, [hydrated, flags]);
  return hydrated && flags.every(Boolean);
}
