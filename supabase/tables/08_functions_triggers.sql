-- ═══════════════════════════════════════════════════════════════
-- Functions & triggers shared across tables.
-- Run after 01_profiles.sql (the trigger writes into public.profiles).
-- Final effective state (see ../migrations/ for history).
-- ═══════════════════════════════════════════════════════════════

-- Auto-create a profiles row whenever a new auth.users row is created,
-- so saved_items / meal_plans / swipes FKs resolve immediately on signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'display_name', ''),
    coalesce(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- The trigger fires server-side on auth.users INSERT under SECURITY
-- DEFINER, but anon/authenticated still need EXECUTE to invoke it.
grant execute on function public.handle_new_user() to anon, authenticated;
