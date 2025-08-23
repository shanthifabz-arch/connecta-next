import * as dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';
import * as XLSX from 'xlsx';
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from .env.local
dotenv.config({ path: path.resolve(__dirname, '../../.env.local') });

// Initialize Supabase client
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

async function uploadTranslationsForFile(filePath: string, languageCode: string, languageColumn: string) {
  try {
    const fileBuffer = await fs.readFile(filePath);
    const workbook = XLSX.read(fileBuffer);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows: any[] = XLSX.utils.sheet_to_json(sheet);

    const translations: Record<string, string> = {};
    rows.forEach(row => {
      if (row.Key && row[languageColumn]) {
        translations[row.Key] = row[languageColumn];
      }
    });

    const { error } = await supabase
      .from('translations')
      .upsert(
        {
          language_code: languageCode,
          translations: translations,
        },
        { onConflict: 'language_code' }
      );

    if (error) {
      console.error(`Error uploading translations for ${languageCode}:`, error);
    } else {
      console.log(`Successfully uploaded translations for ${languageCode}!`);
    }
  } catch (err) {
    console.error(`Error reading or uploading file for ${languageCode}:`, err);
  }
}

async function run() {
  const dataDir = path.resolve(__dirname, './data');
  const files = await fs.readdir(dataDir);

  for (const file of files) {
    if (file.endsWith('.xlsx')) {
      const fullPath = path.join(dataDir, file);

      // Extract language code from filename: e.g. translation_german.xlsx â†' german
      const langMatch = file.match(/^translation_(.+)\.xlsx$/i);
      if (!langMatch) {
        console.warn(`Skipping file with unexpected name format: ${file}`);
        continue;
      }
      const languageCode = langMatch[1].toLowerCase();

      // Language column header usually matches languageCode with first letter uppercase
      // e.g. 'german' -> 'German'
      const languageColumn = languageCode.charAt(0).toUpperCase() + languageCode.slice(1);

      console.log(`Uploading ${file} as language code "${languageCode}", column "${languageColumn}"`);
      await uploadTranslationsForFile(fullPath, languageCode, languageColumn);
    }
  }
}

run();

