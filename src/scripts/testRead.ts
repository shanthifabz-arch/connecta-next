import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function testRead() {
  try {
    const DATA_DIR = path.resolve(__dirname, "./data");
    const files = await fs.readdir(DATA_DIR);
    const xlsxFiles = files.filter(f => f.toLowerCase().endsWith(".xlsx"));
    console.log("Files found:", xlsxFiles);
    
    for (const file of xlsxFiles) {
      const filePath = path.join(DATA_DIR, file);
      console.log(`Reading file: ${filePath}`);
      const buffer = await fs.readFile(filePath);
      console.log(`File size: ${buffer.byteLength} bytes`);
    }
  } catch (error) {
    console.error("Error reading files:", error);
  }
}

testRead();

