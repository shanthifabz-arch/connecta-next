// app/api/wellness/ping/route.ts
import { NextResponse } from "next/server";
export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json({ ok: true, pong: "pong" }, { status: 200 });
}
