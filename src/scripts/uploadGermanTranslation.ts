import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';

// Fix for __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from .env.local two levels up
dotenv.config({ path: path.resolve(__dirname, '../../.env.local') });

import * as XLSX from 'xlsx';
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs/promises';

// Initialize Supabase client with environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

async function uploadTranslations() {
  try {
    // Path to the Excel file relative to this script
    const filePath = path.resolve(__dirname, './data/translation_german.xlsx');

    // Read the Excel file as a buffer
    const fileBuffer = await fs.readFile(filePath);

    // Parse workbook and get first sheet
    const workbook = XLSX.read(fileBuffer);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];

    // Convert sheet to JSON array
    const rows: any[] = XLSX.utils.sheet_to_json(sheet);

    // Build translations object
    const translations: Record<string, string> = {};
    rows.forEach(row => {
      if (row.Key && row.German) {
        translations[row.Key] = row.German;
      }
    });

    // Define the language code matching your table schema
    const languageCode = 'de'; // German

    // Upsert translations in Supabase to avoid duplicates
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
      console.error('Error uploading translations:', error);
    } else {
      console.log('Successfully uploaded German translations!');
    }
  } catch (err) {
    console.error('Error reading or uploading file:', err);
  }
}

uploadTranslations();

