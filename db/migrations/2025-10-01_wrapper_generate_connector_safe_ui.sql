-- Wrapper: keeps your existing v3 logic *unchanged* but guarantees UI fields are safe.
-- Calls your generate_and_insert_connector_v3 with sanitized payload.
create or replace function public.generate_connector_safe_ui(
  p_country        text,
  p_state          text,
  p_parent_ref     text,
  p_mobile         text,
  p_fullname       text,
  p_email          text,
  p_extra          jsonb,
  p_recovery_e164  text,
  p_payload        jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  pl jsonb := coalesce(p_payload, '{}'::jsonb);
begin
  -- Only ensure UI fields are never NULL/empty; IDs & referral remain owned by v3.
  pl := pl
    || jsonb_build_object(
         'profession',
         case when nullif(pl->>'profession','') is null then 'general' else pl->>'profession' end
       )
    || jsonb_build_object(
         'short_name',
         case
           when nullif(pl->>'short_name','') is not null then pl->>'short_name'
           when nullif(p_fullname,'') is not null
             then left(regexp_replace(p_fullname, '\s+', ' ', 'g'), 24)
           else 'CONNECTA'
         end
       );

  return public.generate_and_insert_connector_v3(
    p_country, p_state, p_parent_ref,
    p_mobile, p_fullname, p_email,
    p_extra, p_recovery_e164, pl
  );
end;
$$;
