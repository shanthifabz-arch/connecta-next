"use client";

import { useEffect, useRef, useState } from "react";

type Row = {
  label: string;
  element: JSX.Element;
  ref: React.RefObject<HTMLElement>;
  family?: string;
};

export default function FontDiagnosticsPage() {
  const sampleEn = "Hello, this is an English typeface check.";
  const sampleTa = "வணக்கம், இது தமிழ் எழுத்துரு சோதனை.";
  const sampleMixed =
    'This line mixes English and <span lang="ta">தமிழ்</span> text.';

  // Refs for each line so we can read computed style in the browser
  const rDefaultTa = useRef<HTMLParagraphElement>(null);
  const rLangTa = useRef<HTMLParagraphElement>(null);
  const rMixed = useRef<HTMLParagraphElement>(null);
  const rForceNotoTa = useRef<HTMLParagraphElement>(null);
  const rForceInter = useRef<HTMLParagraphElement>(null);

  const [rows, setRows] = useState<Row[]>([
    {
      label: "Tamil (no lang, default styling)",
      element: <p ref={rDefaultTa}>{sampleTa}</p>,
      ref: rDefaultTa,
    },
    {
      label: 'Tamil with lang="ta" (should use Noto Sans Tamil)',
      element: (
        <p ref={rLangTa} lang="ta">
          {sampleTa}
        </p>
      ),
      ref: rLangTa,
    },
    {
      label: 'Mixed inline — English + <span lang="ta">Tamil</span>',
      element: (
        <p
          ref={rMixed}
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{ __html: sampleMixed }}
        />
      ),
      ref: rMixed,
    },
    {
      label: "Force Noto Sans Tamil via CSS variable",
      element: (
        <p
          ref={rForceNotoTa}
          style={{ fontFamily: "var(--font-noto-tamil), var(--font-sans)" }}
        >
          {sampleTa}
        </p>
      ),
      ref: rForceNotoTa,
    },
    {
      label: "Force Inter (Latin) via CSS variable",
      element: (
        <p ref={rForceInter} style={{ fontFamily: "var(--font-inter)" }}>
          {sampleEn}
        </p>
      ),
      ref: rForceInter,
    },
  ]);

  useEffect(() => {
    // Read computed font-family for each row after mount
    setRows((prev) =>
      prev.map((row) => {
        const el = row.ref.current;
        const fam = el
          ? window.getComputedStyle(el).getPropertyValue("font-family")
          : "";
        return { ...row, family: fam };
      })
    );
  }, []);

  return (
    <main className="mx-auto max-w-3xl p-6 space-y-8">
      <h1 className="text-2xl font-bold">Font Diagnostics</h1>

      <section className="space-y-2 text-sm text-gray-700">
        <p>
          This page helps verify that{" "}
          <code className="px-1 py-0.5 rounded bg-gray-100">Inter</code> is used
          for Latin text and{" "}
          <code className="px-1 py-0.5 rounded bg-gray-100">
            Noto Sans Tamil
          </code>{" "}
          is used for Tamil text when either:
        </p>
        <ul className="list-disc pl-6">
          <li>
            elements (or spans) are marked with{" "}
            <code className="px-1 py-0.5 rounded bg-gray-100">lang="ta"</code>
          </li>
          <li>
            or you force the font via{" "}
            <code className="px-1 py-0.5 rounded bg-gray-100">
              var(--font-noto-tamil)
            </code>
          </li>
        </ul>
        <p className="text-xs">
          Variables configured in <code>layout.tsx</code>:
          <code className="ml-2 px-1 py-0.5 rounded bg-gray-100">
            --font-inter
          </code>{" "}
          and{" "}
          <code className="px-1 py-0.5 rounded bg-gray-100">
            --font-noto-tamil
          </code>
          . Global CSS applies{" "}
          <code className="px-1 py-0.5 rounded bg-gray-100">:lang(ta)</code> to
          prefer Noto Sans Tamil.
        </p>
      </section>

      <div className="grid md:grid-cols-2 gap-6">
        <div className="space-y-4">
          <h2 className="font-semibold">Samples</h2>
          <div className="space-y-4 p-4 rounded-xl border bg-white">
            {rows.map((row, idx) => (
              <div key={idx} className="space-y-1">
                <div className="text-xs font-medium text-gray-600">
                  {row.label}
                </div>
                <div className="text-lg leading-7">{row.element}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="font-semibold">Computed font-family</h2>
          <div className="space-y-3 p-4 rounded-xl border bg-white">
            {rows.map((row, idx) => (
              <div
                key={idx}
                className="flex items-start gap-2 text-xs break-words"
              >
                <span className="min-w-6 h-6 flex items-center justify-center rounded bg-gray-100 text-gray-600">
                  {idx + 1}
                </span>
                <div>
                  <div className="font-medium text-gray-700">{row.label}</div>
                  <code className="block mt-0.5 px-1.5 py-1 rounded bg-gray-100">
                    {row.family || "—"}
                  </code>
                </div>
              </div>
            ))}
          </div>

          <div className="text-xs text-gray-600 p-3 rounded-md bg-blue-50 border border-blue-200">
            <p className="mb-1 font-medium">What you should see:</p>
            <ul className="list-disc pl-5 space-y-1">
              <li>
                Lines with <code>lang="ta"</code> or the forced Noto variable
                should report a family that includes something like{" "}
                <strong>Noto Sans Tamil</strong>.
              </li>
              <li>
                English lines should report <strong>Inter</strong> (or your OS
                fallback if Inter failed to load).
              </li>
            </ul>
          </div>
        </div>
      </div>
    </main>
  );
}
