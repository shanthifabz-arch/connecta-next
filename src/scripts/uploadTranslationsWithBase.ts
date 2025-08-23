import fs from "fs/promises";
import path from "path";
import XLSX from "xlsx";
import dotenv from "dotenv";
import { fileURLToPath } from "url";
import { createClient } from "@supabase/supabase-js";

// Setup __dirname for ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load env variables from project root .env
dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error("Missing Supabase env variables. Exiting.");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const DATA_DIR = path.resolve(__dirname, "./data");

interface ExcelRow {
  Key?: string;
  key?: string;
  Translation?: string;
  translation?: string;
  English?: string;
  english?: string;
}

async function uploadTranslationFile(
  fileName: string,
  _baseTranslations: Record<string, string> | null // Not used now, but kept for signature consistency
): Promise<void> {
  try {
    const filePath = path.join(DATA_DIR, fileName);
    const fileBuffer = await fs.readFile(filePath);
    const workbook = XLSX.read(fileBuffer);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json<ExcelRow>(worksheet);

    console.log(`Reading file: ${fileName} (${rows.length} rows)`);

    const translations: Record<string, string> = {};
    const baseTrans: Record<string, string> = {};

    for (const row of rows) {
      const key = row.key || row.Key;
      const translation = row.translation || row.Translation || "";
      const englishText = row.english || row.English || "";

      if (key) {
        translations[key] = translation;
        if (englishText) {
          baseTrans[key] = englishText;
        }
      }
    }

    if (Object.keys(translations).length === 0) {
      console.warn(`No translations found in file "${fileName}". Skipping upload.`);
      return;
    }

    const language_code = fileName.toLowerCase().replace("translation_", "").replace(".xlsx", "");

    const keysArray = Object.keys(translations);

    const upsertPayload: any = {
      language_code,
      keys: keysArray,             // <-- Added keys array here
      translations,
      base_translations: baseTrans,
      created_at: new Date().toISOString(),
    };

    console.log(`Uploading translations for "${language_code}" with keys array and base translations.`);

    const { error } = await supabase
      .from("translations")
      .upsert([upsertPayload], { onConflict: "language_code" });

    if (error) {
      console.error(`Error uploading "${language_code}":`, error.message);
    } else {
      console.log(`Uploaded "${language_code}" successfully.`);
    }

  } catch (error: any) {
    console.error(`Error processing file "${fileName}":`, error.message);
    if (error.stack) console.error(error.stack);
  }
}

async function main() {
  try {
    const files = await fs.readdir(DATA_DIR);
    const xlsxFiles = files.filter((f) => f.toLowerCase().endsWith(".xlsx"));

    if (xlsxFiles.length === 0) {
      console.warn(`No .xlsx files found in directory "${DATA_DIR}".`);
      return;
    }

    console.log(`Found ${xlsxFiles.length} .xlsx files. Starting upload process...`);

    for (const file of xlsxFiles) {
      await uploadTranslationFile(file, null);
    }

    console.log("All files processed.");
  } catch (error: any) {
    console.error("Fatal error in main:", error.message);
    if (error.stack) console.error(error.stack);
  }
}

main().catch((err) => {
  console.error("Uncaught error in main:", err);
  if (err.stack) console.error(err.stack);
});

