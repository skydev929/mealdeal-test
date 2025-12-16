-- Deprecate old calculate_dish_price function
-- This function is no longer used as we've moved to per-unit savings calculation
-- Keeping it for backwards compatibility during migration, but marking as deprecated

COMMENT ON FUNCTION calculate_dish_price(TEXT, TEXT) IS 
  'DEPRECATED: This function calculates total dish prices which is no longer part of the MVP. '
  'Use calculate_dish_aggregated_savings() instead for aggregated per-unit savings. '
  'This function may be removed in a future migration after all code has been updated.';

-- Note: We're not dropping the function yet to maintain backwards compatibility
-- It can be removed in a future migration after all code has been updated

