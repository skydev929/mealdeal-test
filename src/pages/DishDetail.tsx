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

  // Calculate ingredient pricing totals
  const calculateIngredientPrice = (ing: DishIngredient): number => {
    if (ing.current_offer_price !== undefined) {
      return ing.current_offer_price;
    }
    if (ing.price_baseline_per_unit) {
      // Simple calculation - in real app would use unit conversion
      return ing.qty * ing.price_baseline_per_unit;
    }
    return 0;
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
                    {requiredIngredients.map((ing) => (
                      <div
                        key={ing.ingredient_id}
                        className="flex items-center justify-between p-3 rounded-lg border bg-card hover:bg-accent/50 transition-colors"
                      >
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{ing.ingredient_name}</span>
                            {ing.has_offer && (
                              <Badge variant="outline" className="text-xs bg-green-50 border-green-200 text-green-700">
                                On Sale
                              </Badge>
                            )}
                          </div>
                          <div className="text-sm text-muted-foreground mt-1">
                            {ing.qty} {ing.unit}
                            {ing.role && ` • ${ing.role}`}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-medium">
                            {ing.current_offer_price !== undefined ? (
                              <>
                                <span className="text-green-600">€{ing.current_offer_price.toFixed(2)}</span>
                                {ing.price_baseline_per_unit && (
                                  <span className="text-xs text-muted-foreground line-through ml-2">
                                    €{(ing.qty * ing.price_baseline_per_unit).toFixed(2)}
                                  </span>
                                )}
                              </>
                            ) : ing.price_baseline_per_unit ? (
                              <span>€{(ing.qty * ing.price_baseline_per_unit).toFixed(2)}</span>
                            ) : (
                              <span className="text-muted-foreground text-sm">N/A</span>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
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
                      {optionalIngredients.map((ing) => (
                        <div
                          key={ing.ingredient_id}
                          className="flex items-center justify-between p-3 rounded-lg border bg-muted/30 hover:bg-accent/50 transition-colors"
                        >
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <span className="font-medium">{ing.ingredient_name}</span>
                              <Badge variant="outline" className="text-xs">Optional</Badge>
                            </div>
                            <div className="text-sm text-muted-foreground mt-1">
                              {ing.qty} {ing.unit}
                              {ing.role && ` • ${ing.role}`}
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="font-medium text-muted-foreground">
                              {ing.price_baseline_per_unit ? (
                                <span>€{(ing.qty * ing.price_baseline_per_unit).toFixed(2)}</span>
                              ) : (
                                <span className="text-sm">N/A</span>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
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

