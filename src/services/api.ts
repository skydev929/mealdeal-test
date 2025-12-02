// API Service Layer - Wraps Supabase calls
// This provides a clean interface for the UI, abstracting away direct Supabase usage

import { supabase } from '@/integrations/supabase/client';
import { log } from 'console';

// Types
export interface Dish {
  dish_id: string;
  name: string;
  category: string;
  is_quick: boolean;
  is_meal_prep: boolean;
  season?: string;
  cuisine?: string;
  notes?: string;
  currentPrice?: number;
  basePrice?: number;
  savings?: number;
  savingsPercent?: number;
  availableOffers?: number;
  isFavorite?: boolean;
}

export interface Ingredient {
  ingredient_id: string;
  name_canonical: string;
  unit_default: string;
  price_baseline_per_unit?: number;
  allergen_tags?: string[];
  notes?: string;
}

export interface Offer {
  offer_id: number;
  region_id: number;
  ingredient_id: string;
  price_total: number;
  pack_size: number;
  unit_base: string;
  valid_from: string;
  valid_to: string;
  source?: string;
  source_ref_id?: string;
}

export interface Chain {
  chain_id: number;
  chain_name: string;
}

export interface Store {
  store_id: number;
  chain_id: number;
  store_name: string;
  plz?: string;
  city?: string;
  street?: string;
  lat?: number;
  lon?: number;
}

export interface DishFilters {
  category?: string;
  chain?: string;
  maxPrice?: number;
  plz?: string;
  isQuick?: boolean;
  isMealPrep?: boolean;
}

export interface DishPricing {
  dish_id: string;
  base_price: number;
  offer_price: number;
  savings: number;
  savings_percent: number;
  available_offers_count: number;
}

// API Service Class
class ApiService {
  // ============ DISHES ============
  async getDishes(filters?: DishFilters, limit = 50): Promise<Dish[]> {
    try {
      let query = supabase
        .from('dishes')
        .select('*')
        .limit(limit);

      // Apply filters
      if (filters?.category && filters.category !== 'all') {
        query = query.eq('category', filters.category);
      }

      if (filters?.isQuick !== undefined) {
        query = query.eq('is_quick', filters.isQuick);
      }

      if (filters?.isMealPrep !== undefined) {
        query = query.eq('is_meal_prep', filters.isMealPrep);
      }

      const { data, error } = await query;

      if (error) throw error;

      // Calculate pricing for each dish
      const dishesWithPricing = await Promise.all(
        (data || []).map(async (dish) => {
          const pricing = await this.getDishPricing(dish.dish_id, filters?.plz);
          
          // Log if pricing is missing or zero
          if (!pricing || (pricing.base_price === 0 && pricing.offer_price === 0)) {
            console.warn(`Dish ${dish.dish_id} (${dish.name}) has zero pricing. PLZ: ${filters?.plz || 'none'}`);
          }
          
          return {
            ...dish,
            currentPrice: pricing?.offer_price ?? pricing?.base_price ?? 0,
            basePrice: pricing?.base_price ?? 0,
            savings: pricing?.savings ?? 0,
            savingsPercent: pricing?.savings_percent ?? 0,
            availableOffers: pricing?.available_offers_count ?? 0,
          };
        })
      );

      // Filter by max price if specified
      let filtered = dishesWithPricing;
      if (filters?.maxPrice) {
        filtered = dishesWithPricing.filter(
          (d) => d.currentPrice <= filters.maxPrice!
        );
      }

      // Filter by chain if specified (requires checking offers)
      if (filters?.chain && filters.chain !== 'all') {
        // Get chain_id from chain name
        const chain = await this.getChainByName(filters.chain);
        if (chain) {
          // Filter dishes that have offers from this chain
          const dishesWithChainOffers = await Promise.all(
            filtered.map(async (dish) => {
              const hasOffers = await this.dishHasChainOffers(
                dish.dish_id,
                chain.chain_id,
                filters?.plz
              );
              return hasOffers ? dish : null;
            })
          );
          filtered = dishesWithChainOffers.filter((d) => d !== null) as Dish[];
        }
      }

      return filtered;
    } catch (error) {
      console.error('Error fetching dishes:', error);
      throw error;
    }
  }

  async getDishById(dishId: string): Promise<Dish | null> {
    try {
      const { data, error } = await supabase
        .from('dishes')
        .select('*')
        .eq('dish_id', dishId)
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error fetching dish:', error);
      return null;
    }
  }

  async getDishPricing(
    dishId: string,
    plz?: string | null
  ): Promise<DishPricing | null> {
    try {
      const { data, error } = await supabase.rpc('calculate_dish_price', {
        _dish_id: dishId,
        _user_plz: plz || null,
      });

      if (error) {
        console.error('RPC error calculating dish price:', error);
        throw error;
      }
      
      if (!data || data.length === 0) {
        console.warn(`No pricing data returned for dish ${dishId}`);
        return null;
      }

      const result = data[0];
      console.log(`Pricing for ${dishId}:`, {
        base_price: result.base_price,
        offer_price: result.offer_price,
        savings: result.savings,
        offers_count: result.available_offers_count,
      });

      return result;
    } catch (error) {
      console.error('Error calculating dish price:', error);
      return null;
    }
  }

  async dishHasChainOffers(
    dishId: string,
    chainId: number,
    plz?: string | null
  ): Promise<boolean> {
    try {
      // Get region_id from PLZ
      let regionIds: number[] = [];
      if (plz) {
        const { data: postalData } = await supabase
          .from('postal_codes')
          .select('region_id')
          .eq('plz', plz);
        if (postalData) {
          regionIds = postalData.map((p) => p.region_id);
        }
      }

      // If no PLZ or no regions found, get all regions for this chain
      if (regionIds.length === 0) {
        const { data: regions } = await supabase
          .from('ad_regions')
          .select('region_id')
          .eq('chain_id', chainId);
        if (regions) {
          regionIds = regions.map((r) => r.region_id);
        }     
      }

      if (regionIds.length === 0) return false;

      // Get dish ingredients 
      const { data: dishIngredients } = await supabase
        .from('dish_ingredients')
        .select('ingredient_id')
        .eq('dish_id', dishId)
        .eq('optional', false);

      if (!dishIngredients || dishIngredients.length === 0) return false;

      const ingredientIds = dishIngredients.map((di) => di.ingredient_id);
      const today = new Date().toISOString().split('T')[0];

      // Check if any offers exist for these ingredients in any of the regions
      const { data: offers } = await supabase
        .from('offers')
        .select('offer_id')
        .in('ingredient_id', ingredientIds)
        .in('region_id', regionIds)
        .lte('valid_from', today)
        .gte('valid_to', today)
        .limit(1);

      return offers && offers.length > 0;
    } catch (error) {
      console.error('Error checking chain offers:', error);
      return false;
    }
  }

  // ============ FILTERS ============
  async getCategories(): Promise<string[]> {
    try {
      const { data, error } = await supabase
        .from('lookups_categories')
        .select('category');

      if (error) throw error;
      return (data || []).map((c) => c.category);
    } catch (error) {
      console.error('Error fetching categories:', error);
      return [];
    }
  }

  async getChains(): Promise<Chain[]> {
    try {
      const { data, error } = await supabase
        .from('chains')
        .select('*')
        .order('chain_name');

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching chains:', error);
      return [];
    }
  }

  async getChainByName(chainName: string): Promise<Chain | null> {
    try {
      const { data, error } = await supabase
        .from('chains')
        .select('*')
        .eq('chain_name', chainName)
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error fetching chain:', error);
      return null;
    }
  }

  // ============ USER PROFILE ============
  async getUserPLZ(userId: string): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select('plz')
        .eq('id', userId)
        .single();

      if (error) throw error;
      return data?.plz || null;
    } catch (error) {
      console.error('Error fetching user PLZ:', error);
      return null;
    }
  }

  async updateUserPLZ(userId: string, plz: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('user_profiles')
        .update({ plz, updated_at: new Date().toISOString() })
        .eq('id', userId);

      if (error) throw error;
    } catch (error) {
      console.error('Error updating user PLZ:', error);
      throw error;
    }
  }

  // ============              ============
  async getFavorites(userId: string): Promise<string[]> {
    try {
      const { data, error } = await supabase
        .from('favorites')
        .select('dish_id')
        .eq('user_id', userId);

      if (error) throw error;
      return (data || []).map((f) => f.dish_id);
    } catch (error) {
      console.error('Error fetching favorites:', error);
      return [];
    }
  }

  async addFavorite(userId: string, dishId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('favorites')
        .insert({ user_id: userId, dish_id: dishId });

      if (error) throw error;
    } catch (error) {
      console.error('Error adding favorite:', error);
      throw error;
    }
  }

  async removeFavorite(userId: string, dishId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('dish_id', dishId);

      if (error) throw error;
    } catch (error) {
      console.error('Error removing favorite:', error);
      throw error;
    }
  }

  async isFavorite(userId: string, dishId: string): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('favorites')
        .select('dish_id')
        .eq('user_id', userId)
        .eq('dish_id', dishId)
        .single();

      if (error && error.code !== 'PGRST116') throw error;
      return !!data;
    } catch (error) {
      console.error('Error checking favorite:', error);
      return false;
    }
  }

  // ============ ADMIN - DATA TABLES ============
  async getTableData(tableName: string, limit = 50): Promise<any[]> {
    try {
      const { data, error } = await supabase
        .from(tableName)
        .select('*')
        .limit(limit);

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error(`Error fetching ${tableName}:`, error);
      throw error;
    }
  }

  // ============ ADMIN - CSV IMPORT ============
  async importCSV(
    file: File,
    type: string,
    dryRun: boolean = true
  ): Promise<{
    validRows: number;
    errors: string[];
    imported?: number;
  }> {
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('type', type);
      formData.append('dryRun', dryRun.toString());

      console.log('Calling import-csv function with:', { type, dryRun, fileName: file.name });

      for (const [key, value] of formData.entries()) {
        console.log(key, value);
      }
      
      const reader = new FileReader();
      reader.onload = () => {
        console.log("CSV file content:");
        console.log(reader.result);
      };
      reader.readAsText(file);

      // Use Supabase Edge Function if available, otherwise handle client-side
      const { data, error } = await supabase.functions.invoke('import-csv', {
        body: formData,
      });

      if (error) {
        console.error('Edge function error:', error);
        throw error;
      }

      console.log('Edge function response:', data);

      const result = {
        validRows: data?.validRows || 0,
        errors: data?.errors || [],
        imported: data?.imported !== undefined ? data.imported : (dryRun ? undefined : 0),
      };

      console.log('Parsed result:', result);
      return result;
    } catch (error: any) {
      console.error('Error importing CSV:', error);
      throw new Error(error.message || 'CSV import failed');
    }
  }
}

// Export singleton instance
export const api = new ApiService();

