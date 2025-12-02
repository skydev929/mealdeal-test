// Script to convert CSV files to SQL INSERT statements
// Run with: node scripts/csv-to-sql.js

const fs = require('fs');
const path = require('path');

// Helper to escape SQL strings
function escapeSQL(str) {
  if (str === null || str === undefined || str === '') return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
}

// Convert comma decimal to dot
function parseDecimal(str) {
  if (!str || str === '' || str === 'NULL' || str === 'null') return 'NULL';
  return str.replace(',', '.');
}

// Convert CSV row to SQL values
function csvRowToSQL(headers, row, tableType) {
  const values = headers.map((header, idx) => {
    const value = row[idx]?.trim() || '';
    const headerLower = header.toLowerCase().trim();
    
    // Handle empty values
    if (value === '' || value === 'NULL' || value === 'null') {
      return 'NULL';
    }
    
    // Handle numeric fields
    if (tableType === 'ingredients' && headerLower === 'price_baseline_per_unit') {
      const num = parseDecimal(value);
      return num === 'NULL' ? 'NULL' : num;
    }
    
    if (tableType === 'offers' && (headerLower === 'price_total' || headerLower === 'pack_size')) {
      return parseDecimal(value);
    }
    
    if (tableType === 'dish_ingredients' && headerLower === 'qty') {
      return parseDecimal(value);
    }
    
    // Handle boolean fields
    if ((headerLower === 'is_quick' || headerLower === 'is_meal_prep' || headerLower === 'optional') && 
        (value.toUpperCase() === 'TRUE' || value.toUpperCase() === 'FALSE')) {
      return value.toUpperCase() === 'TRUE' ? 'TRUE' : 'FALSE';
    }
    
    // Handle integer fields
    if (headerLower === 'region_id' || headerLower === 'chain_id' || headerLower === 'store_id') {
      const num = parseInt(value, 10);
      return isNaN(num) ? 'NULL' : num.toString();
    }
    
    // Handle array fields (allergen_tags)
    if (headerLower === 'allergen_tags' && value) {
      const tags = value.split(',').map(t => escapeSQL(t.trim())).join(',');
      return `ARRAY[${tags}]`;
    }
    
    // Default: escape as string
    return escapeSQL(value);
  });
  
  return `(${values.join(', ')})`;
}

// Process a CSV file
function processCSV(filePath, tableName) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n').filter(line => line.trim());
  
  if (lines.length < 2) {
    console.error(`File ${filePath} has no data rows`);
    return '';
  }
  
  const headers = lines[0].split(',').map(h => h.trim().replace(/^"|"$/g, ''));
  const dataRows = lines.slice(1);
  
  const sqlStatements = [];
  sqlStatements.push(`-- Seed data for ${tableName}`);
  sqlStatements.push(`-- Generated from ${path.basename(filePath)}`);
  sqlStatements.push('');
  
  // Determine conflict resolution
  let conflictClause = '';
  if (tableName === 'lookups_categories' || tableName === 'lookups_units') {
    conflictClause = `ON CONFLICT (${headers[0]}) DO NOTHING`;
  } else if (tableName === 'chains') {
    conflictClause = `ON CONFLICT (chain_id) DO UPDATE SET chain_name = EXCLUDED.chain_name`;
  } else if (tableName === 'ingredients') {
    conflictClause = `ON CONFLICT (ingredient_id) DO UPDATE SET 
      name_canonical = EXCLUDED.name_canonical,
      unit_default = EXCLUDED.unit_default,
      price_baseline_per_unit = EXCLUDED.price_baseline_per_unit`;
  } else if (tableName === 'dishes') {
    conflictClause = `ON CONFLICT (dish_id) DO UPDATE SET 
      name = EXCLUDED.name,
      category = EXCLUDED.category`;
  } else if (tableName === 'dish_ingredients') {
    conflictClause = `ON CONFLICT (dish_id, ingredient_id) DO NOTHING`;
  } else if (tableName === 'offers') {
    conflictClause = `ON CONFLICT (offer_hash) DO NOTHING`;
  }
  
  // Process in batches of 100
  const batchSize = 100;
  for (let i = 0; i < dataRows.length; i += batchSize) {
    const batch = dataRows.slice(i, i + batchSize);
    const values = batch
      .map(row => {
        // Simple CSV parsing (handles quoted fields)
        const parsed = [];
        let current = '';
        let inQuotes = false;
        for (let j = 0; j < row.length; j++) {
          const char = row[j];
          if (char === '"') {
            inQuotes = !inQuotes;
          } else if (char === ',' && !inQuotes) {
            parsed.push(current.trim());
            current = '';
          } else {
            current += char;
          }
        }
        parsed.push(current.trim());
        return parsed;
      })
      .filter(row => row.length === headers.length && row.some(cell => cell.trim() !== ''))
      .map(row => csvRowToSQL(headers, row, tableName));
    
    if (values.length > 0) {
      sqlStatements.push(`INSERT INTO ${tableName} (${headers.join(', ')})`);
      sqlStatements.push(`VALUES`);
      sqlStatements.push(values.join(',\n'));
      if (conflictClause) {
        sqlStatements.push(conflictClause + ';');
      } else {
        sqlStatements.push(';');
      }
      sqlStatements.push('');
    }
  }
  
  return sqlStatements.join('\n');
}

// Main execution
const dataDir = path.join(__dirname, '..', 'data');
const outputDir = path.join(__dirname, '..', 'supabase', 'seed');

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Map CSV files to table names
const fileMap = {
  'Master (11).xlsx - lookups_categories.csv': 'lookups_categories',
  'Master (11).xlsx - lookups_units.csv': 'lookups_units',
  'chains_csv.csv': 'chains',
  'ad_regions_csv.csv': 'ad_regions',
  'stores_csv.csv': 'stores',
  'store_region_map_csv.csv': 'store_region_map',
  'Master (11).xlsx - ingredients.csv': 'ingredients',
  'Master (11).xlsx - dishes.csv': 'dishes',
  'Master (11).xlsx - dish_ingredients.csv': 'dish_ingredients',
  'offers_csv.csv': 'offers',
  'product_map_csv.csv': 'product_map',
};

console.log('Converting CSV files to SQL...\n');

for (const [fileName, tableName] of Object.entries(fileMap)) {
  const filePath = path.join(dataDir, fileName);
  if (fs.existsSync(filePath)) {
    console.log(`Processing ${fileName} -> ${tableName}...`);
    const sql = processCSV(filePath, tableName);
    const outputPath = path.join(outputDir, `${tableName}.sql`);
    fs.writeFileSync(outputPath, sql);
    console.log(`  ✓ Created ${outputPath}`);
  } else {
    console.log(`  ✗ File not found: ${filePath}`);
  }
}

console.log('\nDone! SQL files created in supabase/seed/');

