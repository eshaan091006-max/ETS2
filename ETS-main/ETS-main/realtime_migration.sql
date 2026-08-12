-- Enables Supabase Realtime for the participations table
-- This allows the Flutter app to receive instant updates without refreshing
ALTER PUBLICATION supabase_realtime ADD TABLE participations;
