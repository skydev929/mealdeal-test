// Supabase Edge Function for CSV Import
// Handles CSV file uploads, validation, and database insertion

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface CSVImportResult {
  validRows: number;
  errors: string[];
  imported?: number;
}

// Generate hash for offer deduplication
function generateOfferHash(row: Record<string, any>): string {
  const hashData = [
    row.region_id,
    row.ingredient_id,
    row.price_total,
    row.pack_size,
    row.valid_from,
    row.valid_to,
    row.source_ref_id,
  ].join('|');
  
  // Simple hash function
  let hash = 0;
  for (let i = 0; i < hashData.length; i++) {
    const char = hashData.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return hash.toString(36);
}

// Parse CSV content
function parseCSV(content: string): string[][] {
  const lines: string[][] = [];
  let currentLine: string[] = [];
  let currentField = '';
  let inQuotes = false;

  for (let i = 0; i < content.length; i++) {
    const char = content[i];
    const nextChar = content[i + 1];

    if (char === '"') {
      if (inQuotes && nextChar === '"') {
        currentField += '"';
        i++; // Skip next quote
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      currentLine.push(currentField.trim());
      currentField = '';
    } else if ((char === '\n' || char === '\r') && !inQuotes) {
      if (currentField || currentLine.length > 0) {
        currentLine.push(currentField.trim());
        currentField = '';
      }
      if (currentLine.length > 0) {
        lines.push(currentLine);
        currentLine = [];
      }
    } else {
      currentField += char;
    }
  }

  // Add last line
  if (currentField || currentLine.length > 0) {
    currentLine.push(currentField.trim());
    lines.push(currentLine);
  }

  return lines.filter(line => line.length > 0);
}

// Validate and transform row based on table type
function validateRow(
  headers: string[],
  row: string[],
  tableType: string
): { valid: boolean; data?: Record<string, any>; error?: string } {
  if (row.length !== headers.length) {
    return { 
      valid: false, 
      error: `Wrong number of columns: found ${row.length}, expected ${headers.length}. Check for extra commas or missing values.` 
    };
  }

  const rowData: Record<string, any> = {};
  for (let i = 0; i < headers.length; i++) {
    const value = row[i].trim();
    const header = headers[i].trim();

    // Skip empty values for optional fields
    if (value === '' || value === 'NULL' || value === 'null') {
      rowData[header] = null;
      continue;
    }

    // Type conversions based on table schema
    switch (tableType) {
      case 'offers':
        if (header === 'region_id') {
          // Convert to integer
          const num = parseInt(value, 10);
          if (isNaN(num)) {
            return { valid: false, error: `Invalid region_id "${value}": must be a number (e.g., 500, 501). Make sure the region exists in ad_regions table.` };
          }
          rowData[header] = num;
        } else if (header === 'ingredient_id') {
          // Convert numeric ID to text ID format (e.g., 1 -> I001, 2 -> I002)
          // If it's already in text format, keep it
          if (/^\d+$/.test(value)) {
            // It's a number, convert to I001 format
            const num = parseInt(value, 10);
            rowData[header] = `I${String(num).padStart(3, '0')}`;
          } else {
            // Already in text format
            rowData[header] = value;
          }
        } else if (header === 'price_total' || header === 'pack_size') {
          const num = parseFloat(value.replace(',', '.'));
          if (isNaN(num)) {
            return { valid: false, error: `Invalid number for ${header}: "${value}". Use numbers only (e.g., 1.99 or 1,99).` };
          }
          if (num < 0) {
            return { valid: false, error: `Invalid ${header}: "${value}". Numbers cannot be negative.` };
          }
          rowData[header] = num;
        } else if (header === 'valid_from' || header === 'valid_to') {
          // Validate date format (YYYY-MM-DD)
          const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
          if (!dateRegex.test(value)) {
            return { valid: false, error: `Invalid date format for ${header}: "${value}". Use format YYYY-MM-DD (e.g., 2025-01-13).` };
          }
          // Check if date is valid
          const date = new Date(value);
          if (isNaN(date.getTime())) {
            return { valid: false, error: `Invalid date for ${header}: "${value}". Date does not exist (e.g., 2025-13-45 is invalid).` };
          }
          rowData[header] = value; // Date as string
        } else {
          rowData[header] = value;
        }
        break;

      case 'dishes':
        if (header === 'is_quick' || header === 'is_meal_prep') {
          rowData[header] = value.toUpperCase() === 'TRUE';
        } else {
          rowData[header] = value;
        }
        break;

      case 'dish_ingredients':
        if (header === 'qty') {
          const num = parseFloat(value.replace(',', '.'));
          if (isNaN(num)) {
            return { valid: false, error: `Invalid quantity: "${value}". Use numbers only (e.g., 250 or 250,5).` };
          }
          if (num <= 0) {
            return { valid: false, error: `Invalid quantity: "${value}". Quantity must be greater than 0.` };
          }
          rowData[header] = num;
        } else if (header === 'optional') {
          rowData[header] = value.toUpperCase() === 'TRUE';
        } else {
          rowData[header] = value;
        }
        break;

      case 'ingredients':
        if (header === 'price_baseline_per_unit') {
          const num = parseFloat(value.replace(',', '.'));
          if (value && !isNaN(num) && num < 0) {
            return { valid: false, error: `Invalid price_baseline_per_unit: "${value}". Price cannot be negative.` };
          }
          rowData[header] = isNaN(num) ? null : num;
        } else if (header === 'allergen_tags') {
          rowData[header] = value ? value.split(',').map(t => t.trim()) : null;
        } else {
          rowData[header] = value;
        }
        break;

      default:
        rowData[header] = value;
    }
  }

  return { valid: true, data: rowData };
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Use service role key to bypass RLS for admin operations
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    const formData = await req.formData();
    const file = formData.get('file') as File;
    const tableType = formData.get('type') as string;
    const dryRun = formData.get('dryRun') === 'true';

    if (!file || !tableType) {
      return new Response(
        JSON.stringify({ error: 'Missing file or type' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const content = await file.text();
    const lines = parseCSV(content);

    if (lines.length < 2) {
      return new Response(
        JSON.stringify({ error: 'CSV must have at least a header and one data row' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const headers = lines[0].map(h => h.trim());
    const dataRows = lines.slice(1);

    const result: CSVImportResult = {
      validRows: 0,
      errors: [],
    };

    const validRows: Record<string, any>[] = [];

    // Validate all rows
    for (let i = 0; i < dataRows.length; i++) {
      const row = dataRows[i];
      const validation = validateRow(headers, row, tableType);

      if (!validation.valid) {
        // Add row number and more context to error
        const rowNum = i + 2; // +2 because row 1 is header, and arrays are 0-indexed
        const errorMsg = validation.error || 'Unknown validation error';
        result.errors.push(`Row ${rowNum}: ${errorMsg}`);
        continue;
      }

      // Add offer hash for offers table
      if (tableType === 'offers' && validation.data) {
        validation.data.offer_hash = generateOfferHash(validation.data);
      }

      validRows.push(validation.data!);
      result.validRows++;
    }

    // If dry run, return validation results
    if (dryRun) {
      result.imported = undefined; // Explicitly set to undefined for dry run
      return new Response(
        JSON.stringify(result),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Import data
    if (validRows.length > 0) {
      console.log(`Importing ${validRows.length} rows into ${tableType}`);
      let insertError = null;
      let insertedCount = 0;
      
      // Handle different conflict resolution based on table type
      if (tableType === 'offers') {
        // Offers table has offer_hash for deduplication
        // Insert in batches to avoid issues
        for (const row of validRows) {
          const { error, data } = await supabaseClient
            .from(tableType)
            .upsert(row, { 
              onConflict: 'offer_hash', 
              ignoreDuplicates: false 
            })
            .select();
          if (error) {
            console.error(`Error inserting offer row:`, row, error);
            const rowIndex = validRows.indexOf(row) + 2; // +2 for header and 0-index
            result.errors.push(`Row ${rowIndex}: Failed to import offer - ${error.message || 'Unknown error'}`);
            if (!insertError) insertError = error;
            continue; // Continue with next row instead of breaking
          }
          if (data && data.length > 0) insertedCount++;
        }
      } else if (tableType === 'lookups_categories' || tableType === 'lookups_units') {
        // Lookup tables use the first column as primary key
        const primaryKey = headers[0];
        const { error, data } = await supabaseClient
          .from(tableType)
          .upsert(validRows, { 
            onConflict: primaryKey,
            ignoreDuplicates: false 
          })
          .select();
        insertError = error;
        if (data) insertedCount = data.length;
      } else if (tableType === 'chains') {
        // Chains table uses chain_id or chain_name as unique
        const { error, data } = await supabaseClient
          .from(tableType)
          .upsert(validRows, { 
            onConflict: 'chain_id',
            ignoreDuplicates: false 
          })
          .select();
        insertError = error;
        if (data) insertedCount = data.length;
      } else if (tableType === 'ingredients') {
        // Ingredients uses ingredient_id as primary key
        const { error, data } = await supabaseClient
          .from(tableType)
          .upsert(validRows, { 
            onConflict: 'ingredient_id',
            ignoreDuplicates: false 
          })
          .select();
        insertError = error;
        if (data) insertedCount = data.length;
      } else if (tableType === 'dishes') {
        // Dishes uses dish_id as primary key
        const { error, data } = await supabaseClient
          .from(tableType)
          .upsert(validRows, { 
            onConflict: 'dish_id',
            ignoreDuplicates: false 
          })
          .select();
        insertError = error;
        if (data) insertedCount = data.length;
      } else if (tableType === 'dish_ingredients') {
        // Dish ingredients has composite primary key (dish_id, ingredient_id)
        // Supabase doesn't support composite keys in onConflict, so we need to insert one by one
        for (const row of validRows) {
          const { error, data } = await supabaseClient
            .from(tableType)
            .upsert(row, { 
              onConflict: 'dish_id,ingredient_id',
              ignoreDuplicates: false 
            })
            .select();
          if (error) {
            console.error(`Error inserting dish_ingredient row:`, row, error);
            const rowIndex = validRows.indexOf(row) + 2; // +2 for header and 0-index
            let errorMsg = error.message || 'Unknown error';
            
            // Enhance error message with context
            if (error.message?.includes('foreign key')) {
              if (error.message.includes('dish_id')) {
                errorMsg = `Dish ID "${row.dish_id}" not found. Import dishes first.`;
              } else if (error.message.includes('ingredient_id')) {
                errorMsg = `Ingredient ID "${row.ingredient_id}" not found. Import ingredients first.`;
              } else if (error.message.includes('unit')) {
                errorMsg = `Unit "${row.unit}" not found. Import units lookup first.`;
              }
            }
            
            result.errors.push(`Row ${rowIndex}: ${errorMsg}`);
            if (!insertError) insertError = error;
            continue; // Continue with next row
          }
          if (data && data.length > 0) insertedCount++;
        }
      } else {
        // For other tables, use regular insert (will fail on duplicates)
        const { error, data } = await supabaseClient
          .from(tableType)
          .insert(validRows)
          .select();
        insertError = error;
        if (data) insertedCount = data.length;
      }

      if (insertError && insertedCount === 0) {
        // Only return error if no rows were inserted at all
        console.error('Insert error:', insertError);
        console.error('Error details:', JSON.stringify(insertError, null, 2));
        result.imported = insertedCount;
        
        // Extract detailed error message
        let errorMsg = insertError.message || 'Unknown error';
        const errorMsgLower = errorMsg.toLowerCase();
        
        // Provide user-friendly error messages based on error type
        if (errorMsgLower.includes('foreign key') || errorMsgLower.includes('violates foreign key')) {
          // Foreign key errors - provide specific guidance
          if (tableType === 'ingredients') {
            result.errors.push('Import Error: Unit not found');
            result.errors.push(`The unit_default value in your CSV does not exist in the lookups_units table.`);
            result.errors.push(`Fix: Import "Units (Lookup)" CSV file first, then verify unit names match exactly.`);
          } else if (tableType === 'dishes') {
            result.errors.push('Import Error: Category not found');
            result.errors.push(`The category value in your CSV does not exist in the lookups_categories table.`);
            result.errors.push(`Fix: Import "Categories (Lookup)" CSV file first, then verify category names match exactly.`);
          } else if (tableType === 'dish_ingredients') {
            result.errors.push('Import Error: Reference data missing');
            result.errors.push(`One or more references in your CSV do not exist:`);
            result.errors.push(`- dish_id must exist in dishes table (import dishes first)`);
            result.errors.push(`- ingredient_id must exist in ingredients table (import ingredients first)`);
            result.errors.push(`- unit must exist in lookups_units table (import units lookup first)`);
          } else if (tableType === 'offers') {
            result.errors.push('Import Error: Reference data missing');
            result.errors.push(`One or more references in your CSV do not exist:`);
            result.errors.push(`- region_id must exist in ad_regions table (import ad_regions first)`);
            result.errors.push(`- ingredient_id must exist in ingredients table (import ingredients first)`);
            result.errors.push(`- unit_base must exist in lookups_units table (import units lookup first)`);
          } else if (tableType === 'ad_regions') {
            result.errors.push('Import Error: Chain not found');
            result.errors.push(`The chain_id in your CSV does not exist in the chains table.`);
            result.errors.push(`Fix: Import "Chains" CSV file first.`);
          } else if (tableType === 'stores') {
            result.errors.push('Import Error: Chain not found');
            result.errors.push(`The chain_id in your CSV does not exist in the chains table.`);
            result.errors.push(`Fix: Import "Chains" CSV file first.`);
          } else if (tableType === 'postal_codes') {
            result.errors.push('Import Error: Region not found');
            result.errors.push(`The region_id in your CSV does not exist in the ad_regions table.`);
            result.errors.push(`Fix: Import "Ad Regions" CSV file first.`);
          } else if (tableType === 'store_region_map') {
            result.errors.push('Import Error: Reference data missing');
            result.errors.push(`Either store_id or region_id in your CSV does not exist.`);
            result.errors.push(`Fix: Import "Stores" and "Ad Regions" CSV files first.`);
          } else {
            result.errors.push(`Import Error: Reference data missing`);
            result.errors.push(`Some data referenced in your CSV does not exist. Make sure to import data in the correct order.`);
          }
        } else if (errorMsgLower.includes('row-level security') || errorMsgLower.includes('policy') || errorMsgLower.includes('rls')) {
          result.errors.push('Import Error: Permission denied');
          result.errors.push(`The import function does not have permission to write to the database.`);
          result.errors.push(`Fix: Contact your administrator. This is a system configuration issue.`);
        } else if (errorMsgLower.includes('duplicate') || errorMsgLower.includes('unique constraint')) {
          // Duplicate errors are usually OK (upsert will handle), but inform user
          result.errors.push(`Note: Some records already exist and will be updated.`);
          if (insertError.details) {
            result.errors.push(`Details: ${insertError.details}`);
          }
        } else {
          // Generic error with details
          result.errors.push(`Import Error: ${errorMsg}`);
          if (insertError.details) {
            result.errors.push(`Details: ${insertError.details}`);
          }
          if (insertError.hint) {
            result.errors.push(`Hint: ${insertError.hint}`);
          }
        }
        
        return new Response(
          JSON.stringify(result),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      
      // If some rows were inserted but there were errors, continue
      if (insertError && insertedCount > 0) {
        console.warn('Partial import success:', insertedCount, 'rows inserted, but errors occurred');
        result.errors.push(`Partial import: ${insertError.message}`);
      }

      console.log(`Successfully imported ${insertedCount || validRows.length} rows`);
      result.imported = insertedCount || validRows.length;
    } else {
      console.log('No valid rows to import');
      result.imported = 0;
    }

    console.log('Final result:', JSON.stringify(result));
    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

