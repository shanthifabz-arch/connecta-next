// src/app/layout.tsx
import "./globals.css";
import type { Metadata } from "next";
import { Inter, Noto_Sans_Tamil } from "next/font/google";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const notoTamil = Noto_Sans_Tamil({
  subsets: ["tamil"],
  weight: ["400", "700"],
  display: "swap",
  variable: "--font-noto-tamil",
});

export const metadata: Metadata = {
  title: "CONNECTA",
  description: "Empowering Connections, Enabling Commissions",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      {/* We attach the font CSS variables at the body level */}
      <body className={`${inter.variable} ${notoTamil.variable}`}>
        {children}
      </body>
    </html>
  );
}
