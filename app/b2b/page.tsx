// app/b2b/page.tsx
import { redirect } from "next/navigation";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default function Page() {
  // Server-only redirect — no client code, no Supabase, super safe in CI
  redirect("/connect/b2b");
}
