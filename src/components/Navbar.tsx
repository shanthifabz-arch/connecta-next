'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navItems = [
  { label: 'Dashboard', href: '/dashboard' },
  { label: 'Merchant Onboarding', href: '/dashboard/merchant' },
  { label: 'Join Community', href: '/join-community' },
  { label: 'Register', href: '/register' },
  { label: 'Login', href: '/login' },
];

export default function Navbar() {
  const pathname = usePathname();

  return (
    <nav className="bg-gray-800 text-white px-4 py-3 shadow-md">
      <div className="max-w-7xl mx-auto flex justify-between items-center">
        <div className="font-bold text-lg">CONNECTA</div>
        <div className="flex space-x-4">
          {navItems.map((item) => (
            <Link key={item.href} href={item.href}>
              <span className={`cursor-pointer hover:underline ${pathname === item.href ? 'text-yellow-300' : ''}`}>
                {item.label}
              </span>
            </Link>
          ))}
        </div>
      </div>
    </nav>
  );
}

