import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Keep builds moving while we tidy ESLint separately
  eslint: { ignoreDuringBuilds: true },
};

export default nextConfig;
