// src/app/onboarding-tabs/page.tsx
import { Suspense } from "react";
import OnboardingTabs from "@/components/OnboardingTabs";

// This route reads client router state (query string), so don't pre-render it.
export const dynamic = "force-dynamic";
export const revalidate = 0;

export default function OnboardingTabsPage() {
  return (
    <Suspense fallback={<div className="p-6 text-gray-600">Loading…</div>}>
      <OnboardingTabs />
    </Suspense>
  );
}
