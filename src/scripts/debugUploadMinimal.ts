import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs/promises";
import XLSX from "xlsx";
import { createClient } from "@supabase/supabase-js";

// Setup __dirname in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables explicitly from project root .env
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

// Check env vars
console.log("Loaded .env");
console.log("SUPABASE_URL:", process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL);
console.log("SUPABASE_KEY:", process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY);

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error("Missing Supabase env variables, exiting.");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const DATA_DIR = path.resolve(__dirname, "./data");

async function test() {
  try {
    // List files in data dir
    const files = await fs.readdir(DATA_DIR);
    console.log("Files found in data dir:", files);

    // Read first file's content and parse with XLSX
    if (files.length === 0) {
      console.error("No files found in data directory. Exiting.");
      return;
    }
    const filePath = path.join(DATA_DIR, files[0]);
    const buffer = await fs.readFile(filePath);
    const workbook = XLSX.read(buffer);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(worksheet);
    console.log("First 3 rows from first file:", rows.slice(0, 3));

    // Test a simple Supabase query
    const { data, error } = await supabase.from("translations").select("*").limit(1);
    if (error) throw error;
    console.log("Supabase query succeeded:", data);
  } catch (err: any) {
    console.error("Error in test():", err.message || err);
    if (err.stack) console.error(err.stack);
  }
}

test();

