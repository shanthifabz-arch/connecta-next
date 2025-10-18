import { NextRequest, NextResponse } from 'next/server';
export async function GET(req: NextRequest) { return new NextResponse('OK'); }
export async function POST(req: NextRequest) { return NextResponse.json({ ok: true }); }
