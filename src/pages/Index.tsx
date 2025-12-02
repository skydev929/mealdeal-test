import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import useAuth from '@/hooks/useAuth';
import { api, type Dish, type DishFilters } from '@/services/api';
import { PLZInput } from '@/components/PLZInput';
import { DishFilters as DishFiltersComponent } from '@/components/DishFilters';
import { DishCard } from '@/components/DishCard';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ShoppingCart, Sparkles, Lock, LogOut, ArrowUpDown } from 'lucide-react';
import { toast } from 'sonner';

export default function Index() {
  const { userId, loading: authLoading, updatePLZ, signOut } = useAuth();
  const navigate = useNavigate();
  const [dishes, setDishes] = useState<Dish[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [chains, setChains] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedChain, setSelectedChain] = useState('all');
  const [maxPrice, setMaxPrice] = useState(30);
  const [showQuickMeals, setShowQuickMeals] = useState(false);
  const [showMealPrep, setShowMealPrep] = useState(false);
  const [sortBy, setSortBy] = useState<'price' | 'savings' | 'name'>('price');
  const [loading, setLoading] = useState(true);
  const [userPLZ, setUserPLZ] = useState<string>('');

  console.log('userId === >', userId);

  useEffect(() => {
    if (userId) {
      loadUserData();
      loadFilterOptions();
    }
  }, [userId]);

  useEffect(() => {
    if (userId) {
      loadDishes();
    }
  }, [userId, selectedCategory, selectedChain, maxPrice, userPLZ, showQuickMeals, showMealPrep]);

  const loadUserData = async () => {
    if (!userId) return;

    try {
      const plz = await api.getUserPLZ(userId);
      if (plz) {
        setUserPLZ(plz);
      }
    } catch (error) {
      console.error('Error loading user data:', error);
    }
  };

  const loadFilterOptions = async () => {
    try {
      const [categoriesData, chainsData] = await Promise.all([
        api.getCategories(),
        api.getChains(),
      ]);

      setCategories(categoriesData);
      setChains(chainsData.map((c) => c.chain_name));
    } catch (error) {
      console.error('Error loading filter options:', error);
    }
  };

  const loadDishes = async () => {
    if (!userId) return;

    setLoading(true);
    try {
      const filters: DishFilters = {
        category: selectedCategory !== 'all' ? selectedCategory : undefined,
        chain: selectedChain !== 'all' ? selectedChain : undefined,
        maxPrice,
        plz: userPLZ || undefined,
        isQuick: showQuickMeals ? true : undefined,
        isMealPrep: showMealPrep ? true : undefined,
      };

      const dishesData = await api.getDishes(filters, 100); 

      // Load favorites for user
      const favorites = await api.getFavorites(userId);
      const dishesWithFavorites: Dish[] = dishesData.map((dish) => ({
        ...dish,
        isFavorite: favorites.includes(dish.dish_id),
      }));

      // Sort dishes
      const sortedDishes = sortDishes(dishesWithFavorites, sortBy);

      setDishes(sortedDishes);
    } catch (error) {
      console.error('Error loading dishes:', error);
      toast.error('Failed to load dishes');
    } finally {
      setLoading(false);
    }
  };

  const sortDishes = (dishes: Dish[], sort: typeof sortBy): Dish[] => {
    const sorted = [...dishes];
    switch (sort) {
      case 'price':
        return sorted.sort((a, b) => (a.currentPrice || 0) - (b.currentPrice || 0));
      case 'savings':
        return sorted.sort((a, b) => (b.savings || 0) - (a.savings || 0));
      case 'name':
        return sorted.sort((a, b) => a.name.localeCompare(b.name));
      default:
        return sorted;
    }
  };

  const handleSortChange = (value: typeof sortBy) => {
    setSortBy(value);
    const sorted = sortDishes(dishes, value);
    setDishes(sorted);
  };

  const handlePLZChange = async (plz: string) => {
    if (!userId) return;

    try {
      await api.updateUserPLZ(userId, plz);
      await updatePLZ(plz); // Also update via auth hook for consistency
      setUserPLZ(plz);
      // loadDishes will be triggered by useEffect
    } catch (error) {
      console.error('Error updating PLZ:', error);
      toast.error('Failed to update location');
    }
  };

  const handleFavorite = async (dishId: string) => {
    if (!userId) return;

    try {
      const isFavorite = await api.isFavorite(userId, dishId);
      if (isFavorite) {
        await api.removeFavorite(userId, dishId);
        toast.success('Removed from favorites');
      } else {
        // Check if user has access (paywall placeholder)
        toast.info('This is a premium feature', {
          description: 'Upgrade to save your favorite dishes',
          icon: <Lock className="h-4 w-4" />,
        });
        // Uncomment when paywall is removed:
        // await api.addFavorite(userId, dishId);
        // toast.success('Added to favorites');
      }
      // Reload dishes to update favorite status
      loadDishes();
    } catch (error) {
      console.error('Error toggling favorite:', error);
      toast.error('Failed to update favorite');
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      toast.success('Signed out successfully');
      navigate('/login');
    } catch (error: any) {
      toast.error(error.message || 'Failed to sign out');
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card/50 backdrop-blur sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShoppingCart className="h-6 w-6 text-primary" />
              <h1 className="text-2xl font-bold">MealDeal</h1>
            </div>
            <Button variant="ghost" size="sm" onClick={handleSignOut}>
              <LogOut className="mr-2 h-4 w-4" />
              Sign Out
            </Button>
          </div>
        </div>
      </header>

      <section className="bg-gradient-to-br from-primary/10 to-accent/10 py-12">
        <div className="container mx-auto px-4">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            <div className="flex items-center justify-center gap-2">
              <Sparkles className="h-8 w-8 text-primary" />
              <h2 className="text-3xl md:text-4xl font-bold">Cook Smart, Save More</h2>
            </div>
            <p className="text-lg text-muted-foreground">
              Discover delicious meals based on current supermarket deals in your area
            </p>
            <div className="max-w-md mx-auto">
              <PLZInput onPLZChange={handlePLZChange} currentPLZ={userPLZ} />
            </div>
            {userPLZ && <p className="text-sm text-muted-foreground">Showing deals for PLZ {userPLZ}</p>}
          </div>
        </div>
      </section>

      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          <aside className="lg:col-span-1">
            <div className="sticky top-24">
              <DishFiltersComponent
                categories={categories}
                chains={chains}
                selectedCategory={selectedCategory}
                selectedChain={selectedChain}
                maxPrice={maxPrice}
                showQuickMeals={showQuickMeals}
                showMealPrep={showMealPrep}
                onCategoryChange={setSelectedCategory}
                onChainChange={setSelectedChain}
                onMaxPriceChange={setMaxPrice}
                onQuickMealsChange={setShowQuickMeals}
                onMealPrepChange={setShowMealPrep}
              />
            </div>
          </aside>

          <main className="lg:col-span-3">
            <div className="mb-6 flex items-center justify-between flex-wrap gap-4">
              <div>
                <h3 className="text-2xl font-bold">Available Meals</h3>
                <p className="text-muted-foreground">
                  {dishes.length} {dishes.length === 1 ? 'dish' : 'dishes'} found
                  {userPLZ && ` for PLZ ${userPLZ}`}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <ArrowUpDown className="h-4 w-4 text-muted-foreground" />
                <Select value={sortBy} onValueChange={handleSortChange}>
                  <SelectTrigger className="w-[140px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="price">Price (Low)</SelectItem>
                    <SelectItem value="savings">Savings (High)</SelectItem>
                    <SelectItem value="name">Name (A-Z)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
              {dishes.map((dish) => (
                <DishCard key={dish.dish_id} dish={dish} onFavorite={handleFavorite} />
              ))}
            </div>

            {dishes.length === 0 && !loading && (
              <div className="text-center py-12 space-y-4">
                <div className="text-6xl mb-4">🍽️</div>
                <h4 className="text-xl font-semibold">No dishes found</h4>
                <p className="text-muted-foreground max-w-md mx-auto">
                  {!userPLZ 
                    ? 'Enter your postal code to see dishes with current offers in your area.'
                    : 'Try adjusting your filters or check back later for new offers.'}
                </p>
                {!userPLZ && (
                  <div className="max-w-md mx-auto mt-4">
                    <PLZInput onPLZChange={handlePLZChange} currentPLZ={userPLZ} />
                  </div>
                )}
              </div>
            )}
          </main>
        </div>
      </div>

      <footer className="border-t mt-16 py-8">
        <div className="container mx-auto px-4 text-center text-sm text-muted-foreground">
          <p className="mb-2">© 2025 MealDeal. Alle Rechte vorbehalten.</p>
          <div className="flex justify-center gap-4">
            <Link to="/privacy" className="hover:text-primary underline">
              Datenschutz
            </Link>
            <Link to="/terms" className="hover:text-primary underline">
              Nutzungsbedingungen
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
