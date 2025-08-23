"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import TestSupabaseConnection from "@/components/TestSupabaseConnection";

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    router.push("/welcome");
  }, [router]);

  return (
    <>
      <TestSupabaseConnection />
    </>
  );
}

