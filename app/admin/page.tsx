'use client';

import { useMemo, useState } from 'react';
import dynamic from 'next/dynamic';

/* -------------------------------------------
   Small helpers
-------------------------------------------- */
function cx(...parts: Array<string | false | null | undefined>) {
  return parts.filter(Boolean).join(' ');
}
const Loading = ({ label = 'Loading…' }: { label?: string }) => (
  <div className="py-6 text-center text-sm text-gray-600">{label}</div>
);

/* -------------------------------------------
   Lazy panels (no SSR; they’re heavy + client-only)
-------------------------------------------- */
const AAConnectorUpload = dynamic(
  () => import('@/components/admin/AAConnectorUpload'),
  { ssr: false, loading: () => <Loading label="Loading AA Connector List…" /> }
);

const LanguageManagement = dynamic(
  () => import('@/components/admin/LanguageManagement'),
  { ssr: false, loading: () => <Loading label="Loading Language Management…" /> }
);

const CountryStateManager = dynamic(
  () => import('@/components/admin/CountryStateManager'),
  { ssr: false, loading: () => <Loading label="Loading Country/State Manager…" /> }
);

const ReadOnlyViewer = dynamic(
  () => import('@/components/admin/ReadOnlyViewer'),
  { ssr: false, loading: () => <Loading label="Loading Read-Only Viewer…" /> }
);

const TranslationEditor = dynamic(
  () => import('@/components/admin/TranslationEditor'),
  { ssr: false, loading: () => <Loading label="Loading Translation Editor…" /> }
);

const TranslationUpload = dynamic(
  () => import('@/components/admin/TranslationUpload'),
  { ssr: false, loading: () => <Loading label="Loading Translation Upload…" /> }
);

const TranslationViewer = dynamic(
  () => import('@/components/admin/TranslationViewer'),
  { ssr: false, loading: () => <Loading label="Loading Translation Viewer…" /> }
);

/* ---------- NEW: Affiliates Management tab ---------- */
const AdminAffiliatesPage = dynamic(
  () => import('@/components/admin/AdminAffiliatesPage').then(m => m.default),
  { ssr: false, loading: () => <Loading label="Loading Affiliates Management…" /> }
);



/* -------------------------------------------
   Page
-------------------------------------------- */
type TabKey =
  | 'aa'
  | 'lang'
  | 'geo'
  | 'ro'
  | 'tvedit'
  | 'tvupload'
  | 'tv'
  | 'aff';                 // NEW

const TABS: Array<{ key: TabKey; label: string }> = [
  { key: 'aa',       label: 'AA Connector List' },
  { key: 'lang',     label: 'Language Management' },
  { key: 'geo',      label: 'Country/State Manager' },
  { key: 'tvedit',   label: 'Translation Editor' },
  { key: 'tvupload', label: 'Translation Upload' },
  { key: 'tv',       label: 'Translation Viewer' },
  { key: 'aff',      label: 'Affiliates Management' }, // NEW
  { key: 'ro',       label: 'Read-Only Viewer' },
];

export default function AdminPage() {
  const [active, setActive] = useState<TabKey>('aa');

  const Content = useMemo(() => {
    switch (active) {
      case 'aa':       return <AAConnectorUpload />;
      case 'lang':     return <LanguageManagement />;
      case 'geo':      return <CountryStateManager />;
      case 'ro':       return <ReadOnlyViewer />;
      case 'tvedit':   return <TranslationEditor />;
      case 'tvupload': return <TranslationUpload />;
      case 'tv':       return <TranslationViewer />;
      case 'aff':      return <AdminAffiliatesPage />; // NEW
      default:         return null;
    }
  }, [active]);

  return (
    <div className="min-h-screen bg-white text-black">
      <div className="mx-auto w-full max-w-6xl px-4 py-8">
        <h1 className="text-center text-3xl font-extrabold text-blue-600 tracking-wide">
          CONNECTA ADMIN PANEL
        </h1>

        {/* Tabs */}
        <div className="sticky top-0 z-10 mt-6 mb-6 bg-white/80 backdrop-blur supports-[backdrop-filter]:bg-white/60">
          <div className="mx-auto flex flex-wrap justify-center gap-3">
            {TABS.map(t => (
              <button
                key={t.key}
                type="button"
                onClick={() => setActive(t.key)}
                className={cx(
                  'rounded-full px-5 py-2 text-sm border transition',
                  active === t.key
                    ? 'bg-blue-600 text-white border-blue-600 shadow'
                    : 'bg-white text-gray-800 border-gray-300 hover:bg-gray-50'
                )}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>

        {/* Panel content */}
        <div className="rounded-lg border border-gray-200 bg-white p-4 sm:p-6 shadow-sm">
          {Content}
        </div>
      </div>
    </div>
  );
}
