import './globals.css';

export const metadata = {
  title: 'Connecta',
  description: 'Welcome',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        {/* Legacy styles first; we override only what we must */}
        <link rel="stylesheet" href="/assets/styles.css" />

        <style
          dangerouslySetInnerHTML={{
            __html: `
              :root {
                color-scheme: light;
                --field-max: 640px;     /* inputs/selects/textarea max width */
                --button-width: 300px;   /* uniform button width */
                --radius: 12px;
              }

              /* Always light, no dark gutters */
              html, body { background:#fff !important; color:#111 !important; margin:0; padding:0; }
              body > div, #__next, main { background:#fff !important; }

              /* ---------- Form controls: rounded + gentle 3D ---------- */
              .min-h-screen input,
              .min-h-screen select,
              .min-h-screen textarea {
                display:block;
                width:100%;
                max-width:var(--field-max);
                margin-left:auto;
                margin-right:auto;
                border-radius:var(--radius);
                border:1px solid #cbd5e1;                               /* slate-300 */
                background:
                  linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);     /* soft top-light */
                color:#111;
                box-shadow:
                  inset 0 1px 0 rgba(255,255,255,0.9),                  /* highlight */
                  inset 0 -1px 0 rgba(0,0,0,0.035),                      /* subtle bottom */
                  0 1px 2px rgba(0,0,0,0.08);                            /* outer */
              }
              .min-h-screen input:focus,
              .min-h-screen select:focus,
              .min-h-screen textarea:focus {
                outline:none;
                border-color:#60a5fa;                                   /* blue-400 */
                box-shadow:
                  0 0 0 3px rgba(59,130,246,0.25),
                  inset 0 1px 0 rgba(255,255,255,0.9),
                  inset 0 -1px 0 rgba(0,0,0,0.035),
                  0 1px 2px rgba(0,0,0,0.08);
              }

              /* ---------- Uniform buttons (centered, lighter blue, clearer text) ---------- */
              .min-h-screen button {
                display:block;
                width:var(--button-width);
                margin-left:auto;
                margin-right:auto;
                border-radius: calc(var(--radius) + 4px);
                box-shadow:
                  0 2px 0 rgba(0,0,0,0.06),
                  inset 0 1px 0 rgba(255,255,255,0.25);
                transition: transform .02s ease, filter .12s ease;
                font-weight: 600;
                text-shadow: 0 1px 0 rgba(0,0,0,0.12);
              }
              /* lighten the primary blue */
              .min-h-screen button.bg-blue-600 {
                background: linear-gradient(180deg,#3b82f6 0%,#2563eb 100%); /* blue-500 -> blue-600 */
              }
              .min-h-screen button.bg-blue-600:hover { filter: brightness(1.03); }
              .min-h-screen button:active { transform: translateY(1px); }
              .min-h-screen button.cursor-not-allowed { opacity:.9; transform:none; }

              /* ---------- Terms row: align & center like fields ---------- */
              .min-h-screen .mb-6.w-full.text-center {
                max-width: var(--field-max);
                margin-left: auto;
                margin-right: auto;
              }
              .min-h-screen .mb-6.w-full.text-center label.inline-flex.items-center {
                display:flex;
                align-items:center;
                justify-content:center;
                gap: .5rem;      /* space between checkbox and text */
                width:100%;
              }

              /* ---------- NO dial-code badge override ----------
                 We intentionally do NOT restyle the +91 span now, so the
                 default layout from your component remains. */
            `,
          }}
        />
      </head>

      {/* Tailwind utilities available app-wide */}
      <body className="bg-white text-black font-sans">
        {children}
      </body>
    </html>
  );
}
