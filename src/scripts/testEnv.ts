import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Point to project root .env
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

console.log("Loaded .env file");
console.log("SUPABASE_URL:", process.env.NEXT_PUBLIC_SUPABASE_URL || "NOT FOUND");
console.log("SUPABASE_KEY:", process.env.SUPABASE_SERVICE_ROLE_KEY || "NOT FOUND");

