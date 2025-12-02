import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Heart, Zap, ChefHat } from 'lucide-react';
import { cn } from '@/lib/utils';

interface DishCardProps {
  dish: {
    dish_id: string;
    name: string;
    category: string;
    is_quick?: boolean;
    is_meal_prep?: boolean;
    currentPrice?: number;
    basePrice?: number;
    savings?: number;
    savingsPercent?: number;
    availableOffers?: number;
    isFavorite?: boolean;
  };
  onFavorite?: (dishId: string) => void;
}

export function DishCard({ dish, onFavorite }: DishCardProps) {
  const savingsPercent = dish.savingsPercent !== undefined 
    ? dish.savingsPercent 
    : (dish.basePrice && dish.savings 
      ? Math.round((dish.savings / dish.basePrice) * 100) 
      : 0);

  const hasOffers = (dish.availableOffers ?? 0) > 0;
  const hasSavings = dish.savings && dish.savings > 0;

  return (
    <Card className="overflow-hidden hover:shadow-lg transition-shadow flex flex-col h-full">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 min-w-0">
            <div className="flex items-start gap-2 mb-1">
              <CardTitle className="text-lg line-clamp-2 flex-1">{dish.name}</CardTitle>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => onFavorite?.(dish.dish_id)}
                className="shrink-0 h-8 w-8"
              >
                <Heart
                  className={cn(
                    'h-4 w-4',
                    dish.isFavorite && 'fill-destructive text-destructive'
                  )}
                />
              </Button>
            </div>
            <div className="flex items-center gap-2 flex-wrap mt-2">
              <Badge variant="secondary" className="text-xs">
                {dish.category}
              </Badge>
              {dish.is_quick && (
                <Badge variant="outline" className="text-xs border-yellow-500 text-yellow-600">
                  <Zap className="h-3 w-3 mr-1" />
                  Quick
                </Badge>
              )}
              {dish.is_meal_prep && (
                <Badge variant="outline" className="text-xs border-blue-500 text-blue-600">
                  <ChefHat className="h-3 w-3 mr-1" />
                  Meal Prep
                </Badge>
              )}
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-3 flex-1 flex flex-col">
        <div className="flex items-baseline gap-2">
          <span className="text-2xl font-bold text-primary">
            €{(dish.currentPrice || dish.basePrice || 0).toFixed(2)}
          </span>
          {dish.basePrice && dish.basePrice > (dish.currentPrice || 0) && (
            <span className="text-sm text-muted-foreground line-through">
              €{dish.basePrice.toFixed(2)}
            </span>
          )}
        </div>

        {hasSavings && (
          <div className="flex items-center gap-2">
            <Badge variant="default" className="bg-green-600 hover:bg-green-700 text-white">
              Save €{dish.savings!.toFixed(2)} ({savingsPercent}%)
            </Badge>
          </div>
        )}

        {hasOffers && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Badge variant="outline" className="text-xs">
              {dish.availableOffers} {dish.availableOffers === 1 ? 'offer' : 'offers'} available
            </Badge>
          </div>
        )}

        {!hasOffers && !hasSavings && dish.currentPrice === 0 && (
          <div className="text-xs text-muted-foreground italic">
            Pricing unavailable
          </div>
        )}
      </CardContent>
    </Card>
  );
}
