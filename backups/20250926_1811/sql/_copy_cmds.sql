SELECT format(
  '\copy %I.%I to ''C:/Users/User/connecta-next/backups/20250926_1811/csv/%s/%s.csv'' csv header',
  schemaname, tablename, schemaname, tablename
)
FROM pg_tables
WHERE schemaname IN ('public','auth','storage')
ORDER BY schemaname, tablename;