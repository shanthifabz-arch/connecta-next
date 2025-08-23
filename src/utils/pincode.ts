import { supabase } from "@/lib/supabaseClient";

export async function validatePincode(country: string, pincode: string): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .from("pincode_rules")
      .select("pattern")
      .eq("country", country)
      .single();

    if (error) {
      console.error("Error fetching pincode rule:", error);
      return false;
    }

    if (!data || !data.pattern) {
      console.warn("No pincode pattern found for country:", country);
      return false;
    }

    // Fix escaping (convert \\d{4} into \d{4})
    const rawPattern = data.pattern.replace(/\\\\/g, "\\");
    const regex = new RegExp(rawPattern);

    // Trim spaces and validate
    return regex.test(pincode.trim());
  } catch (err) {
    console.error("Validation error:", err);
    return false;
  }
}

