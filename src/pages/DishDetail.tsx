import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { api, type Dish, type DishIngredient, type DishPricing } from '@/services/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  ArrowLeft, 
  Heart, 
  Zap, 
  ChefHat, 
  ShoppingCart, 
  Euro,
  AlertCircle,
  CheckCircle2
} from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { ThemeToggle } from '@/components/ThemeToggle';

export default function DishDetail() {
  const { dishId } = useParams<{ dishId: string }>();
  const navigate = useNavigate();
  const { userId } = useAuth();
  const [dish, setDish] = useState<Dish | null>(null);
  const [ingredients, setIngredients] = useState<DishIngredient[]>([]);
  const [pricing, setPricing] = useState<DishPricing | null>(null);
  const [userPLZ, setUserPLZ] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [isFavorite, setIsFavorite] = useState(false);

  useEffect(() => {
    if (dishId && userId) {
      loadUserPLZ();
    }
  }, [dishId, userId]);

  useEffect(() => {
    if (dishId && userId) {
      loadDishData();
    }
  }, [dishId, userId, userPLZ]);

  const loadUserPLZ = async () => {
    if (!userId) return;
    try {
      const plz = await api.getUserPLZ(userId);
      if (plz) {
        setUserPLZ(plz);
      }
    } catch (error) {
      console.error('Error loading user PLZ:', error);
    }
  };

  const loadDishData = async () => {
    if (!dishId) return;

    setLoading(true);
    try {
      const [dishData, ingredientsData, pricingData, favorites] = await Promise.all([
        api.getDishById(dishId),
        api.getDishIngredients(dishId, userPLZ || undefined),
        api.getDishPricing(dishId, userPLZ || undefined),
        userId ? api.getFavorites(userId) : Promise.resolve([]),
      ]);

      if (!dishData) {
        toast.error('Dish not found');
        navigate('/');
        return;
      }

      setDish(dishData);
      setIngredients(ingredientsData);
      setPricing(pricingData);
      setIsFavorite(favorites.includes(dishId));
    } catch (error: any) {
      console.error('Error loading dish data:', error);
      toast.error(error?.message || 'Failed to load dish details');
    } finally {
      setLoading(false);
    }
  };

  const handleFavorite = async () => {
    if (!userId || !dishId) return;

    try {
      if (isFavorite) {
        await api.removeFavorite(userId, dishId);
        setIsFavorite(false);
        toast.success('Removed from favorites');
      } else {
        await api.addFavorite(userId, dishId);
        setIsFavorite(true);
        toast.success('Added to favorites');
      }
    } catch (error: any) {
      console.error('Error toggling favorite:', error);
      toast.error(error?.message || 'Failed to update favorite');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!dish) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto" />
          <h2 className="text-2xl font-bold">Dish not found</h2>
          <Button onClick={() => navigate('/')}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to Dishes
          </Button>
        </div>
      </div>
    );
  }

  const requiredIngredients = ingredients.filter((ing) => !ing.optional);
  const optionalIngredients = ingredients.filter((ing) => ing.optional);

  // Helper function to convert units (matches database logic)
  const convertUnit = (qty: number, fromUnit: string, toUnit: string): number | null => {
    if (!fromUnit || !toUnit) return null;
    
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
  };

  // Calculate ingredient pricing with proper unit conversion
  const calculateIngredientPrice = (ing: DishIngredient): number => {
    if (ing.current_offer_price !== undefined) {
      return ing.current_offer_price;
    }
    if (ing.price_baseline_per_unit && ing.unit_default) {
      // Convert qty from dish_ingredients.unit to ingredients.unit_default
      const convertedQty = convertUnit(ing.qty, ing.unit, ing.unit_default);
      if (convertedQty !== null) {
        return convertedQty * ing.price_baseline_per_unit;
      }
      // If conversion not possible, try direct calculation (may be wrong for non-matching units)
      // This handles cases like EL, TL, Bund where conversion isn't possible
      return ing.qty * ing.price_baseline_per_unit;
    }
    return 0;
  };

  // Calculate baseline price for display (with unit conversion)
  const calculateBaselinePrice = (ing: DishIngredient): number | null => {
    if (!ing.price_baseline_per_unit || !ing.unit_default) {
      return null;
    }
    const convertedQty = convertUnit(ing.qty, ing.unit, ing.unit_default);
    if (convertedQty !== null) {
      return convertedQty * ing.price_baseline_per_unit;
    }
    // Fallback for non-convertible units
    return ing.qty * ing.price_baseline_per_unit;
  };

  const totalIngredientPrice = ingredients.reduce(
    (sum, ing) => sum + calculateIngredientPrice(ing),
    0
  );

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card/50 backdrop-blur sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="icon" onClick={() => navigate('/')}>
                <ArrowLeft className="h-5 w-5" />
              </Button>
              <div className="flex items-center gap-2">
                <ShoppingCart className="h-6 w-6 text-primary" />
                <h1 className="text-2xl font-bold">MealDeal</h1>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <ThemeToggle />
              <Button variant="ghost" size="icon" onClick={handleFavorite}>
                <Heart
                  className={cn(
                    'h-5 w-5',
                    isFavorite && 'fill-destructive text-destructive'
                  )}
                />
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8 max-w-4xl">
        {/* Dish Header */}
        <Card className="mb-6">
          <CardHeader>
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1">
                <CardTitle className="text-3xl mb-4">{dish.name}</CardTitle>
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge variant="secondary">{dish.category}</Badge>
                  {dish.is_quick && (
                    <Badge variant="outline" className="border-yellow-500 text-yellow-600">
                      <Zap className="h-3 w-3 mr-1" />
                      Quick Meal
                    </Badge>
                  )}
                  {dish.is_meal_prep && (
                    <Badge variant="outline" className="border-blue-500 text-blue-600">
                      <ChefHat className="h-3 w-3 mr-1" />
                      Meal Prep
                    </Badge>
                  )}
                  {dish.cuisine && (
                    <Badge variant="outline">{dish.cuisine}</Badge>
                  )}
                  {dish.season && (
                    <Badge variant="outline">Season: {dish.season}</Badge>
                  )}
                </div>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {/* Pricing Summary */}
            <div className="space-y-4">
              <div className="flex items-baseline gap-4">
                <div>
                  <div className="text-sm text-muted-foreground mb-1">Current Price</div>
                  <div className="text-4xl font-bold text-primary">
                    €{(pricing?.offer_price ?? pricing?.base_price ?? 0).toFixed(2)}
                  </div>
                </div>
                {pricing && pricing.base_price > pricing.offer_price && (
                  <div>
                    <div className="text-sm text-muted-foreground mb-1">Base Price</div>
                    <div className="text-2xl text-muted-foreground line-through">
                      €{pricing.base_price.toFixed(2)}
                    </div>
                  </div>
                )}
              </div>

              {pricing && pricing.savings > 0 && (
                <div className="flex items-center gap-2">
                  <Badge variant="default" className="bg-green-600 hover:bg-green-700 text-white text-base px-3 py-1">
                    <CheckCircle2 className="h-4 w-4 mr-1" />
                    Save €{pricing.savings.toFixed(2)} ({pricing.savings_percent.toFixed(1)}%)
                  </Badge>
                  {pricing.available_offers_count > 0 && (
                    <Badge variant="outline" className="text-sm">
                      {pricing.available_offers_count} {pricing.available_offers_count === 1 ? 'offer' : 'offers'} available
                    </Badge>
                  )}
                </div>
              )}

              {userPLZ && (
                <p className="text-sm text-muted-foreground">
                  Prices for PLZ {userPLZ}
                </p>
              )}
              {!userPLZ && (
                <p className="text-sm text-muted-foreground">
                  <Link to="/" className="text-primary hover:underline">
                    Enter your postal code
                  </Link>{' '}
                  to see current offers and savings
                </p>
              )}
            </div>

            {dish.notes && (
              <>
                <Separator className="my-6" />
                <div>
                  <h3 className="font-semibold mb-2">Notes</h3>
                  <p className="text-muted-foreground whitespace-pre-wrap">{dish.notes}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Ingredients List */}
        <Card>
          <CardHeader>
            <CardTitle>Ingredients</CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              {requiredIngredients.length} required
              {optionalIngredients.length > 0 && `, ${optionalIngredients.length} optional`}
            </p>
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
              {/* Required Ingredients */}
              {requiredIngredients.length > 0 && (
                <div>
                  <h3 className="font-semibold mb-3 text-lg">Required</h3>
                  <div className="space-y-2">
                    {requiredIngredients.map((ing) => {
                      const baselinePrice = calculateBaselinePrice(ing);
                      const hasSavings = ing.current_offer_price !== undefined && 
                                        baselinePrice !== null && 
                                        baselinePrice > ing.current_offer_price;
                      
                      return (
                        <div
                          key={ing.ingredient_id}
                          className="p-4 rounded-lg border bg-card hover:bg-accent/50 transition-colors space-y-2"
                        >
                          <div className="flex items-start justify-between gap-4">
                            <div className="flex-1">
                              <div className="flex items-center gap-2 flex-wrap">
                                <span className="font-medium text-base">{ing.ingredient_name}</span>
                                {ing.has_offer && (
                                  <Badge variant="outline" className="text-xs bg-green-50 border-green-200 text-green-700">
                                    On Sale
                                  </Badge>
                                )}
                                {ing.role && (
                                  <Badge variant="outline" className="text-xs">
                                    {ing.role}
                                  </Badge>
                                )}
                              </div>
                              <div className="text-sm text-muted-foreground mt-1">
                                {ing.qty} {ing.unit}
                                {ing.unit_default && ing.unit !== ing.unit_default && (
                                  <span className="ml-1">({ing.unit_default})</span>
                                )}
                              </div>
                            </div>
                            <div className="text-right">
                              <div className="font-semibold text-lg">
                                {ing.current_offer_price !== undefined ? (
                                  <>
                                    <span className="text-green-600">€{ing.current_offer_price.toFixed(2)}</span>
                                    {baselinePrice !== null && baselinePrice > ing.current_offer_price && (
                                      <span className="text-xs text-muted-foreground line-through ml-2 block">
                                        €{baselinePrice.toFixed(2)}
                                      </span>
                                    )}
                                  </>
                                ) : (
                                  baselinePrice !== null ? (
                                    <span>€{baselinePrice.toFixed(2)}</span>
                                  ) : (
                                    <span className="text-muted-foreground text-sm">N/A</span>
                                  )
                                )}
                              </div>
                            </div>
                          </div>
                          
                          {/* Enhanced offer details - show ALL available offers */}
                          {ing.has_offer && ing.all_offers && ing.all_offers.length > 0 && (
                            <div className="pt-2 border-t space-y-2">
                              <div className="text-xs font-semibold text-muted-foreground mb-2">
                                Available Offers ({ing.all_offers.length}):
                              </div>
                              <div className="space-y-2">
                                {ing.all_offers.map((offer, offerIndex) => {
                                  const isLowestPrice = offer.is_lowest_price;
                                  return (
                                    <div
                                      key={offer.offer_id}
                                      className={`p-2.5 rounded-md border text-xs ${
                                        isLowestPrice
                                          ? 'bg-green-50 border-green-200'
                                          : 'bg-muted/30 border-border'
                                      }`}
                                    >
                                      <div className="flex items-start justify-between gap-2 mb-1.5">
                                        <div className="flex-1">
                                          <div className="flex items-center gap-2 flex-wrap">
                                            {isLowestPrice && (
                                              <Badge variant="outline" className="text-xs bg-green-600 text-white border-green-600">
                                                Best Price
                                              </Badge>
                                            )}
                                            {offer.source && (
                                              <span className="font-medium text-foreground">
                                                {offer.source}
                                              </span>
                                            )}
                                          </div>
                                          {offer.valid_from && offer.valid_to && (
                                            <div className="text-muted-foreground mt-0.5">
                                              Valid: {new Date(offer.valid_from).toLocaleDateString()} - {new Date(offer.valid_to).toLocaleDateString()}
                                            </div>
                                          )}
                                        </div>
                                        <div className="text-right">
                                          {offer.calculated_price_for_qty !== undefined && (
                                            <div className={`font-semibold ${isLowestPrice ? 'text-green-700' : 'text-foreground'}`}>
                                              €{offer.calculated_price_for_qty.toFixed(2)}
                                            </div>
                                          )}
                                        </div>
                                      </div>
                                      <div className="flex items-center gap-3 flex-wrap text-muted-foreground">
                                        {offer.pack_size && offer.price_total !== undefined && (
                                          <span>
                                            <span className="font-medium">Pack:</span> {offer.pack_size} {offer.unit_base || ing.unit} for €{offer.price_total.toFixed(2)}
                                          </span>
                                        )}
                                        {offer.price_per_unit !== undefined && (
                                          <span>
                                            <span className="font-medium">Per {offer.unit_base || ing.unit_default || ing.unit}:</span> €{offer.price_per_unit.toFixed(2)}
                                            {isLowestPrice && ing.price_per_unit_baseline !== undefined && 
                                             offer.price_per_unit < ing.price_per_unit_baseline && (
                                              <span className="line-through ml-1 text-xs">
                                                (was €{ing.price_per_unit_baseline.toFixed(2)})
                                              </span>
                                            )}
                                          </span>
                                        )}
                                      </div>
                                    </div>
                                  );
                                })}
                              </div>
                              {ing.all_offers.length > 1 && (
                                <div className="text-xs text-muted-foreground italic pt-1">
                                  Note: The lowest price offer (marked "Best Price") is used for total cost calculation.
                                </div>
                              )}
                            </div>
                          )}
                          
                          {/* Fallback: Show single offer details if all_offers is not available (backwards compatibility) */}
                          {ing.has_offer && (!ing.all_offers || ing.all_offers.length === 0) && (
                            <div className="pt-2 border-t space-y-1.5 text-xs">
                              {ing.offer_source && (
                                <div className="flex items-center gap-2 text-muted-foreground">
                                  <span className="font-medium">Source:</span>
                                  <span>{ing.offer_source}</span>
                                </div>
                              )}
                              {ing.offer_valid_from && ing.offer_valid_to && (
                                <div className="flex items-center gap-2 text-muted-foreground">
                                  <span className="font-medium">Valid:</span>
                                  <span>
                                    {new Date(ing.offer_valid_from).toLocaleDateString()} - {new Date(ing.offer_valid_to).toLocaleDateString()}
                                  </span>
                                </div>
                              )}
                              <div className="flex items-center gap-4 flex-wrap">
                                {ing.offer_pack_size && ing.offer_price_total !== undefined && (
                                  <div className="text-muted-foreground">
                                    <span className="font-medium">Pack:</span> {ing.offer_pack_size} {ing.offer_unit_base || ing.unit} for €{ing.offer_price_total.toFixed(2)}
                                  </div>
                                )}
                                {ing.price_per_unit_offer !== undefined && ing.price_per_unit_baseline !== undefined && (
                                  <div className={hasSavings ? "text-green-600" : "text-muted-foreground"}>
                                    <span className="font-medium">Per {ing.offer_unit_base || ing.unit_default || ing.unit}:</span>{' '}
                                    €{ing.price_per_unit_offer.toFixed(2)}
                                    {hasSavings && (
                                      <span className="text-muted-foreground line-through ml-1">
                                        (was €{ing.price_per_unit_baseline.toFixed(2)})
                                      </span>
                                    )}
                                  </div>
                                )}
                              </div>
                            </div>
                          )}
                          
                          {/* Baseline price info when no offer */}
                          {!ing.has_offer && ing.price_per_unit_baseline !== undefined && (
                            <div className="pt-2 border-t text-xs text-muted-foreground">
                              <span className="font-medium">Price per {ing.unit_default || ing.unit}:</span> €{ing.price_per_unit_baseline.toFixed(2)}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Optional Ingredients */}
              {optionalIngredients.length > 0 && (
                <>
                  <Separator />
                  <div>
                    <h3 className="font-semibold mb-3 text-lg">Optional</h3>
                    <div className="space-y-2">
                      {optionalIngredients.map((ing) => {
                        const baselinePrice = calculateBaselinePrice(ing);
                        const hasSavings = ing.current_offer_price !== undefined && 
                                          baselinePrice !== null && 
                                          baselinePrice > ing.current_offer_price;
                        
                        return (
                          <div
                            key={ing.ingredient_id}
                            className="p-4 rounded-lg border bg-muted/30 hover:bg-accent/50 transition-colors space-y-2"
                          >
                            <div className="flex items-start justify-between gap-4">
                              <div className="flex-1">
                                <div className="flex items-center gap-2 flex-wrap">
                                  <span className="font-medium text-base">{ing.ingredient_name}</span>
                                  <Badge variant="outline" className="text-xs">Optional</Badge>
                                  {ing.has_offer && (
                                    <Badge variant="outline" className="text-xs bg-green-50 border-green-200 text-green-700">
                                      On Sale
                                    </Badge>
                                  )}
                                  {ing.role && (
                                    <Badge variant="outline" className="text-xs">
                                      {ing.role}
                                    </Badge>
                                  )}
                                </div>
                                <div className="text-sm text-muted-foreground mt-1">
                                  {ing.qty} {ing.unit}
                                  {ing.unit_default && ing.unit !== ing.unit_default && (
                                    <span className="ml-1">({ing.unit_default})</span>
                                  )}
                                </div>
                              </div>
                              <div className="text-right">
                                <div className={`font-semibold ${ing.current_offer_price ? 'text-lg' : 'text-base text-muted-foreground'}`}>
                                  {ing.current_offer_price !== undefined ? (
                                    <>
                                      <span className="text-green-600">€{ing.current_offer_price.toFixed(2)}</span>
                                      {baselinePrice !== null && baselinePrice > ing.current_offer_price && (
                                        <span className="text-xs text-muted-foreground line-through ml-2 block">
                                          €{baselinePrice.toFixed(2)}
                                        </span>
                                      )}
                                    </>
                                  ) : (
                                    baselinePrice !== null ? (
                                      <span>€{baselinePrice.toFixed(2)}</span>
                                    ) : (
                                      <span className="text-sm">N/A</span>
                                    )
                                  )}
                                </div>
                              </div>
                            </div>
                            
                            {/* Show all offers for optional ingredients too */}
                            {ing.has_offer && ing.all_offers && ing.all_offers.length > 0 && (
                              <div className="pt-2 border-t space-y-2">
                                <div className="text-xs font-semibold text-muted-foreground mb-2">
                                  Available Offers ({ing.all_offers.length}):
                                </div>
                                <div className="space-y-2">
                                  {ing.all_offers.map((offer) => {
                                    const isLowestPrice = offer.is_lowest_price;
                                    return (
                                      <div
                                        key={offer.offer_id}
                                        className={`p-2.5 rounded-md border text-xs ${
                                          isLowestPrice
                                            ? 'bg-green-50 border-green-200'
                                            : 'bg-background border-border'
                                        }`}
                                      >
                                        <div className="flex items-start justify-between gap-2 mb-1.5">
                                          <div className="flex-1">
                                            <div className="flex items-center gap-2 flex-wrap">
                                              {isLowestPrice && (
                                                <Badge variant="outline" className="text-xs bg-green-600 text-white border-green-600">
                                                  Best Price
                                                </Badge>
                                              )}
                                              {offer.source && (
                                                <span className="font-medium text-foreground">
                                                  {offer.source}
                                                </span>
                                              )}
                                            </div>
                                            {offer.valid_from && offer.valid_to && (
                                              <div className="text-muted-foreground mt-0.5">
                                                Valid: {new Date(offer.valid_from).toLocaleDateString()} - {new Date(offer.valid_to).toLocaleDateString()}
                                              </div>
                                            )}
                                          </div>
                                          <div className="text-right">
                                            {offer.calculated_price_for_qty !== undefined && (
                                              <div className={`font-semibold ${isLowestPrice ? 'text-green-700' : 'text-foreground'}`}>
                                                €{offer.calculated_price_for_qty.toFixed(2)}
                                              </div>
                                            )}
                                          </div>
                                        </div>
                                        <div className="flex items-center gap-3 flex-wrap text-muted-foreground">
                                          {offer.pack_size && offer.price_total !== undefined && (
                                            <span>
                                              <span className="font-medium">Pack:</span> {offer.pack_size} {offer.unit_base || ing.unit} for €{offer.price_total.toFixed(2)}
                                            </span>
                                          )}
                                          {offer.price_per_unit !== undefined && (
                                            <span>
                                              <span className="font-medium">Per {offer.unit_base || ing.unit_default || ing.unit}:</span> €{offer.price_per_unit.toFixed(2)}
                                              {isLowestPrice && ing.price_per_unit_baseline !== undefined && 
                                               offer.price_per_unit < ing.price_per_unit_baseline && (
                                                <span className="line-through ml-1 text-xs">
                                                  (was €{ing.price_per_unit_baseline.toFixed(2)})
                                                </span>
                                              )}
                                            </span>
                                          )}
                                        </div>
                                      </div>
                                    );
                                  })}
                                </div>
                                {ing.all_offers.length > 1 && (
                                  <div className="text-xs text-muted-foreground italic pt-1">
                                    Note: The lowest price offer (marked "Best Price") is used for total cost calculation.
                                  </div>
                                )}
                              </div>
                            )}
                            
                            {/* Baseline price info when no offer */}
                            {!ing.has_offer && ing.price_per_unit_baseline !== undefined && (
                              <div className="pt-2 border-t text-xs text-muted-foreground">
                                <span className="font-medium">Price per {ing.unit_default || ing.unit}:</span> €{ing.price_per_unit_baseline.toFixed(2)}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </>
              )}

              {/* Pricing Summary */}
              <Separator />
              <div className="bg-muted/50 p-4 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-semibold">Total Ingredients Cost</span>
                  <span className="text-lg font-bold">
                    €{totalIngredientPrice.toFixed(2)}
                  </span>
                </div>
                {pricing && pricing.base_price !== totalIngredientPrice && (
                  <p className="text-xs text-muted-foreground mt-1">
                    Note: Calculated price may differ due to unit conversions and offer calculations
                  </p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

