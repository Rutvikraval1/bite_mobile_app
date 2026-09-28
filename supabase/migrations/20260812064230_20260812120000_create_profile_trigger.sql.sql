/*
# Auto-create profile on user signup

## What this does
1. Creates a `handle_new_user` SECURITY DEFINER function that inserts a row
   into `profiles` when a new auth.users row is created. The profile `id`
   is set to the new user's auth UID so foreign keys (saved_items, swipes,
   meal_plans) resolve correctly.
2. Creates a trigger on `auth.users` that fires `handle_new_user` AFTER INSERT.
3. Grants EXECUTE on the function to the `anon` and `authenticated` roles
   so the trigger can run during signup.

## Security
- Function is SECURITY DEFINER so it can write to `profiles` even though
  the caller (anon) normally cannot INSERT.
- The function only runs via the trigger — it is not callable by app
  clients for arbitrary use (trigger fires server-side on auth.users INSERT).
- Existing RLS policies on `profiles` are unchanged (anon can read/write all,
  which is the current no-auth-app pattern).
*/

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'username', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon, authenticated;
