﻿import { NextResponse } from "next/server";
export async function GET() {
  return NextResponse.json({ ok: true, router: "app-root", ts: new Date().toISOString() });
}
