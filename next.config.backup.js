/** @type {import('next').NextConfig} */
const nextConfig = {
  // Do NOT set output: 'export' here; it breaks API routes.
  // Leave experimental.appDir as default (App Router enabled).
  // No rewrites that swallow /api/*.
};
module.exports = nextConfig;
