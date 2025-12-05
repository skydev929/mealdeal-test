import { useState, useEffect } from 'react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { api } from '@/services/api';
import { Loader2 } from 'lucide-react';

const TABLES = {
  dishes: 'Dishes',
  ingredients: 'Ingredients',
  offers: 'Offers',
  chains: 'Chains',
  stores: 'Stores',
  lookups_categories: 'Categories',
  ad_regions: 'Ad Regions',
  store_region_map: 'Store-Region Map',
  postal_codes: 'Postal Codes',
  dish_ingredients: 'Dish Ingredients',
};

export function DataTable() {
  const [selectedTable, setSelectedTable] = useState('dishes');
  const [data, setData] = useState<Record<string, any>[]>([]);
  const [columns, setColumns] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (selectedTable) {
      fetchData();
    }
  }, [selectedTable]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const tableData = await api.getTableData(selectedTable, 50);

      if (tableData && tableData.length > 0) {
        setColumns(Object.keys(tableData[0]));
        setData(tableData);
      } else {
        setColumns([]);
        setData([]);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
      setColumns([]);
      setData([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Database Viewer</CardTitle>
        <CardDescription>
          View and inspect database tables (showing first 50 rows)
        </CardDescription>
        <div className="pt-4">
          <Select value={selectedTable} onValueChange={setSelectedTable}>
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="Select table" />
            </SelectTrigger>
            <SelectContent>
              {Object.entries(TABLES).map(([key, label]) => (
                <SelectItem key={key} value={key}>
                  {label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        ) : data.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No data available
          </div>
        ) : (
          <div className="rounded-md border overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  {columns.map((col) => (
                    <TableHead key={col} className="whitespace-nowrap">
                      {col}
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.map((row, idx) => (
                  <TableRow key={idx}>
                    {columns.map((col) => (
                      <TableCell key={col} className="whitespace-nowrap">
                        {JSON.stringify(row[col])}
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
