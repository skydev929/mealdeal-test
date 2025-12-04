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

export interface DishIngredient {
  dish_id: string;
  ingredient_id: string;
  ingredient_name: string;
  qty: number;
  unit: string;
  unit_default?: string; // Ingredient's default unit (for price conversion)
  optional: boolean;
  role?: string;
  price_baseline_per_unit?: number;
  current_offer_price?: number;
  has_offer: boolean;
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

      // Filter to show only dishes with available offers
      let filtered = dishesWithPricing.filter((d) => d.availableOffers > 0);

      // Filter by max price if specified
      if (filters?.maxPrice) {
        filtered = filtered.filter(
          (d) => d.currentPrice <= filters.maxPrice!
        );
      }

      // Filter by chain if specified (requires checking offers)
      if (filters?.chain && filters.chain !== 'all') {
        // Get chain_id from chain name
        const chain = await this.getChainByName(filters.chain);
        if (chain) {
          // Get region_ids from PLZ if provided
          let regionIds: number[] = [];
          if (filters?.plz) {
            const { data: postalData } = await supabase
              .from('postal_codes')
              .select('region_id')
              .eq('plz', filters.plz);
            if (postalData) {
              regionIds = postalData.map((p) => p.region_id);
            }
          }

          // If no PLZ or no regions found, get all regions for this chain
          if (regionIds.length === 0) {
            const { data: regions } = await supabase
              .from('ad_regions')
              .select('region_id')
              .eq('chain_id', chain.chain_id);
            if (regions) {
              regionIds = regions.map((r) => r.region_id);
            }
          }

          if (regionIds.length > 0) {
            const today = new Date().toISOString().split('T')[0];
            const dishIds = filtered.map((d) => d.dish_id);

            // Get all ingredient_ids that have offers for this chain/region
            const { data: offers } = await supabase
              .from('offers')
              .select('ingredient_id')
              .in('region_id', regionIds)
              .lte('valid_from', today)
              .gte('valid_to', today);

            if (offers && offers.length > 0) {
              const ingredientIdsWithOffers = new Set(
                offers.map((o) => o.ingredient_id)
              );

              // Get all dish_ingredients that match these ingredients and dishes
              const { data: dishIngredients } = await supabase
                .from('dish_ingredients')
                .select('dish_id')
                .in('dish_id', dishIds)
                .in('ingredient_id', Array.from(ingredientIdsWithOffers))
                .eq('optional', false);

              const dishIdsWithOffers = new Set(
                (dishIngredients || []).map((di) => di.dish_id)
              );

              filtered = filtered.filter((dish) => 
                dishIdsWithOffers.has(dish.dish_id)
              );
            } else {
              // No offers found for this chain/region
              filtered = [];
            }
          } else {
            // No regions found, filter out all dishes
            filtered = [];
          }
        }
      }

      return filtered;
    } catch (error: any) {
      console.error('Error fetching dishes:', error);
      throw new Error(error?.message || 'Failed to load dishes. Please try again.');
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

  async getDishIngredients(dishId: string, plz?: string | null): Promise<DishIngredient[]> {
    try {
      // Get region_id from PLZ if provided
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

      // Get dish ingredients
      const { data: dishIngredients, error: diError } = await supabase
        .from('dish_ingredients')
        .select('dish_id, ingredient_id, qty, unit, optional, role')
        .eq('dish_id', dishId)
        .order('optional', { ascending: true });

      if (diError) throw diError;
      if (!dishIngredients) return [];

      // Get ingredient details separately
      const ingredientIds = dishIngredients.map((di: any) => di.ingredient_id);
      const { data: ingredientsData, error: ingError } = await supabase
        .from('ingredients')
        .select('ingredient_id, name_canonical, price_baseline_per_unit, unit_default')
        .in('ingredient_id', ingredientIds);

      if (ingError) throw ingError;

      // Create a map of ingredient details
      const ingredientsMap = new Map(
        (ingredientsData || []).map((ing: any) => [ing.ingredient_id, ing])
      );

      const today = new Date().toISOString().split('T')[0];

      // Get current offers for these ingredients if region available
      let offers: any[] = [];
      
      if (regionIds.length > 0 && ingredientIds.length > 0) {
        const { data: offersData } = await supabase
          .from('offers')
          .select('ingredient_id, price_total, pack_size, unit_base')
          .in('ingredient_id', ingredientIds)
          .in('region_id', regionIds)
          .lte('valid_from', today)
          .gte('valid_to', today);

        if (offersData) {
          offers = offersData;
        }
      }

      // Map offers by ingredient_id
      const offersMap = new Map(
        offers.map((o) => [o.ingredient_id, o])
      );

      // Transform to DishIngredient format
      return dishIngredients.map((di: any) => {
        const ingredient = ingredientsMap.get(di.ingredient_id);
        const offer = offersMap.get(di.ingredient_id);
        
        // Calculate offer price if available
        let currentOfferPrice: number | undefined;
        if (offer) {
          // Convert qty to offer unit, then calculate price
          const qtyInOfferUnit = this.convertUnitForPricing(
            di.qty,
            di.unit,
            offer.unit_base
          );
          if (qtyInOfferUnit !== null && offer.pack_size > 0) {
            currentOfferPrice = (qtyInOfferUnit / offer.pack_size) * offer.price_total;
          }
        }

        return {
          dish_id: di.dish_id,
          ingredient_id: di.ingredient_id,
          ingredient_name: ingredient ? ingredient.name_canonical : '',
          qty: di.qty,
          unit: di.unit,
          unit_default: ingredient ? ingredient.unit_default : undefined,
          optional: di.optional || false,
          role: di.role || undefined,
          price_baseline_per_unit: ingredient ? ingredient.price_baseline_per_unit : undefined,
          current_offer_price: currentOfferPrice,
          has_offer: !!offer,
        };
      });
    } catch (error: any) {
      console.error('Error fetching dish ingredients:', error);
      return [];
    }
  }

  // Helper to convert units (simplified version matching database logic)
  private convertUnitForPricing(qty: number, fromUnit: string, toUnit: string): number | null {
    const from = fromUnit.toLowerCase().trim();
    const to = toUnit.toLowerCase().trim();

    if (from === to) return qty;

    // Weight conversions
    if (from === 'g' && to === 'kg') return qty / 1000.0;
    if (from === 'kg' && to === 'g') return qty * 1000.0;

    // Volume conversions
    if (from === 'ml' && to === 'l') return qty / 1000.0;
    if (from === 'l' && to === 'ml') return qty * 1000.0;

    // Piece units
    if ((from === 'stück' || from === 'st') && (to === 'stück' || to === 'st')) {
      return qty;
    }

    // Non-convertible units
    return null;
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
        return null;
      }

      return data[0];
    } catch (error: any) {
      console.error('Error calculating dish price:', error);
      // Return null to allow dishes to show with zero pricing rather than failing completely
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
    } catch (error: any) {
      console.error('Error updating user PLZ:', error);
      throw new Error(error?.message || 'Failed to update location. Please try again.');
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
    } catch (error: any) {
      console.error('Error adding favorite:', error);
      if (error?.code === '23505') {
        throw new Error('This dish is already in your favorites');
      }
      throw new Error(error?.message || 'Failed to add favorite. Please try again.');
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
    } catch (error: any) {
      console.error('Error removing favorite:', error);
      throw new Error(error?.message || 'Failed to remove favorite. Please try again.');
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

      // Use Supabase Edge Function if available, otherwise handle client-side
      const { data, error } = await supabase.functions.invoke('import-csv', {
        body: formData,
      });

      if (error) {
        console.error('Edge function error:', error);
        throw error;
      }

      const result = {
        validRows: data?.validRows || 0,
        errors: data?.errors || [],
        imported: data?.imported !== undefined ? data.imported : (dryRun ? undefined : 0),
      };

      return result;
    } catch (error: any) {
      console.error('Error importing CSV:', error);
      throw new Error(error.message || 'CSV import failed');
    }
  }
}

// Export singleton instance
export const api = new ApiService();

