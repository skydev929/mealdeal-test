import { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { MapPin, Loader2 } from 'lucide-react';
import { toast } from 'sonner';

interface PLZInputProps {
  onPLZChange: (plz: string) => void;
  currentPLZ?: string;
}

export function PLZInput({ onPLZChange, currentPLZ }: PLZInputProps) {
  const [plz, setPLZ] = useState(currentPLZ || '');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (plz.length !== 5 || !/^\d+$/.test(plz)) {
      toast.error('Please enter a valid 5-digit postal code');
      return;
    }

    setIsLoading(true);
    try {
      await onPLZChange(plz);
      toast.success('Location updated');
    } catch (error) {
      toast.error('Failed to update location');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <div className="flex-1">
        <Label htmlFor="plz" className="sr-only">Postal Code</Label>
        <div className="relative">
          <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            id="plz"
            type="text"
            placeholder="Enter PLZ (e.g., 10115)"
            value={plz}
            onChange={(e) => setPLZ(e.target.value)}
            maxLength={5}
            className="pl-10"
            disabled={isLoading}
          />
        </div>
      </div>
      <Button type="submit" disabled={isLoading}>
        {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
        Update
      </Button>
    </form>
  );
}
