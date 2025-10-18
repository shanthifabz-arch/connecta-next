import { NextResponse } from "next/server";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const timezone   = searchParams.get("timezone")   ?? "Asia/Kolkata";
  const language   = searchParams.get("language")   ?? "en-IN";
  const onlyVisible = (searchParams.get("onlyVisible") ?? "true").toLowerCase() === "true";
  const limit      = Math.max(1, Math.min(200, Number(searchParams.get("limit") ?? "50") || 50));

  // TODO: replace with real data source
  const allItems = [
    { id: 1, title: "Hydration",      isVisible: true,  language: "ta-IN" },
    { id: 2, title: "Walk 20 mins",   isVisible: true,  language: "ta-IN" },
    { id: 3, title: "Digital Detox",  isVisible: false, language: "ta-IN" },
    { id: 4, title: "Read 10 pages",  isVisible: true,  language: "en-IN" },
  ];

  let items = allItems.filter(i => i.language === language);
  if (onlyVisible) items = items.filter(i => i.isVisible);
  items = items.slice(0, limit);

  return NextResponse.json({
    timezone, language, onlyVisible, limit, count: items.length, items
  });
}
