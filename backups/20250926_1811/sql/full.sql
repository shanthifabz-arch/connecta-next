--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: connecta; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA connecta;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: global_connecta_id_text(text, text, integer, text, text); Type: FUNCTION; Schema: connecta; Owner: -
--

CREATE FUNCTION connecta.global_connecta_id_text(p_self_connecta_id text, p_self_level text, p_self_level_seq integer, p_parent_ref text, p_suffix text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
WITH me AS (
  -- Derive self level (AA/AB/AC/...) and sequence; prefer parsing from p_self_connecta_id, fallback to explicit args
  SELECT
    upper(coalesce(
      p_self_level,
      (regexp_match(coalesce(p_self_connecta_id, ''), 'INTA([A-Z]{2})'))[1],
      ''
    )) AS lvl,
    coalesce(
      nullif(
        regexp_replace(
          coalesce((regexp_match(coalesce(p_self_connecta_id, ''), 'INTA[A-Z]{2}(\d+)'))[1], ''),
          '^0+(?=\d)', ''
        ),
        ''
      ),
      nullif(p_self_level_seq::text, '')
    ) AS serial
),
tokens AS (
  -- Normalize parent token: accept either `AC2` or `INTAAC2` from caller; ensure final form is `INTA..`
  SELECT
    CASE
      WHEN coalesce(p_parent_ref, '') = '' THEN NULL
      WHEN upper(p_parent_ref) ~ '^INTA'   THEN upper(p_parent_ref)
      ELSE 'INTA' || upper(p_parent_ref)
    END AS parent_token,
    CASE
      WHEN (SELECT serial FROM me) IS NOT NULL
        THEN 'INTA' || (SELECT lvl FROM me) || (SELECT serial FROM me)
      ELSE NULL
    END AS self_token
),
sx AS (
  -- Caller enforces label policy (business short name OR left(fullName,14)); don't truncate here
  SELECT upper(coalesce(p_suffix, '')) AS label_text
)
SELECT trim(both ' ' FROM
  CASE
    -- Root AA: SELF_TOKEN CONNECTA LABEL
    WHEN (SELECT parent_token FROM tokens) IS NULL OR (SELECT parent_token FROM tokens) = '' THEN
      coalesce((SELECT self_token FROM tokens), '') ||
      CASE WHEN (SELECT self_token FROM tokens) IS NOT NULL THEN ' CONNECTA ' ELSE '' END ||
      (SELECT label_text FROM sx)
    -- Non-root: PARENT_TOKEN-SELF_TOKEN CONNECTA LABEL
    ELSE
      (SELECT parent_token FROM tokens) || '-' ||
      coalesce((SELECT self_token FROM tokens), '') ||
      ' CONNECTA ' ||
      (SELECT label_text FROM sx)
  END
);
$$;


--
-- Name: tg_connectors_parent_ref_changed(); Type: FUNCTION; Schema: connecta; Owner: -
--

CREATE FUNCTION connecta.tg_connectors_parent_ref_changed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if (tg_op = 'UPDATE') and (new."referralCode" is distinct from old."referralCode") then
    update connectors ch
       set global_connecta_id = connecta.global_connecta_id_text(
             null,
             coalesce(
               nullif(trim(both from ch.level::text),''),
               (regexp_match(coalesce(ch."connectaID_full",''), '^([A-Z]+)'))[1]
             ),
             ch.level_sequence,
             new."referralCode",
             coalesce(
               nullif(ch.short_name,''),
               nullif(ch.shortname,''),
               nullif(ch.payload_json->>'shortCompany',''),
               nullif(ch.payload_json->>'company',''),
               nullif(ch.company_name,'')
             )
           )
     where ch.parent_connector_id = new.id;
  end if;
  return new;
end;
$$;


--
-- Name: tg_connectors_set_global_id(); Type: FUNCTION; Schema: connecta; Owner: -
--

CREATE FUNCTION connecta.tg_connectors_set_global_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  parent_token text;
  label_text   text;
  lvl_text     text;
BEGIN
  -- Parent token = parent's connectaID_full (or NULL for roots)
  IF NEW.parent_connector_id IS NOT NULL THEN
    SELECT "connectaID_full" INTO parent_token
    FROM public.connectors
    WHERE id = NEW.parent_connector_id;
  END IF;

  -- Label rule: business → short name; individual → first 14 chars of fullName
  IF NEW.connector_type = 'business' THEN
    label_text := coalesce(
      nullif(NEW.short_name, ''),
      nullif(NEW.shortname, ''),
      nullif(NEW.payload_json->>'shortCompany', ''),
      nullif(NEW.payload_json->>'company', ''),
      nullif(NEW.company_name, '')
    );
    -- fallback to name if none of the business fields exist
    IF coalesce(label_text, '') = '' THEN
      label_text := left(coalesce(nullif(NEW."fullName", ''), ''), 14);
    END IF;
  ELSE
    label_text := left(coalesce(nullif(NEW."fullName", ''), ''), 14);
  END IF;

  -- Level text: prefer NEW.level, fallback is handled by the generator
  lvl_text := nullif(trim(NEW.level::text), '');

  -- Compute the Global CONNECTA ID via the canonical function
  NEW.global_connecta_id := connecta.global_connecta_id_text(
    NEW."connectaID_full",     -- p_self_connecta_id
    lvl_text,                  -- p_self_level
    NEW.level_sequence,        -- p_self_level_seq
    parent_token,              -- p_parent_ref  (parent's connectaID_full)
    label_text                 -- p_suffix      (label)
  );

  RETURN NEW;
END
$$;


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$_$;


--
-- Name: add_child_connector(uuid, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_child_connector(parent_id uuid, mobile text, alt_mobile text, gst_no text, company_name text, classification text, address1 text, address2 text, address3 text, city_name text, state_name text, pincode text, email_id text, upi text, connector_type text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  parent_level char(2);
  child_level char(2);
  child_count int;
  new_sequence int;
  country_code text := 'IN'; -- replace or fetch dynamically
  state_code text := 'TN'; -- replace or fetch dynamically
  new_connecta_id text;
  new_connector_id uuid;
BEGIN
  -- Get parent's level
  SELECT level INTO parent_level FROM connectors WHERE id = parent_id;
  
  -- Calculate child level (e.g. AA -> AB, AB -> AC)
  child_level := chr(ascii(parent_level) + 1) || 'A';
  
  -- Count existing children at this level under parent
  SELECT COUNT(*) INTO child_count FROM connectors WHERE parent_connector_id = parent_id AND level = child_level;
  
  IF child_count >= 999 THEN
    RAISE EXCEPTION 'Max 999 child connectors reached at level %', child_level;
  END IF;
  
  new_sequence := child_count + 1;
  
  -- Generate Connecta ID
  new_connecta_id := country_code || state_code || child_level || new_sequence::text;
  
  -- Insert new connector
  INSERT INTO connectors (
    mobile_number, alternate_mobile, connecta_id, gst_number, company_name, classification,
    address_line1, address_line2, address_line3, city, state, pincode, email,
    upi_id, parent_connector_id, level, level_sequence, connector_type, created_at, updated_at
  ) VALUES (
    mobile, alt_mobile, new_connecta_id, gst_no, company_name, classification,
    address1, address2, address3, city_name, state_name, pincode, email_id,
    upi, parent_id, child_level, new_sequence, connector_type, now(), now()
  ) RETURNING id INTO new_connector_id;
  
  RETURN new_connector_id;
END;
$$;


--
-- Name: assign_connecta_fields(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assign_connecta_fields() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
  parent_lvl   text;
  parent_ref   text;
  parent_cid   text;
  parent_ord   integer;   -- AD<n> number we want (2 for AD2, etc.)
  seq          integer;
  serial       integer;
  serial_txt   text;
BEGIN
  -- 1) Authoritative per-parent, per-child-level sequence if not provided
  IF NEW.level_sequence IS NULL THEN
    SELECT COALESCE(COUNT(*) + 1, 1)
      INTO seq
      FROM public.connectors c
     WHERE c.parent_connector_id IS NOT DISTINCT FROM NEW.parent_connector_id
       AND c.level = NEW.level;
    NEW.level_sequence := seq;
  ELSE
    seq := NEW.level_sequence;
  END IF;

  -- 2) Fetch parent basics
  IF NEW.parent_connector_id IS NOT NULL THEN
    SELECT COALESCE(level,'AA'), "referralCode", "connectaID"
      INTO parent_lvl, parent_ref, parent_cid
    FROM public.connectors
    WHERE id IS NOT DISTINCT FROM NEW.parent_connector_id;
  ELSE
    parent_lvl := 'AA';
    parent_ref := NULL;
    parent_cid := NULL;
  END IF;

  -- 3) Derive parent ordinal:
  --    Prefer 9-digit block in referralCode (…INT..AD#########_…),
  --    else digits after AD in parent connectaID (e.g., AD7007-… → 7007).
  parent_ord := NULL;
  IF parent_ref IS NOT NULL THEN
    -- grab the 9-digit run just before the underscore
    BEGIN
      parent_ord := NULLIF(regexp_replace(parent_ref, '^.*?([0-9]{9})_.*$', '\1'), '')::int;
    EXCEPTION WHEN others THEN
      parent_ord := NULL;
    END;
  END IF;

  IF parent_ord IS NULL AND parent_cid IS NOT NULL THEN
    BEGIN
      parent_ord := NULLIF(regexp_replace(parent_cid, '^[A-Z]{2}([0-9]+)-.*$', '\1'), '')::int;
    EXCEPTION WHEN others THEN
      parent_ord := NULL;
    END;
  END IF;

  IF parent_ord IS NULL THEN
    parent_ord := 1;  -- safe fallback
  END IF;

  -- 4) Serial from the child's sequence
  serial := seq;
  IF serial < 1000 THEN
    serial_txt := lpad(serial::text, 3, '0');   -- 001..999
  ELSE
    serial_txt := serial::text;                 -- 1000.. etc
  END IF;

  -- 5) Build IDs only if not provided explicitly
  IF (NEW."connectaID" IS NULL OR NEW."connectaID" = '') THEN
    NEW."connectaID" := parent_lvl || parent_ord::text || '-' || NEW.level || '-' || serial_txt;
  END IF;

  IF (NEW."connectaID_full" IS NULL OR NEW."connectaID_full" = '') THEN
    NEW."connectaID_full" := 'INT' || NEW.level || ' ' || NEW."connectaID";
  END IF;

  RETURN NEW;
END $_$;


--
-- Name: badge_for_referral_v1(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.badge_for_referral_v1(p_ref text, p_country text, p_state text, p_company text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_ref text := coalesce(trim(p_ref), '');
  v_cc  text := upper(coalesce(p_country, ''))::text;
  v_st  text := coalesce(p_state, '');
  v_level text;
  v_serial text;
  v_match text;
begin
  -- Try to extract INTA.. from referral
  v_match := (regexp_match(v_ref, 'INTA([A-Z]{2})([0-9]+)(?:_[A-Z])?' , 'i'))[1] || (regexp_match(v_ref, 'INTA([A-Z]{2})([0-9]+)(?:_[A-Z])?' , 'i'))[2];
  if v_match is not null then
    v_level  := upper((regexp_match(v_ref, 'INTA([A-Z]{2})', 'i'))[1]);
    v_serial := ltrim((regexp_match(v_ref, 'INTA[A-Z]{2}([0-9]+)', 'i'))[1], '0');
  end if;

  -- Country → ISO2 quick map (extend as you need)
  if v_cc is null or length(v_cc) <> 2 then
    v_cc := case upper(p_country)
              when 'INDIA' then 'IN'
              when 'BANGLADESH' then 'BD'
              when 'UNITED STATES' then 'US'
              when 'USA' then 'US'
              else upper(substr(coalesce(p_country,''),1,2))
            end;
  end if;

  return trim(
    coalesce(v_cc,'') || ' ' ||
    coalesce(v_st,'') || ' ' ||
    coalesce(v_level,'') || '-' ||
    lpad(coalesce(v_serial,''), 9, '0') || ' ' ||
    coalesce(left(coalesce(p_company,''),10),'')
  );
end;
$$;


--
-- Name: base36_decode(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.base36_decode(s text) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  str text := upper(trim(s));
  i int; ch text; val int; acc bigint := 0;
BEGIN
  IF str IS NULL OR str = '' THEN
    RETURN NULL;
  END IF;
  FOR i IN 1..length(str) LOOP
    ch := substr(str, i, 1);
    IF ch BETWEEN '0' AND '9' THEN
      val := ascii(ch) - ascii('0');
    ELSIF ch BETWEEN 'A' AND 'Z' THEN
      val := 10 + (ascii(ch) - ascii('A'));
    ELSE
      RAISE EXCEPTION 'Invalid base36 char: % in "%"', ch, s;
    END IF;
    acc := acc * 36 + val;
    IF acc > 2147483647 THEN
      RAISE EXCEPTION 'Decoded value out of int range for "%"', s;
    END IF;
  END LOOP;
  RETURN acc::int;
END;
$$;


--
-- Name: base36_encode(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.base36_encode(n integer) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  v int := n;
  digits text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  out text := '';
  r int;
BEGIN
  IF v IS NULL OR v < 0 THEN
    RAISE EXCEPTION 'base36_encode expects non-negative integer, got %', v;
  END IF;
  IF v = 0 THEN
    RETURN '0';
  END IF;
  WHILE v > 0 LOOP
    r := v % 36;
    out := substr(digits, r+1, 1) || out;
    v := v / 36;
  END LOOP;
  RETURN out;
END;
$$;


--
-- Name: build_referralcode(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.build_referralcode() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
  v_prefix text := public.build_region_level_prefix(NEW.country, NEW.state, NEW.level);
  v_serial text := to_char(
                     (regexp_replace(NEW."connectaID", '^.*-(\d+)$', '\1'))::int,
                     'FM000000000'
                   );
  v_name   text := substr(
                     upper(
                       regexp_replace(
                         coalesce(nullif(NEW.company_name,''),
                                  nullif(NEW."fullName",''),
                                  nullif(NEW.shortname,''),
                                  'CONNECTA'),
                         '[^A-Za-z0-9]', '', 'g'
                       )
                     ),
                     1, 10
                   );
BEGIN
  NEW."referralCode" := format('%s_%s_%s%s_%s',
    coalesce(NEW.country,''),
    coalesce(NEW.state,''),
    v_prefix,
    v_serial,
    v_name
  );
  RETURN NEW;
END;
$_$;


--
-- Name: build_region_level_prefix(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.build_region_level_prefix(p_country text, p_state text, p_level text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  c2 text; s2 text;
BEGIN
  -- Try country_codes table if it exists
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='country_codes') THEN
    SELECT code2 INTO c2 FROM public.country_codes WHERE country = p_country;
  END IF;
  -- Fallback
  c2 := COALESCE(c2, COALESCE(NULLIF(UPPER(SUBSTRING(p_country FROM 1 FOR 2)), ''), 'UN'));

  -- Try state_codes table if it exists
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='state_codes') THEN
    SELECT code2 INTO s2 FROM public.state_codes WHERE country = p_country AND state = p_state;
  END IF;
  -- Fallback
  s2 := COALESCE(s2, COALESCE(NULLIF(UPPER(SUBSTRING(p_state FROM 1 FOR 2)), ''), 'XX'));

  RETURN c2 || s2 || COALESCE(p_level,'');
END;
$$;


--
-- Name: charity_deduction(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.charity_deduction(net_post_tax numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
  select case when net_post_tax > 100000 then round(net_post_tax * 0.10, 2) else 0 end
$$;


--
-- Name: child_block_start(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.child_block_start(p_parent_serial integer) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE
           WHEN p_parent_serial IS NULL OR p_parent_serial <= 1 THEN 1
           ELSE (p_parent_serial - 1) * 1000
         END;
$$;


--
-- Name: classify_connector_v1(uuid, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.classify_connector_v1(p_id uuid DEFAULT NULL::uuid, p_connecta_id text DEFAULT NULL::text, p_referral_code text DEFAULT NULL::text, p_connector_type text DEFAULT NULL::text, p_business_variant text DEFAULT NULL::text, p_short_name text DEFAULT NULL::text, p_full_name text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE
  target_id uuid;

  has_connecta_id      boolean;
  has_connectaID       boolean;
  has_referral_code    boolean;
  has_referralCode     boolean;
  has_full_name        boolean;
  has_fullName         boolean;

  sql_resolve text;
  sql_update  text;
BEGIN
  -- Detect alternate spellings once
  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='connectors' AND column_name='connecta_id')
    INTO has_connecta_id;

  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='connectors' AND column_name='connectaID')
    INTO has_connectaID;

  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='connectors' AND column_name='referral_code')
    INTO has_referral_code;

  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='connectors' AND column_name='referralCode')
    INTO has_referralCode;

  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='connectors' AND column_name='full_name')
    INTO has_full_name;

  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='connectors' AND column_name='fullName')
    INTO has_fullName;

  -- Resolve target row: prefer id, else connecta_id, else referral_code
  IF p_id IS NOT NULL THEN
    SELECT id INTO target_id FROM public.connectors WHERE id = p_id LIMIT 1;
  END IF;

  IF target_id IS NULL AND p_connecta_id IS NOT NULL THEN
    IF has_connecta_id THEN
      sql_resolve := 'SELECT id FROM public.connectors WHERE connecta_id = $1 LIMIT 1';
      EXECUTE sql_resolve USING p_connecta_id INTO target_id;
    ELSIF has_connectaID THEN
      sql_resolve := 'SELECT id FROM public.connectors WHERE "connectaID" = $1 LIMIT 1';
      EXECUTE sql_resolve USING p_connecta_id INTO target_id;
    END IF;
  END IF;

  IF target_id IS NULL AND p_referral_code IS NOT NULL THEN
    IF has_referral_code THEN
      sql_resolve := 'SELECT id FROM public.connectors WHERE referral_code = $1 LIMIT 1';
      EXECUTE sql_resolve USING p_referral_code INTO target_id;
    ELSIF has_referralCode THEN
      sql_resolve := 'SELECT id FROM public.connectors WHERE "referralCode" = $1 LIMIT 1';
      EXECUTE sql_resolve USING p_referral_code INTO target_id;
    END IF;
  END IF;

  IF target_id IS NULL THEN
    RAISE EXCEPTION 'Target connector not found (provide id, connecta_id, or referral_code)';
  END IF;

  -- Build dynamic UPDATE (handles snake vs camel for full name)
  sql_update := 'UPDATE public.connectors SET ' ||
                'connector_type = lower($1), ' ||
                'business_variant = lower($2), ' ||
                'short_name = NULLIF(btrim($3), '''')';

  IF p_full_name IS NOT NULL THEN
    IF has_full_name THEN
      sql_update := sql_update || ', full_name = COALESCE(NULLIF(btrim($4), ''''), full_name)';
    ELSIF has_fullName THEN
      sql_update := sql_update || ', "fullName" = COALESCE(NULLIF(btrim($4), ''''), "fullName")';
    END IF;
  END IF;

  sql_update := sql_update || ' WHERE id = $5';

  EXECUTE sql_update
    USING p_connector_type, p_business_variant, p_short_name, p_full_name, target_id;
END
$_$;


--
-- Name: compute_global_connecta_id(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_global_connecta_id(p_child_ref text, p_parent_ref text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  cm  text[];  pm  text[];
  ctyp text; cnum_raw text; cnum text; cname text;
  ptyp text; pnum_raw text; pnum text;
BEGIN
  IF p_child_ref IS NULL OR p_parent_ref IS NULL THEN
    RETURN NULL;
  END IF;

  cm := regexp_match(p_child_ref,  '_INTA([A-Z]{2})([0-9]+)_([A-Z0-9]+)$');
  pm := regexp_match(p_parent_ref, '_INTA([A-Z]{2})([0-9]+)_');
  IF cm IS NULL OR pm IS NULL THEN
    RETURN NULL;
  END IF;

  ctyp := cm[1]; cnum_raw := cm[2]; cname := cm[3];
  cnum := COALESCE(NULLIF(regexp_replace(cnum_raw, '^0+', ''), ''), '0');

  ptyp := pm[1]; pnum_raw := pm[2];
  pnum := COALESCE(NULLIF(regexp_replace(pnum_raw, '^0+', ''), ''), '0');

  RETURN FORMAT('INTA%s%s-INTA%s%s %s', ptyp, pnum, ctyp, cnum, cname);
END
$_$;


--
-- Name: compute_next_connectaid(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_next_connectaid(p_parent_ref text, p_child_branch text) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
  v_parent_caid   text;     -- e.g. 'AB1-AB-000'
  v_parent_left   text;     -- 'AB1'
  v_parent_level  text;     -- 'AB'
  v_parent_ord    int;      -- 1, 2, 3 … from the digits in 'AB1'
  v_offset        int;      -- (ord-1)*1000
  v_min_start     int;      -- 1 for ord=1, else 1000
  v_max_tail      int;      -- max numeric tail already used for this parent+branch
  v_next_tail     int;      -- chosen next numeric tail
begin
  -- Try to get parent's row (source of truth)
  select "connectaID", level
    into v_parent_caid, v_parent_level
  from public.connectors
  where "referralCode" = p_parent_ref
  limit 1;

  if not found then
    -- Fallback: derive level from referral text (…INTAAB000… → 'AB')
    v_parent_level :=
      coalesce(upper(regexp_replace(p_parent_ref, '.*INTA([A-Z]{2})\d+.*', '\1')), 'AA');
    -- If no parent row, default left token to level+'1'
    v_parent_left := v_parent_level || '1';
    v_parent_ord  := 1;
  else
    v_parent_left := split_part(v_parent_caid, '-', 1);               -- 'AB1'
    v_parent_ord  := coalesce(nullif(regexp_replace(v_parent_left, '^\D+', ''), '')::int, 1);
  end if;

  -- Concurrency guard per (parent_left, branch)
  perform pg_advisory_xact_lock(hashtext(v_parent_left), hashtext(p_child_branch));

  -- Bucket math
  v_offset    := (v_parent_ord - 1) * 1000;
  v_min_start := case when v_parent_ord = 1 then 1 else 1000 end;

  -- Highest tail already issued for THIS parent + THIS branch
  select max( (regexp_replace("connectaID", '^\w+-\w+-', '') )::int )
    into v_max_tail
  from public.connectors
  where split_part("connectaID", '-', 1) = v_parent_left
    and split_part("connectaID", '-', 2) = p_child_branch;

  -- Next tail must be inside the block
  v_next_tail := greatest(
                   coalesce(v_max_tail, v_offset + v_min_start - 1) + 1,
                   v_offset + v_min_start
                 );

  -- Compose final ID; to_char pads <1000 to 3 digits, and leaves >=1000 as-is
  return format(
    '%s-%s-%s',
    v_parent_left,
    p_child_branch,
    to_char(v_next_tail, 'FM000')
  );
end;
$$;


--
-- Name: connector_exists_normalized(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.connector_exists_normalized(p_mobile text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  with d as (
    select regexp_replace(coalesce(p_mobile,''), '[^0-9]', '', 'g') as digits
  )
  select exists(
    select 1
    from public.connectors c, d
    where regexp_replace(coalesce(c.mobile_number,''), '[^0-9]', '', 'g')
          in (d.digits, right(d.digits, 10))
  );
$$;


--
-- Name: connector_exists_normalized_bak_20250903084504(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.connector_exists_normalized_bak_20250903084504(p_mobile text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  select exists (
    select 1
    from public.connectors c
    where right(regexp_replace(c.mobile_number, '[^0-9]', '', 'g'), 10)
      = right(regexp_replace(p_mobile,       '[^0-9]', '', 'g'), 10)
  );
$$;


--
-- Name: connector_id_for_current_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.connector_id_for_current_user() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select c.id
  from public.connectors c
  join auth.users u on u.id = auth.uid()
  where c.email = u.email  -- or your real linkage
  limit 1
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: connectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connectors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mobile_number text NOT NULL,
    alternate_mobile text,
    gst_number text,
    company_name text,
    classification text,
    city text,
    state text,
    pincode text,
    email text,
    upi_id text,
    homepage_image_url text,
    video_url text,
    website_url text,
    facebook_url text,
    instagram_url text,
    youtube_shorts_url text,
    youtube_url text,
    other_links text[],
    google_map_link text,
    parent_connector_id uuid,
    level character(2) DEFAULT 1 NOT NULL,
    level_sequence integer DEFAULT 1 NOT NULL,
    connector_type text DEFAULT 'individual'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    "addressLine1" text,
    "addressLine2" text,
    "addressLine3" text,
    "connectaID" text,
    country text DEFAULT ''::text NOT NULL,
    "fullName" text DEFAULT ''::text NOT NULL,
    language text DEFAULT ''::text NOT NULL,
    profession text DEFAULT ''::text NOT NULL,
    "recoveryMobile" text DEFAULT ''::text NOT NULL,
    "referralCode" text DEFAULT ''::text NOT NULL,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
    "connectaID_full" text,
    path_ids text,
    shortname text,
    payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    subscription_expires_at timestamp with time zone,
    subscription_status text DEFAULT 'active'::text NOT NULL,
    last_notified_at timestamp with time zone,
    business_variant text,
    short_name text,
    is_active boolean DEFAULT true NOT NULL,
    archived_at timestamp with time zone,
    global_connecta_id text,
    CONSTRAINT chk_level_pair CHECK ((level ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT chk_mobile_ne_recovery CHECK (((mobile_number IS NULL) OR ("recoveryMobile" IS NULL) OR (mobile_number <> "recoveryMobile"))),
    CONSTRAINT chk_root_parent_null CHECK ((((level = 'AA'::bpchar) AND (parent_connector_id IS NULL)) OR ((level <> 'AA'::bpchar) AND (parent_connector_id IS NOT NULL)))),
    CONSTRAINT ck_connectors_business_variant CHECK (((business_variant IS NULL) OR (lower(business_variant) = ANY (ARRAY['b2c'::text, 'b2b'::text, 'import'::text, 'export'::text])))),
    CONSTRAINT ck_connectors_connector_type CHECK (((connector_type IS NULL) OR (lower(connector_type) = ANY (ARRAY['individual'::text, 'business'::text, 'b2c'::text, 'b2b'::text, 'import'::text, 'export'::text])))),
    CONSTRAINT connectors_subscription_status_check CHECK ((subscription_status = ANY (ARRAY['active'::text, 'grace'::text, 'expired'::text, 'disabled'::text])))
);


--
-- Name: COLUMN connectors."connectaID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.connectors."connectaID" IS 'Unique CONNECTA ID assigned to connector (e.g., IN753229787709)';


--
-- Name: COLUMN connectors.shortname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.connectors.shortname IS 'Human-friendly short name shown in UI (e.g., “Mary”).';


--
-- Name: COLUMN connectors.payload_json; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.connectors.payload_json IS 'Free-form JSONB blob for extra attributes captured during onboarding.';


--
-- Name: create_child_under_parent(uuid, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_child_under_parent(p_parent_id uuid, p_fullname text, p_country text, p_state text, p_city text, p_pincode text, p_email text) RETURNS public.connectors
    LANGUAGE plpgsql
    AS $$
DECLARE
  parent_level text;
  new_row public.connectors;
BEGIN
  SELECT level INTO parent_level FROM public.connectors WHERE id = p_parent_id;
  IF parent_level IS NULL THEN
    RAISE EXCEPTION 'Parent not found: %', p_parent_id;
  END IF;

  INSERT INTO public.connectors (
    id, "fullName", level, parent_connector_id,
    country, state, city, pincode, email, "createdAt"
  ) VALUES (
    gen_random_uuid(), p_fullname,
    public.next_level(parent_level),            -- compute on server
    p_parent_id,
    p_country, p_state, p_city, p_pincode, p_email, NOW()
  )
  RETURNING * INTO new_row;

  RETURN new_row;
END;
$$;


--
-- Name: enforce_level_progression(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_level_progression() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE plc text;
BEGIN
  IF NEW.parent_connector_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT level INTO plc FROM public.connectors WHERE id = NEW.parent_connector_id;
  IF plc IS NULL THEN
    RAISE EXCEPTION 'Parent not found for %', NEW.id;
  END IF;
  IF NEW.level <> public.next_level(plc) THEN
    RAISE EXCEPTION 'Level violation: child % must be %, parent is % (got %)',
      NEW."fullName", public.next_level(plc), plc, NEW.level;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: ensure_connectaid_before_ins(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_connectaid_before_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    -- If blank or NULL, always assign from sequence
    IF NEW."connectaID" IS NULL OR btrim(NEW."connectaID"::text) = '' THEN
      NEW."connectaID" := nextval('public.connectors_connectaid_seq'::regclass)::text;
      RETURN NEW;
    END IF;

    -- If value already exists, override with a fresh sequence value
    IF EXISTS (SELECT 1 FROM public.connectors WHERE "connectaID" = NEW."connectaID") THEN
      NEW."connectaID" := nextval('public.connectors_connectaid_seq'::regclass)::text;
    END IF;

    RETURN NEW;
  END
  $$;


--
-- Name: ensure_connector_by_mobile_normalized(text, text, text, text, text, text, jsonb, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_connector_by_mobile_normalized(p_country text, p_state text, p_parent_ref text, p_mobile text, p_fullname text, p_email text, p_extra jsonb DEFAULT '{}'::jsonb, p_recovery_e164 text DEFAULT NULL::text, p_payload jsonb DEFAULT '{}'::jsonb) RETURNS TABLE(status text, connector_id uuid, referral_code text, connecta_id text, connecta_id_full text, country text, state text, level text, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  r   RECORD;
  ins jsonb;
BEGIN
  -- 1) If a connector already matches this mobile as PRIMARY, return it.
  SELECT
    c.id                              AS connector_id,
    c."referralCode"                  AS referral_code,
    c."connectaID"::text              AS connecta_id,
    c."connectaID_full"               AS connecta_id_full,
    c.country,
    c.state,
    c.level,
    c.created_at
  INTO r
  FROM public.connectors c
  WHERE c.mobile_number = p_mobile
  ORDER BY c.created_at DESC NULLS LAST
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY
    SELECT
      'existing'::text,
      r.connector_id,
      r.referral_code,
      r.connecta_id,
      r.connecta_id_full,
      r.country,
      r.state,
      r.level::text,
      r.created_at;
    RETURN;
  END IF;

  -- 1.5) Validate recovery per DB rule (required & must differ from primary)
  IF NULLIF(p_recovery_e164, '') IS NULL THEN
    RAISE EXCEPTION 'recoveryMobile is required'
      USING errcode = '23502', detail = 'UI must collect a recovery number';
  END IF;

  IF p_recovery_e164 = p_mobile THEN
    RAISE EXCEPTION 'recoveryMobile must differ from mobile_number'
      USING errcode = '23514';
  END IF;

  -- 2) Otherwise, attempt create via v3. This is race-safe below.
  BEGIN
    ins := public.generate_and_insert_connector_v3(
      p_country       => p_country,
      p_state         => p_state,
      p_parent_ref    => p_parent_ref,
      p_mobile        => p_mobile,
      p_fullname      => p_fullname,
      p_email         => p_email,
      p_extra         => COALESCE(p_extra, '{}'::jsonb),
      p_recovery_e164 => NULLIF(p_recovery_e164, ''),
      p_payload       => COALESCE(p_payload, '{}'::jsonb)
    );
  EXCEPTION
    WHEN unique_violation THEN
      -- Another request inserted concurrently. Fall through to fetch it.
      NULL;
  END;

  -- 3) Return the (now) existing row by PRIMARY only.
  SELECT
    c.id                              AS connector_id,
    c."referralCode"                  AS referral_code,
    c."connectaID"::text              AS connecta_id,
    c."connectaID_full"               AS connecta_id_full,
    c.country,
    c.state,
    c.level,
    c.created_at
  INTO r
  FROM public.connectors c
  WHERE c.mobile_number = p_mobile
  ORDER BY c.created_at DESC NULLS LAST
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ensure_connector_by_mobile_normalized: insert/fetch race resulted in no row for %', p_mobile;
  END IF;

  RETURN QUERY
  SELECT
    'created'::text,
    r.connector_id,
    r.referral_code,
    r.connecta_id,
    r.connecta_id_full,
    r.country,
    r.state,
    r.level::text,
    r.created_at;
END;
$$;


--
-- Name: example_collect_siblings(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.example_collect_siblings(p_parent_ref text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_siblings text[];
BEGIN
  v_siblings := ARRAY(
    SELECT c."connectaID"
    FROM public.connectors c
    WHERE c.parent_ref = p_parent_ref   -- if your column is "parent_ref" (lowercase), leave unquoted
    ORDER BY c."connectaID"
  );
  RETURN v_siblings;
END$$;


--
-- Name: fill_connectaid_full(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fill_connectaid_full() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Always uppercase the level, defaulting to 'AA'
  -- Prefer level_sequence; if not present yet, fall back to connectaID
  IF NEW.level IS NOT NULL THEN
    NEW."connectaID_full" :=
      UPPER(COALESCE(NEW.level, 'AA')) ||
      COALESCE(NEW.level_sequence::text, NEW."connectaID"::text, '');
  ELSE
    -- No level available: leave as NULL (or set to empty if you prefer)
    NEW."connectaID_full" := NULL;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: fill_level_sequence_from_connectaid(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fill_level_sequence_from_connectaid() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.level_sequence IS NOT NULL THEN
    RETURN NEW;  -- trust value set above
  END IF;

  -- Fallback (only if some other insert path doesn't set it):
  SELECT COALESCE(COUNT(*) + 1, 1)
    INTO NEW.level_sequence
    FROM public.connectors c
   WHERE c.parent_connector_id IS NOT DISTINCT FROM NEW.parent_connector_id;
  RETURN NEW;
END $$;


--
-- Name: fill_path_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fill_path_ids() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE parent_path text;
BEGIN
  IF NEW.parent_connector_id IS NULL THEN
    NEW.path_ids := '/' || NEW.id || '/';
  ELSE
    SELECT path_ids INTO parent_path FROM public.connectors WHERE id = NEW.parent_connector_id;
    IF parent_path IS NULL THEN
      RAISE EXCEPTION 'Parent path missing for %', NEW.parent_connector_id;
    END IF;
    NEW.path_ids := parent_path || NEW.id || '/';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: format_child_serial_b36(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.format_child_serial_b36(n integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE
           WHEN n < 1000 THEN lpad(public.base36_encode(n), 3, '0')
           ELSE public.base36_encode(n)
         END;
$$;


--
-- Name: format_connecta_badge_v1(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.format_connecta_badge_v1(p_country text, p_state text, p_connecta_id text, p_short text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  cc text := upper(regexp_replace(coalesce(p_country,''), '[^A-Za-z]', '', 'g'));
  st text := regexp_replace(coalesce(p_state,''), '\s+', ' ', 'g');
  st_abbr text;
  out text;
BEGIN
  -- crude ISO2-ish: first 2 letters of the cleaned country (override if you have a mapping table)
  cc := left(cc, 2);

  -- state abbreviation: first letters of words ("Tamil Nadu" -> "TN")
  SELECT string_agg(upper(left(w,1)), '')
    INTO st_abbr
  FROM regexp_split_to_table(st, '\s+') AS w
  WHERE w <> '';

  out := trim(both ' ' from cc || ' ' || coalesce(st_abbr,'') || ' CONNECTA');

  IF nullif(p_short,'') IS NOT NULL THEN
    out := out || '(' || p_short || ')';
  END IF;

  RETURN out;
END;
$$;


--
-- Name: generate_aa_from_code(text, text, text, text, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_aa_from_code(p_country text, p_state text, p_aa_code_input text, p_mobile_e164 text, p_recovery_e164 text, p_shortname text, p_payload jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
  v_row           public.connectors%rowtype;
  v_attempt       int := 0;

  v_country_norm  text := upper(regexp_replace(coalesce(p_country,''), '[^A-Za-z]', '', 'g'));
  v_state_norm    text := upper(regexp_replace(coalesce(p_state,''),   '[^A-Za-z]', '', 'g'));

  v_code          text := upper(coalesce(p_aa_code_input,''));
  v_code_clean    text;

  v_ord           int;      -- AA1 / AA2 / ...
  v_left          text;     -- 'AA' || v_ord  e.g. 'AA1'
  v_max_tail      int;
  v_next_tail     int;

  v_mobile        text;
  v_recovery      text;
BEGIN
  -- Extract trailing M-code even if a longer string is provided
  SELECT COALESCE( (regexp_match(v_code, '(M[0-9]+)$'))[1], v_code ) INTO v_code_clean;

  -- Validate against aa_connectors (state can be specific, ALL, or *)
  IF NOT EXISTS (
    SELECT 1
    FROM public.aa_connectors a
    WHERE upper(a.code) = v_code_clean
      AND upper(regexp_replace(coalesce(a.country,''), '[^A-Za-z]', '', 'g')) = v_country_norm
      AND (
            a.state IS NULL
         OR upper(a.state) IN ('ALL','*')
         OR upper(regexp_replace(a.state, '[^A-Za-z]', '', 'g')) = v_state_norm
      )
  ) THEN
    RAISE EXCEPTION 'Unknown/invalid AA code: %', p_aa_code_input USING errcode = '22023';
  END IF;

  -- Next AA ordinal for this (country,state)
  SELECT COALESCE(
           MAX(NULLIF(regexp_replace(split_part("connectaID", '-', 1), '^\D+', ''), '')::int),
           0
         ) + 1
    INTO v_ord
  FROM public.connectors
  WHERE level = 'AA'
    AND upper(regexp_replace(country, '[^A-Za-z]', '', 'g')) = v_country_norm
    AND upper(regexp_replace(state,   '[^A-Za-z]', '', 'g')) = v_state_norm;

  v_left := 'AA' || v_ord;

  -- Unique numeric tail among AA rows (2nd token = 'AA')
  SELECT MAX((regexp_replace("connectaID", '^\w+-\w+-', '') )::int)
    INTO v_max_tail
  FROM public.connectors
  WHERE split_part("connectaID", '-', 2) = 'AA';

  v_next_tail := COALESCE(v_max_tail, 0) + 1;

  -- Normalize phones
  v_mobile   := regexp_replace(coalesce(p_mobile_e164,''),   '[^+0-9]', '', 'g');
  v_recovery := regexp_replace(coalesce(NULLIF(p_recovery_e164,''), v_mobile), '[^+0-9]', '', 'g');

  <<retry_insert>>
  LOOP
    BEGIN
      INSERT INTO public.connectors (
        "connectaID",
        country, state,
        mobile_number, "recoveryMobile",
        shortname, level, parent_connector_id,
        payload_json
      ) VALUES (
        format('%s-AA-%s', v_left,
               CASE WHEN v_next_tail < 1000
                    THEN lpad(v_next_tail::text, 3, '0')
                    ELSE v_next_tail::text END),
        p_country, p_state,
        v_mobile, v_recovery,
        p_shortname, 'AA', NULL,
        COALESCE(p_payload, '{}'::jsonb)
      )
      RETURNING * INTO v_row;

      EXIT; -- success
    EXCEPTION WHEN unique_violation THEN
      v_attempt := v_attempt + 1;
      IF v_attempt >= 5 THEN RAISE; END IF;
      v_next_tail := v_next_tail + 1;
      PERFORM pg_sleep(0.05);
    END;
  END LOOP;

  RETURN to_jsonb(v_row);
END;
$_$;


--
-- Name: generate_and_insert_connector_v1(text, text, text, text, text, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_and_insert_connector_v1(p_country text, p_state text, p_parent_ref text, p_mobile_e164 text, p_recovery_e164 text, p_shortname text, p_child_branch text, p_payload jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_parent_connector_id uuid := NULL;
  v_inserted            public.connectors%rowtype;
  v_level2              text;     -- 'AA' or 'AB' (2 letters)
  v_seq                 integer;  -- level_sequence to insert
  v_parent_aa_n         integer;  -- AA number = parent's level_sequence
BEGIN
  -- Resolve connector parent by referralCode (connector only)
  IF p_parent_ref IS NOT NULL AND p_parent_ref <> '' THEN
    SELECT c.id INTO v_parent_connector_id
    FROM public.connectors c
    WHERE c."referralCode" = p_parent_ref
    LIMIT 1;
  END IF;

  IF v_parent_connector_id IS NULL THEN
    -- Root row → this is an AA
    v_level2 := 'AA';

    -- Next AA number (1,2,3,...) = max AA level_sequence + 1
    SELECT COALESCE(MAX(c.level_sequence), 0) + 1
      INTO v_seq
    FROM public.connectors c
    WHERE c.level = 'AA';
  ELSE
    -- Child of a connector parent → AB under that AA bucket
    v_level2 := 'AB';

    -- Find the AA number of the parent (its level_sequence)
    SELECT level_sequence
      INTO v_parent_aa_n
    FROM public.connectors
    WHERE id = v_parent_connector_id
      AND level = 'AA'
    LIMIT 1;

    IF v_parent_aa_n IS NULL THEN
      RAISE EXCEPTION 'Parent % is not an AA row (cannot derive bucket)', v_parent_connector_id
        USING ERRCODE = 'P0001';
    END IF;

    -- Bucket start for this AA: (aa_n-1)*1000
    -- Next AB sequence = max(existing children) or base, then +1
    SELECT COALESCE(MAX(c.level_sequence), ((v_parent_aa_n - 1) * 1000)) + 1
      INTO v_seq
    FROM public.connectors c
    WHERE c.parent_connector_id = v_parent_connector_id
      AND c.level = 'AB';
  END IF;

  INSERT INTO public.connectors (
      country,
      state,
      mobile_number,
      "recoveryMobile",
      shortname,
      parent_connector_id,
      level,
      level_sequence,
      payload_json
  ) VALUES (
      COALESCE(p_country, ''),
      COALESCE(p_state,   ''),
      p_mobile_e164,
      COALESCE(p_recovery_e164, ''),
      NULLIF(p_shortname, ''),
      v_parent_connector_id,
      v_level2,
      v_seq,
      COALESCE(p_payload, '{}'::jsonb)
  )
  RETURNING * INTO v_inserted;

  RETURN to_jsonb(v_inserted);

EXCEPTION
  WHEN unique_violation THEN
    -- Make the 23505 message explicit
    IF EXISTS (SELECT 1 FROM public.connectors WHERE mobile_number = p_mobile_e164) THEN
      RAISE EXCEPTION 'duplicate mobile_number: %', p_mobile_e164 USING ERRCODE = '23505';
    ELSIF EXISTS (SELECT 1 FROM public.connectors WHERE "recoveryMobile" = p_mobile_e164) THEN
      RAISE EXCEPTION 'mobile exists as recoveryMobile: %', p_mobile_e164 USING ERRCODE = '23505';
    ELSE
      RAISE; -- fallback
    END IF;
END
$$;


--
-- Name: generate_and_insert_connector_v2(text, text, text, text, text, text, jsonb, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_and_insert_connector_v2(p_country text, p_state text, p_parent_ref text, p_mobile text, p_fullname text, p_email text, p_extra jsonb DEFAULT '{}'::jsonb, p_recovery_e164 text DEFAULT NULL::text, p_payload jsonb DEFAULT '{}'::jsonb) RETURNS TABLE(connector_id uuid, connecta_id text, referral_code text, level_pair text, country text, state text, display_badge text)
    LANGUAGE plpgsql
    AS $_$
DECLARE
  -- identifiers that vary across environments
  col_connecta text;
  col_mobile   text;
  col_created  text;
  col_level    text;

  v_id        uuid;
  v_country   text;
  v_state     text;
  v_cid_full  text;
  v_suffix    text;

  sql text;
BEGIN
  ---------------------------------------------------------------------------
  -- 1) Do the real insert (v3). Make sure recovery is never NULL.
  ---------------------------------------------------------------------------
  PERFORM public.generate_and_insert_connector_v3(
    p_country       => p_country,
    p_state         => p_state,
    p_parent_ref    => p_parent_ref,
    p_mobile        => p_mobile,
    p_fullname      => p_fullname,
    p_email         => p_email,
    p_extra         => COALESCE(p_extra, '{}'::jsonb),
    p_recovery_e164 => NULLIF(p_recovery_e164, ''),
    p_payload       => COALESCE(p_payload, '{}'::jsonb)
  );

  ---------------------------------------------------------------------------
  -- 2) Work out actual column spellings on public.connectors
  ---------------------------------------------------------------------------
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='connectors' AND column_name='connecta_id')
  THEN col_connecta := 'connecta_id';
  ELSE col_connecta := '"connectaID"';
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='connectors' AND column_name='mobile_e164')
  THEN col_mobile := 'mobile_e164';
  ELSIF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema='public' AND table_name='connectors' AND column_name='mobile_number')
  THEN col_mobile := 'mobile_number';
  ELSE col_mobile := '"mobileNumber"';
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='connectors' AND column_name='created_at')
  THEN col_created := 'created_at';
  ELSE col_created := '"createdAt"';
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='connectors' AND column_name='level_pair')
  THEN col_level := 'level_pair';
  ELSE col_level := 'level';
  END IF;

  ---------------------------------------------------------------------------
  -- 3) Fetch the newest row for this mobile and ensure referralCode is set
  ---------------------------------------------------------------------------
  sql := format($q$
    SELECT
      id,
      country,
      state,
      COALESCE("connectaID_full","connectaID",connecta_id) AS cid_full
    FROM public.connectors
    WHERE %1$s = $1
    ORDER BY %2$s DESC NULLS LAST
    LIMIT 1
  $q$, col_mobile, col_created);

  EXECUTE sql INTO v_id, v_country, v_state, v_cid_full USING p_mobile;

  IF v_id IS NOT NULL THEN
    -- sanitize suffix from the name (letters/digits only, max 10)
    SELECT substring(regexp_replace(COALESCE(p_fullname,''), '[^A-Za-z0-9]+', '', 'g') FROM 1 FOR 10)
      INTO v_suffix;

    -- write referralCode only if missing
    UPDATE public.connectors c
       SET "referralCode" = format('%s_%s_%s_%s', v_country, v_state, v_cid_full, v_suffix)
     WHERE c.id = v_id
       AND COALESCE(c."referralCode",'') = '';
  END IF;

  ---------------------------------------------------------------------------
  -- 4) Return that latest row in a stable shape for the frontend
  --    (added display_badge; uses format_connecta_badge_v1 if present)
  ---------------------------------------------------------------------------
  sql := format($q$
    SELECT
      id::uuid                      AS connector_id,
      %1$s::text                    AS connecta_id,
      "referralCode"::text          AS referral_code,
      (%2$s)::text                  AS level_pair,
      country::text                 AS country,
      state::text                   AS state,
      (
        CASE
          WHEN to_regprocedure('public.format_connecta_badge_v1(text,text,bigint,text)') IS NOT NULL
          THEN public.format_connecta_badge_v1(
                 country::text,
                 state::text,
                 (%1$s)::bigint,
                 COALESCE(
                   NULLIF(shortname,''),
                   NULLIF(company_name,''),
                   NULLIF("fullName",''),
                   NULLIF((payload_json->>'shortCompany'),''),
                   ''
                 )
               )
          ELSE NULL::text
        END
      )                              AS display_badge
    FROM public.connectors
    WHERE %3$s = $1
    ORDER BY %4$s DESC NULLS LAST
    LIMIT 1
  $q$, col_connecta, col_level, col_mobile, col_created);

  RETURN QUERY EXECUTE sql USING p_mobile;
END
$_$;


--
-- Name: generate_and_insert_connector_v3(text, text, text, text, text, text, jsonb, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_and_insert_connector_v3(p_country text, p_state text, p_parent_ref text, p_mobile text, p_fullname text, p_email text, p_extra jsonb, p_recovery_e164 text, p_payload jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- normalized inputs
  v_country   text := coalesce(p_country,'');
  v_state_in  text := coalesce(p_state,'');
  v_state     text := case when v_state_in ilike 'all states' then 'All States' else v_state_in end;
  v_serial_text text;  -- 9-digit padded serial block for referral

  -- hierarchy / ids
  v_parent_id  uuid;
  v_parent_lvl text;
  v_level      text;
  v_serial     bigint;
  v_scope      text;

  -- short suffix (≤10 A–Z0–9)
  v_short_raw text := coalesce(nullif(p_extra->>'suffix',''), nullif(p_fullname,''), nullif(p_payload->>'company',''));
  v_short     text;

  -- identifiers
  v_referral_code text;
  v_connecta_full text;   -- printable 'AA2'
  v_path_ids      text;
  v_connecta_id   text;   -- NEW: 'INTA' || level || 9-digit serial (e.g., INTAA000000123)

  -- never-null full name
  v_fullname_final text;

  -- connector_type normalized
  v_connector_type text := lower(coalesce(nullif(p_payload->>'connector_type',''),'business'));

  -- return row fields
  r_id            uuid;
  r_referral      text;
  r_level         text;
  r_level_seq     bigint;
  r_connecta      text;  -- numeric serial (from column "connectaID")
  r_connecta_full text;  -- printable 'AA2'
  r_display_badge text;  -- NEW: human-friendly badge string

  -- final recovery value (must differ from primary)
  v_recovery_final text;
BEGIN
  -- sanitize suffix
  IF v_short_raw IS NOT NULL THEN
    v_short := substring(regexp_replace(upper(v_short_raw), '[^A-Z0-9]+', '', 'g') FOR 10);
    IF v_short = '' THEN v_short := NULL; END IF;
  END IF;

  -- resolve parent / level
  IF nullif(p_parent_ref,'') IS NOT NULL THEN
    SELECT c.id, upper(c.level)
      INTO v_parent_id, v_parent_lvl
      FROM public.connectors c
     WHERE c."referralCode" = p_parent_ref
     LIMIT 1;

    IF v_parent_id IS NULL THEN
      RAISE EXCEPTION 'Parent referralCode not found: %', p_parent_ref USING errcode='P0001';
    END IF;

    v_level := next_alpha_pair(coalesce(v_parent_lvl,'AA'));
    v_scope := format('CHILD|%s|%s', v_parent_id, v_level);
  ELSE
    v_parent_id := NULL;
    v_level := 'AA';
    v_scope := format('ROOT|%s|%s', v_country, v_state);
  END IF;

  -- serial & printable code
  v_serial := public.next_counter(v_scope);

  -- keep printable AA + plain serial for connectaID_full, e.g. 'AA2'
  v_connecta_full := v_level || v_serial::text;

  -- referral MUST carry a 9-digit block after the level, e.g. India_Tamil Nadu_INTAA000000123
  v_serial_text := to_char(v_serial, 'FM000000000');                  -- 9 digits
  v_referral_code := format('%s_%s_%s%s%s',
                          v_country,
                          v_state,
                          public.region_tag(v_country, v_state),
                          v_level,
                          v_serial_text);

  -- NEW: canonical connecta_id string (INTA + level + 9-digit block)
  v_connecta_id := 'INTA' || v_level || v_serial_text;

  IF v_short IS NOT NULL THEN
    v_referral_code := v_referral_code || '_' || v_short;             -- add suffix
  END IF;
  v_path_ids := NULL;

  -- fullName fallback chain (never NULL)
  v_fullname_final := coalesce(
    nullif(p_fullname,''),
    nullif(p_payload->>'fullName',''),
    nullif(p_payload->>'company',''),
    nullif(p_email,''),
    nullif(p_mobile,''),
    'CONNECTA'
  );

  -- connector_type must match CHECK; fallback to 'business'
  IF v_connector_type NOT IN ('individual','business','b2b') THEN
    v_connector_type := 'business';
  END IF;

  -- recovery is required and must differ from primary
  IF nullif(p_recovery_e164,'') IS NULL THEN
    RAISE EXCEPTION 'recoveryMobile is required' USING errcode = '23502';
  ELSIF p_recovery_e164 = p_mobile THEN
    RAISE EXCEPTION 'recoveryMobile must differ from mobile_number' USING errcode = '23514';
  ELSE
    v_recovery_final := p_recovery_e164;
  END IF;

  INSERT INTO public.connectors (
    mobile_number,
    "recoveryMobile",
    gst_number,
    company_name,
    classification,
    city,
    state,
    pincode,
    email,
    homepage_image_url,
    website_url,
    facebook_url,
    instagram_url,
    youtube_shorts_url,
    youtube_url,
    other_links,
    google_map_link,
    parent_connector_id,
    level,
    level_sequence,
    connector_type,
    created_at,
    updated_at,
    "addressLine1",
    "addressLine2",
    "addressLine3",
    "connectaID",         -- numeric/bigint in your table
    country,
    "fullName",           -- NOT NULL
    language,
    upi_id,
    video_url,
    "referralCode",
    "connectaID_full",    -- 'AA2' printable
    path_ids,
    shortname,
    payload_json,
    joined_at,
    subscription_expires_at,
    subscription_status
  )
  VALUES (
    nullif(p_mobile,''),
    v_recovery_final,                                      -- required and != primary
    nullif(p_payload->>'gstin',''),
    nullif(p_payload->>'company',''),
    nullif(p_payload->>'classification',''),
    nullif(p_payload->>'city',''),
    v_state,
    nullif(p_payload->>'pincode',''),
    coalesce(nullif(p_email,''), nullif(p_payload->>'email','')),

    -- ⬇⬇ THE ONLY SURGICAL CHANGE WE MADE (key from UI)
    nullif(p_payload->>'homepage_image_url',''),

    nullif(p_payload->'links'->>'website',''),
    nullif(p_payload->'links'->>'facebook',''),
    nullif(p_payload->'links'->>'instagram',''),
    nullif(p_payload->'links'->>'ytShorts',''),
    nullif(p_payload->'links'->>'youtube',''),
    CASE
      WHEN nullif(p_payload->'links'->>'other','') IS NULL THEN NULL
      ELSE ARRAY[ p_payload->'links'->>'other' ]::text[]
    END,
    nullif(p_payload->>'google_map_link',''),
    v_parent_id,
    v_level,
    v_serial,
    v_connector_type,
    now(),
    now(),
    nullif(p_payload->>'addressLine1',''),
    nullif(p_payload->>'addressLine2',''),
    nullif(p_payload->>'addressLine3',''),
    v_serial,                  -- numeric connectaID
    v_country,
    v_fullname_final,
    coalesce(nullif(p_payload->>'language',''), 'en'),
    nullif(p_payload->>'upi_id',''),
    nullif(p_payload->>'video_url',''),
    v_referral_code,
    v_connecta_full,
    v_path_ids,
    nullif(p_extra->>'suffix',''),
    p_payload,
    coalesce((p_payload->>'subscription_joined_at')::timestamptz, now()),
    (p_payload->>'subscription_expires_at')::timestamptz,
    'active'
  )
  RETURNING id, "referralCode", level, level_sequence, "connectaID", "connectaID_full"
  INTO r_id, r_referral, r_level, r_level_seq, r_connecta, r_connecta_full;

  -- NEW: build a display badge server-side (preferred single source of truth)
  r_display_badge := format_connecta_badge_v1(
    v_country,
    v_state,
    v_connecta_id,
    nullif(p_extra->>'suffix','')
  );

  RETURN jsonb_build_object(
    'id', r_id,
    'referral_code', r_referral,
    'country', v_country,
    'state', v_state,
    'level', r_level,
    'level_sequence', r_level_seq,
    'connectaID', r_connecta,
    'connectaID_full', r_connecta_full,
    'connecta_id', v_connecta_id,          -- NEW
    'display_badge', r_display_badge       -- NEW
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE;
END;
$$;


--
-- Name: generate_connecta_id(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_connecta_id(p_country text, p_state text) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE
  v_prefix TEXT;
  v_count INT;
  v_new_id TEXT;
BEGIN
  -- Step 1: Construct prefix from country and state
  v_prefix := UPPER(LEFT(p_country, 2) || LEFT(p_state, 2));

  -- Step 2: Count existing connectors with this prefix
  SELECT COUNT(*) INTO v_count
  FROM connectors
  WHERE "connectaID" LIKE v_prefix || '%';

  -- Step 3: Generate new Connecta ID
  v_new_id := v_prefix || LPAD((v_count + 1)::TEXT, 3, '0');

  RETURN v_new_id;
END;$$;


--
-- Name: generate_full_referral_code(text, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_full_referral_code(p_country text, p_state text, p_branch text, p_branch_count integer, p_shortname text) RETURNS TABLE(referral_code text, connecta_id text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  country_code TEXT := UPPER(LEFT(p_country, 2));
  state_code TEXT := UPPER(LEFT(REPLACE(p_state, ' ', ''), 2));
  base_prefix TEXT := country_code || state_code;
BEGIN
  referral_code := CONCAT(
    p_country, '_', p_state, '_',
    base_prefix, p_branch,
    LPAD(p_branch_count::TEXT, 9, '0'),
    '_', p_shortname
  );

  connecta_id := CONCAT('IN', TO_CHAR(NOW(), 'YYYYMMDDHH24MISS'));

  RETURN NEXT;
END;
$$;


--
-- Name: generate_full_referral_code_v2(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_full_referral_code_v2(p_country text, p_state text, p_parent_ref text, p_child_branch text, p_shortname text) RETURNS TABLE(referral_code text, connecta_id text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  cc TEXT := upper(substr(p_country, 1, 2));
  st TEXT := upper(substr(p_state,   1, 2));
  parent_suffix TEXT;       -- e.g. 'AA'
  parent_order  INT;        -- AA1, AA2, ...
  bucket_start  INT;
  bucket_end    INT;
  next_in_bucket INT;
  seq BIGINT;
BEGIN
  -- Extract parent suffix (allow letters between AA and digits, e.g. INTAA F 000000001)
  parent_suffix := substr(
    regexp_replace(p_parent_ref, '.*_([A-Z]{2})[A-Z]*[0-9]+_.*', '\1'),
    1, 2
  );

  -- Order AA parents in (country, state) by "createdAt" (earliest first)
  WITH aa_order AS (
    SELECT id, "referralCode",
           ROW_NUMBER() OVER (ORDER BY "createdAt" ASC) AS rn
    FROM public.connectors
    WHERE country = p_country
      AND state   = p_state
      AND level   = 'AA'
  )
  SELECT rn INTO parent_order
  FROM aa_order
  WHERE "referralCode" = p_parent_ref;

  IF parent_order IS NULL THEN
    RAISE EXCEPTION 'Parent AA not found for % / % (ref: %)', p_country, p_state, p_parent_ref;
  END IF;

  -- Bucket for child branch (e.g., AB): (order-1)*1000 .. order*1000-1
  bucket_start := (parent_order - 1) * 1000;
  bucket_end   := (parent_order * 1000) - 1;

  -- Next free number within that bucket for p_child_branch
  SELECT COALESCE(
    MIN(x.n) FILTER (
      WHERE x.n NOT IN (
        SELECT CAST(
                 regexp_replace("referralCode", '.*' || p_child_branch || '[A-Z]*([0-9]+).*', '\1'
               ) AS INT)
        FROM public.connectors
        WHERE country = p_country
          AND state   = p_state
          AND level   = p_child_branch
          AND CAST(
                regexp_replace("referralCode", '.*' || p_child_branch || '[A-Z]*([0-9]+).*', '\1'
              ) AS INT)
              BETWEEN bucket_start AND bucket_end
      )
    ),
    bucket_start
  ) + 1
  INTO next_in_bucket
  FROM generate_series(bucket_start, bucket_end) AS x(n);

  IF next_in_bucket > bucket_end THEN
    RAISE EXCEPTION 'No % slots left in bucket (%: %..%) for % / %',
      p_child_branch, parent_order, bucket_start, bucket_end, p_country, p_state;
  END IF;

  -- referral_code (pad number to 9 digits)
  referral_code := format(
    '%s_%s_%s%s%09s_%s',
    p_country,
    p_state,
    cc || st,
    p_child_branch,
    next_in_bucket::text,
    upper(left(p_shortname, 1))
  );

  -- connecta_id: CCSTAA + 10-digit global seq => CCSTAA0000000001
  seq := nextval('connecta_global_seq');
  connecta_id := cc || st || parent_suffix || to_char(seq, 'FM0000000000');

  RETURN NEXT;
END;
$$;


--
-- Name: get_connector_by_mobile_normalized(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_connector_by_mobile_normalized(p_mobile text) RETURNS TABLE(connector_id uuid, referral_code text, connecta_id text, connecta_id_full text, country text, state text, level text, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  WITH norm AS (
    SELECT
      regexp_replace(COALESCE(p_mobile,''), '[^0-9+]', '', 'g') AS raw,
      regexp_replace(COALESCE(p_mobile,''), '[^0-9]',  '', 'g') AS digits
  ),
  canon AS (
    SELECT
      CASE WHEN raw LIKE '00%' THEN '+' || substr(raw,3) ELSE raw END AS e164,
      digits
    FROM norm
  )
  SELECT
    c.id,
    c."referralCode",
    c."connectaID"::text,
    c."connectaID_full",
    c.country,
    c.state,
    c.level::text,
    c.created_at
  FROM public.connectors c, canon n
  WHERE
         c.mobile_number    = n.e164
      OR c."recoveryMobile" = n.e164
      OR regexp_replace(COALESCE(c.mobile_number,    ''), '[^0-9]', '', 'g') = n.digits
      OR regexp_replace(COALESCE(c."recoveryMobile", ''), '[^0-9]', '', 'g') = n.digits
  ORDER BY c.created_at DESC NULLS LAST
  LIMIT 1;
$$;


--
-- Name: is_aa_connectors_tab_unlocked(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_aa_connectors_tab_unlocked(p_ref text) RETURNS TABLE(is_aa boolean, business_pct numeric, unlocked boolean)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
WITH aa AS (
  SELECT id, level
  FROM public.connectors
  WHERE "referralCode" = p_ref
  LIMIT 1
),
ab AS (
  SELECT
    parent_connector_id,
    LOWER(
      COALESCE(NULLIF(TRIM(connector_type), ''), NULLIF(TRIM(classification), ''))
    ) AS raw_type
  FROM public.connectors
  WHERE UPPER(level) LIKE 'AB%'
),
agg AS (
  SELECT
    a.id AS parent_id,
    SUM(
      CASE
        WHEN ab.raw_type IN ('b2c','b2b','business') OR ab.raw_type ILIKE '%business%'
        THEN 1 ELSE 0
      END
    ) AS business_cnt,
    COUNT(*) AS ab_total
  FROM aa a
  LEFT JOIN ab ON ab.parent_connector_id = a.id
  GROUP BY a.id
)
SELECT
  UPPER(COALESCE((SELECT level FROM aa), '')) = 'AA' AS is_aa,
  ROUND(100.0 * COALESCE(business_cnt,0) / NULLIF(ab_total,0), 2) AS business_pct,
  (ROUND(100.0 * COALESCE(business_cnt,0) / NULLIF(ab_total,0), 2) >= 95) AS unlocked
FROM agg;
$$;


--
-- Name: next_alpha_pair(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.next_alpha_pair(p text) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare a int; b int; na int; nb int;
begin
  if p is null or length(p) < 2 then return 'AA'; end if;
  a := ascii(upper(substr(p,1,1))) - 65;
  b := ascii(upper(substr(p,2,1))) - 65;
  nb := (b + 1) % 26;
  na := (a + case when b = 25 then 1 else 0 end) % 26;
  return chr(65 + na) || chr(65 + nb);
end;
$$;


--
-- Name: next_counter(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.next_counter(p_scope text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
declare v bigint;
begin
  loop
    update public.id_counters
       set last_value = last_value + 1, updated_at = now()
     where scope = p_scope
     returning last_value into v;
    if found then return v; end if;

    begin
      insert into public.id_counters(scope,last_value) values (p_scope,1)
      on conflict do nothing;
    exception when unique_violation then
      -- race; retry
    end;
  end loop;
end;
$$;


--
-- Name: next_level(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.next_level(p text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT chr( ascii(substr(p,1,1)) + CASE WHEN substr(p,2,1)='Z' THEN 1 ELSE 0 END )
       || chr( ascii(substr(p,2,1)) + 1 - CASE WHEN substr(p,2,1)='Z' THEN 26 ELSE 0 END );
$$;


--
-- Name: parse_parent_connectaid(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parse_parent_connectaid(p text) RETURNS TABLE(parent_tag text, parent_level text, parent_serial_int integer)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
    split_part(p, '-', 1)                       AS parent_tag,
    split_part(p, '-', 2)                       AS parent_level,
    public.base36_decode(split_part(p, '-', 3)) AS parent_serial_int;
$$;


--
-- Name: parse_referral_serial(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parse_referral_serial(p_ref text) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT NULLIF(substring(p_ref from '.*([0-9]{9})([^0-9]|$)'), '')::bigint
$_$;


--
-- Name: prevent_cycles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_cycles() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE cur uuid;
BEGIN
  IF NEW.parent_connector_id IS NULL THEN
    RETURN NEW;
  END IF;
  cur := NEW.parent_connector_id;
  WHILE cur IS NOT NULL LOOP
    IF cur = NEW.id THEN
      RAISE EXCEPTION 'Cycle detected: % cannot be ancestor of itself', NEW.id;
    END IF;
    SELECT parent_connector_id INTO cur FROM public.connectors WHERE id = cur;
  END LOOP;
  RETURN NEW;
END;
$$;


--
-- Name: preview_next_connectaid(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.preview_next_connectaid(p_parent uuid, p_child_level text) RETURNS TABLE(parent_tag text, parent_serial integer, child_level text, block_start integer, max_child_serial integer, next_serial_int integer, next_serial_b36 text, next_connectaid_short text, next_connectaid_full_preview text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  par_cid text;
  pt text; pl text; ps int;
  blk int; mx int; nxt int; b36 text;
  cty text; st text;
BEGIN
  SELECT "connectaID", country, state
  INTO par_cid, cty, st
  FROM public.connectors WHERE id = p_parent;

  IF par_cid IS NULL THEN
    RAISE EXCEPTION 'Parent not found or missing connectaID';
  END IF;

  SELECT parent_tag, parent_level, parent_serial_int
  INTO pt, pl, ps
  FROM public.parse_parent_connectaid(par_cid);

  blk := public.child_block_start(ps);

  SELECT MAX(public.base36_decode(split_part(c."connectaID", '-', 3)))
  INTO mx
  FROM public.connectors c
  WHERE c.parent_connector_id = p_parent
    AND c.level = p_child_level;

  SELECT next_serial
  INTO nxt
  FROM public.connector_counters
  WHERE parent_id = p_parent AND child_level = p_child_level;

  nxt := COALESCE(nxt, GREATEST(COALESCE(mx, blk-1)+1, blk));
  b36 := public.format_child_serial_b36(nxt);

  RETURN QUERY
  SELECT
    pt, ps, p_child_level,
    blk,
    mx,
    nxt,
    b36,
    pt || '-' || p_child_level || '-' || b36,
    public.build_region_level_prefix(cty, st, p_child_level) || ' ' ||
      pt || '-' || p_child_level || '-' || b36;
END;
$$;


--
-- Name: record_purchase_and_split(uuid, numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_purchase_and_split(p_buyer_connector_id uuid, p_purchase_amount numeric, p_discount_amount numeric) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_commission_id UUID := gen_random_uuid();
  v_commission_amount NUMERIC := p_discount_amount;
  v_remaining NUMERIC := FLOOR(v_commission_amount / 2); -- for upstream
  v_buyer_points NUMERIC := v_commission_amount - v_remaining;
  v_current_connector UUID := p_buyer_connector_id;
  v_split_level INT := 0;
  v_half NUMERIC;
  v_fraction NUMERIC;
  v_connecta_fraction NUMERIC := 0;
BEGIN
  -- 1. Record purchase commission
  INSERT INTO purchase_commissions (id, buyer_connector_id, purchase_amount, discount_amount, buyer_points)
  VALUES (v_commission_id, p_buyer_connector_id, p_purchase_amount, p_discount_amount, v_buyer_points);

  -- 2. Traverse upstream and split commission
  LOOP
    -- Get parent
    SELECT parent_connector_id INTO v_current_connector
    FROM connectors
    WHERE id = v_current_connector;

    -- Stop if no parent or nothing to split
    EXIT WHEN v_current_connector IS NULL OR v_remaining < 1;

    -- Calculate half
    v_half := v_remaining / 2;
    v_fraction := v_half - FLOOR(v_half);
    v_half := FLOOR(v_half);

    -- Add fraction to CONNECTA
    v_connecta_fraction := v_connecta_fraction + v_fraction;

    -- Save this split
    INSERT INTO commission_splits (
      id, commission_id, recipient_connector_id, amount, split_level
    )
    VALUES (
      gen_random_uuid(), v_commission_id, v_current_connector, v_half, v_split_level
    );

    -- Prepare next level
    v_remaining := v_half;
    v_split_level := v_split_level + 1;
  END LOOP;

  -- Log the CONNECTA portion
  RAISE NOTICE 'Total CONNECTA fraction: %', v_connecta_fraction;

  RETURN v_commission_id;
END;
$$;


--
-- Name: region_tag(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.region_tag(p_country text, p_state text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
  lc_country text := lower(coalesce(p_country, ''));
  lc_state   text := lower(coalesce(p_state, ''));
  cc         text;  -- country 2-letter
  sc         text;  -- state   2-letter ('' for All States)
BEGIN
  -- Country code (common ones explicit, else first 2 letters)
  cc := CASE
          WHEN lc_country IN ('india','in')                     THEN 'IN'
          WHEN lc_country IN ('bangladesh','bd')               THEN 'BD'
          WHEN lc_country IN ('united states','usa','us')      THEN 'US'
          ELSE upper(substring(regexp_replace(coalesce(p_country,''), '[^A-Za-z]', '', 'g') from 1 for 2))
        END;

  -- All States → only country code
  IF lc_state ~ '^\s*$'
     OR lc_state IN ('all states','all state','all-states','allstates') THEN
    sc := '';
  ELSE
    -- State code (Tamil Nadu = TA as per your convention; else first 2 letters)
    IF cc = 'IN' THEN
      sc := CASE
              WHEN lc_state IN ('tamil nadu','tamizh nadu','tamilnadu','tamil-nadu') THEN 'TA'
              ELSE upper(substring(regexp_replace(p_state, '[^A-Za-z]', '', 'g') from 1 for 2))
            END;
    ELSE
      sc := upper(substring(regexp_replace(p_state, '[^A-Za-z]', '', 'g') from 1 for 2));
    END IF;
  END IF;

  RETURN cc || sc;
END;
$_$;


--
-- Name: remaining_child_slots(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remaining_child_slots(p_parent uuid, p_child_level text) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  with current_cnt as (
    select count(*)::int as n
    from public.connectors c
    where c.parent_connector_id = p_parent and c.level = p_child_level
  ),
  allowed as (
    -- TODO: compute from spend rules a/b/c. For now: 999 cap.
    select 999::int as cap
  )
  select greatest( (select cap from allowed) - (select n from current_cnt), 0 );
$$;


--
-- Name: trg_set_global_connecta_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_set_global_connecta_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  parent_ref text;
BEGIN
  -- Look up the parent referral (can be NULL for roots)
  IF NEW.parent_connector_id IS NOT NULL THEN
    SELECT "referralCode" INTO parent_ref
    FROM public.connectors
    WHERE id = NEW.parent_connector_id;
  END IF;

  NEW.global_connecta_id :=
    public.compute_global_connecta_id(NEW."referralCode", parent_ref);

  RETURN NEW;
END
$$;


--
-- Name: upsert_connector_by_mobile_number(text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_connector_by_mobile_number(p_mobile_number text, p_full_name text DEFAULT NULL::text, p_country text DEFAULT NULL::text, p_state text DEFAULT NULL::text, p_language text DEFAULT NULL::text, p_referral_code text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  with norm as (
    select case
      when p_mobile_number is null
        or length(regexp_replace(p_mobile_number, '[^0-9]', '', 'g')) = 0
      then null
      else '+' || regexp_replace(p_mobile_number, '[^0-9]', '', 'g')
    end as mn
  ),
  ins as (
    insert into public.connectors
      ("fullName", mobile_number, country, state, language, "referralCode", connector_type)
    select
      nullif(p_full_name, ''),
      norm.mn,
      p_country, p_state, p_language, nullif(p_referral_code, ''),
      'individual'
    from norm
    where norm.mn is not null
    on conflict (mobile_number) do update
      set "fullName"     = coalesce(nullif(excluded."fullName", ''), connectors."fullName"),
          country        = coalesce(excluded.country,   connectors.country),
          state          = coalesce(excluded.state,     connectors.state),
          language       = coalesce(excluded.language,  connectors.language),
          "referralCode" = coalesce(nullif(excluded."referralCode", ''), connectors."referralCode"),
          updated_at     = now()
    returning id
  )
  select id from ins;
$$;


--
-- Name: validate_aa_prereg_v2(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_aa_prereg_v2(p_mobile text, p_country text, p_state text) RETURNS TABLE(ok boolean, reason text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_mob_norm  text := upper(regexp_replace(coalesce(p_mobile,''),  '[^0-9+]', '', 'g'));
  v_country   text := upper(regexp_replace(coalesce(p_country,''), '[^A-Za-z]', '', 'g'));
  v_state     text := upper(regexp_replace(coalesce(p_state,''),   '[^A-Za-z]', '', 'g'));
  v_count     int;
BEGIN
  -- If state empty: only country must match
  IF coalesce(v_state,'') = '' THEN
    SELECT COUNT(*) INTO v_count
    FROM public.aa_connectors a
    WHERE upper(regexp_replace(coalesce(a.mobile,''), '[^0-9+]', '', 'g')) = v_mob_norm
      AND upper(regexp_replace(coalesce(a."COUNTRY",''), '[^A-Za-z]', '', 'g')) = v_country;

  -- If state present: AA must be ALL/*/NULL or match that state
  ELSE
    SELECT COUNT(*) INTO v_count
    FROM public.aa_connectors a
    WHERE upper(regexp_replace(coalesce(a.mobile,''), '[^0-9+]', '', 'g')) = v_mob_norm
      AND upper(regexp_replace(coalesce(a."COUNTRY",''), '[^A-Za-z]', '', 'g')) = v_country
      AND (
            a."STATE" IS NULL
         OR upper(a."STATE") IN ('ALL','*')
         OR upper(regexp_replace(a."STATE", '[^A-Za-z]', '', 'g')) = v_state
      );
  END IF;

  IF v_count > 0 THEN
    RETURN QUERY SELECT true, NULL::text;
  ELSE
    RETURN QUERY SELECT false, 'NOT_PREREG_OR_REGION_MISMATCH';
  END IF;
END;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_;

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  BEGIN
    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (payload, event, topic, private, extension)
    VALUES (payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: add_prefixes(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.add_prefixes(_bucket_id text, _name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    prefixes text[];
BEGIN
    prefixes := "storage"."get_prefixes"("_name");

    IF array_length(prefixes, 1) > 0 THEN
        INSERT INTO storage.prefixes (name, bucket_id)
        SELECT UNNEST(prefixes) as name, "_bucket_id" ON CONFLICT DO NOTHING;
    END IF;
END;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: delete_prefix(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_prefix(_bucket_id text, _name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if we can delete the prefix
    IF EXISTS(
        SELECT FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name") + 1
          AND "prefixes"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    )
    OR EXISTS(
        SELECT FROM "storage"."objects"
        WHERE "objects"."bucket_id" = "_bucket_id"
          AND "storage"."get_level"("objects"."name") = "storage"."get_level"("_name") + 1
          AND "objects"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    ) THEN
    -- There are sub-objects, skip deletion
    RETURN false;
    ELSE
        DELETE FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name")
          AND "prefixes"."name" = "_name";
        RETURN true;
    END IF;
END;
$$;


--
-- Name: delete_prefix_hierarchy_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_prefix_hierarchy_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    prefix text;
BEGIN
    prefix := "storage"."get_prefix"(OLD."name");

    IF coalesce(prefix, '') != '' THEN
        PERFORM "storage"."delete_prefix"(OLD."bucket_id", prefix);
    END IF;

    RETURN OLD;
END;
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    SELECT _parts[array_length(_parts,1)] INTO _filename;
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_level(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_level(name text) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT array_length(string_to_array("name", '/'), 1);
$$;


--
-- Name: get_prefix(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefix(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT
    CASE WHEN strpos("name", '/') > 0 THEN
             regexp_replace("name", '[\/]{1}[^\/]+\/?$', '')
         ELSE
             ''
        END;
$_$;


--
-- Name: get_prefixes(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefixes(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    parts text[];
    prefixes text[];
    prefix text;
BEGIN
    -- Split the name into parts by '/'
    parts := string_to_array("name", '/');
    prefixes := '{}';

    -- Construct the prefixes, stopping one level below the last part
    FOR i IN 1..array_length(parts, 1) - 1 LOOP
            prefix := array_to_string(parts[1:i], '/');
            prefixes := array_append(prefixes, prefix);
    END LOOP;

    RETURN prefixes;
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(name COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                        substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1)))
                    ELSE
                        name
                END AS name, id, metadata, updated_at
            FROM
                storage.objects
            WHERE
                bucket_id = $5 AND
                name ILIKE $1 || ''%'' AND
                CASE
                    WHEN $6 != '''' THEN
                    name COLLATE "C" > $6
                ELSE true END
                AND CASE
                    WHEN $4 != '''' THEN
                        CASE
                            WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                                substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                name COLLATE "C" > $4
                            END
                    ELSE
                        true
                END
            ORDER BY
                name COLLATE "C" ASC) as e order by name COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_token, bucket_id, start_after;
END;
$_$;


--
-- Name: objects_insert_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_insert_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    NEW.level := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


--
-- Name: objects_update_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_update_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    old_prefixes TEXT[];
BEGIN
    -- Ensure this is an update operation and the name has changed
    IF TG_OP = 'UPDATE' AND (NEW."name" <> OLD."name" OR NEW."bucket_id" <> OLD."bucket_id") THEN
        -- Retrieve old prefixes
        old_prefixes := "storage"."get_prefixes"(OLD."name");

        -- Remove old prefixes that are only used by this object
        WITH all_prefixes as (
            SELECT unnest(old_prefixes) as prefix
        ),
        can_delete_prefixes as (
             SELECT prefix
             FROM all_prefixes
             WHERE NOT EXISTS (
                 SELECT 1 FROM "storage"."objects"
                 WHERE "bucket_id" = OLD."bucket_id"
                   AND "name" <> OLD."name"
                   AND "name" LIKE (prefix || '%')
             )
         )
        DELETE FROM "storage"."prefixes" WHERE name IN (SELECT prefix FROM can_delete_prefixes);

        -- Add new prefixes
        PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    END IF;
    -- Set the new level
    NEW."level" := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: prefixes_insert_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.prefixes_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    RETURN NEW;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql
    AS $$
declare
    can_bypass_rls BOOLEAN;
begin
    SELECT rolbypassrls
    INTO can_bypass_rls
    FROM pg_roles
    WHERE rolname = coalesce(nullif(current_setting('role', true), 'none'), current_user);

    IF can_bypass_rls THEN
        RETURN QUERY SELECT * FROM storage.search_v1_optimised(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    ELSE
        RETURN QUERY SELECT * FROM storage.search_legacy_v1(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    END IF;
end;
$$;


--
-- Name: search_legacy_v1(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_legacy_v1(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select path_tokens[$1] as folder
           from storage.objects
             where objects.name ilike $2 || $3 || ''%''
               and bucket_id = $4
               and array_length(objects.path_tokens, 1) <> $1
           group by folder
           order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v1_optimised(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v1_optimised(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select (string_to_array(name, ''/''))[level] as name
           from storage.prefixes
             where lower(prefixes.name) like lower($2 || $3) || ''%''
               and bucket_id = $4
               and level = $1
           order by name ' || v_sort_order || '
     )
     (select name,
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[level] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where lower(objects.name) like lower($2 || $3) || ''%''
       and bucket_id = $4
       and level = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN
    RETURN query EXECUTE
        $sql$
        SELECT * FROM (
            (
                SELECT
                    split_part(name, '/', $4) AS key,
                    name || '/' AS name,
                    NULL::uuid AS id,
                    NULL::timestamptz AS updated_at,
                    NULL::timestamptz AS created_at,
                    NULL::jsonb AS metadata
                FROM storage.prefixes
                WHERE name COLLATE "C" LIKE $1 || '%'
                AND bucket_id = $2
                AND level = $4
                AND name COLLATE "C" > $5
                ORDER BY prefixes.name COLLATE "C" LIMIT $3
            )
            UNION ALL
            (SELECT split_part(name, '/', $4) AS key,
                name,
                id,
                updated_at,
                created_at,
                metadata
            FROM storage.objects
            WHERE name COLLATE "C" LIKE $1 || '%'
                AND bucket_id = $2
                AND level = $4
                AND name COLLATE "C" > $5
            ORDER BY name COLLATE "C" LIMIT $3)
        ) obj
        ORDER BY name COLLATE "C" LIMIT $3;
        $sql$
        USING prefix, bucket_name, limits, levels, start_after;
END;
$_$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: aa_connectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aa_connectors (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    mobile text NOT NULL,
    "COUNTRY" text,
    "STATE" text,
    "LANGUAGE" text,
    aa_joining_code text
);


--
-- Name: aa_connectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.aa_connectors ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.aa_connectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: commission_splits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commission_splits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    commission_id uuid,
    recipient_connector_id uuid,
    amount numeric NOT NULL,
    split_level character(2) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    buyer_connector_id uuid,
    purchase_amount numeric NOT NULL,
    discount_amount numeric NOT NULL,
    commission_amount numeric NOT NULL,
    commission_date timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: connecta_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connecta_global_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connector_counters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_counters (
    parent_id uuid NOT NULL,
    child_level text NOT NULL,
    next_serial integer NOT NULL,
    CONSTRAINT connector_counters_child_level_check CHECK ((child_level ~ '^[A-Z]{2}$'::text))
);


--
-- Name: connector_prospects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_prospects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inviter_referral_code text NOT NULL,
    name text,
    phone_e164 text,
    joined boolean DEFAULT false NOT NULL,
    status text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: connectors_connectaid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connectors_connectaid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connectors_connectaid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connectors_connectaid_seq OWNED BY public.connectors."connectaID";


--
-- Name: connectors_public; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.connectors_public AS
 SELECT id,
    country,
    state,
    city,
    level,
    connector_type,
    "referralCode",
    "connectaID",
        CASE
            WHEN (length(mobile_number) >= 4) THEN ('******'::text || "right"(mobile_number, 4))
            ELSE '******'::text
        END AS mobile_masked,
    created_at,
    "createdAt"
   FROM public.connectors;


--
-- Name: connectors_std; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.connectors_std AS
 SELECT id AS connector_id,
    "connectaID" AS connecta_id,
    "connectaID_full" AS level_pair,
    "referralCode" AS referral_code,
    mobile_number,
    "recoveryMobile",
    country,
    state,
    level,
    level_sequence,
    parent_connector_id,
    created_at,
    updated_at
   FROM public.connectors;


--
-- Name: country_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.country_codes (
    country text NOT NULL,
    code2 text NOT NULL,
    CONSTRAINT country_codes_code2_check CHECK ((char_length(code2) = 2))
);


--
-- Name: country_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.country_states (
    country text NOT NULL,
    states jsonb,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    country_iso2 text,
    country_norm text,
    emoji_flag text
);


--
-- Name: id_counters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.id_counters (
    scope text NOT NULL,
    last_value bigint DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: iso_country_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.iso_country_overrides (
    country_norm text NOT NULL,
    iso2 text NOT NULL,
    CONSTRAINT iso_country_overrides_iso2_check CHECK ((iso2 ~ '^[A-Z]{2}$'::text))
);


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    label text NOT NULL,
    script text,
    enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    label_native text,
    display_name text,
    emoji_flag text,
    country_code text
);


--
-- Name: meeting_attendance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meeting_attendance (
    meeting_id uuid NOT NULL,
    attendee_connector_id uuid NOT NULL,
    joined_at timestamp with time zone,
    left_at timestamp with time zone
);


--
-- Name: meetings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meetings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organizer_connector_id uuid NOT NULL,
    title text NOT NULL,
    scheduled_at timestamp with time zone NOT NULL,
    link text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pending_classifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pending_classifications (
    id bigint NOT NULL,
    name text NOT NULL,
    suggested_by_connector_id uuid,
    country text,
    state text,
    variant text,
    status text DEFAULT 'pending'::text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: pending_classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pending_classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pending_classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pending_classifications_id_seq OWNED BY public.pending_classifications.id;


--
-- Name: pincode_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pincode_rules (
    country text NOT NULL,
    pattern text,
    type text,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    connector_id uuid,
    serial_no integer,
    image_url text,
    description text,
    mrp numeric,
    discount_percent numeric,
    price numeric,
    youtube_video_url text,
    availability boolean,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT products_serial_no_check CHECK (((serial_no >= 1) AND (serial_no <= 50)))
);


--
-- Name: purchase_commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_commissions (
    id uuid NOT NULL,
    buyer_connector_id uuid NOT NULL,
    purchase_amount numeric NOT NULL,
    discount_amount numeric NOT NULL,
    buyer_points integer NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now())
);


--
-- Name: state_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.state_codes (
    country text NOT NULL,
    state text NOT NULL,
    code2 text NOT NULL,
    CONSTRAINT state_codes_code2_check CHECK ((char_length(code2) = 2))
);


--
-- Name: translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    translations jsonb NOT NULL,
    created_at timestamp without time zone,
    language_code text NOT NULL,
    base_translations jsonb,
    keys jsonb,
    language_iso_code text,
    label_native text,
    display_name text,
    emoji_flag text
);


--
-- Name: TABLE translations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.translations IS 'ALL LANGUAGES';


--
-- Name: translations_backup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translations_backup (
    id uuid,
    translations jsonb,
    created_at timestamp without time zone,
    language_code text
);


--
-- Name: translations_backup_27july; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translations_backup_27july (
    id uuid,
    translations jsonb,
    created_at timestamp without time zone,
    language_code text,
    base_translations jsonb,
    keys jsonb,
    language_iso_code text
);


--
-- Name: v_connectors_active; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_connectors_active AS
 SELECT id,
    mobile_number,
    alternate_mobile,
    gst_number,
    company_name,
    classification,
    city,
    state,
    pincode,
    email,
    upi_id,
    homepage_image_url,
    video_url,
    website_url,
    facebook_url,
    instagram_url,
    youtube_shorts_url,
    youtube_url,
    other_links,
    google_map_link,
    parent_connector_id,
    level,
    level_sequence,
    connector_type,
    created_at,
    updated_at,
    "addressLine1",
    "addressLine2",
    "addressLine3",
    "connectaID",
    country,
    "fullName",
    language,
    profession,
    "recoveryMobile",
    "referralCode",
    "createdAt",
    "connectaID_full",
    path_ids,
    shortname,
    payload_json,
    joined_at,
    subscription_expires_at,
    subscription_status,
    last_notified_at,
    business_variant,
    short_name,
    is_active,
    archived_at
   FROM public.connectors
  WHERE (is_active = true);


--
-- Name: v_connectors_unified; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_connectors_unified AS
 SELECT id,
    "connectaID" AS connecta_id,
    "referralCode" AS referral_code,
    country,
    state,
    connector_type,
    business_variant,
    COALESCE(NULLIF(TRIM(BOTH FROM "fullName"), ''::text), NULLIF(TRIM(BOTH FROM short_name), ''::text)) AS display_name,
    "fullName" AS full_name,
    short_name,
    created_at,
    NULL::jsonb AS extra
   FROM public.connectors;


--
-- Name: view_commission_distribution; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_commission_distribution AS
 SELECT cs.commission_id,
    (cs.split_level)::integer AS split_level,
    c.company_name AS recipient_name,
    cs.amount,
    cs.created_at
   FROM (public.commission_splits cs
     JOIN public.connectors c ON ((cs.recipient_connector_id = c.id)))
  ORDER BY cs.commission_id, (cs.split_level)::integer;


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb,
    level integer
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: prefixes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.prefixes (
    bucket_id text NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    level integer GENERATED ALWAYS AS (storage.get_level(name)) STORED NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: connectors connectaID; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connectors ALTER COLUMN "connectaID" SET DEFAULT (nextval('public.connectors_connectaid_seq'::regclass))::text;


--
-- Name: pending_classifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_classifications ALTER COLUMN id SET DEFAULT nextval('public.pending_classifications_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag) FROM stdin;
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
\.


--
-- Data for Name: aa_connectors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.aa_connectors (id, created_at, mobile, "COUNTRY", "STATE", "LANGUAGE", aa_joining_code) FROM stdin;
163	2025-08-19 23:56:56.333392+00	+917400742800	India	Tamil Nadu	Tamil	India_Tamilnadu_M253540
164	2025-08-26 13:21:24.731723+00	+917054625462	India	Tamil Nadu	Tamil	India_Tamilnadu_M253540
\.


--
-- Data for Name: commission_splits; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.commission_splits (id, commission_id, recipient_connector_id, amount, split_level, created_at) FROM stdin;
\.


--
-- Data for Name: commissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.commissions (id, buyer_connector_id, purchase_amount, discount_amount, commission_amount, commission_date, created_at) FROM stdin;
\.


--
-- Data for Name: connector_counters; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.connector_counters (parent_id, child_level, next_serial) FROM stdin;
823974a6-2410-48d9-80e7-ddf10b4394f1	AM	7
823974a6-2410-48d9-80e7-ddf10b4394f1	AL	6
0e63fbd6-0261-4bb2-ad84-f67628cf9895	AH	1
ab99dfd3-571e-414c-911b-d979f9698620	AA	1
823974a6-2410-48d9-80e7-ddf10b4394f1	AJ	4
823974a6-2410-48d9-80e7-ddf10b4394f1	AK	5
b03c130b-b19d-40a5-ade1-8084e58dfa76	AD	3
00000000-0000-0000-0000-0000000000b1	AC	1
61338156-3b0a-4c16-95d1-48ec7bd6c7b6	AB	1
fdff03e7-4555-45a1-9932-80f98e0022f7	AC	2
96a66ffe-3ab6-4421-b428-a518da454b7b	AE	2
00000000-0000-0000-0000-0000000000a1	AB	1
d468998e-8106-492a-8326-22540aeb768c	AB	38000
7e5c63b5-febb-4880-9c0d-a7c3384731c1	AE	46658
\.


--
-- Data for Name: connector_prospects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.connector_prospects (id, inviter_referral_code, name, phone_e164, joined, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: connectors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.connectors (id, mobile_number, alternate_mobile, gst_number, company_name, classification, city, state, pincode, email, upi_id, homepage_image_url, video_url, website_url, facebook_url, instagram_url, youtube_shorts_url, youtube_url, other_links, google_map_link, parent_connector_id, level, level_sequence, connector_type, created_at, updated_at, "addressLine1", "addressLine2", "addressLine3", "connectaID", country, "fullName", language, profession, "recoveryMobile", "referralCode", "createdAt", "connectaID_full", path_ids, shortname, payload_json, joined_at, subscription_expires_at, subscription_status, last_notified_at, business_variant, short_name, is_active, archived_at, global_connecta_id) FROM stdin;
\.


--
-- Data for Name: country_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.country_codes (country, code2) FROM stdin;
India	IN
Bangladesh	BD
\.


--
-- Data for Name: country_states; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.country_states (country, states, id, country_iso2, country_norm, emoji_flag) FROM stdin;
American Samoa	[{"name": "Eastern", "active": true}, {"name": "Manu'a", "active": true}, {"name": "Rose Island", "active": true}, {"name": "Swains Island", "active": true}, {"name": "Western", "active": true}]	ab78b155-ef88-4a15-a510-f4ba2f3dbfca	AM	 merican amoa	🇦🇲
Kiribati	[{"name": "Gilbert Islands", "active": true}, {"name": "Line Islands", "active": true}, {"name": "Phoenix Islands", "active": true}]	519d36bb-50eb-47f0-88b8-1a889a43878d	KI	 iribati	🇰🇮
Anguilla	[{"name": "Anguilla", "active": true}]	ebe719af-2f40-4880-a180-ad12e2264fce	AN	 nguilla	🇦🇳
Luxembourg	[{"name": "Diekirch", "active": true}, {"name": "Grevenmacher", "active": true}, {"name": "Luxembourg", "active": true}]	d0fc95b6-a81a-4e06-9014-0860051bfcc5	LU	 uxembourg	🇱🇺
Martinique	[{"name": "Martinique", "active": true}]	90001160-9845-4a45-b470-5a809b69a65b	MA	 artinique	🇲🇦
Grenada	[{"name": "Saint Andrew", "active": true}, {"name": "Saint David", "active": true}, {"name": "Saint George", "active": true}, {"name": "Saint John", "active": true}, {"name": "Saint Mark", "active": true}, {"name": "Saint Patrick", "active": true}]	eadf640a-5738-4593-853a-7bb7852511e0	GR	 renada	🇬🇷
Guinea	[{"name": "Boké", "active": true}, {"name": "Conakry", "active": true}, {"name": "Faranah", "active": true}, {"name": "Kankan", "active": true}, {"name": "Kindia", "active": true}, {"name": "Labé", "active": true}, {"name": "Mamou", "active": true}, {"name": "Nzérékoré", "active": true}]	18e12056-2869-46b5-86f5-ee95e96cc0b9	GU	 uinea	🇬🇺
Japan	[{"name": "Aichi", "active": true}, {"name": "Akita", "active": true}, {"name": "Aomori", "active": true}, {"name": "Chiba", "active": true}, {"name": "Ehime", "active": true}, {"name": "Fukui", "active": true}, {"name": "Fukuoka", "active": true}, {"name": "Fukushima", "active": true}, {"name": "Gifu", "active": true}, {"name": "Gunma", "active": true}, {"name": "Hiroshima", "active": true}, {"name": "Hokkaido", "active": true}, {"name": "Hyogo", "active": true}, {"name": "Ibaraki", "active": true}, {"name": "Ishikawa", "active": true}, {"name": "Iwate", "active": true}, {"name": "Kagawa", "active": true}, {"name": "Kagoshima", "active": true}, {"name": "Kanagawa", "active": true}, {"name": "Kochi", "active": true}, {"name": "Kumamoto", "active": true}, {"name": "Kyoto", "active": true}, {"name": "Mie", "active": true}, {"name": "Miyagi", "active": true}, {"name": "Miyazaki", "active": true}, {"name": "Nagano", "active": true}, {"name": "Nagasaki", "active": true}, {"name": "Nara", "active": true}, {"name": "Niigata", "active": true}, {"name": "Oita", "active": true}, {"name": "Okayama", "active": true}, {"name": "Okinawa", "active": true}, {"name": "Osaka", "active": true}, {"name": "Saga", "active": true}, {"name": "Saitama", "active": true}, {"name": "Shiga", "active": true}, {"name": "Shimane", "active": true}, {"name": "Shizuoka", "active": true}, {"name": "Tochigi", "active": true}, {"name": "Tokushima", "active": true}, {"name": "Tokyo", "active": true}, {"name": "Tottori", "active": true}, {"name": "Toyama", "active": true}, {"name": "Wakayama", "active": true}, {"name": "Yamagata", "active": true}, {"name": "Yamaguchi", "active": true}, {"name": "Yamanashi", "active": true}]	6565fbfb-ea26-4691-a8ee-9afa4ce388c7	JA	 apan	🇯🇦
Bosnia and Herzegovina	[{"name": "Brčko District", "active": true}, {"name": "Federation of Bosnia and Herzegovina", "active": true}, {"name": "Republika Srpska", "active": true}]	16e3704e-6c3e-4b9f-996c-27bc4e95b993	BO	 osnia and erzegovina	🇧🇴
Réunion	[{"name": "Saint-Denis", "active": true}, {"name": "Saint-Paul", "active": true}, {"name": "Saint-Pierre", "active": true}, {"name": "Le Tampon", "active": true}, {"name": "Saint-André", "active": true}, {"name": "Saint-Benoît", "active": true}, {"name": "Saint-Louis", "active": true}, {"name": "Sainte-Marie", "active": true}, {"name": "Cilaos", "active": true}, {"name": "Saint-Leu", "active": true}]	62ce560e-2374-4c58-acc2-4ea76e00d591	RU	 eunion	🇷🇺
British Virgin Islands	[{"name": "Anegada", "active": true}, {"name": "Jost Van Dyke", "active": true}, {"name": "Tortola", "active": true}]	8c35e055-c0f4-4a63-8c0a-1170db5f4bab	BR	 ritish irgin slands	🇧🇷
Sint Maarten	[{"name": "Sint Maarten", "active": true}]	6e14b77c-17e7-4f9b-a19c-fd1c6ba9ad87	SI	 int aarten	🇸🇮
Andorra	[{"name": "Canillo", "active": true}, {"name": "Encamp", "active": true}, {"name": "Ordino", "active": true}, {"name": "La Massana", "active": true}, {"name": "Andorra la Vella", "active": true}, {"name": "Sant Julià de Lòria", "active": true}, {"name": "Escaldes-Engordany", "active": true}]	bac7834d-3ddd-4460-b181-49938093ab18	AN	 ndorra	🇦🇳
Caribbean Netherlands	[{"name": "Bonaire", "active": true}, {"name": "Saba", "active": true}, {"name": "Sint Eustatius", "active": true}]	c10497e2-fee3-4d9c-9f58-267331f68552	CA	 aribbean etherlands	🇨🇦
Curaçao	[{"name": "Curaçao", "active": true}]	279abeb7-dcb3-48d3-b863-016284f5cbf2	CU	 uracao	🇨🇺
Sao Tome and Principe	[{"name": "Água Grande", "active": true}, {"name": "Cantagalo", "active": true}, {"name": "Caué", "active": true}, {"name": "Lemba", "active": true}, {"name": "Lobata", "active": true}, {"name": "Mé-Zóchi", "active": true}, {"name": "Príncipe", "active": true}]	6a7f3ae5-8b14-4256-ab6a-31f45a03b1d2	SA	 ao ome and rincipe	🇸🇦
French Guiana	[{"name": "French Guiana", "active": true}]	2012eccd-2632-444a-8ab9-76935ac1a8a7	FR	 rench uiana	🇫🇷
Djibouti	[{"name": "Ali Sabieh", "active": true}, {"name": "Arta", "active": true}, {"name": "Dikhil", "active": true}, {"name": "Djibouti", "active": true}, {"name": "Obock", "active": true}, {"name": "Tadjourah", "active": true}]	f9f086f2-ccd4-4795-bb5e-f72ef76a57d1	DJ	 jibouti	🇩🇯
State of Palestine	[{"name": "Gaza Strip", "active": true}, {"name": "West Bank", "active": true}]	d68c0e5f-bd21-405b-8411-20abc7d56ec4	ST	 tate of alestine	🇸🇹
Tokelau	[{"name": "Atafu", "active": true}, {"name": "Nukunonu", "active": true}, {"name": "Fakaofo", "active": true}]	d14f0c0f-518f-449b-9a60-4859ccc04f7a	TO	 okelau	🇹🇴
Afghanistan	[{"name": "Badakhshan", "active": true}, {"name": "Badghis", "active": true}, {"name": "Baghlan", "active": true}, {"name": "Balkh", "active": true}, {"name": "Bamyan", "active": true}, {"name": "Daykundi", "active": true}, {"name": "Farah", "active": true}, {"name": "Faryab", "active": true}, {"name": "Ghazni", "active": true}, {"name": "Ghor", "active": true}, {"name": "Helmand", "active": true}, {"name": "Herat", "active": true}, {"name": "Jowzjan", "active": true}, {"name": "Kabul", "active": true}, {"name": "Kandahar", "active": true}, {"name": "Khost", "active": true}, {"name": "Kunar", "active": true}, {"name": "Laghman", "active": true}, {"name": "Logar", "active": true}, {"name": "Nangarhar", "active": true}, {"name": "Nimroz", "active": true}, {"name": "Nuristan", "active": true}, {"name": "Paktia", "active": true}, {"name": "Paktika", "active": true}, {"name": "Panjshir", "active": true}, {"name": "Parwan", "active": true}, {"name": "Samangan", "active": true}, {"name": "Sar-e Pol", "active": true}, {"name": "Takhar", "active": true}, {"name": "Urozgan", "active": true}, {"name": "Wardak", "active": true}, {"name": "Zabul", "active": true}]	da59600b-d71a-45f0-8fe4-f0180a53fa11	AF	 fghanistan	🇦🇫
Albania	[{"name": "Berat", "active": true}, {"name": "Dibër", "active": true}, {"name": "Durrës", "active": true}, {"name": "Elbasan", "active": true}, {"name": "Fier", "active": true}, {"name": "Gjirokastër", "active": true}, {"name": "Korçë", "active": true}, {"name": "Kukës", "active": true}, {"name": "Lezhë", "active": true}, {"name": "Shkodër", "active": true}, {"name": "Tiranë", "active": true}, {"name": "Vlorë", "active": true}]	348334f2-9e2e-4558-b962-f3487978d401	AL	 lbania	🇦🇱
Jamaica	[{"name": "Clarendon", "active": true}, {"name": "Hanover", "active": true}, {"name": "Kingston", "active": true}, {"name": "Manchester", "active": true}, {"name": "Portland", "active": true}, {"name": "Saint Andrew", "active": true}, {"name": "Saint Ann", "active": true}, {"name": "Saint Catherine", "active": true}, {"name": "Saint Elizabeth", "active": true}, {"name": "Saint James", "active": true}, {"name": "Saint Mary", "active": true}, {"name": "Saint Thomas", "active": true}, {"name": "Trelawny", "active": true}, {"name": "Westmoreland", "active": true}]	c0b83cdb-df5e-4291-951d-54b893c6d915	JA	 amaica	🇯🇦
Algeria	[{"name": "Adrar", "active": true}, {"name": "Chlef", "active": true}, {"name": "Laghouat", "active": true}, {"name": "Oum El Bouaghi", "active": true}, {"name": "Batna", "active": true}, {"name": "Béjaïa", "active": true}, {"name": "Biskra", "active": true}, {"name": "Béchar", "active": true}, {"name": "Blida", "active": true}, {"name": "Bouira", "active": true}, {"name": "Tamanrasset", "active": true}, {"name": "Tébessa", "active": true}, {"name": "Tlemcen", "active": true}, {"name": "Tiaret", "active": true}, {"name": "Tizi Ouzou", "active": true}, {"name": "Algiers", "active": true}, {"name": "Djelfa", "active": true}, {"name": "Jijel", "active": true}, {"name": "Sétif", "active": true}, {"name": "Saïda", "active": true}, {"name": "Skikda", "active": true}, {"name": "Sidi Bel Abbès", "active": true}, {"name": "Annaba", "active": true}, {"name": "Guelma", "active": true}, {"name": "Constantine", "active": true}, {"name": "Médéa", "active": true}, {"name": "Mostaganem", "active": true}, {"name": "M'Sila", "active": true}, {"name": "Mascara", "active": true}, {"name": "Ouargla", "active": true}, {"name": "Oran", "active": true}, {"name": "El Bayadh", "active": true}, {"name": "Illizi", "active": true}, {"name": "Bordj Bou Arréridj", "active": true}, {"name": "Boumerdès", "active": true}, {"name": "El Tarf", "active": true}, {"name": "Tindouf", "active": true}, {"name": "Tissemsilt", "active": true}, {"name": "El Oued", "active": true}, {"name": "Khenchela", "active": true}, {"name": "Souk Ahras", "active": true}, {"name": "Tipaza", "active": true}, {"name": "Mila", "active": true}, {"name": "Aïn Defla", "active": true}, {"name": "Naâma", "active": true}, {"name": "Aïn Témouchent", "active": true}, {"name": "Ghardaïa", "active": true}, {"name": "Relizane", "active": true}]	1ea3b033-2568-47c1-bd75-768a40f8d2fd	AL	 lgeria	🇦🇱
Macao	[{"name": "Macau", "active": true}]	dc62a856-eae5-48da-937c-4141eafb1810	MA	 acao	🇲🇦
Aruba	[{"name": "Aruba", "active": true}]	8d810114-6466-42d9-a440-0de70abec2dc	AR	 ruba	🇦🇷
Monaco	[{"name": "Monaco", "active": true}]	ced1c9b6-6b4f-4b55-b257-e62a0b055ae8	MO	 onaco	🇲🇴
Niue	[{"name": "Niue", "active": true}]	a1e39c73-4b65-41d1-b2c4-27e375fe0a6d	NI	 iue	🇳🇮
Rwanda	[{"name": "Kigali City", "active": true}, {"name": "Eastern Province", "active": true}, {"name": "Kigali", "active": true}, {"name": "Northern Province", "active": true}, {"name": "Western Province", "active": true}, {"name": "Southern Province", "active": true}]	54050424-a508-445d-ba71-a6fee71285b4	RW	 wanda	🇷🇼
Comoros	[{"name": "Anjouan", "active": true}, {"name": "Grande Comore", "active": true}, {"name": "Mohéli", "active": true}]	a6addb97-53a5-4626-9358-56b8b5bbfab6	CO	 omoros	🇨🇴
Gibraltar	[{"name": "Gibraltar", "active": true}]	c4abef86-7124-4406-a188-a76cdfc637c0	GI	 ibraltar	🇬🇮
Tajikistan	[{"name": "Districts of Republican Subordination", "active": true}, {"name": "Gorno-Badakhshan Autonomous Region", "active": true}, {"name": "Khatlon Region", "active": true}, {"name": "Sughd Region", "active": true}]	d0817d0b-517d-494f-87d9-1e4abc26f7b5	TA	 ajikistan	🇹🇦
Togo	[{"name": "Centrale", "active": true}, {"name": "Kara", "active": true}, {"name": "Maritime", "active": true}, {"name": "Plateaux", "active": true}, {"name": "Savanes", "active": true}]	534e4c66-c7c3-410f-a735-202d8fb9885a	TO	 ogo	🇹🇴
Turkmenistan	[{"name": "Ahal", "active": true}, {"name": "Balkan", "active": true}, {"name": "Dashoguz", "active": true}, {"name": "Lebap", "active": true}, {"name": "Mary", "active": true}]	64314647-26b4-4779-9419-32c41adcec24	TU	 urkmenistan	🇹🇺
Tuvalu	[{"name": "Funafuti", "active": true}, {"name": "Nanumanga", "active": true}, {"name": "Nanumea", "active": true}, {"name": "Niutao", "active": true}, {"name": "Nui", "active": true}, {"name": "Vaitupu", "active": true}]	40f743c8-fe73-49fe-8992-b70ae19b5c9d	TU	 uvalu	🇹🇺
Uruguay	[{"name": "Artigas", "active": true}, {"name": "Canelones", "active": true}, {"name": "Cerro Largo", "active": true}, {"name": "Colonia", "active": true}, {"name": "Durazno", "active": true}, {"name": "Flores", "active": true}, {"name": "Florida", "active": true}, {"name": "Lavalleja", "active": true}, {"name": "Maldonado", "active": true}, {"name": "Montevideo", "active": true}, {"name": "Paysandú", "active": true}, {"name": "Río Negro", "active": true}, {"name": "Rivera", "active": true}, {"name": "Rocha", "active": true}, {"name": "Salto", "active": true}, {"name": "San José", "active": true}, {"name": "Soriano", "active": true}, {"name": "Tacuarembó", "active": true}, {"name": "Treinta y Tres", "active": true}]	95bfff10-7429-4f8f-a52a-e50c51ccb2ca	UR	 ruguay	🇺🇷
Vanuatu	[{"name": "Malampa", "active": true}, {"name": "Penama", "active": true}, {"name": "Sanma", "active": true}, {"name": "Shefa", "active": true}, {"name": "Tafea", "active": true}, {"name": "Torba", "active": true}]	8f740058-8b60-447b-b585-49e0d710702b	VA	 anuatu	🇻🇦
Vietnam	[{"name": "An Giang", "active": true}, {"name": "Bà Rịa–Vũng Tàu", "active": true}, {"name": "Bắc Giang", "active": true}, {"name": "Bắc Kạn", "active": true}, {"name": "Bạc Liêu", "active": true}, {"name": "Bắc Ninh", "active": true}, {"name": "Bến Tre", "active": true}, {"name": "Bình Định", "active": true}, {"name": "Bình Dương", "active": true}, {"name": "Bình Phước", "active": true}, {"name": "Bình Thuận", "active": true}, {"name": "Cà Mau", "active": true}, {"name": "Cần Thơ", "active": true}, {"name": "Cao Bằng", "active": true}, {"name": "Đắk Lắk", "active": true}, {"name": "Đắk Nông", "active": true}, {"name": "Điện Biên", "active": true}, {"name": "Đồng Nai", "active": true}, {"name": "Đồng Tháp", "active": true}, {"name": "Gia Lai", "active": true}, {"name": "Hà Giang", "active": true}, {"name": "Hà Nam", "active": true}, {"name": "Hà Tĩnh", "active": true}, {"name": "Hải Dương", "active": true}, {"name": "Hải Phòng", "active": true}, {"name": "Hậu Giang", "active": true}, {"name": "Hòa Bình", "active": true}, {"name": "Hưng Yên", "active": true}, {"name": "Khánh Hòa", "active": true}, {"name": "Kiên Giang", "active": true}, {"name": "Kon Tum", "active": true}, {"name": "Lai Châu", "active": true}, {"name": "Lâm Đồng", "active": true}, {"name": "Lạng Sơn", "active": true}, {"name": "Lào Cai", "active": true}, {"name": "Long An", "active": true}, {"name": "Nam Định", "active": true}, {"name": "Nghệ An", "active": true}, {"name": "Ninh Bình", "active": true}, {"name": "Ninh Thuận", "active": true}, {"name": "Phú Thọ", "active": true}, {"name": "Phú Yên", "active": true}, {"name": "Quảng Bình", "active": true}, {"name": "Quảng Nam", "active": true}, {"name": "Quảng Ngãi", "active": true}, {"name": "Quảng Ninh", "active": true}, {"name": "Quảng Trị", "active": true}, {"name": "Sóc Trăng", "active": true}, {"name": "Sơn La", "active": true}, {"name": "Tây Ninh", "active": true}, {"name": "Thái Bình", "active": true}, {"name": "Thái Nguyên", "active": true}, {"name": "Thanh Hóa", "active": true}, {"name": "Thừa Thiên–Huế", "active": true}, {"name": "Tiền Giang", "active": true}, {"name": "Trà Vinh", "active": true}, {"name": "Tuyên Quang", "active": true}, {"name": "Vĩnh Long", "active": true}, {"name": "Vĩnh Phúc", "active": true}, {"name": "Yên Bái", "active": true}, {"name": "Hanoi", "active": true}, {"name": "Ho Chi Minh City", "active": true}]	b359f329-223b-4d13-9840-39adaf667d7a	VI	 ietnam	🇻🇮
Jordan	[{"name": "Ajloun", "active": true}, {"name": "Amman", "active": true}, {"name": "Aqaba", "active": true}, {"name": "Balqa", "active": true}, {"name": "Irbid", "active": true}, {"name": "Jerash", "active": true}, {"name": "Karak", "active": true}, {"name": "Ma'an", "active": true}, {"name": "Madaba", "active": true}, {"name": "Mafraq", "active": true}, {"name": "Tafilah", "active": true}, {"name": "Zarqa", "active": true}]	b0cea534-465c-4958-81fa-4e2aad2d7207	JO	 ordan	🇯🇴
Kazakhstan	[{"name": "Almaty", "active": true}, {"name": "Aqmola", "active": true}, {"name": "Atyrau", "active": true}, {"name": "East Kazakhstan", "active": true}, {"name": "Jambyl", "active": true}, {"name": "Karaganda", "active": true}, {"name": "Kostanay", "active": true}, {"name": "Kyzylorda", "active": true}, {"name": "Mangystau", "active": true}, {"name": "North Kazakhstan", "active": true}, {"name": "Pavlodar", "active": true}, {"name": "Turkistan", "active": true}, {"name": "West Kazakhstan", "active": true}, {"name": "Zhambyl", "active": true}]	8c69ba5d-92c7-44e8-affe-312184ea8d53	KA	 azakhstan	🇰🇦
Angola	[{"name": "Bengo", "active": true}, {"name": "Benguela", "active": true}, {"name": "Bié", "active": true}, {"name": "Cabinda", "active": true}, {"name": "Cuando Cubango", "active": true}, {"name": "Cuanza Norte", "active": true}, {"name": "Cuanza Sul", "active": true}, {"name": "Cunene", "active": true}, {"name": "Huambo", "active": true}, {"name": "Huíla", "active": true}, {"name": "Luanda", "active": true}, {"name": "Lunda Norte", "active": true}, {"name": "Lunda Sul", "active": true}, {"name": "Malanje", "active": true}, {"name": "Moxico", "active": true}, {"name": "Namibe", "active": true}, {"name": "Uíge", "active": true}, {"name": "Zaire", "active": true}]	a37bbac6-b589-48ec-9977-4ffe06e99988	AN	 ngola	🇦🇳
Kenya	[{"name": "Baringo", "active": true}, {"name": "Bomet", "active": true}, {"name": "Bungoma", "active": true}, {"name": "Busia", "active": true}, {"name": "Elgeyo-Marakwet", "active": true}, {"name": "Embu", "active": true}, {"name": "Garissa", "active": true}, {"name": "Homa Bay", "active": true}, {"name": "Isiolo", "active": true}, {"name": "Kajiado", "active": true}, {"name": "Kakamega", "active": true}, {"name": "Kericho", "active": true}, {"name": "Kiambu", "active": true}, {"name": "Kilifi", "active": true}, {"name": "Kirinyaga", "active": true}, {"name": "Kisii", "active": true}, {"name": "Kisumu", "active": true}, {"name": "Kitui", "active": true}, {"name": "Kwale", "active": true}, {"name": "Laikipia", "active": true}, {"name": "Lamu", "active": true}, {"name": "Machakos", "active": true}, {"name": "Makueni", "active": true}, {"name": "Mandera", "active": true}, {"name": "Marsabit", "active": true}, {"name": "Meru", "active": true}, {"name": "Migori", "active": true}, {"name": "Mombasa", "active": true}, {"name": "Murang'a", "active": true}, {"name": "Nairobi City", "active": true}, {"name": "Nakuru", "active": true}, {"name": "Nandi", "active": true}, {"name": "Narok", "active": true}, {"name": "Nyamira", "active": true}, {"name": "Nyandarua", "active": true}, {"name": "Nyeri", "active": true}, {"name": "Samburu", "active": true}, {"name": "Siaya", "active": true}, {"name": "Taita-Taveta", "active": true}, {"name": "Tana River", "active": true}, {"name": "Tharaka-Nithi", "active": true}, {"name": "Trans-Nzoia", "active": true}, {"name": "Turkana", "active": true}, {"name": "Uasin Gishu", "active": true}, {"name": "Vihiga", "active": true}, {"name": "Wajir", "active": true}, {"name": "West Pokot", "active": true}]	8c946fb5-d724-4183-9a2f-2b8b4c84dab3	KE	 enya	🇰🇪
Kuwait	[{"name": "Al Ahmadi", "active": true}, {"name": "Al Farwaniyah", "active": true}, {"name": "Al Asimah", "active": true}, {"name": "Hawalli", "active": true}, {"name": "Mubarak Al-Kabeer", "active": true}, {"name": "Al Jahra", "active": true}]	fbbe38a1-8b6a-48f4-8795-8861c90344ec	KU	 uwait	🇰🇺
Kyrgyzstan	[{"name": "Bishkek", "active": true}, {"name": "Chuy", "active": true}, {"name": "Jalal-Abad", "active": true}, {"name": "Naryn", "active": true}, {"name": "Osh", "active": true}, {"name": "Talas", "active": true}, {"name": "Batken", "active": true}]	91893683-2d1d-443d-b44d-e5a82ee99d98	KY	 yrgyzstan	🇰🇾
Laos	[{"name": "Attapeu", "active": true}, {"name": "Bokeo", "active": true}, {"name": "Bolikhamsai", "active": true}, {"name": "Champasak", "active": true}, {"name": "Houaphanh", "active": true}, {"name": "Khammouane", "active": true}, {"name": "Luang Namtha", "active": true}, {"name": "Luang Prabang", "active": true}, {"name": "Oudomxay", "active": true}, {"name": "Phongsaly", "active": true}, {"name": "Salavan", "active": true}, {"name": "Savannakhet", "active": true}, {"name": "Sekong", "active": true}, {"name": "Vientiane", "active": true}, {"name": "Vientiane Prefecture", "active": true}, {"name": "Xaignabouli", "active": true}, {"name": "Xaisomboun", "active": true}, {"name": "Xekong", "active": true}, {"name": "Xiangkhouang", "active": true}]	b2bcec6d-fa70-4d8a-b7aa-716cb9290b7b	LA	 aos	🇱🇦
Latvia	[{"name": "Aizkraukle", "active": true}, {"name": "Alūksne", "active": true}, {"name": "Balvi", "active": true}, {"name": "Bauska", "active": true}, {"name": "Cēsis", "active": true}, {"name": "Daugavpils", "active": true}, {"name": "Daugavpils City", "active": true}, {"name": "Dobele", "active": true}, {"name": "Gulbene", "active": true}, {"name": "Jēkabpils", "active": true}, {"name": "Jelgava", "active": true}, {"name": "Jelgava City", "active": true}, {"name": "Jūrmala", "active": true}, {"name": "Kraslava", "active": true}, {"name": "Kuldīga", "active": true}, {"name": "Liepaja", "active": true}, {"name": "Liepāja City", "active": true}, {"name": "Limbaži", "active": true}, {"name": "Ludza", "active": true}, {"name": "Madona", "active": true}, {"name": "Ogre", "active": true}, {"name": "Preiļi", "active": true}, {"name": "Rēzekne", "active": true}, {"name": "Rēzekne City", "active": true}, {"name": "Riga", "active": true}, {"name": "Rīgas City", "active": true}, {"name": "Saldus", "active": true}, {"name": "Talsi", "active": true}, {"name": "Tukums", "active": true}, {"name": "Valka", "active": true}, {"name": "Valmiera", "active": true}, {"name": "Ventspils", "active": true}, {"name": "Ventspils City", "active": true}]	5addfb3b-16dd-4628-acee-aa7241dfa40d	LA	 atvia	🇱🇦
Lebanon	[{"name": "Akkar", "active": true}, {"name": "Baalbek-Hermel", "active": true}, {"name": "Beirut", "active": true}, {"name": "Beqaa", "active": true}, {"name": "Mount Lebanon", "active": true}, {"name": "Nabatieh", "active": true}, {"name": "North Governorate", "active": true}, {"name": "South Governorate", "active": true}]	9e3b1016-e590-4232-bc64-8f95a98236a1	LE	 ebanon	🇱🇪
Lesotho	[{"name": "Berea", "active": true}, {"name": "Butha-Buthe", "active": true}, {"name": "Leribe", "active": true}, {"name": "Mafeteng", "active": true}, {"name": "Maseru", "active": true}, {"name": "Mohale's Hoek", "active": true}, {"name": "Mokhotlong", "active": true}, {"name": "Qacha's Nek", "active": true}, {"name": "Quthing", "active": true}, {"name": "Thaba-Tseka", "active": true}]	11d2398d-898a-47e4-aa36-6920a8493d33	LE	 esotho	🇱🇪
Antigua and Barbuda	[{"name": "Barbuda", "active": true}, {"name": "Saint George", "active": true}, {"name": "Saint John", "active": true}, {"name": "Saint Mary", "active": true}, {"name": "Saint Paul", "active": true}, {"name": "Saint Peter", "active": true}, {"name": "Saint Philip", "active": true}]	9aa5212b-0c5f-4139-9912-0e10894a5f5d	AN	 ntigua and arbuda	🇦🇳
Liberia	[{"name": "Bomi", "active": true}, {"name": "Bong", "active": true}, {"name": "Grand Bassa", "active": true}, {"name": "Grand Cape Mount", "active": true}, {"name": "Grand Gedeh", "active": true}, {"name": "Lofa", "active": true}, {"name": "Margibi", "active": true}, {"name": "Maryland", "active": true}, {"name": "Montserrado", "active": true}, {"name": "Nimba", "active": true}, {"name": "Rivercess", "active": true}, {"name": "Sinoe", "active": true}]	f496445f-96b5-460c-8ff5-cc0305dfd39e	LI	 iberia	🇱🇮
Argentina	[{"name": "Buenos Aires", "active": true}, {"name": "Catamarca", "active": true}, {"name": "Chaco", "active": true}, {"name": "Chubut", "active": true}, {"name": "Córdoba", "active": true}, {"name": "Corrientes", "active": true}, {"name": "Entre Ríos", "active": true}, {"name": "Formosa", "active": true}, {"name": "Jujuy", "active": true}, {"name": "La Pampa", "active": true}, {"name": "La Rioja", "active": true}, {"name": "Mendoza", "active": true}, {"name": "Misiones", "active": true}, {"name": "Neuquén", "active": true}, {"name": "Río Negro", "active": true}, {"name": "Salta", "active": true}, {"name": "San Juan", "active": true}, {"name": "San Luis", "active": true}, {"name": "Santa Cruz", "active": true}, {"name": "Santa Fe", "active": true}, {"name": "Santiago del Estero", "active": true}, {"name": "Tierra del Fuego", "active": true}, {"name": "Tucumán", "active": true}]	c633e1be-0e7b-498a-8ee7-3030cc01d408	AR	 rgentina	🇦🇷
Libya	[{"name": "Al Jabal al Akhdar", "active": true}, {"name": "Al Jufrah", "active": true}, {"name": "Al Marqab", "active": true}, {"name": "Al Wahat", "active": true}, {"name": "An Nuqat al Khams", "active": true}, {"name": "Az Zawiyah", "active": true}, {"name": "Banghazi", "active": true}, {"name": "Darnah", "active": true}, {"name": "Ghadamis", "active": true}, {"name": "Gharyan", "active": true}, {"name": "Misratah", "active": true}, {"name": "Murzuq", "active": true}, {"name": "Sabha", "active": true}, {"name": "Surt", "active": true}, {"name": "Tarhunah", "active": true}, {"name": "Tripoli", "active": true}, {"name": "Wadi al Shatii", "active": true}, {"name": "Wadi al Hayaa", "active": true}]	b1030299-080f-420e-b893-30f522f25702	LI	 ibya	🇱🇮
Liechtenstein	[{"name": "Balzers", "active": true}, {"name": "Eschen", "active": true}, {"name": "Gamprin", "active": true}, {"name": "Mauren", "active": true}, {"name": "Planken", "active": true}, {"name": "Ruggell", "active": true}, {"name": "Schaan", "active": true}, {"name": "Schellenberg", "active": true}, {"name": "Triesen", "active": true}, {"name": "Triesenberg", "active": true}, {"name": "Vaduz", "active": true}]	9c35fb97-7070-4735-9604-b09201a4c72d	LI	 iechtenstein	🇱🇮
Lithuania	[{"name": "Alytus County", "active": true}, {"name": "Kaunas County", "active": true}, {"name": "Klaipėda County", "active": true}, {"name": "Marijampolė County", "active": true}, {"name": "Panevėžys County", "active": true}, {"name": "Šiauliai County", "active": true}, {"name": "Tauragė County", "active": true}, {"name": "Telšiai County", "active": true}, {"name": "Utena County", "active": true}, {"name": "Vilnius County", "active": true}]	3f1af0f5-4e8b-4c5c-afbc-129c166ae9bc	LI	 ithuania	🇱🇮
Madagascar	[{"name": "Antananarivo", "active": true}, {"name": "Antsiranana", "active": true}, {"name": "Fianarantsoa", "active": true}, {"name": "Mahajanga", "active": true}, {"name": "Toamasina", "active": true}, {"name": "Toliara", "active": true}]	2c6ef5e4-22b7-4d6b-95d6-9cb3b20e7030	MA	 adagascar	🇲🇦
Armenia	[{"name": "Aragatsotn", "active": true}, {"name": "Ararat", "active": true}, {"name": "Armavir", "active": true}, {"name": "Gegharkunik", "active": true}, {"name": "Kotayk", "active": true}, {"name": "Lori", "active": true}, {"name": "Shirak", "active": true}, {"name": "Syunik", "active": true}, {"name": "Tavush", "active": true}, {"name": "Vayots Dzor", "active": true}]	94111c3a-8775-4c2d-b632-90efff873531	AR	 rmenia	🇦🇷
Malawi	[{"name": "Central Region", "active": true}, {"name": "Northern Region", "active": true}, {"name": "Southern Region", "active": true}]	f54465f1-6334-4385-be5b-c7480936b3b9	MA	 alawi	🇲🇦
Malaysia	[{"name": "Johor", "active": true}, {"name": "Kedah", "active": true}, {"name": "Kelantan", "active": true}, {"name": "Melaka", "active": true}, {"name": "Negeri Sembilan", "active": true}, {"name": "Pahang", "active": true}, {"name": "Perak", "active": true}, {"name": "Perlis", "active": true}, {"name": "Pulau Pinang", "active": true}, {"name": "Sabah", "active": true}, {"name": "Sarawak", "active": true}, {"name": "Selangor", "active": true}, {"name": "Terengganu", "active": true}, {"name": "Wilayah Persekutuan", "active": true}]	4e4f76fe-7bae-401c-9e6c-ff6770aa2773	MA	 alaysia	🇲🇦
Maldives	[{"name": "Alif Alif Atoll", "active": true}, {"name": "Alif Dhaal Atoll", "active": true}, {"name": "Baa Atoll", "active": true}, {"name": "Dhaalu Atoll", "active": true}, {"name": "Faafu Atoll", "active": true}, {"name": "Gaafu Alif Atoll", "active": true}, {"name": "Gaafu Dhaalu Atoll", "active": true}, {"name": "Gnaviyani Atoll", "active": true}, {"name": "Haa Alif Atoll", "active": true}, {"name": "Haa Dhaalu Atoll", "active": true}, {"name": "Kaafu Atoll", "active": true}, {"name": "Laamu Atoll", "active": true}, {"name": "Lhaviyani Atoll", "active": true}, {"name": "Meemu Atoll", "active": true}, {"name": "Noonu Atoll", "active": true}, {"name": "Raa Atoll", "active": true}, {"name": "Shaviyani Atoll", "active": true}, {"name": "Thaa Atoll", "active": true}, {"name": "Vaavu Atoll", "active": true}]	f959fc3e-e914-45bf-afa1-d045726bf0ad	MA	 aldives	🇲🇦
Mali	[{"name": "Bamako", "active": true}, {"name": "Gao", "active": true}, {"name": "Kayes", "active": true}, {"name": "Kidal", "active": true}, {"name": "Koulikoro", "active": true}, {"name": "Mopti", "active": true}, {"name": "Ségou", "active": true}, {"name": "Sikasso", "active": true}, {"name": "Taoudénit", "active": true}, {"name": "Tombouctou", "active": true}]	917d4f65-69f6-40b9-81e4-5aca057195b4	MA	 ali	🇲🇦
Australia	[{"name": "Australian Capital Territory", "active": true}, {"name": "New South Wales", "active": true}, {"name": "Northern Territory", "active": true}, {"name": "Queensland", "active": true}, {"name": "South Australia", "active": true}, {"name": "Tasmania", "active": true}, {"name": "Victoria", "active": true}, {"name": "Western Australia", "active": true}]	8f467715-5eb1-4787-9698-38af986caea9	AU	 ustralia	🇦🇺
Austria	[{"name": "Burgenland", "active": true}, {"name": "Carinthia", "active": true}, {"name": "Lower Austria", "active": true}, {"name": "Upper Austria", "active": true}, {"name": "Salzburg", "active": true}, {"name": "Styria", "active": true}, {"name": "Tyrol", "active": true}, {"name": "Vorarlberg", "active": true}, {"name": "Vienna", "active": true}]	de505d76-9e79-47c8-a33e-c707e09ea08d	AU	 ustria	🇦🇺
Guinea-Bissau	[{"name": "Bafatá", "active": true}, {"name": "Biombo", "active": true}, {"name": "Bissau", "active": true}, {"name": "Bolama", "active": true}, {"name": "Cacheu", "active": true}, {"name": "Gabu", "active": true}, {"name": "Oio", "active": true}, {"name": "Quinara", "active": true}, {"name": "Tombali", "active": true}]	d5c84c48-bf1d-4dac-abc7-c6339a00ef6a	GU	 uinea issau	🇬🇺
Azerbaijan	[{"name": "Absheron", "active": true}, {"name": "Agdam", "active": true}, {"name": "Agdash", "active": true}, {"name": "Agstafa", "active": true}, {"name": "Agsu", "active": true}, {"name": "Astara", "active": true}, {"name": "Balakan", "active": true}, {"name": "Baku", "active": true}, {"name": "Barbakat", "active": true}, {"name": "Bilasuvar", "active": true}, {"name": "Dashkasan", "active": true}, {"name": "Fizuli", "active": true}, {"name": "Gadabay", "active": true}, {"name": "Goranboy", "active": true}, {"name": "Goychay", "active": true}, {"name": "Hajigabul", "active": true}, {"name": "Imishli", "active": true}, {"name": "Ismayilli", "active": true}, {"name": "Kalbajar", "active": true}, {"name": "Khachmaz", "active": true}, {"name": "Lankaran", "active": true}, {"name": "Lerik", "active": true}, {"name": "Masally", "active": true}, {"name": "Nakhchivan", "active": true}, {"name": "Neftchala", "active": true}, {"name": "Oguz", "active": true}, {"name": "Qabala", "active": true}, {"name": "Qakh", "active": true}, {"name": "Qarachi", "active": true}, {"name": "Quba", "active": true}, {"name": "Qubadli", "active": true}, {"name": "Saatly", "active": true}, {"name": "Sabirabad", "active": true}, {"name": "Sadarak", "active": true}, {"name": "Salyan", "active": true}, {"name": "Shabran", "active": true}, {"name": "Shaki", "active": true}, {"name": "Shamakhi", "active": true}, {"name": "Shamkir", "active": true}, {"name": "Sharur", "active": true}, {"name": "Shusha", "active": true}, {"name": "Tartar", "active": true}, {"name": "Tovuz", "active": true}, {"name": "Ujar", "active": true}, {"name": "Yardymli", "active": true}, {"name": "Yevlakh", "active": true}, {"name": "Zangilan", "active": true}, {"name": "Zaqatala", "active": true}, {"name": "Zardab", "active": true}]	b9afeeda-3e74-4d70-a1a5-a22b0fb1180b	AZ	 zerbaijan	🇦🇿
Cayman Islands	[{"name": "George Town", "active": true}, {"name": "Bodden Town", "active": true}, {"name": "West Bay", "active": true}]	523b7844-e334-4d3f-8d29-e70211c6c89a	CA	 ayman slands	🇨🇦
Dominica	[{"name": "Saint Andrew", "active": true}, {"name": "Saint David", "active": true}, {"name": "Saint George", "active": true}, {"name": "Saint John", "active": true}, {"name": "Saint Joseph", "active": true}, {"name": "Saint Luke", "active": true}, {"name": "Saint Mark", "active": true}, {"name": "Saint Patrick", "active": true}, {"name": "Saint Paul", "active": true}, {"name": "Saint Peter", "active": true}]	5529d392-3f4c-4639-a45e-59cacb6cdee4	DO	 ominica	🇩🇴
Malta	[{"name": "Attard", "active": true}, {"name": "Balzan", "active": true}, {"name": "Birgu", "active": true}, {"name": "Birkirkara", "active": true}, {"name": "Birżebbuġa", "active": true}, {"name": "Bormla", "active": true}, {"name": "Dingli", "active": true}, {"name": "Fgura", "active": true}, {"name": "Floriana", "active": true}, {"name": "Fontana", "active": true}, {"name": "Gudja", "active": true}, {"name": "Gżira", "active": true}, {"name": "Għajnsielem", "active": true}, {"name": "Għarb", "active": true}, {"name": "Għargħur", "active": true}, {"name": "Għasri", "active": true}, {"name": "Għaxaq", "active": true}, {"name": "Ħamrun", "active": true}, {"name": "Iklin", "active": true}, {"name": "Isla", "active": true}, {"name": "Kalkara", "active": true}, {"name": "Kerċem", "active": true}, {"name": "Lija", "active": true}, {"name": "Luqa", "active": true}, {"name": "Marsa", "active": true}, {"name": "Marsaskala", "active": true}, {"name": "Marsaxlokk", "active": true}, {"name": "Mdina", "active": true}, {"name": "Mellieħa", "active": true}, {"name": "Mosta", "active": true}, {"name": "Mqabba", "active": true}, {"name": "Msida", "active": true}, {"name": "Mtarfa", "active": true}, {"name": "Nadur", "active": true}, {"name": "Naxxar", "active": true}, {"name": "Paola", "active": true}, {"name": "Pembroke", "active": true}, {"name": "Pietà", "active": true}, {"name": "Qala", "active": true}, {"name": "Qrendi", "active": true}, {"name": "Rabat", "active": true}, {"name": "Safi", "active": true}, {"name": "Saint Julian's", "active": true}, {"name": "San Ġwann", "active": true}, {"name": "Sannat", "active": true}, {"name": "Santa Lucija", "active": true}, {"name": "Santa Venera", "active": true}, {"name": "Siġġiewi", "active": true}, {"name": "Sliema", "active": true}, {"name": "Swieqi", "active": true}, {"name": "Ta' Xbiex", "active": true}, {"name": "Tarxien", "active": true}, {"name": "Valletta", "active": true}, {"name": "Xagħra", "active": true}, {"name": "Xewkija", "active": true}, {"name": "Xgħajra", "active": true}, {"name": "Żabbar", "active": true}, {"name": "Żebbuġ Gozo", "active": true}, {"name": "Żebbuġ", "active": true}, {"name": "Żejtun", "active": true}, {"name": "Żurrieq", "active": true}]	427747c1-ad7c-49b4-b0b7-78e3d9116261	MA	 alta	🇲🇦
Marshall Islands	[{"name": "Ailinglaplap Atoll", "active": true}, {"name": "Ailuk Atoll", "active": true}, {"name": "Arno Atoll", "active": true}, {"name": "Aur Atoll", "active": true}, {"name": "Ebon Atoll", "active": true}, {"name": "Enewetak Atoll", "active": true}, {"name": "Jabat Island", "active": true}, {"name": "Jaluit Atoll", "active": true}, {"name": "Kili Island", "active": true}, {"name": "Kwajalein Atoll", "active": true}, {"name": "Lae Atoll", "active": true}, {"name": "Lib Island", "active": true}, {"name": "Likiep Atoll", "active": true}, {"name": "Majuro Atoll", "active": true}, {"name": "Maloelap Atoll", "active": true}, {"name": "Mejit Island", "active": true}, {"name": "Mili Atoll", "active": true}, {"name": "Namdrik Atoll", "active": true}, {"name": "Namu Atoll", "active": true}, {"name": "Rongelap Atoll", "active": true}, {"name": "Ujae Atoll", "active": true}, {"name": "Ujelang Atoll", "active": true}, {"name": "Wotho Atoll", "active": true}, {"name": "Wotje Atoll", "active": true}]	e9146ac6-b6e9-490f-886f-2257fed06940	MA	 arshall slands	🇲🇦
Mauritania	[{"name": "Adrar", "active": true}, {"name": "Assaba", "active": true}, {"name": "Brakna", "active": true}, {"name": "Dakhlet Nouadhibou", "active": true}, {"name": "Gorgol", "active": true}, {"name": "Guidimaka", "active": true}, {"name": "Hodh Ech Chargui", "active": true}, {"name": "Hodh El Gharbi", "active": true}, {"name": "Inchiri", "active": true}, {"name": "Nouakchott", "active": true}, {"name": "Tagant", "active": true}, {"name": "Tiris Zemmour", "active": true}, {"name": "Trarza", "active": true}]	b7baf032-c7c1-49d7-989f-8de6f00d5215	MA	 auritania	🇲🇦
Mauritius	[{"name": "Black River", "active": true}, {"name": "Flacq", "active": true}, {"name": "Grand Port", "active": true}, {"name": "Moka", "active": true}, {"name": "Pamplemousses", "active": true}, {"name": "Plaines Wilhems", "active": true}, {"name": "Port Louis", "active": true}, {"name": "Rivière du Rempart", "active": true}, {"name": "Savanne", "active": true}]	2243f8c5-477e-4550-9f6c-db05143554d9	MA	 auritius	🇲🇦
Mayotte	[{"name": "Bandrele", "active": true}, {"name": "Bouéni", "active": true}, {"name": "Chirongui", "active": true}, {"name": "Dembeni", "active": true}, {"name": "Kani-Kéli", "active": true}, {"name": "Mamoudzou", "active": true}, {"name": "Mtsamboro", "active": true}, {"name": "M'Tsangamouji", "active": true}, {"name": "Ouangani", "active": true}, {"name": "Pamandzi", "active": true}, {"name": "Sada", "active": true}, {"name": "Tsingoni", "active": true}]	691430f8-59da-434e-b42f-195f75a1d485	MA	 ayotte	🇲🇦
Venezuela	[{"name": "Amazonas", "active": true}, {"name": "Anzoátegui", "active": true}, {"name": "Apure", "active": true}, {"name": "Aragua", "active": true}, {"name": "Barinas", "active": true}, {"name": "Bolívar", "active": true}, {"name": "Carabobo", "active": true}, {"name": "Cojedes", "active": true}, {"name": "Delta Amacuro", "active": true}, {"name": "Falcón", "active": true}, {"name": "Guárico", "active": true}, {"name": "Lara", "active": true}, {"name": "Mérida", "active": true}, {"name": "Miranda", "active": true}, {"name": "Monagas", "active": true}, {"name": "Nueva Esparta", "active": true}, {"name": "Portuguesa", "active": true}, {"name": "Sucre", "active": true}, {"name": "Táchira", "active": true}, {"name": "Trujillo", "active": true}, {"name": "Yaracuy", "active": true}, {"name": "Zulia", "active": true}, {"name": "Capital District", "active": true}, {"name": "Dependencias Federales", "active": true}, {"name": "Federal Dependencies of Venezuela", "active": true}]	9a749eaa-43b3-4083-b340-a76c9745e98b	VE	 enezuela	🇻🇪
Wallis and Futuna	[{"name": "Alo", "active": true}, {"name": "Sigave", "active": true}, {"name": "Uvea", "active": true}]	c84d6f33-fe76-4890-975e-45da462d7d46	WA	 allis and utuna	🇼🇦
Morocco	[{"name": "Agadir-Ida Ou Tanane", "active": true}, {"name": "Al Hoceima", "active": true}, {"name": "Azilal", "active": true}, {"name": "Béni Mellal", "active": true}, {"name": "Berkane", "active": true}, {"name": "Casablanca", "active": true}, {"name": "Fès", "active": true}, {"name": "Kénitra", "active": true}, {"name": "Khenifra", "active": true}, {"name": "Khouribga", "active": true}, {"name": "Marrakech", "active": true}, {"name": "Meknès", "active": true}, {"name": "Nador", "active": true}, {"name": "Ouarzazate", "active": true}, {"name": "Oujda", "active": true}, {"name": "Rabat-Salé-Zemmour-Zaër", "active": true}, {"name": "Safi", "active": true}, {"name": "Settat", "active": true}, {"name": "Sidi Kacem", "active": true}, {"name": "Tanger-Tétouan", "active": true}, {"name": "Taza", "active": true}, {"name": "Tétouan", "active": true}]	fefae1c4-7717-4f85-b01e-2e010796746c	MO	 orocco	🇲🇴
Mexico	[{"name": "Aguascalientes", "active": true}, {"name": "Baja California", "active": true}, {"name": "Baja California Sur", "active": true}, {"name": "Campeche", "active": true}, {"name": "Chiapas", "active": true}, {"name": "Chihuahua", "active": true}, {"name": "Coahuila", "active": true}, {"name": "Colima", "active": true}, {"name": "Durango", "active": true}, {"name": "Guanajuato", "active": true}, {"name": "Guerrero", "active": true}, {"name": "Hidalgo", "active": true}, {"name": "Jalisco", "active": true}, {"name": "Mexico City", "active": true}, {"name": "México State", "active": true}, {"name": "Michoacán", "active": true}, {"name": "Morelos", "active": true}, {"name": "Nayarit", "active": true}, {"name": "Nuevo León", "active": true}, {"name": "Oaxaca", "active": true}, {"name": "Puebla", "active": true}, {"name": "Querétaro", "active": true}, {"name": "Quintana Roo", "active": true}, {"name": "San Luis Potosí", "active": true}, {"name": "Sinaloa", "active": true}, {"name": "Sonora", "active": true}, {"name": "Tabasco", "active": true}, {"name": "Tamaulipas", "active": true}, {"name": "Tlaxcala", "active": true}, {"name": "Veracruz", "active": true}, {"name": "Yucatán", "active": true}, {"name": "Zacatecas", "active": true}]	f3074d8d-ea9f-4871-812e-f6b733efd37e	ME	 exico	🇲🇪
Micronesia	[{"name": "Chuuk", "active": true}, {"name": "Kosrae", "active": true}, {"name": "Pohnpei", "active": true}, {"name": "Yap", "active": true}]	b80e827d-5df0-41ac-aa25-7dbe46824ade	MI	 icronesia	🇲🇮
Guatemala	[{"name": "Alta Verapaz", "active": true}, {"name": "Baja Verapaz", "active": true}, {"name": "Chimaltenango", "active": true}, {"name": "Chiquimula", "active": true}, {"name": "El Progreso", "active": true}, {"name": "Escuintla", "active": true}, {"name": "Guatemala", "active": true}, {"name": "Huehuetenango", "active": true}, {"name": "Izabal", "active": true}, {"name": "Jalapa", "active": true}, {"name": "Jutiapa", "active": true}, {"name": "Petén", "active": true}, {"name": "Quetzaltenango", "active": true}, {"name": "Quiché", "active": true}, {"name": "Retalhuleu", "active": true}, {"name": "Sacatepéquez", "active": true}, {"name": "San Marcos", "active": true}, {"name": "Santa Rosa", "active": true}, {"name": "Sololá", "active": true}, {"name": "Suchitepéquez", "active": true}, {"name": "Totonicapán", "active": true}, {"name": "Zacapa", "active": true}]	5c35bcab-a300-4e23-9f06-d2e8450f917b	GU	 uatemala	🇬🇺
Moldova	[{"name": "Anenii Noi", "active": true}, {"name": "Basarabeasca", "active": true}, {"name": "Bender", "active": true}, {"name": "Briceni", "active": true}, {"name": "Cahul", "active": true}, {"name": "Cantemir", "active": true}, {"name": "Călărași", "active": true}, {"name": "Căușeni", "active": true}, {"name": "Chișinău", "active": true}, {"name": "Criuleni", "active": true}, {"name": "Dondușeni", "active": true}, {"name": "Drochia", "active": true}, {"name": "Dubăsari", "active": true}, {"name": "Edineț", "active": true}, {"name": "Fălești", "active": true}, {"name": "Florești", "active": true}, {"name": "Gagauzia", "active": true}, {"name": "Glodeni", "active": true}, {"name": "Hîncești", "active": true}, {"name": "Ialoveni", "active": true}, {"name": "Leova", "active": true}, {"name": "Nisporeni", "active": true}, {"name": "Ocnița", "active": true}, {"name": "Orhei", "active": true}, {"name": "Rezina", "active": true}, {"name": "Rîșcani", "active": true}, {"name": "Sîngerei", "active": true}, {"name": "Soroca", "active": true}, {"name": "Strășeni", "active": true}, {"name": "Șoldănești", "active": true}, {"name": "Taraclia", "active": true}, {"name": "Telenești", "active": true}, {"name": "Ungheni", "active": true}]	aa39a724-d3e8-4b9c-8ae8-1d06d4b06d81	MO	 oldova	🇲🇴
Sudan	[{"name": "Al Jazirah", "active": true}, {"name": "Al Qadarif", "active": true}, {"name": "Blue Nile", "active": true}, {"name": "Central Darfur", "active": true}, {"name": "East Darfur", "active": true}, {"name": "Khartoum", "active": true}, {"name": "Kassala", "active": true}, {"name": "North Darfur", "active": true}, {"name": "North Kordofan", "active": true}, {"name": "Northern", "active": true}, {"name": "Red Sea", "active": true}, {"name": "River Nile", "active": true}, {"name": "Sennar", "active": true}, {"name": "South Darfur", "active": true}, {"name": "South Kordofan", "active": true}, {"name": "West Darfur", "active": true}, {"name": "West Kordofan", "active": true}]	ab414ab4-1d4e-47c3-83ba-653f0d498b0f	SU	 udan	🇸🇺
Mongolia	[{"name": "Arhangai", "active": true}, {"name": "Bayan-Ölgii", "active": true}, {"name": "Bayankhongor", "active": true}, {"name": "Bulgan", "active": true}, {"name": "Darhan-Uul", "active": true}, {"name": "Dornod", "active": true}, {"name": "Dornogovi", "active": true}, {"name": "Dzavhan", "active": true}, {"name": "Govi-Altai", "active": true}, {"name": "Govisümber", "active": true}, {"name": "Hentiy", "active": true}, {"name": "Hövsgöl", "active": true}, {"name": "Ömnögovi", "active": true}, {"name": "Orkhon", "active": true}, {"name": "Övörkhangai", "active": true}, {"name": "Selenge", "active": true}, {"name": "Sühbaatar", "active": true}, {"name": "Töv", "active": true}, {"name": "Ulaanbaatar", "active": true}, {"name": "Uvs", "active": true}, {"name": "Zavkhan", "active": true}]	e50fe5eb-df9c-4290-a366-70faf11bd497	MO	 ongolia	🇲🇴
Montenegro	[{"name": "Andrijevica", "active": true}, {"name": "Bar", "active": true}, {"name": "Berane", "active": true}, {"name": "Bijelo Polje", "active": true}, {"name": "Budva", "active": true}, {"name": "Cetinje", "active": true}, {"name": "Danilovgrad", "active": true}, {"name": "Herceg Novi", "active": true}, {"name": "Kolašin", "active": true}, {"name": "Kotor", "active": true}, {"name": "Mojkovac", "active": true}, {"name": "Nikšić", "active": true}, {"name": "Petnjica", "active": true}, {"name": "Plav", "active": true}, {"name": "Plužine", "active": true}, {"name": "Pljevlja", "active": true}, {"name": "Podgorica", "active": true}, {"name": "Rožaje", "active": true}, {"name": "Šavnik", "active": true}, {"name": "Tivat", "active": true}, {"name": "Tuzi", "active": true}, {"name": "Ulcinj", "active": true}, {"name": "Žabljak", "active": true}]	b21d47fa-8506-40f5-951e-e713da37a0d7	MO	 ontenegro	🇲🇴
Montserrat	[{"name": "Plymouth", "active": true}, {"name": "Saint Anthony", "active": true}, {"name": "Saint Georges", "active": true}, {"name": "Saint Peter", "active": true}]	ec896c4a-eeca-4d77-8825-18501c67fc86	MO	 ontserrat	🇲🇴
Western Sahara	[{"name": "Aousserd", "active": true}, {"name": "Es Semara", "active": true}, {"name": "Laâyoune", "active": true}, {"name": "Oued Ed-Dahab", "active": true}]	0b7477a4-416a-44cb-8139-27110a56125f	WE	 estern ahara	🇼🇪
Mozambique	[{"name": "Cabo Delgado", "active": true}, {"name": "Gaza", "active": true}, {"name": "Inhambane", "active": true}, {"name": "Manica", "active": true}, {"name": "Maputo", "active": true}, {"name": "Maputo City", "active": true}, {"name": "Nampula", "active": true}, {"name": "Niassa", "active": true}, {"name": "Sofala", "active": true}, {"name": "Tete", "active": true}, {"name": "Zambezia", "active": true}]	fa4216f3-d5a8-4bd7-ab8e-3f2994cdeb65	MO	 ozambique	🇲🇴
Guadeloupe	[{"name": "Basse-Terre", "active": true}, {"name": "Grande-Terre", "active": true}, {"name": "La Désirade", "active": true}, {"name": "Marie-Galante", "active": true}, {"name": "Les Saintes", "active": true}]	24ce9598-e414-4476-8985-0dda1f8d31ea	GU	 uadeloupe	🇬🇺
Guam	[{"name": "Agana Heights", "active": true}, {"name": "Agat", "active": true}, {"name": "Asan-Maina", "active": true}, {"name": "Barrigada", "active": true}, {"name": "Chalan-Pago-Ordot", "active": true}, {"name": "Dededo", "active": true}, {"name": "Hagatna", "active": true}, {"name": "Inarajan", "active": true}, {"name": "Mangilao", "active": true}, {"name": "Merizo", "active": true}, {"name": "Mongmong-Toto-Maite", "active": true}, {"name": "Santa Rita", "active": true}, {"name": "Sinajana", "active": true}, {"name": "Talofofo", "active": true}, {"name": "Tamuning-Tumon-Harmon", "active": true}, {"name": "Yigo", "active": true}, {"name": "Yona", "active": true}]	a8a51327-37fc-41a6-ac73-49e804ba5b25	GU	 uam	🇬🇺
Guyana	[{"name": "Barima-Waini", "active": true}, {"name": "Cuyuni-Mazaruni", "active": true}, {"name": "Demerara-Mahaica", "active": true}, {"name": "East Berbice-Corentyne", "active": true}, {"name": "Essequibo Islands-West Demerara", "active": true}, {"name": "Mahaica-Berbice", "active": true}, {"name": "Pomeroon-Supenaam", "active": true}, {"name": "Potaro-Siparuni", "active": true}, {"name": "Upper Demerara-Berbice", "active": true}, {"name": "Upper Takutu-Upper Essequibo", "active": true}]	89b55e6b-5e97-415a-b6a2-35f1cd1bf46a	GU	 uyana	🇬🇺
Myanmar	[{"name": "Chin", "active": true}, {"name": "Kachin", "active": true}, {"name": "Kayah", "active": true}, {"name": "Kayin", "active": true}, {"name": "Magway", "active": true}, {"name": "Mandalay", "active": true}, {"name": "Mon", "active": true}, {"name": "Rakhine", "active": true}, {"name": "Sagaing", "active": true}, {"name": "Shan", "active": true}, {"name": "Tanintharyi", "active": true}, {"name": "Yangon", "active": true}]	11bb46ab-23d9-41d9-a0ea-488b28559247	MY	 yanmar	🇲🇾
Namibia	[{"name": "Erongo", "active": true}, {"name": "Hardap", "active": true}, {"name": "Karas", "active": true}, {"name": "Kavango East", "active": true}, {"name": "Kavango West", "active": true}, {"name": "Khomas", "active": true}, {"name": "Kunene", "active": true}, {"name": "Ohangwena", "active": true}, {"name": "Omaheke", "active": true}, {"name": "Omusati", "active": true}, {"name": "Oshana", "active": true}, {"name": "Oshikoto", "active": true}, {"name": "Otjozondjupa", "active": true}]	cc21aa40-025f-4dab-a706-40a2846e7bcd	NA	 amibia	🇳🇦
Nauru	[{"name": "Aiwo", "active": true}, {"name": "Anabar", "active": true}, {"name": "Anetan", "active": true}, {"name": "Anibare", "active": true}, {"name": "Baiti", "active": true}, {"name": "Boe", "active": true}, {"name": "Buada", "active": true}, {"name": "Denigomodu", "active": true}, {"name": "Ewa", "active": true}, {"name": "Ijuw", "active": true}, {"name": "Meneng", "active": true}, {"name": "Nibok", "active": true}, {"name": "Uaboe", "active": true}, {"name": "Yaren", "active": true}]	b71e494b-f62d-4dd4-ba43-cdbb98c2f249	NA	 auru	🇳🇦
Nepal	[{"name": "Bagmati Province", "active": true}, {"name": "Gandaki Province", "active": true}, {"name": "Karnali Province", "active": true}, {"name": "Lumbini Province", "active": true}, {"name": "Madhesh Province", "active": true}, {"name": "Province No. 1", "active": true}, {"name": "Sudurpashchim Province", "active": true}]	46eda7e7-f670-48f3-a6c1-266b2447471e	NE	 epal	🇳🇪
Netherlands	[{"name": "Drenthe", "active": true}, {"name": "Flevoland", "active": true}, {"name": "Friesland", "active": true}, {"name": "Gelderland", "active": true}, {"name": "Groningen", "active": true}, {"name": "Limburg", "active": true}, {"name": "North Brabant", "active": true}, {"name": "North Holland", "active": true}, {"name": "Overijssel", "active": true}, {"name": "South Holland", "active": true}, {"name": "Utrecht", "active": true}, {"name": "Zeeland", "active": true}]	4375a363-8826-4c41-b0e4-506b27f0d2f7	NE	 etherlands	🇳🇪
New Caledonia	[{"name": "Île des Pins", "active": true}, {"name": "Loyalty Islands", "active": true}, {"name": "North Province", "active": true}, {"name": "South Province", "active": true}]	c2a3e1c8-30cb-4160-9fe6-f42aaa958b7b	NE	 ew aledonia	🇳🇪
New Zealand	[{"name": "Auckland", "active": true}, {"name": "Bay of Plenty", "active": true}, {"name": "Canterbury", "active": true}, {"name": "Gisborne", "active": true}, {"name": "Hawke's Bay", "active": true}, {"name": "Manawatu-Wanganui", "active": true}, {"name": "Marlborough", "active": true}, {"name": "Nelson", "active": true}, {"name": "Northland", "active": true}, {"name": "Otago", "active": true}, {"name": "Southland", "active": true}, {"name": "Taranaki", "active": true}, {"name": "Tasman", "active": true}, {"name": "Waikato", "active": true}, {"name": "Wellington", "active": true}, {"name": "West Coast", "active": true}]	65493b06-cc57-42d4-9dd7-4c83532e0c43	NE	 ew ealand	🇳🇪
Nicaragua	[{"name": "Boaco", "active": true}, {"name": "Carazo", "active": true}, {"name": "Chinandega", "active": true}, {"name": "Chontales", "active": true}, {"name": "Estelí", "active": true}, {"name": "Granada", "active": true}, {"name": "Jinotega", "active": true}, {"name": "León", "active": true}, {"name": "Madriz", "active": true}, {"name": "Managua", "active": true}, {"name": "Masaya", "active": true}, {"name": "Matagalpa", "active": true}, {"name": "Nueva Segovia", "active": true}, {"name": "Río San Juan", "active": true}, {"name": "Rivas", "active": true}]	50e4dfa6-26ae-463d-a92b-87628659ff00	NI	 icaragua	🇳🇮
Niger	[{"name": "Agadez", "active": true}, {"name": "Diffa", "active": true}, {"name": "Dosso", "active": true}, {"name": "Maradi", "active": true}, {"name": "Tahoua", "active": true}, {"name": "Tillabéri", "active": true}, {"name": "Zinder", "active": true}]	06c4ab3e-3eea-4d72-8bd2-2acdddf98be8	NI	 iger	🇳🇮
Barbados	[{"name": "Christ Church", "active": true}, {"name": "Saint Andrew", "active": true}, {"name": "Saint George", "active": true}, {"name": "Saint James", "active": true}, {"name": "Saint John", "active": true}, {"name": "Saint Joseph", "active": true}, {"name": "Saint Lucy", "active": true}, {"name": "Saint Michael", "active": true}, {"name": "Saint Peter", "active": true}, {"name": "Saint Philip", "active": true}, {"name": "Saint Thomas", "active": true}]	9e8d9f34-d8ca-4b98-8998-77e2c794b27e	BA	 arbados	🇧🇦
Nigeria	[{"name": "Abia", "active": true}, {"name": "Adamawa", "active": true}, {"name": "Akwa Ibom", "active": true}, {"name": "Anambra", "active": true}, {"name": "Bauchi", "active": true}, {"name": "Bayelsa", "active": true}, {"name": "Benue", "active": true}, {"name": "Borno", "active": true}, {"name": "Cross River", "active": true}, {"name": "Delta", "active": true}, {"name": "Ebonyi", "active": true}, {"name": "Edo", "active": true}, {"name": "Ekiti", "active": true}, {"name": "Enugu", "active": true}, {"name": "Gombe", "active": true}, {"name": "Imo", "active": true}, {"name": "Jigawa", "active": true}, {"name": "Kaduna", "active": true}, {"name": "Kano", "active": true}, {"name": "Katsina", "active": true}, {"name": "Kebbi", "active": true}, {"name": "Kogi", "active": true}, {"name": "Kwara", "active": true}, {"name": "Lagos", "active": true}, {"name": "Nasarawa", "active": true}, {"name": "Niger", "active": true}, {"name": "Ogun", "active": true}, {"name": "Ondo", "active": true}, {"name": "Osun", "active": true}, {"name": "Oyo", "active": true}, {"name": "Plateau", "active": true}, {"name": "Rivers", "active": true}, {"name": "Sokoto", "active": true}, {"name": "Taraba", "active": true}, {"name": "Yobe", "active": true}, {"name": "Zamfara", "active": true}, {"name": "Federal Capital Territory", "active": true}]	97f5ac10-7948-4da9-b025-98d77c7b58e0	NI	 igeria	🇳🇮
North Korea	[{"name": "Chagang", "active": true}, {"name": "North Hamgyong", "active": true}, {"name": "South Hamgyong", "active": true}, {"name": "North Hwanghae", "active": true}, {"name": "South Hwanghae", "active": true}, {"name": "Kangwon", "active": true}, {"name": "North Pyongan", "active": true}, {"name": "South Pyongan", "active": true}, {"name": "Ryanggang", "active": true}, {"name": "Pyongyang", "active": true}]	35e37a62-8a5f-4bda-819d-682a47497ccc	NO	 orth orea	🇳🇴
Suriname	[{"name": "Brokopondo", "active": true}, {"name": "Commewijne", "active": true}, {"name": "Coronie", "active": true}, {"name": "Marowijne", "active": true}, {"name": "Nickerie", "active": true}, {"name": "Para", "active": true}, {"name": "Paramaribo", "active": true}, {"name": "Saramacca", "active": true}, {"name": "Sipaliwini", "active": true}, {"name": "Wanica", "active": true}]	634912c7-826c-45b9-a16e-ab260d72dcb3	SU	 uriname	🇸🇺
North Macedonia	[{"name": "Aerodrom", "active": true}, {"name": "Aračinovo", "active": true}, {"name": "Berovo", "active": true}, {"name": "Bitola", "active": true}, {"name": "Bogdanci", "active": true}, {"name": "Bogovinje", "active": true}, {"name": "Bosilovo", "active": true}, {"name": "Brvenica", "active": true}, {"name": "Butel", "active": true}, {"name": "Čair", "active": true}, {"name": "Čaška", "active": true}, {"name": "Čučer-Sandevo", "active": true}, {"name": "Debar", "active": true}, {"name": "Debarca", "active": true}, {"name": "Delčevo", "active": true}, {"name": "Demir Hisar", "active": true}, {"name": "Demir Kapija", "active": true}, {"name": "Dojran", "active": true}, {"name": "Dolneni", "active": true}, {"name": "Gazi Baba", "active": true}, {"name": "Gevgelija", "active": true}, {"name": "Gostivar", "active": true}, {"name": "Gradsko", "active": true}, {"name": "Ilinden", "active": true}, {"name": "Jegunovce", "active": true}, {"name": "Karbinci", "active": true}, {"name": "Karpoš", "active": true}, {"name": "Kisela Voda", "active": true}, {"name": "Kičevo", "active": true}, {"name": "Kočani", "active": true}, {"name": "Kratovo", "active": true}, {"name": "Kriva Palanka", "active": true}, {"name": "Krivogaštani", "active": true}, {"name": "Kruševo", "active": true}, {"name": "Kumanovo", "active": true}, {"name": "Lipkovo", "active": true}, {"name": "Lozovo", "active": true}, {"name": "Mavrovo and Rostuša", "active": true}, {"name": "Makedonska Kamenica", "active": true}, {"name": "Makedonski Brod", "active": true}, {"name": "Negotino", "active": true}, {"name": "Novaci", "active": true}, {"name": "Novo Selo", "active": true}, {"name": "Ohrid", "active": true}, {"name": "Petrovec", "active": true}, {"name": "Plasnica", "active": true}, {"name": "Prilep", "active": true}, {"name": "Probištip", "active": true}, {"name": "Radoviš", "active": true}, {"name": "Rankovce", "active": true}, {"name": "Resen", "active": true}, {"name": "Saraj", "active": true}, {"name": "Sopište", "active": true}, {"name": "Staro Nagoričane", "active": true}, {"name": "Struga", "active": true}, {"name": "Strumica", "active": true}, {"name": "Studeničani", "active": true}, {"name": "Štip", "active": true}, {"name": "Tetovo", "active": true}, {"name": "Valandovo", "active": true}, {"name": "Vasilevo", "active": true}, {"name": "Veles", "active": true}, {"name": "Vevčani", "active": true}, {"name": "Vinica", "active": true}, {"name": "Zajas", "active": true}, {"name": "Zelenikovo", "active": true}, {"name": "Zrnovci", "active": true}]	e0d69254-8e9b-4b11-86f4-a51545e6c269	NO	 orth acedonia	🇳🇴
Northern Mariana Islands	[{"name": "Rota", "active": true}, {"name": "Saipan", "active": true}, {"name": "Tinian", "active": true}]	83db4956-89fc-41a3-9755-812845eee98a	NO	 orthern ariana slands	🇳🇴
Norway	[{"name": "Agder", "active": true}, {"name": "Innlandet", "active": true}, {"name": "Møre og Romsdal", "active": true}, {"name": "Nordland", "active": true}, {"name": "Oslo", "active": true}, {"name": "Rogaland", "active": true}, {"name": "Troms og Finnmark", "active": true}, {"name": "Trøndelag", "active": true}, {"name": "Vestfold og Telemark", "active": true}, {"name": "Vestland", "active": true}, {"name": "Viken", "active": true}]	ed466e22-240e-4069-a1ef-2c884c912de3	NO	 orway	🇳🇴
Oman	[{"name": "Ad Dakhiliyah", "active": true}, {"name": "Ad Dhahirah", "active": true}, {"name": "Al Batinah North", "active": true}, {"name": "Al Batinah South", "active": true}, {"name": "Al Wusta", "active": true}, {"name": "Ash Sharqiyah North", "active": true}, {"name": "Ash Sharqiyah South", "active": true}, {"name": "Dhofar", "active": true}, {"name": "Muscat", "active": true}, {"name": "Musandam", "active": true}, {"name": "Al Buraymi", "active": true}]	56233c02-83cd-4f29-8d86-c05de058f605	OM	 man	🇴🇲
Pakistan	[{"name": "Azad Jammu and Kashmir", "active": true}, {"name": "Balochistan", "active": true}, {"name": "Gilgit-Baltistan", "active": true}, {"name": "Islamabad Capital Territory", "active": true}, {"name": "Khyber Pakhtunkhwa", "active": true}, {"name": "Punjab", "active": true}, {"name": "Sindh", "active": true}]	99379efc-ce39-41e4-98c9-b3f5adb86615	PA	 akistan	🇵🇦
Palau	[{"name": "Aimeliik", "active": true}, {"name": "Airai", "active": true}, {"name": "Angaur", "active": true}, {"name": "Hatohobei", "active": true}, {"name": "Kayangel", "active": true}, {"name": "Koror", "active": true}, {"name": "Melekeok", "active": true}, {"name": "Ngaraard", "active": true}, {"name": "Ngarchelong", "active": true}, {"name": "Ngardmau", "active": true}, {"name": "Ngatpang", "active": true}, {"name": "Ngchesar", "active": true}, {"name": "Ngiwal", "active": true}, {"name": "Peleliu", "active": true}, {"name": "Sonsorol", "active": true}]	1f837aa8-d493-480b-ac28-0cce58a4c32b	PA	 alau	🇵🇦
Panama	[{"name": "Bocas del Toro", "active": true}, {"name": "Chiriquí", "active": true}, {"name": "Coclé", "active": true}, {"name": "Colón", "active": true}, {"name": "Darién", "active": true}, {"name": "Emberá", "active": true}, {"name": "Herrera", "active": true}, {"name": "Los Santos", "active": true}, {"name": "Ngäbe-Buglé", "active": true}, {"name": "Panamá", "active": true}, {"name": "Veraguas", "active": true}]	93a4aa2a-92c0-4ac7-81e7-ae0e93219df9	PA	 anama	🇵🇦
Papua New Guinea	[{"name": "Bougainville", "active": true}, {"name": "Central", "active": true}, {"name": "Chimbu", "active": true}, {"name": "Eastern Highlands", "active": true}, {"name": "East New Britain", "active": true}, {"name": "East Sepik", "active": true}, {"name": "Enga", "active": true}, {"name": "Gulf", "active": true}, {"name": "Hela", "active": true}, {"name": "Jiwaka", "active": true}, {"name": "Madang", "active": true}, {"name": "Manus", "active": true}, {"name": "Milne Bay", "active": true}, {"name": "Morobe", "active": true}, {"name": "New Ireland", "active": true}, {"name": "Northern Province", "active": true}, {"name": "Southern Highlands", "active": true}, {"name": "West New Britain", "active": true}, {"name": "Western Highlands", "active": true}, {"name": "West Sepik", "active": true}]	bea28278-7db7-4af6-8590-2fe3d0a9dc77	PA	 apua ew uinea	🇵🇦
Paraguay	[{"name": "Alto Paraná", "active": true}, {"name": "Alto Paraguay", "active": true}, {"name": "Alto Pilcomayo", "active": true}, {"name": "Amambay", "active": true}, {"name": "Asunción", "active": true}, {"name": "Boquerón", "active": true}, {"name": "Caaguazú", "active": true}, {"name": "Caazapá", "active": true}, {"name": "Canindeyú", "active": true}, {"name": "Central", "active": true}, {"name": "Concepción", "active": true}, {"name": "Cordillera", "active": true}, {"name": "Guairá", "active": true}, {"name": "Itapúa", "active": true}, {"name": "Misiones", "active": true}, {"name": "Neembucú", "active": true}, {"name": "Paraguarí", "active": true}, {"name": "Presidente Hayes", "active": true}, {"name": "San Pedro", "active": true}]	ba9860e0-f549-4d65-b505-60de145f1a1a	PA	 araguay	🇵🇦
Central African Republic	[{"name": "Bamingui-Bangoran", "active": true}, {"name": "Bangui", "active": true}, {"name": "Basse-Kotto", "active": true}, {"name": "Haut-Mbomou", "active": true}, {"name": "Haute-Kotto", "active": true}, {"name": "Kémo", "active": true}, {"name": "Lobaye", "active": true}, {"name": "Mambéré-Kadéï", "active": true}, {"name": "Mbomou", "active": true}, {"name": "Nana-Grébizi", "active": true}, {"name": "Nana-Mambéré", "active": true}, {"name": "Ombella-M'Poko", "active": true}, {"name": "Ouaka", "active": true}, {"name": "Ouham", "active": true}, {"name": "Ouham-Pendé", "active": true}, {"name": "Sangha-Mbaéré", "active": true}]	6aa41889-cc7d-4cd3-a7c5-2d5d874c7736	CE	 entral frican epublic	🇨🇪
Czech Republic	[{"name": "South Bohemian", "active": true}, {"name": "South Moravian", "active": true}, {"name": "Karlovy Vary", "active": true}, {"name": "Hradec Králové", "active": true}, {"name": "Liberec", "active": true}, {"name": "Moravian-Silesian", "active": true}, {"name": "Olomouc", "active": true}, {"name": "Pardubice", "active": true}, {"name": "Plzeň", "active": true}, {"name": "Prague", "active": true}, {"name": "Central Bohemian", "active": true}, {"name": "Ústí nad Labem", "active": true}, {"name": "Vysočina", "active": true}, {"name": "Zlín", "active": true}]	16d5860a-6d3e-4d2c-a15a-a1af0bada712	CZ	 zech epublic	🇨🇿
Peru	[{"name": "Amazonas", "active": true}, {"name": "Áncash", "active": true}, {"name": "Apurímac", "active": true}, {"name": "Arequipa", "active": true}, {"name": "Ayacucho", "active": true}, {"name": "Cajamarca", "active": true}, {"name": "Callao", "active": true}, {"name": "Cusco", "active": true}, {"name": "Huancavelica", "active": true}, {"name": "Huánuco", "active": true}, {"name": "Ica", "active": true}, {"name": "Junín", "active": true}, {"name": "La Libertad", "active": true}, {"name": "Lambayeque", "active": true}, {"name": "Lima", "active": true}, {"name": "Loreto", "active": true}, {"name": "Madre de Dios", "active": true}, {"name": "Moquegua", "active": true}, {"name": "Pasco", "active": true}, {"name": "Piura", "active": true}, {"name": "Puno", "active": true}, {"name": "San Martín", "active": true}, {"name": "Tacna", "active": true}, {"name": "Tumbes", "active": true}, {"name": "Ucayali", "active": true}]	e116c1a8-f291-4bef-81db-5ff94a175b47	PE	 eru	🇵🇪
United Kingdom	[{"name": "Aberdeen", "active": true}, {"name": "Bath And North East Somerset", "active": true}, {"name": "Belfast", "active": true}, {"name": "Bournemouth", "active": true}, {"name": "Brighton And Hove", "active": true}, {"name": "Bristol", "active": true}, {"name": "Cambridgeshire", "active": true}, {"name": "Cardiff", "active": true}, {"name": "Cheshire", "active": true}, {"name": "Cornwall", "active": true}, {"name": "Cumbria", "active": true}, {"name": "Derry", "active": true}, {"name": "Devon", "active": true}, {"name": "Dumfries And Galloway", "active": true}, {"name": "Dundee", "active": true}, {"name": "Dungannon", "active": true}, {"name": "Edinburgh", "active": true}, {"name": "Glasgow", "active": true}, {"name": "Highland", "active": true}, {"name": "Inverclyde", "active": true}, {"name": "Kent", "active": true}, {"name": "Kingston Upon Hull", "active": true}, {"name": "Lancashire", "active": true}, {"name": "Leicester", "active": true}, {"name": "Luton", "active": true}, {"name": "Manchester", "active": true}, {"name": "Merseyside", "active": true}, {"name": "Moray", "active": true}, {"name": "Norfolk", "active": true}, {"name": "North Yorkshire", "active": true}, {"name": "Nottingham", "active": true}, {"name": "Omagh", "active": true}, {"name": "Oxfordshire", "active": true}, {"name": "Perthshire And Kinross", "active": true}, {"name": "Peterborough", "active": true}, {"name": "Plymouth", "active": true}, {"name": "Portsmouth", "active": true}, {"name": "South Ayrshire", "active": true}, {"name": "South Yorkshire", "active": true}, {"name": "Southampton", "active": true}, {"name": "Southend On Sea", "active": true}, {"name": "Stockton On Tees", "active": true}, {"name": "Stoke On Trent", "active": true}, {"name": "Suffolk", "active": true}, {"name": "Swansea", "active": true}, {"name": "Tyne And Wear", "active": true}, {"name": "West Midlands", "active": true}, {"name": "West Yorkshire", "active": true}, {"name": "Westminster", "active": true}, {"name": "York", "active": true}]	d400645f-9576-4959-8b4b-4afc30bff8c4	UN	 nited ingdom	🇺🇳
Zambia	[{"name": "Central", "active": true}, {"name": "Copperbelt", "active": true}, {"name": "Eastern", "active": true}, {"name": "Luapula", "active": true}, {"name": "Lusaka", "active": true}, {"name": "Muchinga", "active": true}, {"name": "Northern", "active": true}, {"name": "North-Western", "active": true}, {"name": "Southern", "active": true}, {"name": "Western", "active": true}]	5e2a38bc-bb78-4d36-b160-fe8e9ed4dac6	ZA	 ambia	🇿🇦
Bahamas	[{"name": "Acklins", "active": true}, {"name": "Berry Islands", "active": true}, {"name": "Bimini", "active": true}, {"name": "Black Point", "active": true}, {"name": "Cat Island", "active": true}, {"name": "Central Abaco", "active": true}, {"name": "Central Andros", "active": true}, {"name": "City of Freeport", "active": true}, {"name": "Crooked Island", "active": true}, {"name": "East Grand Bahama", "active": true}, {"name": "Exuma", "active": true}, {"name": "Grand Cay", "active": true}, {"name": "Harbour Island", "active": true}, {"name": "Hope Town", "active": true}, {"name": "Inagua", "active": true}, {"name": "Long Island", "active": true}, {"name": "Mangrove Cay", "active": true}, {"name": "Moore's Island", "active": true}, {"name": "North Abaco", "active": true}, {"name": "North Andros", "active": true}, {"name": "Ragged Island", "active": true}, {"name": "Rock Sound", "active": true}, {"name": "San Salvador", "active": true}, {"name": "South Abaco", "active": true}, {"name": "South Andros", "active": true}, {"name": "Spanish Wells", "active": true}, {"name": "West Grand Bahama", "active": true}]	ee13e260-bef6-462a-a5f9-653606060db3	BA	 ahamas	🇧🇦
Bahrain	[{"name": "Al Hadd", "active": true}, {"name": "Al Manamah", "active": true}, {"name": "Al Muharraq", "active": true}, {"name": "Al Janubiyah", "active": true}, {"name": "Al Wusta", "active": true}, {"name": "Ash Shamaliyah", "active": true}]	191186fc-1310-40ff-a3a6-09ab2dce4f0d	BA	 ahrain	🇧🇦
Bangladesh	[{"name": "Bagerhat", "active": true}, {"name": "Bandarban", "active": true}, {"name": "Barguna", "active": true}, {"name": "Barisal", "active": true}, {"name": "Bhola", "active": true}, {"name": "Brahmanbaria", "active": true}, {"name": "Chandpur", "active": true}, {"name": "Chittagong", "active": true}, {"name": "Chuadanga", "active": true}, {"name": "Comilla", "active": true}, {"name": "Cox's Bazar", "active": true}, {"name": "Dhaka", "active": true}, {"name": "Dinajpur", "active": true}, {"name": "Faridpur", "active": true}, {"name": "Feni", "active": true}, {"name": "Gaibandha", "active": true}, {"name": "Gazipur", "active": true}, {"name": "Gopalganj", "active": true}, {"name": "Habiganj", "active": true}, {"name": "Jamalpur", "active": true}, {"name": "Jashore", "active": true}, {"name": "Jhalokati", "active": true}, {"name": "Jhenaidah", "active": true}, {"name": "Joypurhat", "active": true}, {"name": "Kishoreganj", "active": true}, {"name": "Kurigram", "active": true}, {"name": "Kushtia", "active": true}, {"name": "Lakshmipur", "active": true}, {"name": "Lalmonirhat", "active": true}, {"name": "Madaripur", "active": true}, {"name": "Magura", "active": true}, {"name": "Manikganj", "active": true}, {"name": "Meherpur", "active": true}, {"name": "Moulvibazar", "active": true}, {"name": "Munshiganj", "active": true}, {"name": "Mymensingh", "active": true}, {"name": "Naogaon", "active": true}, {"name": "Narail", "active": true}, {"name": "Narsingdi", "active": true}, {"name": "Natore", "active": true}, {"name": "Netrokona", "active": true}, {"name": "Nilphamari", "active": true}, {"name": "Pabna", "active": true}, {"name": "Panchagarh", "active": true}, {"name": "Patuakhali", "active": true}, {"name": "Pirojpur", "active": true}, {"name": "Rajbari", "active": true}, {"name": "Rajshahi", "active": true}, {"name": "Rangamati", "active": true}, {"name": "Rangpur", "active": true}, {"name": "Satkhira", "active": true}, {"name": "Shariatpur", "active": true}, {"name": "Sherpur", "active": true}, {"name": "Sirajganj", "active": true}, {"name": "Sunamganj", "active": true}, {"name": "Sylhet", "active": true}, {"name": "Tangail", "active": true}, {"name": "Thakurgaon", "active": true}]	4c52a1fc-eee7-4858-9568-9c007fe9b381	BA	 angladesh	🇧🇦
Belarus	[{"name": "Brest", "active": true}, {"name": "Gomel", "active": true}, {"name": "Grodno", "active": true}, {"name": "Minsk", "active": true}, {"name": "Mogilev", "active": true}, {"name": "Vitebsk", "active": true}]	031d7651-d3db-41f7-b891-e8f3ee8f23c4	BE	 elarus	🇧🇪
Belgium	[{"name": "Antwerp", "active": true}, {"name": "Brussels-Capital", "active": true}, {"name": "East Flanders", "active": true}, {"name": "Flemish Brabant", "active": true}, {"name": "Hainaut", "active": true}, {"name": "Liège", "active": true}, {"name": "Limburg", "active": true}, {"name": "Luxembourg", "active": true}, {"name": "Namur", "active": true}, {"name": "Walloon Brabant", "active": true}, {"name": "West Flanders", "active": true}]	6f137cf7-1f32-4338-8f82-6485f484425d	BE	 elgium	🇧🇪
Belize	[{"name": "Belize", "active": true}, {"name": "Cayo", "active": true}, {"name": "Corozal", "active": true}, {"name": "Orange Walk", "active": true}, {"name": "Stann Creek", "active": true}, {"name": "Toledo", "active": true}]	c95900cc-8a58-49c6-80d2-7d925df27c83	BE	 elize	🇧🇪
Benin	[{"name": "Alibori", "active": true}, {"name": "Atakora", "active": true}, {"name": "Atlantique", "active": true}, {"name": "Borgou", "active": true}, {"name": "Collines", "active": true}, {"name": "Donga", "active": true}, {"name": "Kouffo", "active": true}, {"name": "Littoral", "active": true}, {"name": "Mono", "active": true}, {"name": "Ouémé", "active": true}, {"name": "Plateau", "active": true}, {"name": "Zou", "active": true}]	1d8343c6-10be-4a0b-b9d4-343040f7b62b	BE	 enin	🇧🇪
Bermuda	[{"name": "Devonshire", "active": true}, {"name": "Hamilton", "active": true}, {"name": "Hamilton Parish", "active": true}, {"name": "Paget", "active": true}, {"name": "Pembroke", "active": true}, {"name": "Saint George's", "active": true}, {"name": "Sandys", "active": true}, {"name": "Smith's", "active": true}, {"name": "Southampton", "active": true}, {"name": "Warwick", "active": true}]	f5e4b8f8-a61f-4cfb-9ee3-ce1f8acc2ffc	BE	 ermuda	🇧🇪
Denmark	[{"name": "Capital Region of Denmark", "active": true}, {"name": "Central Denmark Region", "active": true}, {"name": "North Denmark Region", "active": true}, {"name": "Region Zealand", "active": true}, {"name": "Southern Denmark Region", "active": true}]	c1dbb145-34ac-4a28-acdb-5892e0b2e9dc	DE	 enmark	🇩🇪
Philippines	[{"name": "Abra", "active": true}, {"name": "Agusan del Norte", "active": true}, {"name": "Agusan del Sur", "active": true}, {"name": "Aklan", "active": true}, {"name": "Albay", "active": true}, {"name": "Antique", "active": true}, {"name": "Apayao", "active": true}, {"name": "Aurora", "active": true}, {"name": "Basilan", "active": true}, {"name": "Bataan", "active": true}, {"name": "Batanes", "active": true}, {"name": "Batangas", "active": true}, {"name": "Benguet", "active": true}, {"name": "Biliran", "active": true}, {"name": "Bohol", "active": true}, {"name": "Bukidnon", "active": true}, {"name": "Bulacan", "active": true}, {"name": "Cagayan", "active": true}, {"name": "Camarines Norte", "active": true}, {"name": "Camarines Sur", "active": true}, {"name": "Camiguin", "active": true}, {"name": "Capiz", "active": true}, {"name": "Catanduanes", "active": true}, {"name": "Cavite", "active": true}, {"name": "Cebu", "active": true}, {"name": "Cotabato", "active": true}, {"name": "Davao de Oro", "active": true}, {"name": "Davao del Norte", "active": true}, {"name": "Davao del Sur", "active": true}, {"name": "Davao Occidental", "active": true}, {"name": "Davao Oriental", "active": true}, {"name": "Dinagat Islands", "active": true}, {"name": "Eastern Samar", "active": true}, {"name": "Guimaras", "active": true}, {"name": "Ifugao", "active": true}, {"name": "Ilocos Norte", "active": true}, {"name": "Ilocos Sur", "active": true}, {"name": "Iloilo", "active": true}, {"name": "Isabela", "active": true}, {"name": "Kalinga", "active": true}, {"name": "La Union", "active": true}, {"name": "Laguna", "active": true}, {"name": "Lanao del Norte", "active": true}, {"name": "Lanao del Sur", "active": true}, {"name": "Leyte", "active": true}, {"name": "Maguindanao", "active": true}, {"name": "Marinduque", "active": true}, {"name": "Masbate", "active": true}, {"name": "Mindoro Occidental", "active": true}, {"name": "Mindoro Oriental", "active": true}, {"name": "Misamis Occidental", "active": true}, {"name": "Misamis Oriental", "active": true}, {"name": "Mountain Province", "active": true}, {"name": "Negros Occidental", "active": true}, {"name": "Negros Oriental", "active": true}, {"name": "Northern Samar", "active": true}, {"name": "Nueva Ecija", "active": true}, {"name": "Nueva Vizcaya", "active": true}, {"name": "Occidental Mindoro", "active": true}, {"name": "Oriental Mindoro", "active": true}, {"name": "Palawan", "active": true}, {"name": "Pampanga", "active": true}, {"name": "Pangasinan", "active": true}, {"name": "Quezon", "active": true}, {"name": "Quirino", "active": true}, {"name": "Rizal", "active": true}, {"name": "Romblon", "active": true}, {"name": "Samar", "active": true}, {"name": "Sarangani", "active": true}, {"name": "Siquijor", "active": true}, {"name": "Sorsogon", "active": true}, {"name": "South Cotabato", "active": true}, {"name": "Southern Leyte", "active": true}, {"name": "Sultan Kudarat", "active": true}, {"name": "Sulu", "active": true}, {"name": "Surigao del Norte", "active": true}, {"name": "Surigao del Sur", "active": true}, {"name": "Tarlac", "active": true}, {"name": "Tawi-Tawi", "active": true}, {"name": "Zambales", "active": true}, {"name": "Zamboanga del Norte", "active": true}, {"name": "Zamboanga del Sur", "active": true}, {"name": "Zamboanga Sibugay", "active": true}]	e1142f9c-d93a-46f4-845a-859c345fe8fa	PH	 hilippines	🇵🇭
Poland	[{"name": "Greater Poland", "active": true}, {"name": "Kuyavian-Pomeranian", "active": true}, {"name": "Lesser Poland", "active": true}, {"name": "Łódź", "active": true}, {"name": "Lower Silesian", "active": true}, {"name": "Lublin", "active": true}, {"name": "Lubusz", "active": true}, {"name": "Masovian", "active": true}, {"name": "Opole", "active": true}, {"name": "Podlaskie", "active": true}, {"name": "Pomeranian", "active": true}, {"name": "Silesian", "active": true}, {"name": "Subcarpathian", "active": true}, {"name": "Świętokrzyskie", "active": true}, {"name": "Warmian-Masurian", "active": true}, {"name": "West Pomeranian", "active": true}]	306b2c52-f5ef-443a-90a7-7fc8fc4a5d22	PO	 oland	🇵🇴
Bhutan	[{"name": "Bumthang", "active": true}, {"name": "Chukha", "active": true}, {"name": "Dagana", "active": true}, {"name": "Gasa", "active": true}, {"name": "Haa", "active": true}, {"name": "Lhuntse", "active": true}, {"name": "Mongar", "active": true}, {"name": "Paro", "active": true}, {"name": "Pemagatshel", "active": true}, {"name": "Punakha", "active": true}, {"name": "Samdrup Jongkhar", "active": true}, {"name": "Samtse", "active": true}, {"name": "Sarpang", "active": true}, {"name": "Thimphu", "active": true}, {"name": "Trashigang", "active": true}, {"name": "Trashiyangtse", "active": true}, {"name": "Trongsa", "active": true}, {"name": "Tsirang", "active": true}, {"name": "Wangdue Phodrang", "active": true}, {"name": "Zhemgang", "active": true}]	7a7649cb-c476-4a58-ac5c-97ec7a0105da	BH	 hutan	🇧🇭
Bolivia	[{"name": "Beni", "active": true}, {"name": "Chuquisaca", "active": true}, {"name": "Cochabamba", "active": true}, {"name": "La Paz", "active": true}, {"name": "Oruro", "active": true}, {"name": "Pando", "active": true}, {"name": "Potosí", "active": true}, {"name": "Santa Cruz", "active": true}, {"name": "Tarija", "active": true}]	04663364-000f-44e0-a44a-671d3779da0e	BO	 olivia	🇧🇴
Portugal	[{"name": "Aveiro", "active": true}, {"name": "Beja", "active": true}, {"name": "Braga", "active": true}, {"name": "Bragança", "active": true}, {"name": "Castelo Branco", "active": true}, {"name": "Coimbra", "active": true}, {"name": "Évora", "active": true}, {"name": "Faro", "active": true}, {"name": "Guarda", "active": true}, {"name": "Leiria", "active": true}, {"name": "Lisbon", "active": true}, {"name": "Portalegre", "active": true}, {"name": "Porto", "active": true}, {"name": "Santarém", "active": true}, {"name": "Setúbal", "active": true}, {"name": "Viana do Castelo", "active": true}, {"name": "Vila Real", "active": true}, {"name": "Viseu", "active": true}]	9a8c7458-e58a-41c2-a7b7-a344e20173ac	PO	 ortugal	🇵🇴
Puerto Rico	[{"name": "Adjuntas", "active": true}, {"name": "Aguada", "active": true}, {"name": "Aguadilla", "active": true}, {"name": "Aguas Buenas", "active": true}, {"name": "Aibonito", "active": true}, {"name": "Anasco", "active": true}, {"name": "Arecibo", "active": true}, {"name": "Arroyo", "active": true}, {"name": "Barceloneta", "active": true}, {"name": "Barranquitas", "active": true}, {"name": "Bayamon", "active": true}, {"name": "Cabo Rojo", "active": true}, {"name": "Caguas", "active": true}, {"name": "Camuy", "active": true}, {"name": "Canóvanas", "active": true}, {"name": "Carolina", "active": true}, {"name": "Catano", "active": true}, {"name": "Cayey", "active": true}, {"name": "Ceiba", "active": true}, {"name": "Ciales", "active": true}, {"name": "Cidra", "active": true}, {"name": "Coamo", "active": true}, {"name": "Comerio", "active": true}, {"name": "Corozal", "active": true}, {"name": "Culebra", "active": true}, {"name": "Dorado", "active": true}, {"name": "Fajardo", "active": true}, {"name": "Florida", "active": true}, {"name": "Guayama", "active": true}, {"name": "Guayanilla", "active": true}, {"name": "Guaynabo", "active": true}, {"name": "Gurabo", "active": true}, {"name": "Hatillo", "active": true}, {"name": "Hormigueros", "active": true}, {"name": "Humacao", "active": true}, {"name": "Isabela", "active": true}, {"name": "Jayuya", "active": true}, {"name": "Juana Diaz", "active": true}, {"name": "Juncos", "active": true}, {"name": "Lajas", "active": true}, {"name": "Lares", "active": true}, {"name": "Las Marias", "active": true}, {"name": "Las Piedras", "active": true}, {"name": "Loiza", "active": true}, {"name": "Luquillo", "active": true}, {"name": "Manati", "active": true}, {"name": "Maricao", "active": true}, {"name": "Maunabo", "active": true}, {"name": "Mayaguez", "active": true}, {"name": "Moca", "active": true}, {"name": "Morovis", "active": true}, {"name": "Naguabo", "active": true}, {"name": "Naranjito", "active": true}, {"name": "Orocovis", "active": true}, {"name": "Patillas", "active": true}, {"name": "Peñuelas", "active": true}, {"name": "Ponce", "active": true}, {"name": "Quebradillas", "active": true}, {"name": "Rincon", "active": true}, {"name": "Rio Grande", "active": true}, {"name": "Sabana Grande", "active": true}, {"name": "Salinas", "active": true}, {"name": "San German", "active": true}, {"name": "San Juan", "active": true}, {"name": "San Lorenzo", "active": true}, {"name": "San Sebastian", "active": true}, {"name": "Santa Isabel", "active": true}, {"name": "Toa Alta", "active": true}, {"name": "Toa Baja", "active": true}, {"name": "Trujillo Alto", "active": true}, {"name": "Utuado", "active": true}, {"name": "Vega Alta", "active": true}, {"name": "Vega Baja", "active": true}, {"name": "Vieques", "active": true}, {"name": "Villalba", "active": true}, {"name": "Yabucoa", "active": true}, {"name": "Yauco", "active": true}]	a0847d9e-8068-43c6-bc4d-2c15c734d1ad	PU	 uerto ico	🇵🇺
Qatar	[{"name": "Ad Dawhah", "active": true}, {"name": "Al Rayyan", "active": true}, {"name": "Al Wakrah", "active": true}, {"name": "Al Khor", "active": true}, {"name": "Al Shamal", "active": true}, {"name": "Umm Salal", "active": true}, {"name": "Al Daayen", "active": true}]	d4d4bc43-a9ed-468b-9d8e-0a5b442c7e92	QA	 atar	🇶🇦
Botswana	[{"name": "Central", "active": true}, {"name": "Ghanzi", "active": true}, {"name": "Kgalagadi", "active": true}, {"name": "Kgatleng", "active": true}, {"name": "Kweneng", "active": true}, {"name": "North East", "active": true}, {"name": "North West", "active": true}, {"name": "South East", "active": true}, {"name": "Southern", "active": true}]	d9749ccf-6770-4b19-9413-97931e3e3412	BO	 otswana	🇧🇴
Croatia	[{"name": "Bjelovar-Bilogora", "active": true}, {"name": "Brodsko-Posavska", "active": true}, {"name": "Dubrovnik-Neretva", "active": true}, {"name": "Istria", "active": true}, {"name": "Karlovac", "active": true}, {"name": "Koprivnica-Križevci", "active": true}, {"name": "Krapina-Zagorje", "active": true}, {"name": "Lika-Senj", "active": true}, {"name": "Međimurje", "active": true}, {"name": "Osijek-Baranja", "active": true}, {"name": "Požega-Slavonia", "active": true}, {"name": "Primorje-Gorski Kotar", "active": true}, {"name": "Šibenik-Knin", "active": true}, {"name": "Sisak-Moslavina", "active": true}, {"name": "Split-Dalmatia", "active": true}, {"name": "Varaždin", "active": true}, {"name": "Virovitica-Podravina", "active": true}, {"name": "Vukovar-Syrmia", "active": true}, {"name": "Zadar", "active": true}, {"name": "Zagreb", "active": true}, {"name": "City of Zagreb", "active": true}]	89338cbd-39b1-455c-aa89-f691f1e9f19c	CR	 roatia	🇨🇷
Romania	[{"name": "Alba", "active": true}, {"name": "Arad", "active": true}, {"name": "Arges", "active": true}, {"name": "Bacău", "active": true}, {"name": "Bihor", "active": true}, {"name": "Bistrița-Năsăud", "active": true}, {"name": "Botoșani", "active": true}, {"name": "Brașov", "active": true}, {"name": "Brăila", "active": true}, {"name": "Buzău", "active": true}, {"name": "Caraș-Severin", "active": true}, {"name": "Călărași", "active": true}, {"name": "Cluj", "active": true}, {"name": "Constanța", "active": true}, {"name": "Covasna", "active": true}, {"name": "Dâmbovița", "active": true}, {"name": "Dolj", "active": true}, {"name": "Galați", "active": true}, {"name": "Giurgiu", "active": true}, {"name": "Gorj", "active": true}, {"name": "Harghita", "active": true}, {"name": "Hunedoara", "active": true}, {"name": "Ialomița", "active": true}, {"name": "Iași", "active": true}, {"name": "Ilfov", "active": true}, {"name": "Maramureș", "active": true}, {"name": "Mehedinți", "active": true}, {"name": "Mureș", "active": true}, {"name": "Neamț", "active": true}, {"name": "Olt", "active": true}, {"name": "Prahova", "active": true}, {"name": "Satu Mare", "active": true}, {"name": "Sălaj", "active": true}, {"name": "Sibiu", "active": true}, {"name": "Suceava", "active": true}, {"name": "Teleorman", "active": true}, {"name": "Timiș", "active": true}, {"name": "Tulcea", "active": true}, {"name": "Vaslui", "active": true}, {"name": "Vâlcea", "active": true}, {"name": "Vrancea", "active": true}, {"name": "Bucharest", "active": true}]	4ec2da54-11b3-4da1-b3b4-ad39683c1d2a	RO	 omania	🇷🇴
Russia	[{"name": "Adygea", "active": true}, {"name": "Altai Republic", "active": true}, {"name": "Altai Krai", "active": true}, {"name": "Amur Oblast", "active": true}, {"name": "Arkhangelsk Oblast", "active": true}, {"name": "Astrakhan Oblast", "active": true}, {"name": "Bashkortostan", "active": true}, {"name": "Belgorod Oblast", "active": true}, {"name": "Bryansk Oblast", "active": true}, {"name": "Buryatia", "active": true}, {"name": "Chechen Republic", "active": true}, {"name": "Chelyabinsk Oblast", "active": true}, {"name": "Chukotka Autonomous Okrug", "active": true}, {"name": "Chuvash Republic", "active": true}, {"name": "Dagestan", "active": true}, {"name": "Ingushetia", "active": true}, {"name": "Irkutsk Oblast", "active": true}, {"name": "Ivanovo Oblast", "active": true}, {"name": "Jewish Autonomous Oblast", "active": true}, {"name": "Kabardino-Balkar Republic", "active": true}, {"name": "Kaliningrad Oblast", "active": true}, {"name": "Kalmykia", "active": true}, {"name": "Kaluga Oblast", "active": true}, {"name": "Kamchatka Krai", "active": true}, {"name": "Karachay-Cherkess Republic", "active": true}, {"name": "Karelia", "active": true}, {"name": "Kemerovo Oblast", "active": true}, {"name": "Khabarovsk Krai", "active": true}, {"name": "Khakassia", "active": true}, {"name": "Khanty-Mansi Autonomous Okrug", "active": true}, {"name": "Kirov Oblast", "active": true}, {"name": "Komi Republic", "active": true}, {"name": "Kostroma Oblast", "active": true}, {"name": "Krasnodar Krai", "active": true}, {"name": "Krasnoyarsk Krai", "active": true}, {"name": "Kurgan Oblast", "active": true}, {"name": "Kursk Oblast", "active": true}, {"name": "Leningrad Oblast", "active": true}, {"name": "Lipetsk Oblast", "active": true}, {"name": "Magadan Oblast", "active": true}, {"name": "Mari El Republic", "active": true}, {"name": "Mordovia", "active": true}, {"name": "Moscow", "active": true}, {"name": "Moscow Oblast", "active": true}, {"name": "Murmansk Oblast", "active": true}, {"name": "Nenets Autonomous Okrug", "active": true}, {"name": "Nizhny Novgorod Oblast", "active": true}, {"name": "North Ossetia-Alania", "active": true}, {"name": "Novgorod Oblast", "active": true}, {"name": "Novosibirsk Oblast", "active": true}, {"name": "Omsk Oblast", "active": true}, {"name": "Orel Oblast", "active": true}, {"name": "Orenburg Oblast", "active": true}, {"name": "Penza Oblast", "active": true}, {"name": "Perm Krai", "active": true}, {"name": "Primorsky Krai", "active": true}, {"name": "Pskov Oblast", "active": true}, {"name": "Rostov Oblast", "active": true}, {"name": "Ryazan Oblast", "active": true}, {"name": "Saint Petersburg", "active": true}, {"name": "Sakha Republic", "active": true}, {"name": "Sakhalin Oblast", "active": true}, {"name": "Samara Oblast", "active": true}, {"name": "Saratov Oblast", "active": true}, {"name": "Smolensk Oblast", "active": true}, {"name": "Stavropol Krai", "active": true}, {"name": "Sverdlovsk Oblast", "active": true}, {"name": "Tambov Oblast", "active": true}, {"name": "Tatarstan", "active": true}, {"name": "Tomsk Oblast", "active": true}, {"name": "Tula Oblast", "active": true}, {"name": "Tver Oblast", "active": true}, {"name": "Tyumen Oblast", "active": true}, {"name": "Udmurt Republic", "active": true}, {"name": "Ulyanovsk Oblast", "active": true}, {"name": "Vladimir Oblast", "active": true}, {"name": "Volgograd Oblast", "active": true}, {"name": "Vologda Oblast", "active": true}, {"name": "Voronezh Oblast", "active": true}, {"name": "Yamalo-Nenets Autonomous Okrug", "active": true}, {"name": "Yaroslavl Oblast", "active": true}, {"name": "Zabaykalsky Krai", "active": true}]	63ec47b3-5516-4264-b84e-7121520e8999	RU	 ussia	🇷🇺
Saint Kitts and Nevis	[{"name": "Christ Church Nichola Town", "active": true}, {"name": "Saint Anne Sandy Point", "active": true}, {"name": "Saint George Basseterre", "active": true}, {"name": "Saint George Gingerland", "active": true}, {"name": "Saint James Windward", "active": true}, {"name": "Saint John Capisterre", "active": true}, {"name": "Saint John Figtree", "active": true}, {"name": "Saint Mary Cayon", "active": true}, {"name": "Saint Paul Capisterre", "active": true}, {"name": "Saint Paul Charlestown", "active": true}, {"name": "Saint Peter Basseterre", "active": true}, {"name": "Saint Thomas Lowland", "active": true}, {"name": "Saint Thomas Middle Island", "active": true}, {"name": "Trinity Palmetto Point", "active": true}]	4007f8b1-0d47-4e24-9256-268d3431a5aa	SA	 aint itts and evis	🇸🇦
Saint Lucia	[{"name": "Anse la Raye", "active": true}, {"name": "Canaries", "active": true}, {"name": "Castries", "active": true}, {"name": "Choiseul", "active": true}, {"name": "Dauphin", "active": true}, {"name": "Dennery", "active": true}, {"name": "Gros Islet", "active": true}, {"name": "Laborie", "active": true}, {"name": "Micoud", "active": true}, {"name": "Praslin", "active": true}, {"name": "Soufrière", "active": true}, {"name": "Vieux Fort", "active": true}]	8adcb530-1272-4f88-a4ca-49a4c3628c0c	SA	 aint ucia	🇸🇦
Saint Vincent and the Grenadines	[{"name": "Charlotte", "active": true}, {"name": "Grenadines", "active": true}, {"name": "Saint Andrew", "active": true}, {"name": "Saint David", "active": true}, {"name": "Saint George", "active": true}, {"name": "Saint Patrick", "active": true}]	61a662cb-482c-42fc-8ad1-3c8582d9b038	SA	 aint incent and the renadines	🇸🇦
Samoa	[{"name": "A'ana", "active": true}, {"name": "Aiga-i-le-Tai", "active": true}, {"name": "Atua", "active": true}, {"name": "Fa'asaleleaga", "active": true}, {"name": "Gaga'emauga", "active": true}, {"name": "Gagaifomauga", "active": true}, {"name": "Palauli", "active": true}, {"name": "Satupa'itea", "active": true}, {"name": "Tuamasaga", "active": true}, {"name": "Va'a-o-Fonoti", "active": true}, {"name": "Vaisigano", "active": true}]	2098bdc7-668f-48af-aa10-e2a1373f8c72	SA	 amoa	🇸🇦
San Marino	[{"name": "Acquaviva", "active": true}, {"name": "Borgo Maggiore", "active": true}, {"name": "Chiesanuova", "active": true}, {"name": "Domagnano", "active": true}, {"name": "Faetano", "active": true}, {"name": "Fiorentino", "active": true}, {"name": "Montegiardino", "active": true}, {"name": "San Marino", "active": true}, {"name": "Serravalle", "active": true}]	11118ba9-ec4d-4427-9d81-05ff86839634	SA	 an arino	🇸🇦
Saudi Arabia	[{"name": "Al Bahah", "active": true}, {"name": "Al Jawf", "active": true}, {"name": "Al Madinah", "active": true}, {"name": "Al Qassim", "active": true}, {"name": "Ar Riyadh", "active": true}, {"name": "Asir", "active": true}, {"name": "Eastern Province", "active": true}, {"name": "Ha'il", "active": true}, {"name": "Jizan", "active": true}, {"name": "Makkah", "active": true}, {"name": "Najran", "active": true}, {"name": "Northern Borders", "active": true}, {"name": "Al Hudud ash Shamaliyah", "active": true}, {"name": "Tabuk", "active": true}]	ddbb9dc6-545b-4fba-9827-2ac324609a98	SA	 audi rabia	🇸🇦
Senegal	[{"name": "Dakar", "active": true}, {"name": "Diourbel", "active": true}, {"name": "Fatick", "active": true}, {"name": "Kaolack", "active": true}, {"name": "Kédougou", "active": true}, {"name": "Kolda", "active": true}, {"name": "Louga", "active": true}, {"name": "Matam", "active": true}, {"name": "Saint-Louis", "active": true}, {"name": "Sédhiou", "active": true}, {"name": "Tambacounda", "active": true}, {"name": "Thiès", "active": true}, {"name": "Ziguinchor", "active": true}]	d5d60cbd-4699-44b6-94ea-6468b07bceb0	SE	 enegal	🇸🇪
Brazil	[{"name": "Acre", "active": true}, {"name": "Alagoas", "active": true}, {"name": "Amapá", "active": true}, {"name": "Amazonas", "active": true}, {"name": "Bahia", "active": true}, {"name": "Ceará", "active": true}, {"name": "Distrito Federal", "active": true}, {"name": "Espírito Santo", "active": true}, {"name": "Goiás", "active": true}, {"name": "Maranhão", "active": true}, {"name": "Mato Grosso", "active": true}, {"name": "Mato Grosso do Sul", "active": true}, {"name": "Minas Gerais", "active": true}, {"name": "Pará", "active": true}, {"name": "Paraíba", "active": true}, {"name": "Paraná", "active": true}, {"name": "Pernambuco", "active": true}, {"name": "Piauí", "active": true}, {"name": "Rio de Janeiro", "active": true}, {"name": "Rio Grande do Norte", "active": true}, {"name": "Rio Grande do Sul", "active": true}, {"name": "Rondônia", "active": true}, {"name": "Roraima", "active": true}, {"name": "Santa Catarina", "active": true}, {"name": "São Paulo", "active": true}, {"name": "Sergipe", "active": true}, {"name": "Tocantins", "active": true}]	97c02d93-4dd7-40c0-a4d8-a86f5c855729	BR	 razil	🇧🇷
Brunei	[{"name": "Belait", "active": true}, {"name": "Brunei-Muara", "active": true}, {"name": "Temburong", "active": true}, {"name": "Tutong", "active": true}]	0534bfa1-9604-474c-98be-ef00d5aa9616	BR	 runei	🇧🇷
Serbia	[{"name": "Belgrade", "active": true}, {"name": "Bor", "active": true}, {"name": "Braničevo", "active": true}, {"name": "Jablanica", "active": true}, {"name": "Kolubara", "active": true}, {"name": "Mačva", "active": true}, {"name": "Moravica", "active": true}, {"name": "Nišava", "active": true}, {"name": "Pčinja", "active": true}, {"name": "Pomoravlje", "active": true}, {"name": "Raška", "active": true}, {"name": "Rasina", "active": true}, {"name": "Raš", "active": true}, {"name": "Srem", "active": true}, {"name": "Toplica", "active": true}, {"name": "Zaječar", "active": true}, {"name": "Zlatibor", "active": true}]	84fcb778-35f3-4c69-aea3-a7ceba22352c	SE	 erbia	🇸🇪
Seychelles	[{"name": "Anse aux Pins", "active": true}, {"name": "Anse Boileau", "active": true}, {"name": "Anse Etoile", "active": true}, {"name": "Anse Louis", "active": true}, {"name": "Anse Royale", "active": true}, {"name": "Baie Lazare", "active": true}, {"name": "Baie Sainte Anne", "active": true}, {"name": "Beau Vallon", "active": true}, {"name": "Bel Air", "active": true}, {"name": "Bel Ombre", "active": true}, {"name": "Cascade", "active": true}, {"name": "Glacis", "active": true}, {"name": "Grand' Anse Mahe", "active": true}, {"name": "Grand' Anse Praslin", "active": true}, {"name": "La Digue", "active": true}, {"name": "English River", "active": true}, {"name": "Mont Buxton", "active": true}, {"name": "Mont Fleuri", "active": true}, {"name": "Plaisance", "active": true}, {"name": "Pointe La Rue", "active": true}, {"name": "Port Glaud", "active": true}, {"name": "Saint Louis", "active": true}, {"name": "Takamaka", "active": true}, {"name": "Les Mamelles", "active": true}]	a805afbd-385f-4110-952a-14e99a400336	SE	 eychelles	🇸🇪
Sierra Leone	[{"name": "Eastern Province", "active": true}, {"name": "Northern Province", "active": true}, {"name": "North Western Province", "active": true}, {"name": "Southern Province", "active": true}, {"name": "Western Area", "active": true}]	abc231cf-a368-4be3-ae07-8788e550ab6d	SI	 ierra eone	🇸🇮
Singapore	[{"name": "Central Singapore", "active": true}, {"name": "North East", "active": true}, {"name": "North West", "active": true}, {"name": "South East", "active": true}, {"name": "South West", "active": true}]	e70bd3cb-5aea-4b87-8530-e450507173de	SI	 ingapore	🇸🇮
Bulgaria	[{"name": "Blagoevgrad", "active": true}, {"name": "Burgas", "active": true}, {"name": "Dobrich", "active": true}, {"name": "Gabrovo", "active": true}, {"name": "Haskovo", "active": true}, {"name": "Kardzhali", "active": true}, {"name": "Kyustendil", "active": true}, {"name": "Lovech", "active": true}, {"name": "Montana", "active": true}, {"name": "Pazardzhik", "active": true}, {"name": "Pernik", "active": true}, {"name": "Pleven", "active": true}, {"name": "Plovdiv", "active": true}, {"name": "Razgrad", "active": true}, {"name": "Ruse", "active": true}, {"name": "Shumen", "active": true}, {"name": "Silistra", "active": true}, {"name": "Sliven", "active": true}, {"name": "Smolyan", "active": true}, {"name": "Sofia", "active": true}, {"name": "Sofia City", "active": true}, {"name": "Stara Zagora", "active": true}, {"name": "Targovishte", "active": true}, {"name": "Varna", "active": true}, {"name": "Veliko Tarnovo", "active": true}, {"name": "Vidin", "active": true}, {"name": "Vratsa", "active": true}, {"name": "Yambol", "active": true}]	97b55362-1fb2-4a14-98be-479d3d784a0f	BU	 ulgaria	🇧🇺
Cuba	[{"name": "Artemisa", "active": true}, {"name": "Camagüey", "active": true}, {"name": "Ciego de Ávila", "active": true}, {"name": "Cienfuegos", "active": true}, {"name": "Granma", "active": true}, {"name": "Guantánamo", "active": true}, {"name": "Holguín", "active": true}, {"name": "Isla de la Juventud", "active": true}, {"name": "La Habana", "active": true}, {"name": "Las Tunas", "active": true}, {"name": "Matanzas", "active": true}, {"name": "Mayabeque", "active": true}, {"name": "Pinar del Río", "active": true}, {"name": "Sancti Spíritus", "active": true}, {"name": "Santiago de Cuba", "active": true}, {"name": "Villa Clara", "active": true}]	77f54496-9e1f-43e3-a45d-03c957e17817	CU	 uba	🇨🇺
Slovakia	[{"name": "Bratislava", "active": true}, {"name": "Košice", "active": true}, {"name": "Prešov", "active": true}, {"name": "Trnava", "active": true}, {"name": "Trenčín", "active": true}, {"name": "Nitra", "active": true}, {"name": "Žilina", "active": true}, {"name": "Banská Bystrica", "active": true}]	c3b86632-9056-4a96-80dc-f462bc00d014	SL	 lovakia	🇸🇱
Canada	[{"name": "Alberta", "active": true}, {"name": "British Columbia", "active": true}, {"name": "Manitoba", "active": true}, {"name": "New Brunswick", "active": true}, {"name": "Newfoundland and Labrador", "active": true}, {"name": "Nova Scotia", "active": true}, {"name": "Ontario", "active": true}, {"name": "Prince Edward Island", "active": true}, {"name": "Quebec", "active": true}, {"name": "Saskatchewan", "active": true}, {"name": "Northwest Territories", "active": true}, {"name": "Nunavut", "active": true}, {"name": "Yukon", "active": true}]	d51a8023-bd41-4758-a400-7b616b3a2957	CA	 anada	🇨🇦
Sweden	[{"name": "Blekinge", "active": true}, {"name": "Dalarna", "active": true}, {"name": "Gotland", "active": true}, {"name": "Gävleborg", "active": true}, {"name": "Halland", "active": true}, {"name": "Jämtland", "active": true}, {"name": "Jönköping", "active": true}, {"name": "Kalmar", "active": true}, {"name": "Kronoberg", "active": true}, {"name": "Norrbotten", "active": true}, {"name": "Örebro", "active": true}, {"name": "Östergötland", "active": true}, {"name": "Skåne", "active": true}, {"name": "Södermanland", "active": true}, {"name": "Uppsala", "active": true}, {"name": "Värmland", "active": true}, {"name": "Västerbotten", "active": true}, {"name": "Västernorrland", "active": true}, {"name": "Västmanland", "active": true}, {"name": "Västra Götaland", "active": true}]	0a91bdfc-92b0-4447-80b7-a3c837997086	SW	 weden	🇸🇼
Zimbabwe	[{"name": "Bulawayo", "active": true}, {"name": "Harare", "active": true}, {"name": "Manicaland", "active": true}, {"name": "Mashonaland Central", "active": true}, {"name": "Mashonaland East", "active": true}, {"name": "Mashonaland West", "active": true}, {"name": "Masvingo", "active": true}, {"name": "Matabeleland North", "active": true}, {"name": "Matabeleland South", "active": true}, {"name": "Midlands", "active": true}]	295d3e81-22bd-44c9-92e9-6c929caa9079	ZI	 imbabwe	🇿🇮
Slovenia	[{"name": "Ajdovščina", "active": true}, {"name": "Beltinci", "active": true}, {"name": "Bled", "active": true}, {"name": "Bohinj", "active": true}, {"name": "Borovnica", "active": true}, {"name": "Bovec", "active": true}, {"name": "Brda", "active": true}, {"name": "Brezovica", "active": true}, {"name": "Celje", "active": true}, {"name": "Cerklje na Gorenjskem", "active": true}, {"name": "Cerknica", "active": true}, {"name": "Cerkno", "active": true}, {"name": "Črenšovci", "active": true}, {"name": "Črnomelj", "active": true}, {"name": "Destrnik", "active": true}, {"name": "Divaca", "active": true}, {"name": "Dobrepolje", "active": true}, {"name": "Dobrova-Polhov Gradec", "active": true}, {"name": "Dol pri Ljubljani", "active": true}, {"name": "Domžale", "active": true}, {"name": "Dornava", "active": true}, {"name": "Dravograd", "active": true}, {"name": "Duplek", "active": true}, {"name": "Gorenja Vas-Poljane", "active": true}, {"name": "Gorišnica", "active": true}, {"name": "Gornja Radgona", "active": true}, {"name": "Gornji Grad", "active": true}, {"name": "Gornji Petrovci", "active": true}, {"name": "Grad", "active": true}, {"name": "Grosuplje", "active": true}, {"name": "Hajdina", "active": true}, {"name": "Hoče-Slivnica", "active": true}, {"name": "Hodoš", "active": true}, {"name": "Horjul", "active": true}, {"name": "Hrastnik", "active": true}, {"name": "Hrpelje-Kozina", "active": true}, {"name": "Idrija", "active": true}, {"name": "Ig", "active": true}, {"name": "Ilirska Bistrica", "active": true}, {"name": "Ivancna Gorica", "active": true}, {"name": "Izola", "active": true}, {"name": "Jesenice", "active": true}, {"name": "Juršinci", "active": true}, {"name": "Kamnik", "active": true}, {"name": "Kanal", "active": true}, {"name": "Kidricevo", "active": true}, {"name": "Kobarid", "active": true}, {"name": "Kobilje", "active": true}, {"name": "Kocevje", "active": true}, {"name": "Komen", "active": true}, {"name": "Komenda", "active": true}, {"name": "Koper", "active": true}, {"name": "Kozje", "active": true}, {"name": "Kranj", "active": true}, {"name": "Kranjska Gora", "active": true}, {"name": "Krizevci", "active": true}, {"name": "Krško", "active": true}, {"name": "Kungota", "active": true}, {"name": "Kuzma", "active": true}, {"name": "Laško", "active": true}, {"name": "Lenart", "active": true}, {"name": "Lendava", "active": true}, {"name": "Litija", "active": true}, {"name": "Ljubljana", "active": true}, {"name": "Ljubno", "active": true}, {"name": "Ljutomer", "active": true}, {"name": "Logatec", "active": true}, {"name": "Loška Dolina", "active": true}, {"name": "Loški Potok", "active": true}, {"name": "Lovrenc na Pohorju", "active": true}, {"name": "Luče", "active": true}, {"name": "Lukovica", "active": true}, {"name": "Majšperk", "active": true}, {"name": "Maribor", "active": true}, {"name": "Medvode", "active": true}, {"name": "Mengeš", "active": true}, {"name": "Metlika", "active": true}, {"name": "Mežica", "active": true}, {"name": "Miklavž na Dravskem Polju", "active": true}, {"name": "Mirna", "active": true}, {"name": "Mirna Peč", "active": true}, {"name": "Mislinja", "active": true}, {"name": "Mozirje", "active": true}, {"name": "Murska Sobota", "active": true}, {"name": "Muta", "active": true}, {"name": "Naklo", "active": true}, {"name": "Nazarje", "active": true}, {"name": "Nova Gorica", "active": true}, {"name": "Novo Mesto", "active": true}, {"name": "Odranci", "active": true}, {"name": "Ormož", "active": true}, {"name": "Osilnica", "active": true}, {"name": "Pesnica", "active": true}, {"name": "Piran", "active": true}, {"name": "Pivka", "active": true}, {"name": "Podčetrtek", "active": true}, {"name": "Podvelka", "active": true}, {"name": "Postojna", "active": true}, {"name": "Prebold", "active": true}, {"name": "Preddvor", "active": true}, {"name": "Prevalje", "active": true}, {"name": "Ptuj", "active": true}, {"name": "Puconci", "active": true}, {"name": "Rače-Fram", "active": true}, {"name": "Radeče", "active": true}, {"name": "Radenci", "active": true}, {"name": "Radlje ob Dravi", "active": true}, {"name": "Radovljica", "active": true}, {"name": "Ribnica", "active": true}, {"name": "Rogaška Slatina", "active": true}, {"name": "Rogašovci", "active": true}, {"name": "Rogatec", "active": true}, {"name": "Ruše", "active": true}, {"name": "Semič", "active": true}, {"name": "Šempeter-Vrtojba", "active": true}, {"name": "Selnica ob Dravi", "active": true}, {"name": "Sevnica", "active": true}, {"name": "Sežana", "active": true}, {"name": "Slovenj Gradec", "active": true}, {"name": "Slovenska Bistrica", "active": true}, {"name": "Slovenske Konjice", "active": true}, {"name": "Starše", "active": true}, {"name": "Straža", "active": true}, {"name": "Sveta Ana", "active": true}, {"name": "Sveti Jurij", "active": true}, {"name": "Sveti Tomaž", "active": true}, {"name": "Tabor", "active": true}, {"name": "Tišina", "active": true}, {"name": "Tolmin", "active": true}, {"name": "Trbovlje", "active": true}, {"name": "Trebnje", "active": true}, {"name": "Tržič", "active": true}, {"name": "Turnišče", "active": true}, {"name": "Velenje", "active": true}, {"name": "Velike Lašče", "active": true}, {"name": "Vipava", "active": true}, {"name": "Vitanje", "active": true}, {"name": "Vodice", "active": true}, {"name": "Vojnik", "active": true}, {"name": "Vransko", "active": true}, {"name": "Vrhnika", "active": true}, {"name": "Vuzenica", "active": true}, {"name": "Zagorje ob Savi", "active": true}, {"name": "Zreče", "active": true}, {"name": "Železniki", "active": true}, {"name": "Žiri", "active": true}, {"name": "Žirovnica", "active": true}, {"name": "Žužemberk", "active": true}]	6b6a2006-18aa-429b-9f5e-888e5ca2f25f	SL	 lovenia	🇸🇱
Burkina Faso	[{"name": "Balé", "active": true}, {"name": "Bam", "active": true}, {"name": "Banwa", "active": true}, {"name": "Bazèga", "active": true}, {"name": "Boucle du Mouhoun", "active": true}, {"name": "Boulgou", "active": true}, {"name": "Ganzourgou", "active": true}, {"name": "Gnagna", "active": true}, {"name": "Gourma", "active": true}, {"name": "Houet", "active": true}, {"name": "Ioba", "active": true}, {"name": "Kadiogo", "active": true}, {"name": "Kénédougou", "active": true}, {"name": "Komondjari", "active": true}, {"name": "Kompienga", "active": true}, {"name": "Kossi", "active": true}, {"name": "Koulpélogo", "active": true}, {"name": "Kouritenga", "active": true}, {"name": "Kourwéogo", "active": true}, {"name": "Léraba", "active": true}, {"name": "Loroum", "active": true}, {"name": "Mouhoun", "active": true}, {"name": "Namentenga", "active": true}, {"name": "Nayala", "active": true}, {"name": "Noumbiel", "active": true}, {"name": "Oubritenga", "active": true}, {"name": "Oudalan", "active": true}, {"name": "Passoré", "active": true}, {"name": "Poni", "active": true}, {"name": "Sanguié", "active": true}, {"name": "Sanmatenga", "active": true}, {"name": "Séno", "active": true}, {"name": "Sissili", "active": true}, {"name": "Soum", "active": true}, {"name": "Sourou", "active": true}, {"name": "Tapoa", "active": true}, {"name": "Tuy", "active": true}, {"name": "Yagha", "active": true}, {"name": "Yatenga", "active": true}, {"name": "Ziro", "active": true}, {"name": "Zondoma", "active": true}, {"name": "Zoundwéogo", "active": true}]	68f9d22e-5be6-4591-bafa-2736a761d35b	BU	 urkina aso	🇧🇺
Burundi	[{"name": "Bubanza", "active": true}, {"name": "Bujumbura Mairie", "active": true}, {"name": "Bujumbura Rural", "active": true}, {"name": "Bururi", "active": true}, {"name": "Cankuzo", "active": true}, {"name": "Cibitoke", "active": true}, {"name": "Gitega", "active": true}, {"name": "Karuzi", "active": true}, {"name": "Kayanza", "active": true}, {"name": "Kirundo", "active": true}, {"name": "Makamba", "active": true}, {"name": "Muramvya", "active": true}, {"name": "Muyinga", "active": true}, {"name": "Mwaro", "active": true}, {"name": "Ngozi", "active": true}, {"name": "Rutana", "active": true}, {"name": "Ruyigi", "active": true}]	c6a93cec-a797-4987-9cc5-1f71e98c83b1	BU	 urundi	🇧🇺
Cabo Verde	[{"name": "Boa Vista", "active": true}, {"name": "Brava", "active": true}, {"name": "Fogo", "active": true}, {"name": "Maio", "active": true}, {"name": "Sal", "active": true}, {"name": "Santiago", "active": true}, {"name": "São Nicolau", "active": true}, {"name": "São Vicente", "active": true}, {"name": "Santa Catarina", "active": true}, {"name": "Santa Cruz", "active": true}, {"name": "São Domingos", "active": true}, {"name": "São Miguel", "active": true}, {"name": "Tarrafal", "active": true}]	24d6e8ff-759f-449a-9df2-9d5852b0faf4	CA	 abo erde	🇨🇦
Cambodia	[{"name": "Banteay Meanchey", "active": true}, {"name": "Battambang", "active": true}, {"name": "Kampong Cham", "active": true}, {"name": "Kampong Chhnang", "active": true}, {"name": "Kampong Speu", "active": true}, {"name": "Kampong Thom", "active": true}, {"name": "Kampot", "active": true}, {"name": "Kandal", "active": true}, {"name": "Kep", "active": true}, {"name": "Kratié", "active": true}, {"name": "Mondulkiri", "active": true}, {"name": "Phnom Penh", "active": true}, {"name": "Preah Vihear", "active": true}, {"name": "Prey Veng", "active": true}, {"name": "Pursat", "active": true}, {"name": "Ratanakiri", "active": true}, {"name": "Siem Reap", "active": true}, {"name": "Preah Sihanouk", "active": true}, {"name": "Stung Treng", "active": true}, {"name": "Svay Rieng", "active": true}, {"name": "Takéo", "active": true}, {"name": "Oddar Meanchey", "active": true}, {"name": "Pailin", "active": true}, {"name": "Tboung Khmum", "active": true}]	fca2f83f-a834-45f2-9c62-ec00345970fd	CA	 ambodia	🇨🇦
Cameroon	[{"name": "Adamawa", "active": true}, {"name": "Centre", "active": true}, {"name": "East", "active": true}, {"name": "Far North", "active": true}, {"name": "Littoral", "active": true}, {"name": "North", "active": true}, {"name": "North-West", "active": true}, {"name": "West", "active": true}, {"name": "South", "active": true}, {"name": "South-West", "active": true}]	6f33edd7-5af3-4e08-ad75-b4d41cee7ae1	CA	 ameroon	🇨🇦
Chad	[{"name": "Bahr el Gazel", "active": true}, {"name": "Batha", "active": true}, {"name": "Biltine", "active": true}, {"name": "Borkou", "active": true}, {"name": "Chari-Baguirmi", "active": true}, {"name": "Ennedi-Est", "active": true}, {"name": "Ennedi-Ouest", "active": true}, {"name": "Guéra", "active": true}, {"name": "Hadjer-Lamis", "active": true}, {"name": "Kanem", "active": true}, {"name": "Lac", "active": true}, {"name": "Logone Occidental", "active": true}, {"name": "Logone Oriental", "active": true}, {"name": "Mayo-Kebbi Est", "active": true}, {"name": "Mayo-Kebbi Ouest", "active": true}, {"name": "Moyen-Chari", "active": true}, {"name": "N'Djamena", "active": true}, {"name": "Ouaddaï", "active": true}, {"name": "Salamat", "active": true}, {"name": "Sila", "active": true}, {"name": "Tandjilé", "active": true}, {"name": "Tibesti", "active": true}, {"name": "Wadi Fira", "active": true}]	56b28a52-6410-49c6-98dd-70eca329144d	CH	 had	🇨🇭
Chile	[{"name": "Aisén", "active": true}, {"name": "Antofagasta", "active": true}, {"name": "Araucanía", "active": true}, {"name": "Arica y Parinacota", "active": true}, {"name": "Atacama", "active": true}, {"name": "Biobío", "active": true}, {"name": "Coquimbo", "active": true}, {"name": "Los Lagos", "active": true}, {"name": "Los Ríos", "active": true}, {"name": "Magallanes", "active": true}, {"name": "Maule", "active": true}, {"name": "Metropolitana de Santiago", "active": true}, {"name": "Ñuble", "active": true}, {"name": "O'Higgins", "active": true}, {"name": "Tarapacá", "active": true}, {"name": "Valparaíso", "active": true}]	b34cbaf6-0df8-4d74-b894-792383502f65	CH	 hile	🇨🇭
China	[{"name": "Anhui", "active": true}, {"name": "Beijing", "active": true}, {"name": "Chongqing", "active": true}, {"name": "Fujian", "active": true}, {"name": "Gansu", "active": true}, {"name": "Guangdong", "active": true}, {"name": "Guangxi", "active": true}, {"name": "Guizhou", "active": true}, {"name": "Hainan", "active": true}, {"name": "Hebei", "active": true}, {"name": "Heilongjiang", "active": true}, {"name": "Henan", "active": true}, {"name": "Hubei", "active": true}, {"name": "Hunan", "active": true}, {"name": "Jiangsu", "active": true}, {"name": "Jiangxi", "active": true}, {"name": "Jilin", "active": true}, {"name": "Liaoning", "active": true}, {"name": "Macau", "active": true}, {"name": "Ningxia", "active": true}, {"name": "Qinghai", "active": true}, {"name": "Shaanxi", "active": true}, {"name": "Shandong", "active": true}, {"name": "Shanghai", "active": true}, {"name": "Shanxi", "active": true}, {"name": "Sichuan", "active": true}, {"name": "Taiwan", "active": true}, {"name": "Tianjin", "active": true}, {"name": "Tibet", "active": true}, {"name": "Xinjiang", "active": true}, {"name": "Yunnan", "active": true}, {"name": "Zhejiang", "active": true}]	7169218c-fead-4aff-aa4e-188166a5cc58	CH	 hina	🇨🇭
Colombia	[{"name": "Amazonas", "active": true}, {"name": "Antioquia", "active": true}, {"name": "Arauca", "active": true}, {"name": "Atlántico", "active": true}, {"name": "Bolívar", "active": true}, {"name": "Boyacá", "active": true}, {"name": "Caldas", "active": true}, {"name": "Caquetá", "active": true}, {"name": "Casanare", "active": true}, {"name": "Cauca", "active": true}, {"name": "Cesar", "active": true}, {"name": "Chocó", "active": true}, {"name": "Córdoba", "active": true}, {"name": "Cundinamarca", "active": true}, {"name": "Guainía", "active": true}, {"name": "Guaviare", "active": true}, {"name": "Huila", "active": true}, {"name": "La Guajira", "active": true}, {"name": "Magdalena", "active": true}, {"name": "Meta", "active": true}, {"name": "Nariño", "active": true}, {"name": "Norte de Santander", "active": true}, {"name": "Putumayo", "active": true}, {"name": "Quindío", "active": true}, {"name": "Risaralda", "active": true}, {"name": "San Andrés and Providencia", "active": true}, {"name": "Santander", "active": true}, {"name": "Sucre", "active": true}, {"name": "Tolima", "active": true}, {"name": "Valle del Cauca", "active": true}, {"name": "Vaupés", "active": true}, {"name": "Vichada", "active": true}]	8de4f239-6afe-4c88-9155-12b13073ec76	CO	 olombia	🇨🇴
Congo	[{"name": "Bouenza", "active": true}, {"name": "Cuvette", "active": true}, {"name": "Cuvette-Ouest", "active": true}, {"name": "Kouilou", "active": true}, {"name": "Lékoumou", "active": true}, {"name": "Likouala", "active": true}, {"name": "Niari", "active": true}, {"name": "Plateaux", "active": true}, {"name": "Pool", "active": true}, {"name": "Sangha", "active": true}, {"name": "Brazzaville", "active": true}, {"name": "Pointe-Noire", "active": true}]	7f18891b-ea0c-42fc-b2fe-625391be71b0	CO	 ongo	🇨🇴
Cook Islands	[{"name": "Aitutaki", "active": true}, {"name": "Atiu", "active": true}, {"name": "Mangaia", "active": true}, {"name": "Manihiki", "active": true}, {"name": "Mauke", "active": true}, {"name": "Mitiaro", "active": true}, {"name": "Palmerston", "active": true}, {"name": "Penrhyn", "active": true}, {"name": "Pukapuka", "active": true}, {"name": "Rakahanga", "active": true}, {"name": "Rarotonga", "active": true}, {"name": "San Jorge Island", "active": true}]	9b86ae69-69be-4274-8a2b-cc12c93d49ff	CO	 ook slands	🇨🇴
Costa Rica	[{"name": "Alajuela", "active": true}, {"name": "Cartago", "active": true}, {"name": "Guanacaste", "active": true}, {"name": "Heredia", "active": true}, {"name": "Limón", "active": true}, {"name": "Puntarenas", "active": true}, {"name": "San José", "active": true}]	3c66bf63-e334-4366-b0d3-318107e83a42	CO	 osta ica	🇨🇴
Côte d'Ivoire	[{"name": "Abidjan", "active": true}, {"name": "Bas-Sassandra", "active": true}, {"name": "Comoé", "active": true}, {"name": "Denguélé", "active": true}, {"name": "Dix-Huit Montagnes", "active": true}, {"name": "Fromager", "active": true}, {"name": "Lacs", "active": true}, {"name": "Lagunes", "active": true}, {"name": "Marahoué", "active": true}, {"name": "Moyen-Cavally", "active": true}, {"name": "Moyen-Comoé", "active": true}, {"name": "N'zi-Comoé", "active": true}, {"name": "Sassandra-Marahoué", "active": true}, {"name": "Savanes", "active": true}, {"name": "Sud-Bandama", "active": true}, {"name": "Vallée du Bandama", "active": true}, {"name": "Worodougou", "active": true}, {"name": "Zanzan", "active": true}]	29a249af-f7d3-41c2-a3b4-d8e8a17016db	CT	 ote d voire	🇨🇹
Cyprus	[{"name": "Famagusta", "active": true}, {"name": "Kyrenia", "active": true}, {"name": "Larnaca", "active": true}, {"name": "Limassol", "active": true}, {"name": "Nicosia", "active": true}, {"name": "Paphos", "active": true}]	87d7a18c-0032-4d33-bfb8-0b1077cb161a	CY	 yprus	🇨🇾
Dominican Republic	[{"name": "Azua", "active": true}, {"name": "Bahoruco", "active": true}, {"name": "Barahona", "active": true}, {"name": "Dajabón", "active": true}, {"name": "Distrito Nacional", "active": true}, {"name": "Duarte", "active": true}, {"name": "El Seibo", "active": true}, {"name": "Elías Piña", "active": true}, {"name": "Espaillat", "active": true}, {"name": "Hato Mayor", "active": true}, {"name": "Hermanas Mirabal", "active": true}, {"name": "Independencia", "active": true}, {"name": "La Altagracia", "active": true}, {"name": "La Romana", "active": true}, {"name": "La Vega", "active": true}, {"name": "María Trinidad Sánchez", "active": true}, {"name": "Monseñor Nouel", "active": true}, {"name": "Monte Cristi", "active": true}, {"name": "Monte Plata", "active": true}, {"name": "Pedernales", "active": true}, {"name": "Peravia", "active": true}, {"name": "Puerto Plata", "active": true}, {"name": "Samaná", "active": true}, {"name": "San Cristóbal", "active": true}, {"name": "San José de Ocoa", "active": true}, {"name": "San Juan", "active": true}, {"name": "San Pedro de Macorís", "active": true}, {"name": "Sánchez Ramírez", "active": true}, {"name": "Santiago", "active": true}, {"name": "Santiago Rodríguez", "active": true}, {"name": "Santo Domingo", "active": true}, {"name": "Valverde", "active": true}]	18519367-63c9-4940-a7b8-8724709f8d16	DO	 ominican epublic	🇩🇴
DR Congo	[{"name": "Bas-Uele", "active": true}, {"name": "Equateur", "active": true}, {"name": "Haut-Katanga", "active": true}, {"name": "Haut-Lomami", "active": true}, {"name": "Haut-Uele", "active": true}, {"name": "Ituri", "active": true}, {"name": "Kasaï", "active": true}, {"name": "Kasaï-Central", "active": true}, {"name": "Kasaï-Oriental", "active": true}, {"name": "Kinshasa", "active": true}, {"name": "Kongo Central", "active": true}, {"name": "Kwango", "active": true}, {"name": "Kwilu", "active": true}, {"name": "Lomami", "active": true}, {"name": "Lualaba", "active": true}, {"name": "Mai-Ndombe", "active": true}, {"name": "Maniema", "active": true}, {"name": "Mongala", "active": true}, {"name": "Nord-Kivu", "active": true}, {"name": "Nord-Ubangi", "active": true}, {"name": "Sankuru", "active": true}, {"name": "Sud-Kivu", "active": true}, {"name": "Sud-Ubangi", "active": true}, {"name": "Tshopo", "active": true}, {"name": "Tshuapa", "active": true}]	749f0d1f-d8aa-406c-a362-58e8ed1052ec	DR	 ongo	🇩🇷
Ecuador	[{"name": "Azuay", "active": true}, {"name": "Bolívar", "active": true}, {"name": "Cañar", "active": true}, {"name": "Carchi", "active": true}, {"name": "Chimborazo", "active": true}, {"name": "Cotopaxi", "active": true}, {"name": "El Oro", "active": true}, {"name": "Esmeraldas", "active": true}, {"name": "Galápagos", "active": true}, {"name": "Guayas", "active": true}, {"name": "Imbabura", "active": true}, {"name": "Loja", "active": true}, {"name": "Los Ríos", "active": true}, {"name": "Manabí", "active": true}, {"name": "Morona Santiago", "active": true}, {"name": "Napo", "active": true}, {"name": "Orellana", "active": true}, {"name": "Pastaza", "active": true}, {"name": "Pichincha", "active": true}, {"name": "Santa Elena", "active": true}, {"name": "Santo Domingo de los Tsáchilas", "active": true}, {"name": "Sucumbíos", "active": true}, {"name": "Tungurahua", "active": true}, {"name": "Zamora-Chinchipe", "active": true}]	b7c789df-7d67-4910-befd-be921478cf45	EC	 cuador	🇪🇨
Egypt	[{"name": "Alexandria", "active": true}, {"name": "Aswan", "active": true}, {"name": "Asyut", "active": true}, {"name": "Beheira", "active": true}, {"name": "Beni Suef", "active": true}, {"name": "Cairo", "active": true}, {"name": "Dakahlia", "active": true}, {"name": "Damietta", "active": true}, {"name": "Faiyum", "active": true}, {"name": "Gharbia", "active": true}, {"name": "Giza", "active": true}, {"name": "Ismailia", "active": true}, {"name": "Kafr el-Sheikh", "active": true}, {"name": "Luxor", "active": true}, {"name": "Matruh", "active": true}, {"name": "Minya", "active": true}, {"name": "Monufia", "active": true}, {"name": "New Valley", "active": true}, {"name": "North Sinai", "active": true}, {"name": "Port Said", "active": true}, {"name": "Qalyubia", "active": true}, {"name": "Qena", "active": true}, {"name": "Red Sea", "active": true}, {"name": "Sharqia", "active": true}, {"name": "Sohag", "active": true}, {"name": "South Sinai", "active": true}, {"name": "Suez", "active": true}]	cc8a24d7-5738-483a-a34c-f4c86cec8c23	EG	 gypt	🇪🇬
El Salvador	[{"name": "Ahuachapán", "active": true}, {"name": "Cabañas", "active": true}, {"name": "Chalatenango", "active": true}, {"name": "Cuscatlán", "active": true}, {"name": "La Libertad", "active": true}, {"name": "La Paz", "active": true}, {"name": "La Unión", "active": true}, {"name": "Morazán", "active": true}, {"name": "San Miguel", "active": true}, {"name": "San Salvador", "active": true}, {"name": "San Vicente", "active": true}, {"name": "Santa Ana", "active": true}, {"name": "Sonsonate", "active": true}, {"name": "Usulután", "active": true}]	f21c7162-f31f-47f4-af11-a91adb34f1dd	EL	 l alvador	🇪🇱
Equatorial Guinea	[{"name": "Annobón", "active": true}, {"name": "Bioko Norte", "active": true}, {"name": "Bioko Sur", "active": true}, {"name": "Centro Sur", "active": true}, {"name": "Kié-Ntem", "active": true}, {"name": "Litoral", "active": true}, {"name": "Wele-Nzas", "active": true}]	7ec5f8dd-fe58-4a3a-86fd-ae835cc4709d	EQ	 quatorial uinea	🇪🇶
Eritrea	[{"name": "Anseba", "active": true}, {"name": "Debub", "active": true}, {"name": "Debubawi K’eyyih Bahri", "active": true}, {"name": "Gash-Barka", "active": true}, {"name": "Maekel", "active": true}, {"name": "Semienawi K’eyyih Bahri", "active": true}]	dd379aa3-5a1e-4b7c-8f05-1929e7f67068	ER	 ritrea	🇪🇷
Estonia	[{"name": "Harju County", "active": true}, {"name": "Hiiu County", "active": true}, {"name": "Ida-Viru County", "active": true}, {"name": "Jõgeva County", "active": true}, {"name": "Järva County", "active": true}, {"name": "Lääne County", "active": true}, {"name": "Lääne-Viru County", "active": true}, {"name": "Põlva County", "active": true}, {"name": "Pärnu County", "active": true}, {"name": "Rapla County", "active": true}, {"name": "Saare County", "active": true}, {"name": "Tartu County", "active": true}, {"name": "Valga County", "active": true}, {"name": "Viljandi County", "active": true}, {"name": "Võru County", "active": true}]	5946fb18-b2f8-47b5-8f5a-9462a900cdd5	ES	 stonia	🇪🇸
Eswatini	[{"name": "Hhohho", "active": true}, {"name": "Lubombo", "active": true}, {"name": "Manzini", "active": true}, {"name": "Shiselweni", "active": true}]	a1b942f5-b694-4a5c-b584-0805fe2d070c	ES	 swatini	🇪🇸
Haiti	[{"name": "Artibonite", "active": true}, {"name": "Centre", "active": true}, {"name": "Grand'Anse", "active": true}, {"name": "Nippes", "active": true}, {"name": "Nord", "active": true}, {"name": "Nord-Est", "active": true}, {"name": "Nord-Ouest", "active": true}, {"name": "Ouest", "active": true}, {"name": "Sud", "active": true}, {"name": "Sud-Est", "active": true}]	2a617f46-9a48-43bc-bde1-53285593d872	HA	 aiti	🇭🇦
Ethiopia	[{"name": "Addis Ababa", "active": true}, {"name": "Afar", "active": true}, {"name": "Amhara", "active": true}, {"name": "Benishangul-Gumuz", "active": true}, {"name": "Dire Dawa", "active": true}, {"name": "Gambela", "active": true}, {"name": "Harari", "active": true}, {"name": "Oromia", "active": true}, {"name": "Sidama", "active": true}, {"name": "Somali", "active": true}, {"name": "Southern Nations, Nationalities, and Peoples' Region", "active": true}, {"name": "Tigray", "active": true}]	742f4f85-6c08-401c-9650-fd4e642f6bd2	ET	 thiopia	🇪🇹
Faeroe Islands	[{"name": "Eysturoy", "active": true}, {"name": "Klaksvík", "active": true}, {"name": "Norðoyar", "active": true}, {"name": "Sandoy", "active": true}, {"name": "Streymoy", "active": true}, {"name": "Suðuroy", "active": true}, {"name": "Vágar", "active": true}]	90ca28a1-39ac-439e-a0df-8010b092c7da	FA	 aeroe slands	🇫🇦
Falkland Islands	[{"name": "Camp", "active": true}, {"name": "East Falkland", "active": true}, {"name": "West Falkland", "active": true}]	dcf62242-d785-4a3d-8dc2-ac15f76e0662	FA	 alkland slands	🇫🇦
Fiji	[{"name": "Central Division", "active": true}, {"name": "Eastern Division", "active": true}, {"name": "Northern Division", "active": true}, {"name": "Western Division", "active": true}]	edfbebed-520c-47c8-8322-143824b60040	FI	 iji	🇫🇮
Finland	[{"name": "Åland Islands", "active": true}, {"name": "Central Finland", "active": true}, {"name": "Central Ostrobothnia", "active": true}, {"name": "Etelä-Karjala (South Karelia)", "active": true}, {"name": "Etelä-Pohjanmaa (South Ostrobothnia)", "active": true}, {"name": "Etelä-Savo (South Savo)", "active": true}, {"name": "Kainuu", "active": true}, {"name": "Kanta-Häme (Tavastia Proper)", "active": true}, {"name": "Keski-Pohjanmaa (Central Ostrobothnia)", "active": true}, {"name": "Keski-Suomi (Central Finland)", "active": true}, {"name": "Kymenlaakso", "active": true}, {"name": "Lapland", "active": true}, {"name": "Pirkanmaa", "active": true}, {"name": "Pohjanmaa (Ostrobothnia)", "active": true}, {"name": "Pohjois-Karjala (North Karelia)", "active": true}, {"name": "Pohjois-Pohjanmaa (Northern Ostrobothnia)", "active": true}, {"name": "Pohjois-Savo (Northern Savonia)", "active": true}, {"name": "Päijät-Häme", "active": true}, {"name": "Satakunta", "active": true}, {"name": "Uusimaa (Nyland)", "active": true}, {"name": "Varsinais-Suomi (Southwest Finland)", "active": true}]	5112aee2-e630-4cb6-af15-20c857bae908	FI	 inland	🇫🇮
France	[{"name": "Auvergne-Rhône-Alpes", "active": true}, {"name": "Bourgogne-Franche-Comté", "active": true}, {"name": "Brittany", "active": true}, {"name": "Centre-Val de Loire", "active": true}, {"name": "Corsica", "active": true}, {"name": "Grand Est", "active": true}, {"name": "Hauts-de-France", "active": true}, {"name": "Île-de-France", "active": true}, {"name": "Normandy", "active": true}, {"name": "Nouvelle-Aquitaine", "active": true}, {"name": "Occitanie", "active": true}, {"name": "Pays de la Loire", "active": true}, {"name": "Provence-Alpes-Côte d'Azur", "active": true}]	0ffa7d6e-6cf3-40c9-9cf3-f262057c3921	FR	 rance	🇫🇷
French Polynesia	[{"name": "Austral Islands", "active": true}, {"name": "Gambier Islands", "active": true}, {"name": "Marquesas Islands", "active": true}, {"name": "Tuamotu-Gambier", "active": true}, {"name": "Society Islands", "active": true}]	c7ac7b4d-b56a-42d2-b3c5-0ac004adb915	FR	 rench olynesia	🇫🇷
Gabon	[{"name": "Estuaire", "active": true}, {"name": "Haut-Ogooué", "active": true}, {"name": "Moyen-Ogooué", "active": true}, {"name": "Ngounié", "active": true}, {"name": "Nyanga", "active": true}, {"name": "Ogooué-Ivindo", "active": true}, {"name": "Ogooué-Lolo", "active": true}, {"name": "Ogooué-Maritime", "active": true}, {"name": "Woleu-Ntem", "active": true}]	1716eb03-5c18-4cd2-bcb0-6221a1c013dd	GA	 abon	🇬🇦
Gambia	[{"name": "Banjul", "active": true}, {"name": "Central River", "active": true}, {"name": "Lower River", "active": true}, {"name": "North Bank", "active": true}, {"name": "Upper River", "active": true}, {"name": "Western", "active": true}]	6f86c5cb-6068-4574-80fa-96ee42d72d7e	GA	 ambia	🇬🇦
Georgia	[{"name": "Abkhazia", "active": true}, {"name": "Adjara", "active": true}, {"name": "Guria", "active": true}, {"name": "Imereti", "active": true}, {"name": "Kakheti", "active": true}, {"name": "Kvemo Kartli", "active": true}, {"name": "Mtskheta-Mtianeti", "active": true}, {"name": "Racha-Lechkhumi and Kvemo Svaneti", "active": true}, {"name": "Samegrelo-Zemo Svaneti", "active": true}, {"name": "Samtskhe-Javakheti", "active": true}, {"name": "Shida Kartli", "active": true}, {"name": "Tbilisi", "active": true}]	dd5de99e-e625-49b2-9657-48e369fec9ce	GE	 eorgia	🇬🇪
Germany	[{"name": "Baden-Württemberg", "active": true}, {"name": "Bavaria", "active": true}, {"name": "Berlin", "active": true}, {"name": "Brandenburg", "active": true}, {"name": "Bremen", "active": true}, {"name": "Hamburg", "active": true}, {"name": "Hesse", "active": true}, {"name": "Lower Saxony", "active": true}, {"name": "Mecklenburg-Vorpommern", "active": true}, {"name": "North Rhine-Westphalia", "active": true}, {"name": "Rhineland-Palatinate", "active": true}, {"name": "Saarland", "active": true}, {"name": "Saxony", "active": true}, {"name": "Saxony-Anhalt", "active": true}, {"name": "Schleswig-Holstein", "active": true}, {"name": "Thuringia", "active": true}]	f8a071bb-4ca1-4919-8e08-5668b2015847	GE	 ermany	🇬🇪
Ghana	[{"name": "Ahafo", "active": true}, {"name": "Ashanti", "active": true}, {"name": "Bono", "active": true}, {"name": "Bono East", "active": true}, {"name": "Central", "active": true}, {"name": "Eastern", "active": true}, {"name": "Greater Accra", "active": true}, {"name": "North East", "active": true}, {"name": "Northern", "active": true}, {"name": "Oti", "active": true}, {"name": "Savannah", "active": true}, {"name": "Upper East", "active": true}, {"name": "Upper West", "active": true}, {"name": "Volta", "active": true}, {"name": "Western", "active": true}, {"name": "Western North", "active": true}]	0453e977-7d09-476c-ad28-5d7ede535028	GH	 hana	🇬🇭
Greece	[{"name": "Attica", "active": true}, {"name": "Central Greece", "active": true}, {"name": "Central Macedonia", "active": true}, {"name": "Crete", "active": true}, {"name": "East Macedonia and Thrace", "active": true}, {"name": "Epirus", "active": true}, {"name": "Ionian Islands", "active": true}, {"name": "North Aegean", "active": true}, {"name": "Peloponnese", "active": true}, {"name": "South Aegean", "active": true}, {"name": "Thessaly", "active": true}, {"name": "Western Greece", "active": true}, {"name": "Western Macedonia", "active": true}]	2a782423-29c4-4ff1-a5cb-a7b71d2cf724	GR	 reece	🇬🇷
Greenland	[{"name": "Avannaata", "active": true}, {"name": "Kommuneqarfik Sermersooq", "active": true}, {"name": "Qeqertalik", "active": true}, {"name": "Qeqqata", "active": true}, {"name": "Kujalleq", "active": true}]	4071959a-a1d7-478e-8d16-2f9156f53d56	GR	 reenland	🇬🇷
Honduras	[{"name": "Atlántida", "active": true}, {"name": "Choluteca", "active": true}, {"name": "Colón", "active": true}, {"name": "Comayagua", "active": true}, {"name": "Copán", "active": true}, {"name": "Cortés", "active": true}, {"name": "El Paraíso", "active": true}, {"name": "Francisco Morazán", "active": true}, {"name": "Gracias a Dios", "active": true}, {"name": "Intibucá", "active": true}, {"name": "Islas de la Bahía", "active": true}, {"name": "La Paz", "active": true}, {"name": "Lempira", "active": true}, {"name": "Ocotepeque", "active": true}, {"name": "Olancho", "active": true}, {"name": "Santa Bárbara", "active": true}, {"name": "Valle", "active": true}, {"name": "Yoro", "active": true}]	2b1d618c-1cd0-4668-89a2-ba551d4c76dd	HO	 onduras	🇭🇴
Hungary	[{"name": "Baranya", "active": true}, {"name": "Békés", "active": true}, {"name": "Borsod-Abaúj-Zemplén", "active": true}, {"name": "Csongrád-Csanád", "active": true}, {"name": "Fejér", "active": true}, {"name": "Győr-Moson-Sopron", "active": true}, {"name": "Hajdú-Bihar", "active": true}, {"name": "Heves", "active": true}, {"name": "Jász-Nagykun-Szolnok", "active": true}, {"name": "Komárom-Esztergom", "active": true}, {"name": "Nógrád", "active": true}, {"name": "Pest", "active": true}, {"name": "Somogy", "active": true}, {"name": "Szabolcs-Szatmár-Bereg", "active": true}, {"name": "Tolna", "active": true}, {"name": "Vas", "active": true}, {"name": "Veszprém", "active": true}, {"name": "Zala", "active": true}, {"name": "Budapest", "active": true}]	1651fed8-3b2b-483c-ac46-90b6a3bfdf5c	HU	 ungary	🇭🇺
Iceland	[{"name": "Capital Region", "active": true}, {"name": "Eastern Region", "active": true}, {"name": "Northeastern Region", "active": true}, {"name": "Northern Region", "active": true}, {"name": "Southern Region", "active": true}, {"name": "Western Region", "active": true}, {"name": "Westfjords", "active": true}]	745d68de-4814-416d-ba77-cea08b3c7375	IC	 celand	🇮🇨
India	[{"name": "Andhra Pradesh", "active": true}, {"name": "Arunachal Pradesh", "active": true}, {"name": "Assam", "active": true}, {"name": "Bihar", "active": true}, {"name": "Chhattisgarh", "active": true}, {"name": "Goa", "active": true}, {"name": "Gujarat", "active": true}, {"name": "Haryana", "active": true}, {"name": "Himachal Pradesh", "active": true}, {"name": "Jharkhand", "active": true}, {"name": "Karnataka", "active": true}, {"name": "Kerala", "active": true}, {"name": "Madhya Pradesh", "active": true}, {"name": "Maharashtra", "active": true}, {"name": "Manipur", "active": true}, {"name": "Meghalaya", "active": true}, {"name": "Mizoram", "active": true}, {"name": "Nagaland", "active": true}, {"name": "Odisha", "active": true}, {"name": "Punjab", "active": true}, {"name": "Rajasthan", "active": true}, {"name": "Sikkim", "active": true}, {"name": "Tamil Nadu", "active": true}, {"name": "Telangana", "active": true}, {"name": "Tripura", "active": true}, {"name": "Uttar Pradesh", "active": true}, {"name": "Uttarakhand", "active": true}, {"name": "West Bengal", "active": true}, {"name": "Andaman and Nicobar Islands", "active": true}, {"name": "Chandigarh", "active": true}, {"name": "Dadra and Nagar Haveli and Daman and Diu", "active": true}, {"name": "Delhi", "active": true}, {"name": "Jammu and Kashmir", "active": true}, {"name": "Ladakh", "active": true}, {"name": "Lakshadweep", "active": true}, {"name": "Puducherry", "active": true}]	02d93ac6-f4a4-4fcd-8b52-c8867a1f6fe0	IN	 ndia	🇮🇳
Indonesia	[{"name": "Aceh", "active": true}, {"name": "Bali", "active": true}, {"name": "Banten", "active": true}, {"name": "Bengkulu", "active": true}, {"name": "Central Java", "active": true}, {"name": "Central Kalimantan", "active": true}, {"name": "Central Sulawesi", "active": true}, {"name": "East Java", "active": true}, {"name": "East Kalimantan", "active": true}, {"name": "East Nusa Tenggara", "active": true}, {"name": "Gorontalo", "active": true}, {"name": "Jakarta", "active": true}, {"name": "Jambi", "active": true}, {"name": "Lampung", "active": true}, {"name": "Maluku", "active": true}, {"name": "North Kalimantan", "active": true}, {"name": "North Maluku", "active": true}, {"name": "North Sulawesi", "active": true}, {"name": "North Sumatra", "active": true}, {"name": "Papua", "active": true}, {"name": "Riau", "active": true}, {"name": "Riau Islands", "active": true}, {"name": "South Kalimantan", "active": true}, {"name": "South Sulawesi", "active": true}, {"name": "South Sumatra", "active": true}, {"name": "Southeast Sulawesi", "active": true}, {"name": "West Java", "active": true}, {"name": "West Kalimantan", "active": true}, {"name": "West Nusa Tenggara", "active": true}, {"name": "West Papua", "active": true}, {"name": "West Sulawesi", "active": true}, {"name": "West Sumatra", "active": true}, {"name": "Yogyakarta", "active": true}]	108ee7a3-588a-4418-b781-5ef3f0a135db	IN	 ndonesia	🇮🇳
Yemen	[{"name": "Abyan", "active": true}, {"name": "Ad Dali'", "active": true}, {"name": "Al Bayda'", "active": true}, {"name": "Al Hudaydah", "active": true}, {"name": "Al Jawf", "active": true}, {"name": "Al Mahrah", "active": true}, {"name": "Al Mahwit", "active": true}, {"name": "Amran", "active": true}, {"name": "Dhamar", "active": true}, {"name": "Hadhramaut", "active": true}, {"name": "Hajjah", "active": true}, {"name": "Ibb", "active": true}, {"name": "Lahij", "active": true}, {"name": "Ma'rib", "active": true}, {"name": "Raymah", "active": true}, {"name": "Sa'dah", "active": true}, {"name": "Sana'a", "active": true}, {"name": "Shabwah", "active": true}, {"name": "Ta'izz", "active": true}]	8a0c7794-ae2e-4cdc-a089-7080622e6e6b	YE	 emen	🇾🇪
Iran	[{"name": "Alborz", "active": true}, {"name": "Ardabil", "active": true}, {"name": "Bushehr", "active": true}, {"name": "Chaharmahal and Bakhtiari", "active": true}, {"name": "East Azerbaijan", "active": true}, {"name": "Fars", "active": true}, {"name": "Gilan", "active": true}, {"name": "Golestan", "active": true}, {"name": "Hamadan", "active": true}, {"name": "Hormozgan", "active": true}, {"name": "Ilam", "active": true}, {"name": "Isfahan", "active": true}, {"name": "Kerman", "active": true}, {"name": "Kermanshah", "active": true}, {"name": "Khuzestan", "active": true}, {"name": "Kohgiluyeh and Boyer-Ahmad", "active": true}, {"name": "Kurdistan", "active": true}, {"name": "Lorestan", "active": true}, {"name": "Markazi", "active": true}, {"name": "Mazandaran", "active": true}, {"name": "North Khorasan", "active": true}, {"name": "Qazvin", "active": true}, {"name": "Qom", "active": true}, {"name": "Razavi Khorasan", "active": true}, {"name": "Semnan", "active": true}, {"name": "Sistan and Baluchestan", "active": true}, {"name": "South Khorasan", "active": true}, {"name": "Tehran", "active": true}, {"name": "West Azerbaijan", "active": true}, {"name": "Yazd", "active": true}, {"name": "Zanjan", "active": true}]	2ad14c25-c631-4b5c-8ec5-56871616599d	IR	 ran	🇮🇷
Iraq	[{"name": "Al Anbar", "active": true}, {"name": "Al Muthanna", "active": true}, {"name": "Al-Qādisiyyah", "active": true}, {"name": "An-Najaf", "active": true}, {"name": "Arbil", "active": true}, {"name": "As-Sulaymaniyah", "active": true}, {"name": "Babil", "active": true}, {"name": "Baghdad", "active": true}, {"name": "Dahuk", "active": true}, {"name": "Dhi Qar", "active": true}, {"name": "Diyala", "active": true}, {"name": "Karbala", "active": true}, {"name": "Maysan", "active": true}, {"name": "Ninawa", "active": true}, {"name": "Al Basrah", "active": true}, {"name": "Wasit", "active": true}]	d8eb129f-fc1c-43d8-bd76-7f7169b05a15	IR	 raq	🇮🇷
Ireland	[{"name": "Carlow", "active": true}, {"name": "Cavan", "active": true}, {"name": "Clare", "active": true}, {"name": "Cork", "active": true}, {"name": "Donegal", "active": true}, {"name": "Dublin", "active": true}, {"name": "Galway", "active": true}, {"name": "Kerry", "active": true}, {"name": "Kildare", "active": true}, {"name": "Kilkenny", "active": true}, {"name": "Laois", "active": true}, {"name": "Leitrim", "active": true}, {"name": "Limerick", "active": true}, {"name": "Longford", "active": true}, {"name": "Louth", "active": true}, {"name": "Mayo", "active": true}, {"name": "Meath", "active": true}, {"name": "Monaghan", "active": true}, {"name": "Offaly", "active": true}, {"name": "Roscommon", "active": true}, {"name": "Sligo", "active": true}, {"name": "Tipperary", "active": true}, {"name": "Waterford", "active": true}, {"name": "Westmeath", "active": true}, {"name": "Wexford", "active": true}, {"name": "Wicklow", "active": true}]	280e7721-285d-45a4-a6e8-24e649cdaa92	IR	 reland	🇮🇷
Isle of Man	[{"name": "Ayre", "active": true}, {"name": "Glenfaba", "active": true}, {"name": "Middle", "active": true}, {"name": "Michael", "active": true}, {"name": "Rushen", "active": true}, {"name": "Garff", "active": true}]	37d7b2ae-c0df-4c93-9bd8-c72bcbd30417	IS	 sle of an	🇮🇸
Israel	[{"name": "Central District", "active": true}, {"name": "Haifa District", "active": true}, {"name": "Jerusalem District", "active": true}, {"name": "Northern District", "active": true}, {"name": "Southern District", "active": true}, {"name": "Tel Aviv District", "active": true}]	2c860a5e-1bf9-4f9a-beed-90ff833181fa	IS	 srael	🇮🇸
Italy	[{"name": "Abruzzo", "active": true}, {"name": "Aosta Valley", "active": true}, {"name": "Apulia", "active": true}, {"name": "Basilicata", "active": true}, {"name": "Calabria", "active": true}, {"name": "Campania", "active": true}, {"name": "Emilia-Romagna", "active": true}, {"name": "Friuli Venezia Giulia", "active": true}, {"name": "Lazio", "active": true}, {"name": "Liguria", "active": true}, {"name": "Lombardy", "active": true}, {"name": "Marche", "active": true}, {"name": "Molise", "active": true}, {"name": "Piedmont", "active": true}, {"name": "Sardinia", "active": true}, {"name": "Sicily", "active": true}, {"name": "Trentino-Alto Adige/Südtirol", "active": true}, {"name": "Tuscany", "active": true}, {"name": "Umbria", "active": true}, {"name": "Veneto", "active": true}]	28648ef8-668e-4640-af97-c1215a247bc1	IT	 taly	🇮🇹
Solomon Islands	[{"name": "Central Province", "active": true}, {"name": "Choiseul Province", "active": true}, {"name": "Guadalcanal Province", "active": true}, {"name": "Honiara", "active": true}, {"name": "Isabel Province", "active": true}, {"name": "Makira-Ulawa Province", "active": true}, {"name": "Malaita Province", "active": true}, {"name": "Rennell and Bellona Province", "active": true}, {"name": "Temotu Province", "active": true}, {"name": "Western Province", "active": true}]	6d286a8d-7d99-40cf-9beb-fa61d45e5dc0	SO	 olomon slands	🇸🇴
Somalia	[{"name": "Awdal", "active": true}, {"name": "Bakool", "active": true}, {"name": "Banaadir", "active": true}, {"name": "Bari", "active": true}, {"name": "Bay", "active": true}, {"name": "Galguduud", "active": true}, {"name": "Gedo", "active": true}, {"name": "Hiiraan", "active": true}, {"name": "Lower Juba", "active": true}, {"name": "Lower Shabelle", "active": true}, {"name": "Middle Juba", "active": true}, {"name": "Middle Shabelle", "active": true}, {"name": "Nugaal", "active": true}, {"name": "Sanaag", "active": true}, {"name": "Sool", "active": true}, {"name": "Togdheer", "active": true}, {"name": "Woqooyi Galbeed", "active": true}]	aa51ffdc-954e-40d1-a48e-908962acd267	SO	 omalia	🇸🇴
South Africa	[{"name": "Eastern Cape", "active": true}, {"name": "Free State", "active": true}, {"name": "Gauteng", "active": true}, {"name": "KwaZulu-Natal", "active": true}, {"name": "Limpopo", "active": true}, {"name": "Mpumalanga", "active": true}, {"name": "Northern Cape", "active": true}, {"name": "North West", "active": true}, {"name": "Western Cape", "active": true}]	e68280ef-60a2-4931-ad98-cf8eba52a2b5	SO	 outh frica	🇸🇴
South Korea	[{"name": "Busan", "active": true}, {"name": "Chungcheongbuk-do", "active": true}, {"name": "Chungcheongnam-do", "active": true}, {"name": "Daegu", "active": true}, {"name": "Daejeon", "active": true}, {"name": "Gangwon-do", "active": true}, {"name": "Gwangju", "active": true}, {"name": "Gyeonggi-do", "active": true}, {"name": "Gyeongsangbuk-do", "active": true}, {"name": "Gyeongsangnam-do", "active": true}, {"name": "Incheon", "active": true}, {"name": "Jeju-do", "active": true}, {"name": "Jeollabuk-do", "active": true}, {"name": "Jeollanam-do", "active": true}, {"name": "Sejong", "active": true}, {"name": "Seoul", "active": true}, {"name": "Ulsan", "active": true}]	e76b65f5-3742-417e-a739-2dd3d1f562a5	SO	 outh orea	🇸🇴
South Sudan	[{"name": "Central Equatoria", "active": true}, {"name": "Eastern Equatoria", "active": true}, {"name": "Jonglei", "active": true}, {"name": "Lakes", "active": true}, {"name": "Northern Bahr el Ghazal", "active": true}, {"name": "Unity", "active": true}, {"name": "Upper Nile", "active": true}, {"name": "Warrap", "active": true}, {"name": "Western Bahr el Ghazal", "active": true}, {"name": "Western Equatoria", "active": true}]	0c7b8a9b-a0d9-4b59-8ed1-b9e02cba6c1b	SO	 outh udan	🇸🇴
Spain	[{"name": "Andalusia", "active": true}, {"name": "Aragon", "active": true}, {"name": "Asturias", "active": true}, {"name": "Balearic Islands", "active": true}, {"name": "Basque Country", "active": true}, {"name": "Canary Islands", "active": true}, {"name": "Cantabria", "active": true}, {"name": "Castile and León", "active": true}, {"name": "Castilla-La Mancha", "active": true}, {"name": "Catalonia", "active": true}, {"name": "Community of Madrid", "active": true}, {"name": "Extremadura", "active": true}, {"name": "Galicia", "active": true}, {"name": "La Rioja", "active": true}, {"name": "Navarre", "active": true}, {"name": "Region of Murcia", "active": true}, {"name": "Valencian Community", "active": true}]	21e1a2a1-25c3-476e-9717-cbc0078f38bf	SP	 pain	🇸🇵
Sri Lanka	[{"name": "Central Province", "active": true}, {"name": "Eastern Province", "active": true}, {"name": "North Central Province", "active": true}, {"name": "Northern Province", "active": true}, {"name": "North Western Province", "active": true}, {"name": "Sabaragamuwa Province", "active": true}, {"name": "Southern Province", "active": true}, {"name": "Uva Province", "active": true}, {"name": "Western Province", "active": true}]	21c98bea-b8e3-4132-9c3c-354444fd8223	SR	 ri anka	🇸🇷
St. Vincent and the Grenadines	[{"name": "Charlotte", "active": true}, {"name": "Grenadines", "active": true}, {"name": "Saint Andrew", "active": true}, {"name": "Saint David", "active": true}, {"name": "Saint George", "active": true}, {"name": "Saint Patrick", "active": true}]	2bfebadf-8fe5-4921-ad99-32976aaf8f77	ST	 t incent and the renadines	🇸🇹
Switzerland	[{"name": "Aargau", "active": true}, {"name": "Appenzell Ausserrhoden", "active": true}, {"name": "Appenzell Innerrhoden", "active": true}, {"name": "Basel-Landschaft", "active": true}, {"name": "Basel-Stadt", "active": true}, {"name": "Bern", "active": true}, {"name": "Fribourg", "active": true}, {"name": "Geneva", "active": true}, {"name": "Glarus", "active": true}, {"name": "Graubünden", "active": true}, {"name": "Jura", "active": true}, {"name": "Lucerne", "active": true}, {"name": "Neuchâtel", "active": true}, {"name": "Nidwalden", "active": true}, {"name": "Obwalden", "active": true}, {"name": "Schaffhausen", "active": true}, {"name": "Schwyz", "active": true}, {"name": "Solothurn", "active": true}, {"name": "St. Gallen", "active": true}, {"name": "Thurgau", "active": true}, {"name": "Ticino", "active": true}, {"name": "Uri", "active": true}, {"name": "Valais", "active": true}, {"name": "Vaud", "active": true}, {"name": "Zug", "active": true}, {"name": "Zurich", "active": true}]	f81be094-151e-4ac5-aca0-ed53c18a731e	SW	 witzerland	🇸🇼
Syria	[{"name": "Al-Hasakah", "active": true}, {"name": "Al-Raqqah", "active": true}, {"name": "Aleppo", "active": true}, {"name": "Damascus", "active": true}, {"name": "Daraa", "active": true}, {"name": "Deir ez-Zor", "active": true}, {"name": "Hama", "active": true}, {"name": "Homs", "active": true}, {"name": "Idlib", "active": true}, {"name": "Latakia", "active": true}, {"name": "Quneitra", "active": true}, {"name": "Raqqa", "active": true}, {"name": "Rif Dimashq", "active": true}, {"name": "Suwayda", "active": true}, {"name": "Tartus", "active": true}]	86528fae-b31b-47f6-8d63-749252e4e31a	SY	 yria	🇸🇾
Taiwan	[{"name": "Changhua", "active": true}, {"name": "Chiayi", "active": true}, {"name": "Hsinchu", "active": true}, {"name": "Hualien", "active": true}, {"name": "Kaohsiung", "active": true}, {"name": "Keelung", "active": true}, {"name": "Kinmen", "active": true}, {"name": "Lienchiang", "active": true}, {"name": "Miaoli", "active": true}, {"name": "Nantou", "active": true}, {"name": "New Taipei", "active": true}, {"name": "Penghu", "active": true}, {"name": "Pingtung", "active": true}, {"name": "Taichung", "active": true}, {"name": "Tainan", "active": true}, {"name": "Taitung", "active": true}, {"name": "Taoyuan", "active": true}, {"name": "Yilan", "active": true}, {"name": "Yunlin", "active": true}]	45d02468-ba57-44ad-b642-5ff2f8e79fa1	TA	 aiwan	🇹🇦
Tanzania	[{"name": "Arusha", "active": true}, {"name": "Dar es Salaam", "active": true}, {"name": "Dodoma", "active": true}, {"name": "Geita", "active": true}, {"name": "Iringa", "active": true}, {"name": "Kagera", "active": true}, {"name": "Katavi", "active": true}, {"name": "Kigoma", "active": true}, {"name": "Kilimanjaro", "active": true}, {"name": "Lindi", "active": true}, {"name": "Manyara", "active": true}, {"name": "Mara", "active": true}, {"name": "Mbeya", "active": true}, {"name": "Morogoro", "active": true}, {"name": "Mtwara", "active": true}, {"name": "Mwanza", "active": true}, {"name": "Njombe", "active": true}, {"name": "Pwani", "active": true}, {"name": "Rukwa", "active": true}, {"name": "Ruvuma", "active": true}, {"name": "Shinyanga", "active": true}, {"name": "Simiyu", "active": true}, {"name": "Singida", "active": true}, {"name": "Tabora", "active": true}, {"name": "Tanga", "active": true}, {"name": "Zanzibar North", "active": true}, {"name": "Zanzibar South and Central", "active": true}, {"name": "Zanzibar West", "active": true}]	0912ed3b-6a5d-421b-aedf-52035c649bfa	TA	 anzania	🇹🇦
Thailand	[{"name": "Amnat Charoen", "active": true}, {"name": "Ang Thong", "active": true}, {"name": "Bangkok", "active": true}, {"name": "Bueng Kan", "active": true}, {"name": "Buri Ram", "active": true}, {"name": "Chachoengsao", "active": true}, {"name": "Chai Nat", "active": true}, {"name": "Chaiyaphum", "active": true}, {"name": "Chanthaburi", "active": true}, {"name": "Chiang Mai", "active": true}, {"name": "Chiang Rai", "active": true}, {"name": "Chonburi", "active": true}, {"name": "Chumphon", "active": true}, {"name": "Kalasin", "active": true}, {"name": "Kamphaeng Phet", "active": true}, {"name": "Kanchanaburi", "active": true}, {"name": "Khon Kaen", "active": true}, {"name": "Krabi", "active": true}, {"name": "Lampang", "active": true}, {"name": "Lamphun", "active": true}, {"name": "Loei", "active": true}, {"name": "Lopburi", "active": true}, {"name": "Mae Hong Son", "active": true}, {"name": "Maha Sarakham", "active": true}, {"name": "Mukdahan", "active": true}, {"name": "Nakhon Nayok", "active": true}, {"name": "Nakhon Pathom", "active": true}, {"name": "Nakhon Phanom", "active": true}, {"name": "Nakhon Ratchasima", "active": true}, {"name": "Nakhon Sawan", "active": true}, {"name": "Nakhon Si Thammarat", "active": true}, {"name": "Nan", "active": true}, {"name": "Narathiwat", "active": true}, {"name": "Nong Bua Lam Phu", "active": true}, {"name": "Nong Khai", "active": true}, {"name": "Nonthaburi", "active": true}, {"name": "Pathum Thani", "active": true}, {"name": "Pattani", "active": true}, {"name": "Phang Nga", "active": true}, {"name": "Phatthalung", "active": true}, {"name": "Phayao", "active": true}, {"name": "Phetchabun", "active": true}, {"name": "Phetchaburi", "active": true}, {"name": "Phichit", "active": true}, {"name": "Phitsanulok", "active": true}, {"name": "Phrae", "active": true}, {"name": "Phuket", "active": true}, {"name": "Prachinburi", "active": true}, {"name": "Prachuap Khiri Khan", "active": true}, {"name": "Ranong", "active": true}, {"name": "Ratchaburi", "active": true}, {"name": "Rayong", "active": true}, {"name": "Roi Et", "active": true}, {"name": "Sa Kaeo", "active": true}, {"name": "Sakon Nakhon", "active": true}, {"name": "Samut Prakan", "active": true}, {"name": "Samut Sakhon", "active": true}, {"name": "Samut Songkhram", "active": true}, {"name": "Saraburi", "active": true}, {"name": "Satun", "active": true}, {"name": "Sing Buri", "active": true}, {"name": "Sisaket", "active": true}, {"name": "Songkhla", "active": true}, {"name": "Sukhothai", "active": true}, {"name": "Suphan Buri", "active": true}, {"name": "Surat Thani", "active": true}, {"name": "Surin", "active": true}, {"name": "Tak", "active": true}, {"name": "Trang", "active": true}, {"name": "Trat", "active": true}, {"name": "Ubon Ratchathani", "active": true}, {"name": "Udon Thani", "active": true}, {"name": "Uthai Thani", "active": true}, {"name": "Uttaradit", "active": true}, {"name": "Yala", "active": true}, {"name": "Yasothon", "active": true}]	8d37e4d4-899d-412e-8c43-602c09e24583	TH	 hailand	🇹🇭
Timor-Leste	[{"name": "Aileu", "active": true}, {"name": "Ainaro", "active": true}, {"name": "Baucau", "active": true}, {"name": "Bobonaro", "active": true}, {"name": "Covalima", "active": true}, {"name": "Dili", "active": true}, {"name": "Ermera", "active": true}, {"name": "Lautém", "active": true}, {"name": "Liquiçá", "active": true}, {"name": "Manatuto", "active": true}, {"name": "Manufahi", "active": true}, {"name": "Viqueque", "active": true}]	4b0dff2b-da5b-429a-bbe2-3037298ffec3	TI	 imor este	🇹🇮
Tonga	[{"name": "Haʻapai", "active": true}, {"name": "Tongatapu", "active": true}, {"name": "Vavaʻu", "active": true}]	bad80d3a-ced1-40f8-b93c-1eb482e268b1	TO	 onga	🇹🇴
Trinidad and Tobago	[{"name": "Arima", "active": true}, {"name": "Chaguanas", "active": true}, {"name": "Couva–Tabaquite–Talparo", "active": true}, {"name": "Diego Martin", "active": true}, {"name": "Mayaro–Rio Claro", "active": true}, {"name": "Penal–Debe", "active": true}, {"name": "Point Fortin", "active": true}, {"name": "Port of Spain", "active": true}, {"name": "San Fernando", "active": true}, {"name": "San Juan–Laventille", "active": true}, {"name": "Sangre Grande", "active": true}, {"name": "Siparia", "active": true}, {"name": "Tunapuna–Piarco", "active": true}]	229eb9c3-fad9-4053-972a-3735b7c3d13b	TR	 rinidad and obago	🇹🇷
Uzbekistan	[{"name": "Andijan", "active": true}, {"name": "Bukhara", "active": true}, {"name": "Fergana", "active": true}, {"name": "Jizzakh", "active": true}, {"name": "Khorezm", "active": true}, {"name": "Kashkadarya", "active": true}, {"name": "Navoi", "active": true}, {"name": "Namangan", "active": true}, {"name": "Qashqadaryo", "active": true}, {"name": "Samarqand", "active": true}, {"name": "Sirdaryo", "active": true}, {"name": "Surxondaryo", "active": true}, {"name": "Tashkent", "active": true}, {"name": "Tashkent City", "active": true}, {"name": "Xorazm", "active": true}]	a4f4530c-36ef-4392-8f20-42ebce8c8504	UZ	 zbekistan	🇺🇿
Tunisia	[{"name": "Ariana", "active": true}, {"name": "Béja", "active": true}, {"name": "Ben Arous", "active": true}, {"name": "Bizerte", "active": true}, {"name": "Gabès", "active": true}, {"name": "Gafsa", "active": true}, {"name": "Jendouba", "active": true}, {"name": "Kairouan", "active": true}, {"name": "Kasserine", "active": true}, {"name": "Kebili", "active": true}, {"name": "La Manouba", "active": true}, {"name": "Le Kef", "active": true}, {"name": "Mahdia", "active": true}, {"name": "Médenine", "active": true}, {"name": "Monastir", "active": true}, {"name": "Nabeul", "active": true}, {"name": "Sfax", "active": true}, {"name": "Sidi Bou Zid", "active": true}, {"name": "Siliana", "active": true}, {"name": "Sousse", "active": true}, {"name": "Tataouine", "active": true}, {"name": "Tozeur", "active": true}, {"name": "Tunis", "active": true}, {"name": "Zaghouan", "active": true}]	21af0051-f225-4caa-8c98-fe97c5ee490f	TU	 unisia	🇹🇺
Turkey	[{"name": "Adana", "active": true}, {"name": "Adıyaman", "active": true}, {"name": "Afyonkarahisar", "active": true}, {"name": "Ağrı", "active": true}, {"name": "Amasya", "active": true}, {"name": "Ankara", "active": true}, {"name": "Antalya", "active": true}, {"name": "Artvin", "active": true}, {"name": "Aydın", "active": true}, {"name": "Balıkesir", "active": true}, {"name": "Bilecik", "active": true}, {"name": "Bingöl", "active": true}, {"name": "Bitlis", "active": true}, {"name": "Bolu", "active": true}, {"name": "Burdur", "active": true}, {"name": "Bursa", "active": true}, {"name": "Çanakkale", "active": true}, {"name": "Çankırı", "active": true}, {"name": "Çorum", "active": true}, {"name": "Denizli", "active": true}, {"name": "Diyarbakır", "active": true}, {"name": "Edirne", "active": true}, {"name": "Elazığ", "active": true}, {"name": "Erzincan", "active": true}, {"name": "Erzurum", "active": true}, {"name": "Eskişehir", "active": true}, {"name": "Gaziantep", "active": true}, {"name": "Giresun", "active": true}, {"name": "Gümüşhane", "active": true}, {"name": "Hakkari", "active": true}, {"name": "Hatay", "active": true}, {"name": "Iğdır", "active": true}, {"name": "Isparta", "active": true}, {"name": "Mersin", "active": true}, {"name": "İstanbul", "active": true}, {"name": "İzmir", "active": true}, {"name": "Kahramanmaraş", "active": true}, {"name": "Karabük", "active": true}, {"name": "Karaman", "active": true}, {"name": "Kars", "active": true}, {"name": "Kastamonu", "active": true}, {"name": "Kayseri", "active": true}, {"name": "Kırıkkale", "active": true}, {"name": "Kırklareli", "active": true}, {"name": "Kırşehir", "active": true}, {"name": "Kilis", "active": true}, {"name": "Kocaeli", "active": true}, {"name": "Konya", "active": true}, {"name": "Kütahya", "active": true}, {"name": "Malatya", "active": true}, {"name": "Manisa", "active": true}, {"name": "Mardin", "active": true}, {"name": "Muğla", "active": true}, {"name": "Muş", "active": true}, {"name": "Nevşehir", "active": true}, {"name": "Niğde", "active": true}, {"name": "Ordu", "active": true}, {"name": "Osmaniye", "active": true}, {"name": "Rize", "active": true}, {"name": "Sakarya", "active": true}, {"name": "Samsun", "active": true}, {"name": "Siirt", "active": true}, {"name": "Sinop", "active": true}, {"name": "Sivas", "active": true}, {"name": "Şanlıurfa", "active": true}, {"name": "Şırnak", "active": true}, {"name": "Tekirdağ", "active": true}, {"name": "Tokat", "active": true}, {"name": "Trabzon", "active": true}, {"name": "Tunceli", "active": true}, {"name": "Uşak", "active": true}, {"name": "Van", "active": true}, {"name": "Yalova", "active": true}, {"name": "Yozgat", "active": true}, {"name": "Zonguldak", "active": true}]	f3258531-2d48-41a2-806e-59a6a8745bf3	TU	 urkey	🇹🇺
Turks and Caicos Islands	[{"name": "Providenciales", "active": true}, {"name": "Grand Turk", "active": true}, {"name": "South Caicos and East Caicos", "active": true}, {"name": "North Caicos", "active": true}, {"name": "Middle Caicos", "active": true}, {"name": "Salt Cay", "active": true}]	b19591f2-2cc5-4480-ab79-f37b73c89f8f	TU	 urks and aicos slands	🇹🇺
Uganda	[{"name": "Abim", "active": true}, {"name": "Adjumani", "active": true}, {"name": "Agago", "active": true}, {"name": "Alebtong", "active": true}, {"name": "Amolatar", "active": true}, {"name": "Amudat", "active": true}, {"name": "Amuria", "active": true}, {"name": "Amuru", "active": true}, {"name": "Apac", "active": true}, {"name": "Arua", "active": true}, {"name": "Budaka", "active": true}, {"name": "Bududa", "active": true}, {"name": "Bugiri", "active": true}, {"name": "Buhweju", "active": true}, {"name": "Buikwe", "active": true}, {"name": "Bukedea", "active": true}, {"name": "Bukomansimbi", "active": true}, {"name": "Bukwo", "active": true}, {"name": "Bulambuli", "active": true}, {"name": "Buliisa", "active": true}, {"name": "Bundibugyo", "active": true}, {"name": "Bunyangabu", "active": true}, {"name": "Busia", "active": true}, {"name": "Butaleja", "active": true}, {"name": "Butambala", "active": true}, {"name": "Buvuma", "active": true}, {"name": "Buyende", "active": true}, {"name": "Dokolo", "active": true}, {"name": "Gomba", "active": true}, {"name": "Gulu", "active": true}, {"name": "Hoima", "active": true}, {"name": "Ibanda", "active": true}, {"name": "Iganga", "active": true}, {"name": "Isingiro", "active": true}, {"name": "Jinja", "active": true}, {"name": "Kaabong", "active": true}, {"name": "Kabale", "active": true}, {"name": "Kabarole", "active": true}, {"name": "Kaberamaido", "active": true}, {"name": "Kalangala", "active": true}, {"name": "Kaliro", "active": true}, {"name": "Kamuli", "active": true}, {"name": "Kamwenge", "active": true}, {"name": "Kanungu", "active": true}, {"name": "Kapchorwa", "active": true}, {"name": "Kasese", "active": true}, {"name": "Katakwi", "active": true}, {"name": "Kayunga", "active": true}, {"name": "Kibaale", "active": true}, {"name": "Kiboga", "active": true}, {"name": "Kisoro", "active": true}, {"name": "Kitgum", "active": true}, {"name": "Koboko", "active": true}, {"name": "Kole", "active": true}, {"name": "Kotido", "active": true}, {"name": "Kumi", "active": true}, {"name": "Kween", "active": true}, {"name": "Kyankwanzi", "active": true}, {"name": "Kyegegwa", "active": true}, {"name": "Kyenjojo", "active": true}, {"name": "Kyotera", "active": true}, {"name": "Lira", "active": true}, {"name": "Luuka", "active": true}, {"name": "Luwero", "active": true}, {"name": "Lyantonde", "active": true}, {"name": "Madi Okollo", "active": true}, {"name": "Manafwa", "active": true}, {"name": "Maracha", "active": true}, {"name": "Masaka", "active": true}, {"name": "Masindi", "active": true}, {"name": "Mayuge", "active": true}, {"name": "Mbale", "active": true}, {"name": "Mbarara", "active": true}, {"name": "Moroto", "active": true}, {"name": "Moyo", "active": true}, {"name": "Mpigi", "active": true}, {"name": "Mukono", "active": true}, {"name": "Nakapiripirit", "active": true}, {"name": "Nakaseke", "active": true}, {"name": "Nakasongola", "active": true}, {"name": "Namayingo", "active": true}, {"name": "Namisindwa", "active": true}, {"name": "Namutumba", "active": true}, {"name": "Napak", "active": true}, {"name": "Nebbi", "active": true}, {"name": "Ngora", "active": true}, {"name": "Ntoroko", "active": true}, {"name": "Ntungamo", "active": true}, {"name": "Nwoya", "active": true}, {"name": "Omoro", "active": true}, {"name": "Otuke", "active": true}, {"name": "Oyam", "active": true}, {"name": "Pader", "active": true}, {"name": "Pakwach", "active": true}, {"name": "Pallisa", "active": true}, {"name": "Rakai", "active": true}, {"name": "Rubirizi", "active": true}, {"name": "Sembabule", "active": true}, {"name": "Serere", "active": true}, {"name": "Sheema", "active": true}, {"name": "Sironko", "active": true}, {"name": "Soroti", "active": true}, {"name": "Tororo", "active": true}, {"name": "Wakiso", "active": true}, {"name": "Yumbe", "active": true}, {"name": "Zombo", "active": true}]	a752b741-b2ed-4c32-8bf4-85ed23c29997	UG	 ganda	🇺🇬
Ukraine	[{"name": "Cherkasy", "active": true}, {"name": "Chernihiv", "active": true}, {"name": "Chernivtsi", "active": true}, {"name": "Dnipropetrovsk", "active": true}, {"name": "Donetsk", "active": true}, {"name": "Ivano-Frankivsk", "active": true}, {"name": "Kharkiv", "active": true}, {"name": "Kherson", "active": true}, {"name": "Khmelnytskyi", "active": true}, {"name": "Kiev", "active": true}, {"name": "Kirovohrad", "active": true}, {"name": "Luhansk", "active": true}, {"name": "Lviv", "active": true}, {"name": "Mykolaiv", "active": true}, {"name": "Odessa", "active": true}, {"name": "Poltava", "active": true}, {"name": "Rivne", "active": true}, {"name": "Sumy", "active": true}, {"name": "Ternopil", "active": true}, {"name": "Vinnytsia", "active": true}, {"name": "Volyn", "active": true}, {"name": "Zakarpattia", "active": true}, {"name": "Zaporizhia", "active": true}, {"name": "Zhytomyr", "active": true}]	468670c0-d9ce-4af5-bf80-c37882f29cda	UK	 kraine	🇺🇰
United Arab Emirates	[{"name": "Abu Dhabi", "active": true}, {"name": "Ajman", "active": true}, {"name": "Dubai", "active": true}, {"name": "Fujairah", "active": true}, {"name": "Ras Al Khaimah", "active": true}, {"name": "Sharjah", "active": true}, {"name": "Umm Al Quwain", "active": true}]	490fcfac-c8ab-4741-a9b9-e45188f22f6a	UN	 nited rab mirates	🇺🇳
United States	[{"name": "Alabama", "active": true}, {"name": "Alaska", "active": true}, {"name": "Arizona", "active": true}, {"name": "Arkansas", "active": true}, {"name": "California", "active": true}, {"name": "Colorado", "active": true}, {"name": "Connecticut", "active": true}, {"name": "Delaware", "active": true}, {"name": "Florida", "active": true}, {"name": "Georgia", "active": true}, {"name": "Hawaii", "active": true}, {"name": "Idaho", "active": true}, {"name": "Illinois", "active": true}, {"name": "Indiana", "active": true}, {"name": "Iowa", "active": true}, {"name": "Kansas", "active": true}, {"name": "Kentucky", "active": true}, {"name": "Louisiana", "active": true}, {"name": "Maine", "active": true}, {"name": "Maryland", "active": true}, {"name": "Massachusetts", "active": true}, {"name": "Michigan", "active": true}, {"name": "Minnesota", "active": true}, {"name": "Mississippi", "active": true}, {"name": "Missouri", "active": true}, {"name": "Montana", "active": true}, {"name": "Nebraska", "active": true}, {"name": "Nevada", "active": true}, {"name": "New Hampshire", "active": true}, {"name": "New Jersey", "active": true}, {"name": "New Mexico", "active": true}, {"name": "New York", "active": true}, {"name": "North Carolina", "active": true}, {"name": "North Dakota", "active": true}, {"name": "Ohio", "active": true}, {"name": "Oklahoma", "active": true}, {"name": "Oregon", "active": true}, {"name": "Pennsylvania", "active": true}, {"name": "Rhode Island", "active": true}, {"name": "South Carolina", "active": true}, {"name": "South Dakota", "active": true}, {"name": "Tennessee", "active": true}, {"name": "Texas", "active": true}, {"name": "Utah", "active": true}, {"name": "Vermont", "active": true}, {"name": "Virginia", "active": true}, {"name": "Washington", "active": true}, {"name": "West Virginia", "active": true}, {"name": "Wisconsin", "active": true}, {"name": "Wyoming", "active": true}]	ccf70b0d-f3fb-4cab-a84d-95cd7255c388	UN	 nited tates	🇺🇳
\.


--
-- Data for Name: id_counters; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.id_counters (scope, last_value, updated_at) FROM stdin;
CHILD|344db9e5-9e6e-4acb-a159-c3ff0351927f|AC	6	2025-09-02 00:30:42.056504+00
CHILD|ceaa2505-2ce8-447b-96d6-f542f6d5e5f6|AT	2	2025-09-14 11:34:04.993276+00
CHILD|22e49417-7546-4033-86b9-1a516130fbf7|AU	2	2025-09-14 11:42:05.178785+00
CHILD|489f2344-da9a-4cd7-aa5e-fabf9a00eb8f|AV	2	2025-09-14 11:49:49.023079+00
SER::INDIA::TAMIL NADU::AA2::AA	2	2025-08-31 09:57:30.014138+00
ROOT::INDIA::TAMIL NADU	3	2025-08-31 10:18:56.019337+00
SER::INDIA::TAMIL NADU::AA3::AA	2	2025-08-31 10:18:56.019337+00
CHILD|05b95f61-1a0f-4ebd-b095-31f72e5879d3|AB	4	2025-09-02 09:47:30.08476+00
CHILD|701ad21c-7dce-4b90-ba73-18f539f41602|AC	6	2025-09-02 09:49:01.280102+00
CHILD|d4a83114-64c6-4a39-b22a-aa6b8fd131f5|AW	2	2025-09-14 11:51:31.940279+00
CHILD|8f3b5f8f-34ab-4238-94d0-9b13a9aa7daa|AB	2	2025-09-02 10:30:03.85827+00
CHILD|c0a673e1-dc5f-41fb-9352-272f197f8b10|AX	2	2025-09-14 11:57:53.253098+00
CHILD|5dba7010-7d45-4171-bfa7-67ae6c9fa938|AB	3	2025-09-02 10:44:28.789273+00
CHILD|73cacce7-85bd-4dea-8f86-cf24d5e99e6f|AC	2	2025-09-02 10:46:20.571157+00
CHILD|3c0c5266-623b-4c70-a9c5-bf7246a4286f|AD	2	2025-09-02 10:48:25.782035+00
CHILD|17260070-0e1b-4d35-b17c-620f17d39996|AY	2	2025-09-14 12:04:51.117724+00
CHILD|cfe066fd-63a7-4a4f-89af-f7c1195615a1|AZ	2	2025-09-14 12:13:19.032622+00
CHILD|dc4edea6-09b2-4b90-badb-a839ee2bfdf8|BA	2	2025-09-14 12:18:34.242259+00
CHILD|1be0ac53-d679-4244-8081-5c8ecd1aabe0|AB	2	2025-09-04 09:40:49.817173+00
CHILD|bdb67cbf-ded5-41b0-8c50-6f17b188bebf|BB	2	2025-09-14 13:35:00.575969+00
CHILD|199326b2-e913-43a1-80a3-0ce83ec991d2|BC	2	2025-09-15 02:02:52.406629+00
CHILD|e1f93caa-abd2-4a29-b46b-6d0f1420d7b7|AB	2	2025-09-06 00:24:24.676239+00
CHILD|6fb1e719-14f6-41a3-8d8a-8aa7c5246594|AC	2	2025-09-06 01:02:03.313333+00
CHILD|52274f44-c2fe-4d59-9134-04f0c98be5bf|AC	3	2025-09-06 11:26:34.696981+00
CHILD|64c85330-f91f-4610-9dd9-c0e7d0e9b3a4|AD	2	2025-09-06 11:30:32.35947+00
CHILD|2adbe920-e3f0-44f9-8c04-39c66e7d1bf5|AE	2	2025-09-06 11:31:55.445998+00
CHILD|45d22466-bb01-4d2d-8d28-68fe8351ea1e|AH	2	2025-09-16 10:05:45.045072+00
CHILD|bd0f39b4-e69b-41e3-962b-a962b8bd3fd2|AF	2	2025-09-06 11:33:09.24056+00
CHILD|ea44522d-3692-4404-83d7-56cc9bbe4e5a|AI	2	2025-09-16 10:37:58.741057+00
CHILD|0862006c-492e-4864-b55a-21f3a8998365|AG	2	2025-09-13 23:32:54.718261+00
CHILD|15ebf208-06c7-4ac2-a287-9df12c0794fd|AH	2	2025-09-13 23:49:50.833401+00
CHILD|34cb0dd1-b04e-4216-84a1-28afac9e4f3c|AI	2	2025-09-14 00:02:59.414389+00
CHILD|37d2ba47-1f7a-48f3-aec4-31fd0dba1b9b|AJ	2	2025-09-14 00:07:53.39902+00
CHILD|8a10f729-3015-459a-ba62-566020475c45|AK	2	2025-09-14 00:11:03.609898+00
CHILD|90aaa83c-1bbf-4d8a-9cd8-ea01a535fbc7|AL	2	2025-09-14 00:17:53.044994+00
CHILD|8c97e1c9-0c4f-4449-ad68-e3e13f0d6fb7|AM	2	2025-09-14 00:27:36.492846+00
CHILD|e91fdd47-3f20-4441-a86e-c07e0b624549|AN	2	2025-09-14 00:42:40.146703+00
CHILD|8620fdda-2b16-4250-b6cc-f4aeb82491df|AO	2	2025-09-14 00:53:07.864121+00
CHILD|5509e0b5-4525-402d-a7d6-804cc9d7b4a7|AP	2	2025-09-14 06:34:45.444833+00
CHILD|c0b03561-92a3-4b2d-8edb-c665cabcd337|AQ	2	2025-09-14 07:02:07.980016+00
CHILD|b8a88256-efa6-420e-9f43-fa1c2b1ba343|AR	2	2025-09-14 07:22:20.896249+00
CHILD|59e3d186-14a1-42ae-9116-75f2f4fff1b6|AB	2	2025-09-15 11:20:10.024691+00
CHILD|a9f53467-904a-4c44-ba15-ddad68c9884c|AS	3	2025-09-14 11:13:27.880584+00
CHILD|39e60286-b55e-4955-b465-362989276e36|AC	2	2025-09-15 14:14:03.873146+00
CHILD|7a3be462-7ecc-4ce7-9f36-ffe75fce2b3c|AD	2	2025-09-16 01:55:55.207133+00
CHILD|90a4c7b3-d9a7-496e-93d8-532661fdc65d|AE	2	2025-09-16 03:32:32.205948+00
CHILD|b3cf27ae-085b-49da-a5da-864fd85ee0eb|AF	2	2025-09-16 03:55:59.136911+00
ROOT|India|Tamil Nadu	12	2025-09-16 09:08:21.523515+00
CHILD|086f4fbd-2b7b-46d6-bf88-96f5a0724328|AB	2	2025-09-16 09:13:03.565488+00
CHILD|95e6322e-9523-4644-9144-5708b8424f61|AC	2	2025-09-16 09:26:47.712652+00
CHILD|1d31c4ca-17dd-4e9b-a95c-94e548af5b96|AD	2	2025-09-16 09:47:12.086939+00
CHILD|0f567ba1-2d5a-416c-b728-f0f19ecf3ab7|AE	2	2025-09-16 09:50:31.704078+00
CHILD|fa1ead31-b102-46f6-ab14-5518f6c263d4|AF	2	2025-09-16 09:56:51.409109+00
CHILD|12d71be8-42f9-4e43-a7c5-c7cc4a980449|AG	2	2025-09-16 10:03:28.572192+00
CHILD|6a20195f-7195-469c-97f6-a19d3f68039d|AJ	4	2025-09-16 12:20:29.635462+00
CHILD|a1d338ca-1761-4c1b-838c-d6713cc53347|AK	3	2025-09-17 11:19:02.912654+00
\.


--
-- Data for Name: iso_country_overrides; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.iso_country_overrides (country_norm, iso2) FROM stdin;
afghanistan	AF
cote d ivoire	CI
ivory coast	CI
dr congo	CD
republic of the congo	CG
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.languages (id, code, label, script, enabled, created_at, label_native, display_name, emoji_flag, country_code) FROM stdin;
c952a848-e06d-4f71-99b5-d9f1ab35dcd6	ta	Tamil	Tamil	t	2025-07-07 15:40:07.058493+00	தமிழ்	🇮🇳 Tamil (தமிழ்)	🇮🇳	IN
24da24a8-3539-4bc0-a6bd-794ed3765029	hi	Hindi	Devanagari	t	2025-07-07 15:40:07.058493+00	हिन्दी	🇮🇳 Hindi (हिन्दी)	🇮🇳	IN
4e174f89-33fb-4cf5-b9ab-2a3dae872c31	ml	Malayalam	Malayalam	t	2025-07-07 15:40:07.058493+00	മലയാളം	🇮🇳 Malayalam (മലയാളം)	🇮🇳	IN
fa613c15-5b48-4567-a0f5-591cf1be1bc9	kn	Kannada	Kannada	t	2025-07-07 15:40:07.058493+00	ಕನ್ನಡ	🇮🇳 Kannada (ಕನ್ನಡ)	🇮🇳	IN
647bd933-ed6b-4d0b-b9c6-06047848f67a	bn	Bengali	Bengali	t	2025-07-07 15:40:07.058493+00	বাংলা	🇮🇳 Bengali (বাংলা)	🇮🇳	IN
ba1f9351-2fce-409f-96b5-db68eacfc451	mr	Marathi	Devanagari	t	2025-07-07 15:40:07.058493+00	मराठी	🇮🇳 Marathi (मराठी)	🇮🇳	IN
c1a11973-8769-46aa-82bd-cbf48e7fa0ae	gu	Gujarati	Gujarati	t	2025-07-07 15:40:07.058493+00	ગુજરાતી	🇮🇳 Gujarati (ગુજરાતી)	🇮🇳	IN
39c0fbed-9f3f-430d-9680-ecbfdbee2d58	pa	Punjabi	Gurmukhi	t	2025-07-07 15:40:07.058493+00	ਪੰਜਾਬੀ	🇮🇳 Punjabi (ਪੰਜਾਬੀ)	🇮🇳	IN
e576a83a-c010-4d50-a12f-0f836e51a4f1	be	Belarusian		t	2025-07-07 16:22:15.045511+00	Беларуская	🇧🇾 Belarusian (Беларуская)	🇧🇾	UN
f6472ef7-c56c-4bde-a8fb-350e79587a50	my-MM	Burmese		t	2025-07-07 16:22:15.045511+00	မြန်မာစာ	🇲🇲 Burmese (မြန်မာစာ)	🇲🇲	UN
25f8abaa-2a91-4c30-bd18-ffdf7498cc79	ca	Catalan		t	2025-07-07 16:22:15.045511+00	Català	🇪🇸 Catalan (Català)	🇪🇸	UN
5bf89ca0-3921-41dd-9570-2250c573161d	zh-HK	Chinese (Hong Kong)		t	2025-07-07 16:22:15.045511+00	香港中文	🇭🇰 Chinese (Hong Kong) (香港中文)	🇭🇰	UN
ec9f0fc1-8e86-48f0-b04f-8458ef3cb95a	zh-CN	Chinese (Simplified)		t	2025-07-07 16:22:15.045511+00	简体中文	🇨🇳 Chinese (Simplified) (简体中文)	🇨🇳	UN
c0f357a6-f5e8-445c-a754-de6a5da49fb3	zh-TW	Chinese (Traditional)		t	2025-07-07 16:22:15.045511+00	繁體中文	🇹🇼 Chinese (Traditional) (繁體中文)	🇹🇼	UN
abbe08d7-252a-40a7-934a-29dd0d54531c	hr	Croatian		t	2025-07-07 16:22:15.045511+00	Hrvatski	🇭🇷 Croatian (Hrvatski)	🇭🇷	UN
5709251d-ca06-43a5-a428-54ba58f4a3a1	cs-CZ	Czech		t	2025-07-07 16:22:15.045511+00	Čeština	🇨🇿 Czech (Čeština)	🇨🇿	UN
f2ed93e5-7db8-4217-9ae6-6a98bfcb1a32	da-DK	Danish		t	2025-07-07 16:22:15.045511+00	Dansk	🇩🇰 Danish (Dansk)	🇩🇰	UN
f91d7195-9786-4faa-9a23-b1911f05501c	nl-NL	Dutch		t	2025-07-07 16:22:15.045511+00	Nederlands	🇳🇱 Dutch (Nederlands)	🇳🇱	UN
d4b8ee41-d988-4a1a-90c0-e66559f554a7	en-ZA	English		t	2025-07-07 16:22:15.045511+00	English	🇿🇦 English (English)	🇿🇦	UN
e43c31f8-06fe-4878-a064-8867673031ce	en-AU	English (Australia)		t	2025-07-07 16:22:15.045511+00	English	🇦🇺 English (Australia) (English)	🇦🇺	UN
dcc1b0cb-a778-4f8f-a747-ceb87ebc1f04	en-CA	English (Canada)		t	2025-07-07 16:22:15.045511+00	English	🇨🇦 English (Canada) (English)	🇨🇦	UN
c13b6eda-f060-4d19-97c1-614c887db41f	en-GB	English (United Kingdom)		t	2025-07-07 16:22:15.045511+00	English	🇬🇧 English (United Kingdom) (English)	🇬🇧	UN
11de91da-9c25-4030-9120-e728957f59c1	et	Estonian		t	2025-07-07 16:22:15.045511+00	Eesti	🇪🇪 Estonian (Eesti)	🇪🇪	UN
6fca3ccd-1b80-4778-a069-7974edb2d89f	fil	Filipino		t	2025-07-07 16:22:15.045511+00	Filipino	🇵🇭 Filipino (Filipino)	🇵🇭	UN
d6c9919c-e9ae-4328-86f3-f3f4773c5d6b	fi-FI	Finnish		t	2025-07-07 16:22:15.045511+00	Suomi	🇫🇮 Finnish (Suomi)	🇫🇮	UN
7ba04383-9b15-4fbf-82df-6cc96de1c1e8	fr-CA	French (Canada)		t	2025-07-07 16:22:15.045511+00	Français (Canada)	🇨🇦 French (Canada) (Français (Canada))	🇨🇦	UN
73e20571-7b7b-4039-90bc-acd83feb3f7d	fr-FR	French (France)		t	2025-07-07 16:22:15.045511+00	Français (France)	🇫🇷 French (France) (Français (France))	🇫🇷	UN
01b5564b-e922-4fe2-afe7-4951420c447d	gl-ES	Galician		t	2025-07-07 16:22:15.045511+00	Galego	🇪🇸 Galician (Galego)	🇪🇸	UN
d0cabd7c-c0b1-4660-ad10-a20958e08cb4	ka-GE	Georgian		t	2025-07-07 16:22:15.045511+00	ქართული	🇬🇪 Georgian (ქართული)	🇬🇪	UN
24303d18-2ee7-4736-a25e-0dc2ac75b44e	el-GR	Greek		t	2025-07-07 16:22:15.045511+00	Ελληνικά	🇬🇷 Greek (Ελληνικά)	🇬🇷	UN
ea2e53b9-8281-495a-92f5-decc6443f2ae	iw-IL	Hebrew		t	2025-07-07 16:22:15.045511+00	עברית	🇮🇱 Hebrew (עברית)	🇮🇱	UN
402aef4f-ea85-4106-b45e-04fc79ce348b	hu-HU	Hungarian		t	2025-07-07 16:22:15.045511+00	Magyar	🇭🇺 Hungarian (Magyar)	🇭🇺	UN
f64286fd-4fb5-41cf-bebf-69267b1046c0	is-IS	Icelandic		t	2025-07-07 16:22:15.045511+00	Íslenska	🇮🇸 Icelandic (Íslenska)	🇮🇸	UN
377807c3-d20c-4e71-9937-95799ed94ea7	it-IT	Italian		t	2025-07-07 16:22:15.045511+00	Italiano	🇮🇹 Italian (Italiano)	🇮🇹	UN
cff6195c-1e32-4bdd-9287-27de139908bb	kk	Kazakh		t	2025-07-07 16:22:15.045511+00	Қазақ тілі	🇰🇿 Kazakh (Қазақ тілі)	🇰🇿	UN
b4f4955a-2234-42e9-aa12-35be68617191	km-KH	Khmer		t	2025-07-07 16:22:15.045511+00	ខ្មែរ	🇰🇭 Khmer (ខ្មែរ)	🇰🇭	UN
658e8aed-f3b0-4f05-a681-7242f94a5473	ko-KR	Korean		t	2025-07-07 16:22:15.045511+00	한국어	🇰🇷 Korean (한국어)	🇰🇷	UN
1cee72bf-efcc-4fa2-b1f4-8f50a5c00985	ky-KG	Kyrgyz		t	2025-07-07 16:22:15.045511+00	Кыргызча	🇰🇬 Kyrgyz (Кыргызча)	🇰🇬	UN
5726bb41-1efb-4d7e-a5ac-7a052e48dbf0	lo-LA	Lao		t	2025-07-07 16:22:15.045511+00	ລາວ	🇱🇦 Lao (ລາວ)	🇱🇦	UN
d4dd93aa-5292-457a-8202-9db291a14ce0	lv	Latvian		t	2025-07-07 16:22:15.045511+00	Latviešu	🇱🇻 Latvian (Latviešu)	🇱🇻	UN
5f1c3f72-0e2d-4db4-b5ae-173259aee1a4	lt	Lithuanian		t	2025-07-07 16:22:15.045511+00	Lietuvių	🇱🇹 Lithuanian (Lietuvių)	🇱🇹	UN
6a3e6d0d-0ef1-405f-9a52-2298653e0db1	mk-MK	Macedonian		t	2025-07-07 16:22:15.045511+00	Македонски	🇲🇰 Macedonian (Македонски)	🇲🇰	UN
9d108f5d-f5ce-469f-9b79-9963cf414ce5	ms-MY	Malay (Malaysia)		t	2025-07-07 16:22:15.045511+00	Bahasa Malaysia	🇲🇾 Malay (Malaysia) (Bahasa Malaysia)	🇲🇾	UN
81d2fe24-b879-486b-9145-6080b4fc5bed	mr-IN	Marathi		t	2025-07-07 16:22:15.045511+00	मराठी	🇮🇳 Marathi (मराठी)	🇮🇳	IN
17f52a1c-7d47-4c8f-8a74-8de04013bcb8	mn-MN	Mongolian		t	2025-07-07 16:22:15.045511+00	Монгол хэл	🇲🇳 Mongolian (Монгол хэл)	🇲🇳	UN
a79f0c6f-9e54-4658-809f-50df17800904	ne-NP	Nepali		t	2025-07-07 16:22:15.045511+00	नेपाली	🇳🇵 Nepali (नेपाली)	🇳🇵	UN
d628a6a1-0c92-437e-a19c-371ca1e7db1c	no-NO	Norwegian		t	2025-07-07 16:22:15.045511+00	Norsk	🇳🇴 Norwegian (Norsk)	🇳🇴	UN
a2eeb1b5-0cbb-479e-99bc-dc14071060e1	fa-AE	Persian		t	2025-07-07 16:22:15.045511+00	فارسی	🇦🇪 Persian (فارسی)	🇦🇪	UN
7423d046-5880-4e92-b318-fb2dd5576d33	pl-PL	Polish		t	2025-07-07 16:22:15.045511+00	Polski	🇵🇱 Polish (Polski)	🇵🇱	UN
30b79cce-126c-494d-aaf5-033119615908	pt-BR	Portuguese (Brazil)		t	2025-07-07 16:22:15.045511+00	Português (Brasil)	🇧🇷 Portuguese (Brazil) (Português (Brasil))	🇧🇷	UN
08418b86-8d54-49cb-bed4-f0d7ae38db0b	pt-PT	Portuguese (Portugal)		t	2025-07-07 16:22:15.045511+00	Português (Portugal)	🇵🇹 Portuguese (Portugal) (Português (Portugal))	🇵🇹	UN
29c7b701-7346-4c3e-8c8a-f0cfa5d43941	ro	Romanian		t	2025-07-07 16:22:15.045511+00	Română	🇷🇴 Romanian (Română)	🇷🇴	UN
f12a4fed-b27d-486c-9cec-fe18bb510b1d	rm	Romansh		t	2025-07-07 16:22:15.045511+00	Rumantsch	🇨🇭 Romansh (Rumantsch)	🇨🇭	UN
9b4a8bba-33fc-4694-b7a6-c1c3569f6a44	ur	Urdu	Nastaliq	t	2025-07-07 15:40:07.058493+00	اردو	🇵🇰 Urdu (اردو)	🇵🇰	IN
038bff31-1cc7-47b6-a473-e756438f6d4a	ms	Malay	Latin	t	2025-07-07 15:40:07.058493+00	Bahasa Melayu	🇲🇾 Malay (Bahasa Melayu)	🇲🇾	UN
a2e4161b-88ac-47c7-8667-2e0ac0f2ea38	zh	Mandarin Chinese	Han	t	2025-07-07 16:11:14.865284+00	汉语	🇨🇳 Mandarin Chinese (汉语)	🇨🇳	UN
1898ca56-2c08-4d6f-855d-98f252e7fe1f	te	Telugu	Telugu	t	2025-07-07 16:11:14.865284+00	తెలుగు	🇮🇳 Telugu (తెలుగు)	🇮🇳	IN
8c3c576e-d4dd-46ec-b013-c15b57a0db35	az-AZ	Azerbaijani		t	2025-07-07 16:22:15.045511+00	Azərbaycan	🇦🇿 Azerbaijani (Azərbaycan)	🇦🇿	UN
40154c97-05a3-4ed4-9791-f2ee260496a6	bn-BD	Bangla		t	2025-07-07 16:22:15.045511+00	বাংলা	🇧🇩 Bangla (বাংলা)	🇧🇩	UN
58181a75-885f-4e89-b43f-29020e66dad8	eu-ES	Basque		t	2025-07-07 16:22:15.045511+00	Euskara	🇪🇸 Basque (Euskara)	🇪🇸	UN
eb9a3f1b-ac33-40ce-b948-00ddc31a464d	bg	Bulgarian		t	2025-07-07 16:22:15.045511+00	Български	🇧🇬 Bulgarian (Български)	🇧🇬	UN
f467b22b-ce9a-433e-bebd-0b7f1439ec8c	sr	Serbian		t	2025-07-07 16:22:15.045511+00	Српски	🇷🇸 Serbian (Српски)	🇷🇸	UN
72ef4813-4af5-46a1-ad8f-d59f3584aa56	si-LK	Sinhala		t	2025-07-07 16:22:15.045511+00	සිංහල	🇱🇰 Sinhala (සිංහල)	🇱🇰	UN
d037ac92-6565-4675-9441-06388034dd6b	sk	Slovak		t	2025-07-07 16:22:15.045511+00	Slovenčina	🇸🇰 Slovak (Slovenčina)	🇸🇰	UN
80813ffb-027c-40df-a050-0905b1293580	sl	Slovenian		t	2025-07-07 16:22:15.045511+00	Slovenščina	🇸🇮 Slovenian (Slovenščina)	🇸🇮	UN
69b1ef47-95d1-4b3d-93ad-2147879f2095	es-419	Spanish (Latin America)		t	2025-07-07 16:22:15.045511+00	Español (Latinoamérica)	🇲🇽 Spanish (Latin America) (Español (Latinoamérica))	🇲🇽	UN
d5912933-4460-4dfd-9d49-50766a8944ac	es	Spanish	Latin	t	2025-07-07 15:40:07.058493+00	Español	🇪🇸 Spanish (Español)	🇪🇸	UN
d93e3a16-42ab-49f0-bda9-90475ec02ee2	ar	Arabic	Arabic	t	2025-07-07 15:40:07.058493+00	العربية	🇦🇪 Arabic (العربية)	🇦🇪	UN
3886a2a1-99a4-40d8-bb17-8f5a6532cfd8	fr	French	Latin	t	2025-07-07 15:40:07.058493+00	Français	🇫🇷 French (Français)	🇫🇷	UN
ee3d4a34-c477-4fbd-9360-ecfeb2b3f24b	pt	Portuguese	Latin	t	2025-07-07 15:40:07.058493+00	Português	🇵🇹 Portuguese (Português)	🇵🇹	UN
e6e43fee-199d-4100-9cbb-ac1a5928aec3	ru	Russian	Cyrillic	t	2025-07-07 15:40:07.058493+00	Русский	🇷🇺 Russian (Русский)	🇷🇺	UN
af99af75-b7bf-46b2-96f9-ab57971d9580	id	Indonesian	Latin	t	2025-07-07 15:40:07.058493+00	Bahasa Indonesia	🇮🇩 Indonesian (Bahasa Indonesia)	🇮🇩	UN
87edfa19-fe8c-48b2-be14-43544975a694	de	German	Latin	t	2025-07-07 15:40:07.058493+00	Deutsch	🇩🇪 German (Deutsch)	🇩🇪	UN
b7853a31-c4ae-4396-9e1f-3ec6eb5e5731	ja	Japanese	Kanji	t	2025-07-07 15:40:07.058493+00	日本語	🇯🇵 Japanese (日本語)	🇯🇵	UN
fe001129-86d0-4c7b-9f42-768b5a6d8f08	arz	Egyptian Arabic	Arabic	t	2025-07-07 15:40:07.058493+00	العربية المصرية	🇪🇬 Egyptian Arabic (العربية المصرية)	🇪🇬	UN
d92341cb-fb22-4cab-b7ec-5331d9a5d0be	es-ES	Spanish (Spain)		t	2025-07-07 16:22:15.045511+00	Español (España)	🇪🇸 Spanish (Spain) (Español (España))	🇪🇸	UN
e5ee8de3-9c21-462c-a97b-2b0ea33f7247	es-US	Spanish (United States)		t	2025-07-07 16:22:15.045511+00	Español (EE.UU.)	🇺🇸 Spanish (United States) (Español (EE.UU.))	🇺🇸	UN
7da83cd4-74a4-40e5-8fb8-90ac8fed6981	sw	Swahili		t	2025-07-07 16:22:15.045511+00	Kiswahili	🇰🇪 Swahili (Kiswahili)	🇰🇪	UN
2a5bb263-4f8d-4299-a55b-f214c77ad65b	sv-SE	Swedish		t	2025-07-07 16:22:15.045511+00	Svenska	🇸🇪 Swedish (Svenska)	🇸🇪	UN
ef67ecb2-a3d1-4174-8208-822a2dc6d310	th	Thai		t	2025-07-07 16:22:15.045511+00	ไทย	🇹🇭 Thai (ไทย)	🇹🇭	UN
63d702e7-cf1c-4977-940f-4c21da774568	tr-TR	Turkish		t	2025-07-07 16:22:15.045511+00	Türkçe	🇹🇷 Turkish (Türkçe)	🇹🇷	UN
4d4bb90c-aa50-49ff-923a-2a34accf3003	uk	Ukrainian		t	2025-07-07 16:22:15.045511+00	Українська	🇺🇦 Ukrainian (Українська)	🇺🇦	UN
ee9518ce-54dd-4b73-86fc-68803b4f9ca1	vi	Vietnamese		t	2025-07-07 16:22:15.045511+00	Tiếng Việt	🇻🇳 Vietnamese (Tiếng Việt)	🇻🇳	UN
b33635c0-d196-450e-a575-8570c706f893	zu	Zulu		t	2025-07-07 16:22:15.045511+00	isiZulu	🇿🇦 Zulu (isiZulu)	🇿🇦	UN
75841aef-433c-48c8-b76d-a85cbb5c32a9	sq	Albanian		t	2025-07-07 16:30:49.956079+00	Shqip	🇦🇱 Albanian (Shqip)	🇦🇱	UN
caf49d3a-8d6e-4953-8c7a-a80c14c98691	am	Amharic		t	2025-07-07 16:30:49.956079+00	አማርኛ	🇪🇹 Amharic (አማርኛ)	🇪🇹	UN
83a05d14-a696-41ed-9a60-23bd0867f1bc	hy-AM	Armenian		t	2025-07-07 16:30:49.956079+00	Հայերեն	🇦🇲 Armenian (Հայերեն)	🇦🇲	UN
147e3624-95c2-4c88-a1c1-0b07c6f3c01c	af	Afrikaans	Afrikaans	t	2025-07-14 09:09:24.015307+00	Afrikaans	🇿🇦 Afrikaans (Afrikaans)	🇿🇦	UN
\.


--
-- Data for Name: meeting_attendance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.meeting_attendance (meeting_id, attendee_connector_id, joined_at, left_at) FROM stdin;
\.


--
-- Data for Name: meetings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.meetings (id, organizer_connector_id, title, scheduled_at, link, created_at) FROM stdin;
\.


--
-- Data for Name: pending_classifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pending_classifications (id, name, suggested_by_connector_id, country, state, variant, status, created_at) FROM stdin;
1	REFERRAL MARKETING	\N	India	Tamil Nadu	b2c	pending	2025-08-31 09:57:29.585+00
2	FURNITURE FOR IT PARKS	\N	India	Tamil Nadu	b2c	pending	2025-09-05 23:36:43.797+00
3	REFERRAL MARKETING	\N	India	Tamil Nadu	b2c	pending	2025-09-15 03:21:38.222+00
5	CUSTOMISED GENUINE LEATHER FURNITURE	\N	India	Tamil Nadu	b2b	pending	2025-09-15 11:03:49.696+00
4	REFERRAL MARKETING	\N	India	Tamil Nadu	b2c	pending	2025-09-15 03:33:16.904+00
\.


--
-- Data for Name: pincode_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pincode_rules (country, pattern, type, updated_at) FROM stdin;
India	^[1-9][0-9]{5}$	numeric	2025-07-23 01:45:04.231008+00
Bangladesh	^\\\\d{4}$	numeric	2025-07-23 01:45:04.231008+00
United States	^\\\\d{5}(-\\\\d{4})?$	numeric	2025-07-23 01:45:04.231008+00
United Kingdom	^[A-Z]{1,2}\\\\d[A-Z\\\\d]? \\\\d[A-Z]{2}$	alphanumeric	2025-07-23 01:45:04.231008+00
Canada	^[A-Z]\\\\d[A-Z] \\\\d[A-Z]\\\\d$	alphanumeric	2025-07-23 01:45:04.231008+00
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products (id, connector_id, serial_no, image_url, description, mrp, discount_percent, price, youtube_video_url, availability, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: purchase_commissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.purchase_commissions (id, buyer_connector_id, purchase_amount, discount_amount, buyer_points, created_at) FROM stdin;
\.


--
-- Data for Name: state_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.state_codes (country, state, code2) FROM stdin;
India	Tamil Nadu	TA
Bangladesh	Dhaka	DH
\.


--
-- Data for Name: translations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.translations (id, translations, created_at, language_code, base_translations, keys, language_iso_code, label_native, display_name, emoji_flag) FROM stdin;
9f3839c1-224f-4a11-a4c5-85e81e3b999c	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:22.941	basque	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	eu-ES	Euskara	🇪🇸 Basque (Euskara)	🇪🇸
88ca2984-2bbf-4cdb-a561-32b7b81bc413	{"upload_qr": "QR குறியீட்டை பதிவேற்றவும்", "enter_code": "குறியீட்டை உள்ளிடவும்", "welcome_to": "வரவேற்பு", "state_label": "மாநிலம்", "accept_terms": "நிபந்தனைகளை ஏற்கவும்", "select_state": "மாநிலத்தை தேர்ந்தெடுக்கவும்", "country_label": "நாடு", "language_label": "மொழி", "referral_valid": "பரிந்துரை குறியீடு மற்றும் மொபைல் எண் கூட்டமைப்பு சரியானது ✅", "select_country": "நாட்டை தேர்ந்தெடுக்கவும்", "continue_button": "தொடரவும்", "select_language": "மொழியை தேர்ந்தெடுக்கவும்", "validating_code": "குறியீட்டை சரிபார்க்கப்படுகிறது...", "welcome_heading": "CONNECTA-க்கு வரவேற்பு", "welcome_subtitle": "உங்கள் தொடர்புகளை முத்தமாக்குங்கள்", "validate_referral": "பரிந்துரை குறியீட்டை சரிபார்க்கவும்", "mobile_placeholder": "உங்கள் மொபைல் எண்ணை உள்ளிடவும்", "select_state_match": "தயவுசெய்து பரிந்துரை குறியீட்டின் அடிப்படையில் \\"தமிழ்நாடு\\" மாநிலத்தைத் தேர்வுசெய்க", "enter_mobile_number": "மொபைல் எண்ணை உள்ளிடவும் (நாட்டின் குறியீட்டுடன் இல்லாமல்)", "invalid_mobile_error": "தவறான மொபைல் எண்", "referral_placeholder": "பரிந்துரை குறியீட்டை உள்ளிடவும்", "terms_and_conditions": "நிபந்தனைகள் மற்றும் விதிமுறைகள்", "referral_code_invalid": "பரிந்துரை குறியீடு தவறானது", "referral_format_valid": "பரிந்துரை குறியீட்டின் வடிவம் மற்றும் தேர்வுகள் சரியானவை ✅", "join_connecta_community": "CONNECTA சமூகத்தில் சேருங்கள்", "referral_format_invalid": "பரிந்துரை குறியீடு அல்லது தேர்வுகள் தவறானவை ❌", "capitalize_your_contacts": "உங்கள் தொடர்புகளை முத்தமாக்குங்கள்", "enter_mobile_placeholder": "மொபைல் எண்ணை உள்ளிடவும் (நாட்டின் குறியீடு இல்லாமல்)", "validate_mobile_referral": "மொபைல் மற்றும் பரிந்துரை குறியீட்டை சரிபார்க்கவும்", "select_option_placeholder": "-- தேர்ந்தெடுக்கவும் --", "enter_referral_placeholder": "உங்களிடம் உள்ள  பரிந்துரை குறியீட்டை உள்ளிடவும் (உதாரணம்: India_Tamilnadu_M253540 அல்லது India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "மொபைலும் மீட்பு எண்ணும் ஒரேதாக இருக்க முடியாது"}	2025-07-14 12:51:28.557	tamil	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ta	தமிழ்	🇮🇳 Tamil (தமிழ்)	🇮🇳
ffaf8edc-1da5-41c2-b692-aad08a84bee2	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.938	latvian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	lv	Latviešu	🇱🇻 Latvian (Latviešu)	🇱🇻
2b12f701-9457-4aa6-8496-d3b78622b82e	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.003	lithuanian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	lt	Lietuvių	🇱🇹 Lithuanian (Lietuvių)	🇱🇹
75e5b36a-9fa0-473c-8419-4f9b76818bef	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.749	kyrgyz	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ky-KG	Кыргызча	🇰🇬 Kyrgyz (Кыргызча)	🇰🇬
cd48866d-0e9b-4668-9291-8569b046ed3b	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.755	hebrew	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	iw-IL	עברית	🇮🇱 Hebrew (עברית)	🇮🇱
281363c0-71fd-48af-ae99-157d09471735	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.843	lao	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	lo-LA	ລາວ	🇱🇦 Lao (ລາວ)	🇱🇦
afcbffb3-5ac2-4ed4-9bb4-5edba15f4802	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.083	macedonian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	mk-MK	Македонски	🇲🇰 Macedonian (Македонски)	🇲🇰
5e3d38d5-b31c-4816-b763-0f8d32a91b07	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.026	bengali	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	bn	বাংলা	🇮🇳 Bengali (বাংলা)	🇮🇳
1dddb0d5-1dd5-4e1d-9377-a90f29545642	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.765	danish	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	da-DK	Dansk	🇩🇰 Danish (Dansk)	🇩🇰
e08e9f9f-c8a6-48bb-9a9b-0ba62e22be2d	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:05.99	english	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	en-ZA	English	🇿🇦 English (English)	🇿🇦
231c0951-0886-43c8-a391-ae8e4ff7a10a	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:21.88	afrikaans	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	af	Afrikaans	🇿🇦 Afrikaans (Afrikaans)	🇿🇦
e6b44b72-cd62-460c-8aae-28bcc75c4b0f	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:22.538	albanian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	sq	Shqip	🇦🇱 Albanian (Shqip)	🇦🇱
05b3790a-e372-4cb8-83fa-92a514f9d50e	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.161	malay	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ms	Bahasa Melayu	🇲🇾 Malay (Bahasa Melayu)	🇲🇾
ec6a0034-4c35-47aa-80fc-ff206ac1cf7e	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:22.738	armenian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	hy-AM	Հայերեն	🇦🇲 Armenian (Հայերեն)	🇦🇲
ae89a053-4701-476e-afaf-65decc66b21b	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.194	burmese	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	my-MM	မြန်မာစာ	🇲🇲 Burmese (မြန်မာစာ)	🇲🇲
99cff182-dd8a-41a0-8a22-108d7643f98d	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:22.637	amharic	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	am	አማርኛ	🇪🇹 Amharic (አማርኛ)	🇪🇹
bfe55a51-5573-4f22-b978-470d0a28e3f0	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.683	czech	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	cs-CZ	Čeština	🇨🇿 Czech (Čeština)	🇨🇿
3390db72-da74-4d8c-9cf8-74d035293681	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.002	estonian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	et	Eesti	🇪🇪 Estonian (Eesti)	🇪🇪
85d35275-5327-4963-bf5d-6981e19e9952	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:06.608	filipino	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	fil	Filipino	🇵🇭 Filipino (Filipino)	🇵🇭
dde2f81b-e441-4aa2-928a-bf007509fa70	{"upload_qr": "QR കോഡ് അപ്‌ലോഡ് ചെയ്യുക", "enter_code": "കോഡ് നൽകുക", "state_label": "സംസ്ഥാനം", "accept_terms": "ഞാൻ നിബന്ധനകളും വ്യവസ്ഥകളും അംഗീകരിക്കുന്നു", "country_label": "രാജ്യം", "language_label": "ഭാഷ", "continue_button": "തുടരുക", "welcome_heading": "CONNECTA-വിലേക്ക് സ്വാഗതം", "welcome_subtitle": "ദയവായി നിങ്ങളുടെ QR കോഡ് അപ്‌ലോഡ് ചെയ്യുക അല്ലെങ്കിൽ റഫറൽ കോഡ് നൽകുക", "terms_and_conditions": "നിയമങ്ങളും നിബന്ധനകളും"}	2025-07-14 12:51:26.247	malayalam	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ml	മലയാളം	🇮🇳 Malayalam (മലയാളം)	🇮🇳
b88b971d-ee25-4e1b-9910-4ccfa53ac1e2	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.502	khmer	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	km-KH	ខ្មែរ	🇰🇭 Khmer (ខ្មែរ)	🇰🇭
d83ac501-e189-4d91-986e-c9d137d7a80a	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.124	bulgarian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	bg	Български	🇧🇬 Bulgarian (Български)	🇧🇬
ed0393c1-d856-4795-8656-ff5b47213e96	{"upload_qr": "QR कोड अपलोड करा", "enter_code": "कोड टाका", "state_label": "राज्य", "accept_terms": "मी नियम व अटी स्वीकारतो", "country_label": "देश", "language_label": "भाषा", "continue_button": "सुरू ठेवा", "welcome_heading": "CONNECTA मध्ये आपले स्वागत आहे", "welcome_subtitle": "कृपया आपला QR कोड अपलोड करा किंवा रेफरल कोड टाका", "terms_and_conditions": "नियम व अटी"}	2025-07-14 12:51:26.473	marathi	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	mr	मराठी	🇮🇳 Marathi (मराठी)	🇮🇳
39cd4881-6408-4301-af73-f75c013120ed	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.084	finnish	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	fi-FI	Suomi	🇫🇮 Finnish (Suomi)	🇫🇮
ae133435-d47f-4890-9ec6-e329c049d349	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.151	french	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	fr	Français	🇫🇷 French (Français)	🇫🇷
ef465c44-e315-412c-8879-6b74c3f5bd54	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.694	nigerian_pidgin	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	pcm	Naijá	Nigerian Pidgin (Naijá)	🇳🇬
588fb687-892c-4ae7-9c69-1e07a54fae66	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.513	german	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	de	Deutsch	🇩🇪 German (Deutsch)	🇩🇪
3b56d9f5-f0e5-4c95-8252-d17b7280bfc0	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.596	greek	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	el-GR	Ελληνικά	🇬🇷 Greek (Ελληνικά)	🇬🇷
ac7b1940-e55c-40bd-8d2e-f1116d61b584	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.619	romansh	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	rm	Rumantsch	🇨🇭 Romansh (Rumantsch)	🇨🇭
7578e633-3796-4baf-af3b-054e18a87549	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.287	catalan	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ca	Català	🇪🇸 Catalan (Català)	🇪🇸
8020a187-842a-4806-aef9-9b650d0df2ed	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:06.28	english (united kingdom)	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	en-GB	English	🇬🇧 English (United Kingdom) (English)	🇬🇧
a40f8a05-adb7-4df3-9455-9afd206d2660	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.546	mongolian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	mn-MN	Монгол хэл	🇲🇳 Mongolian (Монгол хэл)	🇲🇳
07bae78e-ad2a-4488-b332-4955c74b8e9b	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.626	nepali	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ne-NP	नेपाली	🇳🇵 Nepali (नेपाली)	🇳🇵
e43ef93e-7170-4b6d-bce6-588903f31ff0	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:05.811	belarusian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	be	Беларуская	🇧🇾 Belarusian (Беларуская)	🇧🇾
65a811eb-e8e6-4563-93f0-eec4775f9d98	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.103	spanish	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	es	Español	🇪🇸 Spanish (Español)	🇪🇸
27d29314-ab9a-4def-85cb-71deacd177d7	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.759	norwegian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	no-NO	Norsk	🇳🇴 Norwegian (Norsk)	🇳🇴
b92a1cf7-47e4-415b-a493-db27633f96cc	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:06.06	english (australia)	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	en-AU	English	🇦🇺 English (Australia) (English)	🇦🇺
ad7e32a0-921a-4f8d-b213-57954e03c21f	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.856	persian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	fa-AE	فارسی	🇦🇪 Persian (فارسی)	🇦🇪
2f4f2b82-d555-4313-9fd5-39f17b3da981	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:06.134	english (canada)	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	en-CA	English	🇨🇦 English (Canada) (English)	🇨🇦
c2ba59a6-49af-47b9-a753-ffeb9874797b	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.921	hungarian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	hu-HU	Magyar	🇭🇺 Hungarian (Magyar)	🇭🇺
ae65ac95-1984-4cdb-bd8a-e463f33811de	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.618	croatian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	hr	Hrvatski	🇭🇷 Croatian (Hrvatski)	🇭🇷
40a5ce6f-4bc2-4beb-bf3b-cc2d7b32397a	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.474	swedish	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	sv-SE	Svenska	🇸🇪 Swedish (Svenska)	🇸🇪
80cd0597-f724-4772-80e3-d9ac43e9310c	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.164	italian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	it-IT	Italiano	🇮🇹 Italian (Italiano)	🇮🇹
3204017e-a929-47b3-9b1c-a0616e545233	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.24	japanese	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ja	日本語	🇯🇵 Japanese (日本語)	🇯🇵
1c0f9fe4-07a2-4a5d-a4e8-ee26661ec076	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.412	kazakh	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	kk	Қазақ тілі	🇰🇿 Kazakh (Қазақ тілі)	🇰🇿
57ff975c-53f3-4992-b255-011439a94d61	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.655	korean	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ko-KR	한국어	🇰🇷 Korean (한국어)	🇰🇷
546f900e-84e6-424d-86f7-eb86dfb4365d	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.947	polish	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	pl-PL	Polski	🇵🇱 Polish (Polski)	🇵🇱
406144c7-ebe0-41b8-88dd-3b3713e0dc16	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.045	portuguese	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	pt	Português	🇵🇹 Portuguese (Português)	🇵🇹
10b11409-1aa6-4a0b-a519-ec3a33b5703f	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.954	slovak	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	sk	Slovenčina	🇸🇰 Slovak (Slovenčina)	🇸🇰
5e26df02-0292-4766-bb77-9e52d73f645d	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.429	romanian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ro	Română	🇷🇴 Romanian (Română)	🇷🇴
b880e6ec-2e28-4cc8-b209-d33c08bf94c0	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:05.595	arabic	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ar	العربية	🇦🇪 Arabic (العربية)	🇦🇪
c794f8ca-2c02-48f4-b7e4-2399b3a4b770	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.711	russian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ru	Русский	🇷🇺 Russian (Русский)	🇷🇺
3cec0d3e-e6c5-4ff3-9f05-da284d6a52ec	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.796	serbian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	sr	Српски	🇷🇸 Serbian (Српски)	🇷🇸
5c444a05-c3f2-4935-b966-dcd66913ac47	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:22.847	azerbaijani	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	az-AZ	Azərbaycan	🇦🇿 Azerbaijani (Azərbaycan)	🇦🇿
bb797ab2-baa9-4a36-8fa9-fb872e2c3611	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.028	slovenian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	sl	Slovenščina	🇸🇮 Slovenian (Slovenščina)	🇸🇮
7336582e-106c-480d-b6cd-bc0b0e1c6ac6	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:07.055	thai	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	th	ไทย	🇹🇭 Thai (ไทย)	🇹🇭
7a09ec8a-a37f-4c05-b252-83046b0d9def	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:07.198	turkish	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	tr-TR	Türkçe	🇹🇷 Turkish (Türkçe)	🇹🇷
00e88464-92f3-4315-a045-bd4c3ea81bda	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-13 12:57:07.266	ukrainian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	uk	Українська	🇺🇦 Ukrainian (Українська)	🇺🇦
60f1d39a-49ff-4425-ae59-caadc590d388	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.713	urdu	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ur	اردو	🇵🇰 Urdu (اردو)	🇵🇰
b99b6ac8-cc27-4b11-a280-cbd7be415213	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.806	vietnamese	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	vi	Tiếng Việt	🇻🇳 Vietnamese (Tiếng Việt)	🇻🇳
274a9fe2-2834-4870-a771-3791c84a3379	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.829	dutch	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	nl-NL	Nederlands	🇳🇱 Dutch (Nederlands)	🇳🇱
ee2b5de1-c36f-428e-8751-f71945745937	{"upload_qr": "QR કોડ અપલોડ કરો", "enter_code": "કોડ દાખલ કરો", "state_label": "રાજ્ય", "accept_terms": "હું નિયમો અને શરતો સ્વીકારું છું", "country_label": "દેશ", "language_label": "ભાષા", "continue_button": "ચાલુ રાખો", "welcome_heading": "CONNECTA માં આપનું સ્વાગત છે", "welcome_subtitle": "કૃપા કરીને તમારો QR કોડ અપલોડ કરો અથવા રેફરલ કોડ દાખલ કરો", "terms_and_conditions": "નિયમો અને શરતો"}	2025-07-14 12:51:24.669	gujarati	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	gu	ગુજરાતી	🇮🇳 Gujarati (ગુજરાતી)	🇮🇳
58f56eac-72c1-4e89-bf1a-07459011c9e0	{"upload_qr": "QR ಕೋಡ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ", "enter_code": "ಕೋಡ್ ನಮೂದಿಸಿ", "state_label": "ರಾಜ್ಯ", "accept_terms": "ನಾನು ನಿಯಮಗಳನ್ನು ಮತ್ತು ಶರತ್ತುಗಳನ್ನು ಒಪ್ಪಿಕೊಳ್ಳುತ್ತೇನೆ", "country_label": "ದೇಶ", "language_label": "ಭಾಷೆ", "continue_button": "ಮುಂದುವರಿಸಿ", "welcome_heading": "CONNECTA ಗೆ ಸ್ವಾಗತ", "welcome_subtitle": "ದಯವಿಟ್ಟು ನಿಮ್ಮ QR ಕೋಡ್ ಅನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ಅಥವಾ ರೆಫರಲ್ ಕೋಡ್ ಅನ್ನು ನಮೂದಿಸಿ", "terms_and_conditions": "ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು"}	2025-07-14 12:51:25.33	kannada	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	kn	ಕನ್ನಡ	🇮🇳 Kannada (ಕನ್ನಡ)	🇮🇳
e8448795-eb43-4722-aff1-754b5a0695d9	{"upload_qr": "QR কোড আপলোড করুন", "enter_code": "কোড লিখুন", "state_label": "রাজ্য", "accept_terms": "শর্তাবলী মেনে ", "country_label": "দেশ", "language_label": "ভাষা", "continue_button": "চালিয়ে যান", "welcome_heading": "CONNECTA-  কোড লিখুন কোড লিখুন", "welcome_subtitle": "আপনার QR কোড আপলোড করুন অথবা রেফারেল কোড লিখুন", "terms_and_conditions": "কোড লিখুন"}	2025-07-13 12:57:05.909	bangla	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	bn-BD	বাংলা	🇧🇩 Bangla (বাংলা)	🇧🇩
198c782f-c612-4342-b512-b22d5b0600dd	{"upload_qr": "क्यूआर कोड अपलोड करें", "enter_code": "कोड दर्ज करें", "state_label": "राज्य", "accept_terms": "मैं नियम और शर्तें स्वीकार करता हूँ", "country_label": "देश", "language_label": "भाषा", "continue_button": "जारी रखें", "welcome_heading": "CONNECTA में आपका स्वागत है", "welcome_subtitle": "कृपया अपना क्यूआर कोड अपलोड करें या रेफरल कोड दर्ज करें", "terms_and_conditions": "नियम और शर्तें"}	2025-07-14 12:51:24.838	hindi	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	hi	हिन्दी	🇮🇳 Hindi (हिन्दी)	🇮🇳
78fd0eb2-c340-46db-a473-b35417c3b171	{"upload_qr": "QR కోడ్ అప్లోడ్ చేయండి", "enter_code": "కోడ్ నమోదు చేయండి", "state_label": "రాష్ట్రం", "accept_terms": "నేను నిబంధనలు మరియు షరతులను అంగీకరిస్తున్నాను", "country_label": "దేశం", "language_label": "భాష", "continue_button": "కొనసాగించండి", "welcome_heading": "CONNECTA కి స్వాగతం", "welcome_subtitle": "దయచేసి మీ QR కోడ్‌ను అప్లోడ్ చేయండి లేదా రిఫరల్ కోడ్‌ను నమోదు చేయండి", "terms_and_conditions": "నిబంధనలు మరియు షరతులు"}	2025-07-14 12:51:28.624	telugu	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	te	తెలుగు	🇮🇳 Telugu (తెలుగు)	🇮🇳
c6e9ab7f-ea77-4b90-8795-5c1315f83e1f	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.914	egyptian_arabic	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	arz	العربية المصرية	🇪🇬 Egyptian Arabic (العربية المصرية)	🇪🇬
ded588eb-bd3f-46b0-8c1f-f2da370d3398	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.382	chinese_hk	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	zh-HK\n	香港中文	🇭🇰 Chinese (Hong Kong) (香港中文)	🇭🇰
65db5835-c840-4764-b3ce-52745f24ff9f	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.285	french_france	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	fr-FR	Français (France)	🇫🇷 French (France) (Français (France))	🇫🇷
eef69c46-6e60-4100-b7a9-2440c9f962f3	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.317	malay_malaysia	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ms-MY\n	Bahasa Malaysia	🇲🇾 Malay (Malaysia) (Bahasa Malaysia)	🇲🇾
cb61768f-b78e-4974-9b9b-93234ad57513	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.22	french_canada	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	fr-CA\n	Français (Canada)	🇨🇦 French (Canada) (Français (Canada))	🇨🇦
448c97d1-8fe4-486b-9a39-fb41c463a239	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:26.401	mandarin_chinese	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	zh\n	汉语	🇨🇳 Mandarin Chinese (汉语)	🇨🇳
1fadd6e4-c4bd-47f5-acea-d545e5b5e03d	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.14	portuguese_brazil	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	pt-BR\n	Português (Brasil)	🇧🇷 Portuguese (Brazil) (Português (Brasil))	🇧🇷
66753d43-c137-4f9c-a791-07a855078ecf	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.269	spanish_spain	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	es-ES\n	Español (España)	🇪🇸 Spanish (Spain) (Español (España))	🇪🇸
c3a862cc-8e41-434c-aae1-5d2183667a01	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.374	galician	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	gl-ES	Galego	🇪🇸 Galician (Galego)	🇪🇸
9bd07900-0a17-42b4-bd70-273aa2ec379b	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:24.442	georgian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	ka-GE	ქართული	🇬🇪 Georgian (ქართული)	🇬🇪
730420c4-9b7f-4938-9623-b3162bbb3c3d	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.449	chinese_simplified	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	zh-CN	简体中文	🇨🇳 Chinese (Simplified) (简体中文)	🇨🇳
57aa1099-b737-4f5d-8f4d-c7ca9d220718	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:23.547	chinese_traditional	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	zh-TW	繁體中文	🇹🇼 Chinese (Traditional) (繁體中文)	🇹🇼
4a36c91d-ff51-470d-8169-a27f55fb1fbb	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25	icelandic	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	is-IS	Íslenska	🇮🇸 Icelandic (Íslenska)	🇮🇸
69dd35a4-7ef2-4561-8345-8934c32da1b4	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:25.065	indonesian	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	id	Bahasa Indonesia	🇮🇩 Indonesian (Bahasa Indonesia)	🇮🇩
f4f46abb-d4d1-466d-a9f5-a8a73294eab0	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.862	sinhala	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	si-LK	සිංහල	🇱🇰 Sinhala (සිංහල)	🇱🇰
90ff10a3-2d96-4136-936c-3fd768657ced	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.185	spanish_latam	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	es-419\n	Español (Latinoamérica)	🇲🇽 Spanish (Latin America) (Español (Latinoamérica))	🇲🇽
ab8ebd12-9b8f-4a2a-b67e-1d6cd77e0c65	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.381	swahili	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	sw	Kiswahili	🇰🇪 Swahili (Kiswahili)	🇰🇪
e98579a4-6922-4076-8783-92142816ce89	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:28.897	zulu	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	zu	isiZulu	🇿🇦 Zulu (isiZulu)	🇿🇦
503199f5-7c72-4237-ae99-a9f5da0af04e	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_0825 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	2025-07-14 12:51:27.244	portuguese_portugal	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	pt-PT\n	Português (Portugal)	🇵🇹 Portuguese (Portugal) (Português (Portugal))	🇵🇹
b1cb3bc2-5e5a-408e-b53c-51921a9e1f34	{"upload_qr": "QR ਕੋਡ ਅਪਲੋਡ ਕਰੋ", "enter_code": "ਕੋਡ ਦਾਖਲ ਕਰੋ", "state_label": "ਸੂਬਾ", "accept_terms": "ਮੈਂ ਨਿਯਮਾਂ ਅਤੇ ਸ਼ਰਤਾਂ ਨੂੰ ਸਵੀਕਾਰ ਕਰਦਾ ਹਾਂ", "country_label": "ਦੇਸ਼", "language_label": "ਭਾਸ਼ਾ", "continue_button": "ਜਾਰੀ ਰੱਖੋ", "welcome_heading": "CONNECTA ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ", "welcome_subtitle": "ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ QR ਕੋਡ ਅਪਲੋਡ ਕਰੋ ਜਾਂ ਰੈਫਰਲ ਕੋਡ ਦਾਖਲ ਕਰੋ", "terms_and_conditions": "ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ"}	2025-07-14 12:51:27.354	punjabi	{"upload_qr": "Upload QR code", "enter_code": "Enter code", "welcome_to": "Welcome to", "state_label": "State", "accept_terms": "Accept terms and conditions", "select_state": "Select state", "country_label": "Country", "language_label": "Language", "referral_valid": "Referral code and mobile number combination is valid ✅", "select_country": "Select country", "continue_button": "Continue", "select_language": "Select language", "validating_code": "Validating code...", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Capitalize your contacts", "validate_referral": "Validate referral code", "mobile_placeholder": "Enter your mobile number", "select_state_match": "Please select state \\"Tamil Nadu\\" as per referral code", "enter_mobile_number": "Enter mobile number (without country code)", "invalid_mobile_error": "Invalid mobile number", "referral_placeholder": "Enter referral code", "terms_and_conditions": "Terms and conditions", "referral_code_invalid": "Referral code is invalid", "referral_format_valid": "Referral code format and selections are valid ✅", "join_connecta_community": "Join the CONNECTA community", "referral_format_invalid": "Referral code or selections invalid ❌", "capitalize_your_contacts": "Capitalize your contacts", "enter_mobile_placeholder": "Enter mobile number (without country code)", "validate_mobile_referral": "Validate mobile and referral code", "select_option_placeholder": "-- Select --", "enter_referral_placeholder": "Enter referral code (e.g. India_Tamilnadu_M253540 or India_Tamil Nadu_INTAAA00004_Mary)", "same_recovery_mobile_error": "Mobile and recovery number cannot be the same"}	["upload_qr", "enter_code", "welcome_to", "state_label", "accept_terms", "select_state", "country_label", "language_label", "select_country", "continue_button", "select_language", "validating_code", "welcome_heading", "welcome_subtitle", "validate_referral", "mobile_placeholder", "enter_mobile_number", "invalid_mobile_error", "referral_placeholder", "terms_and_conditions", "referral_code_invalid", "join_connecta_community", "capitalize_your_contacts", "validate_mobile_referral", "select_option_placeholder", "same_recovery_mobile_error", "referral_valid", "referral_format_valid", "referral_format_invalid", "select_state_match", "enter_mobile_placeholder", "enter_referral_placeholder"]	pa	ਪੰਜਾਬੀ	🇮🇳 Punjabi (ਪੰਜਾਬੀ)	🇮🇳
\.


--
-- Data for Name: translations_backup; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.translations_backup (id, translations, created_at, language_code) FROM stdin;
14457ea6-106e-4181-8003-fda8fc8161e7	{"upload_qr": "QR-Code hochladen", "enter_code": "Empfehlungscode eingeben", "state_label": "Bundesland auswählen", "accept_terms": "Ich akzeptiere die Allgemeinen Geschäftsbedingungen", "country_label": "Land auswählen", "language_label": "Sprache auswählen", "continue_button": "Weiter", "welcome_heading": "Willkommen bei CONNECTA", "welcome_subtitle": "Bitte laden Sie Ihren QR-Code hoch oder geben Sie den Empfehlungscode ein", "terms_and_conditions": "Allgemeine Geschäftsbedingungen"}	\N	de
e6b44b72-cd62-460c-8aae-28bcc75c4b0f	{"upload_qr": "Ngarko Kodin QR", "enter_code": "Shkruani Kodin e Referimit", "state_label": "Zgjidh Shtetin", "accept_terms": "Unë pranoj termat dhe kushtet", "country_label": "Zgjidh Vendin", "language_label": "Zgjidh Gjuhën", "continue_button": "Vazhdo", "welcome_heading": "Mirësevini në CONNECTA", "welcome_subtitle": "Ju lutemi ngarkoni kodin tuaj QR ose shkruani kodin e referimit", "terms_and_conditions": "Termat dhe Kushtet"}	\N	albanian
99cff182-dd8a-41a0-8a22-108d7643f98d	{"upload_qr": "QR ኮድ አስገባ", "enter_code": "የአመልካች ኮድ አስገባ", "state_label": "ግዛት ይምረጡ", "accept_terms": "እኔ ውሎችን እና አተገዳዮችን እቀበላለሁ", "country_label": "ሀገር ይምረጡ", "language_label": "ቋንቋ ይምረጡ", "continue_button": "ቀጥል", "welcome_heading": "እንኳን ወደ CONNECTA በደህና መጡ", "welcome_subtitle": "እባክዎ የእርስዎን QR ኮድ ያስገቡ ወይም የአመልካች ኮድ ያስገቡ", "terms_and_conditions": "ውሎችና አተገዳዮች"}	\N	amharic
ec6a0034-4c35-47aa-80fc-ff206ac1cf7e	{"upload_qr": "Վերբեռնել QR կոդը", "enter_code": "Մուտքագրել ուղղորդման կոդը", "state_label": "Ընտրել նահանգը", "accept_terms": "Ես ընդունում եմ պայմաններն ու դրույթները", "country_label": "Ընտրել երկիրը", "language_label": "Ընտրել լեզուն", "continue_button": "Շարունակել", "welcome_heading": "Բարի գալուստ CONNECTA", "welcome_subtitle": "Խնդրում ենք վերբեռնել ձեր QR կոդը կամ մուտքագրել ուղղորդման կոդը", "terms_and_conditions": "Պայմաններ և դրույթներ"}	\N	armenian
5c444a05-c3f2-4935-b966-dcd66913ac47	{"upload_qr": "QR Kodunu Yüklə", "enter_code": "İstinad Kodunu Daxil Et", "state_label": "Dövləti Seçin", "accept_terms": "Mən şərtləri və qaydaları qəbul edirəm", "country_label": "Ölkəni Seçin", "language_label": "Dili Seçin", "continue_button": "Davam et", "welcome_heading": "CONNECTA-ya xoş gəlmisiniz", "welcome_subtitle": "Zəhmət olmasa QR kodunuzu yükləyin və ya istinad kodunu daxil edin", "terms_and_conditions": "Şərtlər və Qaydalar"}	\N	azerbaijani
9f3839c1-224f-4a11-a4c5-85e81e3b999c	{"upload_qr": "Igo QR kodea", "enter_code": "Sartu Erreferentzia Kodea", "state_label": "Hautatu Estatua", "accept_terms": "Baldintzak onartzen ditut", "country_label": "Hautatu Herrialdea", "language_label": "Hautatu Hizkuntza", "continue_button": "Jarraitu", "welcome_heading": "Ongi etorri CONNECTA-ra", "welcome_subtitle": "Mesedez, igo zure QR kodea edo sartu erreferentzia kodea", "terms_and_conditions": "Baldintzak eta xedapenak"}	\N	basque
5e3d38d5-b31c-4816-b763-0f8d32a91b07	{"upload_qr": "কিউআর কোড আপলোড করুন", "enter_code": "রেফারেল কোড দিন", "state_label": "রাজ্য নির্বাচন করুন", "accept_terms": "আমি শর্তাবলীতে সম্মতি দিচ্ছি", "country_label": "দেশ নির্বাচন করুন", "language_label": "ভাষা নির্বাচন করুন", "continue_button": "চালিয়ে যান", "welcome_heading": "কনেক্টাতে স্বাগতম", "welcome_subtitle": "অনুগ্রহ করে আপনার কিউআর কোড আপলোড করুন অথবা রেফারেল কোড দিন", "terms_and_conditions": "শর্তাবলী"}	\N	bengali
d83ac501-e189-4d91-986e-c9d137d7a80a	{"upload_qr": "Качи QR код", "enter_code": "Въведете реферален код", "state_label": "Изберете щат", "accept_terms": "Съгласявам се с общите условия", "country_label": "Изберете държава", "language_label": "Изберете език", "continue_button": "Продължи", "welcome_heading": "Добре дошли в CONNECTA", "welcome_subtitle": "Моля, качете своя QR код или въведете реферален код", "terms_and_conditions": "Общи условия"}	\N	bulgarian
7578e633-3796-4baf-af3b-054e18a87549	{"upload_qr": "Puja el codi QR", "enter_code": "Introdueix el codi de referència", "state_label": "Selecciona l'estat", "accept_terms": "Accepto els termes i condicions", "country_label": "Selecciona el país", "language_label": "Selecciona l'idioma", "continue_button": "Continuar", "welcome_heading": "Benvingut a CONNECTA", "welcome_subtitle": "Si us plau, puja el teu codi QR o introdueix el codi de referència", "terms_and_conditions": "Termes i Condicions"}	\N	catalan
ded588eb-bd3f-46b0-8c1f-f2da370d3398	{}	\N	chinese_hk
ae65ac95-1984-4cdb-bd8a-e463f33811de	{"upload_qr": "Prenesi QR kod", "enter_code": "Unesite referalni kod", "state_label": "Odaberite državu", "accept_terms": "Prihvaćam uvjete i odredbe", "country_label": "Odaberite zemlju", "language_label": "Odaberite jezik", "continue_button": "Nastavi", "welcome_heading": "Dobrodošli u CONNECTA", "welcome_subtitle": "Molimo prenesite svoj QR kod ili unesite referalni kod", "terms_and_conditions": "Uvjeti i odredbe"}	\N	croatian
551d885c-653a-40ef-9f2d-b756b3d85331	{}	\N	swahili (1)
1dddb0d5-1dd5-4e1d-9377-a90f29545642	{"upload_qr": "Upload QR-kode", "enter_code": "Indtast henvisningskode", "state_label": "Vælg Stat", "accept_terms": "Jeg accepterer vilkår og betingelser", "country_label": "Vælg Land", "language_label": "Vælg Sprog", "continue_button": "Fortsæt", "welcome_heading": "Velkommen til CONNECTA", "welcome_subtitle": "Upload venligst din QR-kode eller indtast henvisningskoden", "terms_and_conditions": "Vilkår og Betingelser"}	\N	danish
274a9fe2-2834-4870-a771-3791c84a3379	{"upload_qr": "Upload QR-code", "enter_code": "Voer verwijzingscode in", "state_label": "Selecteer Staat", "accept_terms": "Ik ga akkoord met de algemene voorwaarden", "country_label": "Selecteer Land", "language_label": "Selecteer Taal", "continue_button": "Doorgaan", "welcome_heading": "Welkom bij CONNECTA", "welcome_subtitle": "Upload alstublieft uw QR-code of voer de verwijzingscode in", "terms_and_conditions": "Algemene Voorwaarden"}	\N	dutch
3390db72-da74-4d8c-9cf8-74d035293681	{"upload_qr": "Laadi üles QR-kood", "enter_code": "Sisestage soovituskood", "state_label": "Vali osariik", "accept_terms": "Ma nõustun tingimustega", "country_label": "Vali riik", "language_label": "Vali keel", "continue_button": "Jätka", "welcome_heading": "Tere tulemast CONNECTA-sse", "welcome_subtitle": "Palun laadige üles oma QR-kood või sisestage soovituskood", "terms_and_conditions": "Tingimused ja sätted"}	\N	estonian
39cd4881-6408-4301-af73-f75c013120ed	{"upload_qr": "Lataa QR-koodi", "enter_code": "Syötä suosittelukoodi", "state_label": "Valitse osavaltio", "accept_terms": "Hyväksyn ehdot ja säännöt", "country_label": "Valitse maa", "language_label": "Valitse kieli", "continue_button": "Jatka", "welcome_heading": "Tervetuloa CONNECTAan", "welcome_subtitle": "Lataa QR-koodisi tai syötä suosittelukoodi", "terms_and_conditions": "Ehdot ja säännöt"}	\N	finnish
ae133435-d47f-4890-9ec6-e329c049d349	{"upload_qr": "Télécharger le code QR", "enter_code": "Saisir le code de parrainage", "state_label": "Sélectionnez l'état", "accept_terms": "J'accepte les termes et conditions", "country_label": "Sélectionnez le pays", "language_label": "Sélectionnez la langue", "continue_button": "Continuer", "welcome_heading": "Bienvenue sur CONNECTA", "welcome_subtitle": "Veuillez télécharger votre code QR ou saisir le code de parrainage", "terms_and_conditions": "Termes et conditions"}	\N	french
c3a862cc-8e41-434c-aae1-5d2183667a01	{"upload_qr": "Cargar código QR", "enter_code": "Introducir código de referencia", "state_label": "Seleccionar estado", "accept_terms": "Acepto os termos e condicións", "country_label": "Seleccionar país", "language_label": "Seleccionar idioma", "continue_button": "Continuar", "welcome_heading": "Benvido a CONNECTA", "welcome_subtitle": "Cargue o seu código QR ou introduza o código de referencia", "terms_and_conditions": "Termos e Condicións"}	\N	galician
9bd07900-0a17-42b4-bd70-273aa2ec379b	{"upload_qr": "ატვირთეთ QR კოდი", "enter_code": "შეიყვანეთ რეკომენდაციის კოდი", "state_label": "აირჩიეთ შტატი", "accept_terms": "ვეთანხმები წესებსა და პირობებს", "country_label": "აირჩიეთ ქვეყანა", "language_label": "აირჩიეთ ენა", "continue_button": "გაგრძელება", "welcome_heading": "მოგესალმებით CONNECTA-ში", "welcome_subtitle": "გთხოვთ, ატვირთეთ თქვენი QR კოდი ან შეიყვანეთ რეკომენდაციის კოდი", "terms_and_conditions": "წესები და პირობები"}	\N	georgian
3b56d9f5-f0e5-4c95-8252-d17b7280bfc0	{"upload_qr": "Ανεβάστε QR κωδικό", "enter_code": "Εισάγετε κωδικό παραπομπής", "state_label": "Επιλέξτε Πολιτεία", "accept_terms": "Αποδέχομαι τους όρους και τις προϋποθέσεις", "country_label": "Επιλέξτε Χώρα", "language_label": "Επιλέξτε Γλώσσα", "continue_button": "Συνέχεια", "welcome_heading": "Καλώς ήρθατε στο CONNECTA", "welcome_subtitle": "Παρακαλώ ανεβάστε τον QR κωδικό σας ή εισάγετε τον κωδικό παραπομπής", "terms_and_conditions": "Όροι και Προϋποθέσεις"}	\N	greek
ee2b5de1-c36f-428e-8751-f71945745937	{"upload_qr": "QR કોડ અપલોડ કરો", "enter_code": "રેફરલ કોડ દાખલ કરો", "state_label": "રાજ્ય પસંદ કરો", "accept_terms": "હું નિયમો અને શરતો સ્વીકારું છું", "country_label": "દેશ પસંદ કરો", "language_label": "ભાષા પસંદ કરો", "continue_button": "ચાલુ રાખો", "welcome_heading": "CONNECTA માં આપનું સ્વાગત છે", "welcome_subtitle": "કૃપા કરીને તમારું QR કોડ અપલોડ કરો અથવા રેફરલ કોડ દાખલ કરો", "terms_and_conditions": "નિયમો અને શરતો"}	\N	gujarati
cd48866d-0e9b-4668-9291-8569b046ed3b	{"upload_qr": "העלה קוד QR", "enter_code": "הזן קוד הפניה", "state_label": "בחר מדינה/מחוז", "accept_terms": "אני מקבל את התנאים וההגבלות", "country_label": "בחר מדינה", "language_label": "בחר שפה", "continue_button": "המשך", "welcome_heading": "ברוכים הבאים ל-CONNECTA", "welcome_subtitle": "אנא העלה את קוד ה-QR שלך או הזן את קוד ההפניה", "terms_and_conditions": "תנאים והגבלות"}	\N	hebrew
198c782f-c612-4342-b512-b22d5b0600dd	{"upload_qr": "QR कोड अपलोड करें", "enter_code": "रेफरल कोड दर्ज करें", "state_label": "राज्य चुनें", "accept_terms": "मैं नियम और शर्तें स्वीकार करता/करती हूँ", "country_label": "देश चुनें", "language_label": "भाषा चुनें", "continue_button": "जारी रखें", "welcome_heading": "CONNECTA में आपका स्वागत है", "welcome_subtitle": "कृपया अपना QR कोड अपलोड करें या रेफरल कोड दर्ज करें", "terms_and_conditions": "नियम और शर्तें"}	\N	hindi
4a36c91d-ff51-470d-8169-a27f55fb1fbb	{"upload_qr": "Hlaða upp QR kóða", "enter_code": "Sláðu inn tilvísunarkóða", "state_label": "Veldu fylki", "accept_terms": "Ég samþykki skilmálana", "country_label": "Veldu land", "language_label": "Veldu tungumál", "continue_button": "Halda áfram", "welcome_heading": "Velkomin í CONNECTA", "welcome_subtitle": "Vinsamlegast hlaðið upp QR kóða eða sláið inn tilvísunarkóða", "terms_and_conditions": "Skilmálar og skilyrði"}	\N	icelandic
69dd35a4-7ef2-4561-8345-8934c32da1b4	{"upload_qr": "Unggah Kode QR", "enter_code": "Masukkan Kode Referensi", "state_label": "Pilih Provinsi", "accept_terms": "Saya menerima syarat dan ketentuan", "country_label": "Pilih Negara", "language_label": "Pilih Bahasa", "continue_button": "Lanjutkan", "welcome_heading": "Selamat datang di CONNECTA", "welcome_subtitle": "Silakan unggah kode QR Anda atau masukkan kode referensi", "terms_and_conditions": "Syarat dan Ketentuan"}	\N	indonesian
80cd0597-f724-4772-80e3-d9ac43e9310c	{"upload_qr": "Carica il codice QR", "enter_code": "Inserisci il codice di riferimento", "state_label": "Seleziona Stato", "accept_terms": "Accetto i termini e le condizioni", "country_label": "Seleziona Paese", "language_label": "Seleziona Lingua", "continue_button": "Continua", "welcome_heading": "Benvenuto su CONNECTA", "welcome_subtitle": "Carica il tuo codice QR o inserisci il codice di riferimento", "terms_and_conditions": "Termini e Condizioni"}	\N	italian
3204017e-a929-47b3-9b1c-a0616e545233	{"upload_qr": "QRコードをアップロード", "enter_code": "紹介コードを入力", "state_label": "都道府県を選択", "accept_terms": "利用規約に同意します", "country_label": "国を選択", "language_label": "言語を選択", "continue_button": "続ける", "welcome_heading": "CONNECTAへようこそ", "welcome_subtitle": "QRコードをアップロードするか、紹介コードを入力してください", "terms_and_conditions": "利用規約"}	\N	japanese
1c0f9fe4-07a2-4a5d-a4e8-ee26661ec076	{"upload_qr": "QR кодын жүктеу", "enter_code": "Жолдама кодын енгізу", "state_label": "Штатты таңдаңыз", "accept_terms": "Мен шарттармен келісемін", "country_label": "Елді таңдаңыз", "language_label": "Тілді таңдаңыз", "continue_button": "Жалғастыру", "welcome_heading": "CONNECTA-ға қош келдіңіз", "welcome_subtitle": "QR кодыңызды жүктеңіз немесе жолдама кодын енгізіңіз", "terms_and_conditions": "Шарттар мен ережелер"}	\N	kazakh
b88b971d-ee25-4e1b-9910-4ccfa53ac1e2	{"upload_qr": "អាប់ឡូដកូដ QR", "enter_code": "បញ្ចូលកូដយោង", "state_label": "ជ្រើសរើសរដ្ឋ", "accept_terms": "ខ្ញុំយល់ព្រមលើលក្ខខណ្ឌ និងលក្ខទំនើប", "country_label": "ជ្រើសរើសប្រទេស", "language_label": "ជ្រើសរើសភាសា", "continue_button": "បន្ត", "welcome_heading": "សូមស្វាគមន៍មកកាន់ CONNECTA", "welcome_subtitle": "សូមអាប់ឡូដកូដ QR របស់អ្នក ឬបញ្ចូលកូដយោង", "terms_and_conditions": "លក្ខខណ្ឌ និងលក្ខទំនើប"}	\N	khmer
57ff975c-53f3-4992-b255-011439a94d61	{"upload_qr": "QR 코드 업로드", "enter_code": "추천 코드 입력", "state_label": "주 선택", "accept_terms": "약관에 동의합니다", "country_label": "국가 선택", "language_label": "언어 선택", "continue_button": "계속하기", "welcome_heading": "CONNECTA에 오신 것을 환영합니다", "welcome_subtitle": "QR 코드를 업로드하거나 추천 코드를 입력하세요", "terms_and_conditions": "약관"}	\N	korean
75e5b36a-9fa0-473c-8419-4f9b76818bef	{"upload_qr": "QR кодун жүктөө", "enter_code": "Жолдомо кодун киргизүү", "state_label": "Штатты тандаңыз", "accept_terms": "Мен шарттарга жана жоболорго макулмун", "country_label": "Өлкөнү тандаңыз", "language_label": "Тилди тандаңыз", "continue_button": "Улантуу", "welcome_heading": "CONNECTAга кош келиңиз", "welcome_subtitle": "QR кодуңузду жүктөңүз же жолдомо кодун киргизиңиз", "terms_and_conditions": "Шарттар жана жоболор"}	\N	kyrgyz
281363c0-71fd-48af-ae99-157d09471735	{"upload_qr": "ອັບໂຫຼດ QR ລະຫັດ", "enter_code": "ໃສ່ລະຫັດແນະນຳ", "state_label": "ເລືອກລັດ", "accept_terms": "ຂ້ອຍຍອມຮັບເງື່ອນໄຂແລະຂໍ້ກຳນົດ", "country_label": "ເລືອກປະເທດ", "language_label": "ເລືອກພາສາ", "continue_button": "ດຳເນີນຕໍ່", "welcome_heading": "ຍິນດີຕ້ອນຮັບສູ່ CONNECTA", "welcome_subtitle": "ກະລຸນາອັບໂຫຼດ QR ລະຫັດ ຫຼື ໃສ່ລະຫັດແນະນຳ", "terms_and_conditions": "ເງື່ອນໄຂແລະຂໍ້ກຳນົດ"}	\N	lao
ffaf8edc-1da5-41c2-b692-aad08a84bee2	{"upload_qr": "Augšupielādēt QR kodu", "enter_code": "Ievadīt novirzīšanas kodu", "state_label": "Izvēlieties štatu", "accept_terms": "Es piekrītu noteikumiem un nosacījumiem", "country_label": "Izvēlieties valsti", "language_label": "Izvēlieties valodu", "continue_button": "Turpināt", "welcome_heading": "Laipni lūdzam CONNECTA", "welcome_subtitle": "Lūdzu, augšupielādējiet savu QR kodu vai ievadiet novirzīšanas kodu", "terms_and_conditions": "Noteikumi un nosacījumi"}	\N	latvian
2b12f701-9457-4aa6-8496-d3b78622b82e	{"upload_qr": "Įkelti QR kodą", "enter_code": "Įvesti nukreipimo kodą", "state_label": "Pasirinkite valstiją", "accept_terms": "Sutinku su taisyklėmis ir sąlygomis", "country_label": "Pasirinkite šalį", "language_label": "Pasirinkite kalbą", "continue_button": "Tęsti", "welcome_heading": "Sveiki atvykę į CONNECTA", "welcome_subtitle": "Prašome įkelti savo QR kodą arba įvesti nukreipimo kodą", "terms_and_conditions": "Taisyklės ir sąlygos"}	\N	lithuanian
05b3790a-e372-4cb8-83fa-92a514f9d50e	{"upload_qr": "Muat naik Kod QR", "enter_code": "Masukkan Kod Rujukan", "state_label": "Pilih Negeri", "accept_terms": "Saya bersetuju dengan terma dan syarat", "country_label": "Pilih Negara", "language_label": "Pilih Bahasa", "continue_button": "Teruskan", "welcome_heading": "Selamat datang ke CONNECTA", "welcome_subtitle": "Sila muat naik kod QR anda atau masukkan kod rujukan", "terms_and_conditions": "Terma dan Syarat"}	\N	malay
dde2f81b-e441-4aa2-928a-bf007509fa70	{"upload_qr": "QR കോഡ് അപ്‌ലോഡ് ചെയ്യുക", "enter_code": "റഫറൽ കോഡ് നൽകുക", "state_label": "സംസ്ഥാനം തിരഞ്ഞെടുക്കുക", "accept_terms": "ഞാൻ നിബന്ധനകളും വ്യവസ്ഥകളും അംഗീകരിക്കുന്നു", "country_label": "രാജ്യം തിരഞ്ഞെടുക്കുക", "language_label": "ഭാഷ തിരഞ്ഞെടുക്കുക", "continue_button": "തുടരുക", "welcome_heading": "CONNECTA ലേക്ക് സ്വാഗതം", "welcome_subtitle": "ദയവായി നിങ്ങളുടെ QR കോഡ് അപ്‌ലോഡ് ചെയ്യുക അല്ലെങ്കിൽ റഫറൽ കോഡ് നൽകുക", "terms_and_conditions": "നിബന്ധനകളും വ്യവസ്ഥകളും"}	\N	malayalam
ed0393c1-d856-4795-8656-ff5b47213e96	{"upload_qr": "QR कोड अपलोड करा", "enter_code": "रेफरल कोड प्रविष्ट करा", "state_label": "राज्य निवडा", "accept_terms": "मी अटी व शर्ती स्वीकारतो/स्विकारते", "country_label": "देश निवडा", "language_label": "भाषा निवडा", "continue_button": "सुरू ठेवा", "welcome_heading": "CONNECTA मध्ये आपले स्वागत आहे", "welcome_subtitle": "कृपया आपला QR कोड अपलोड करा किंवा रेफरल कोड प्रविष्ट करा", "terms_and_conditions": "अटी व शर्ती"}	\N	marathi
a40f8a05-adb7-4df3-9455-9afd206d2660	{"upload_qr": "QR код оруулах", "enter_code": "Урамшууллын код оруулах", "state_label": "Муж сонгоно уу", "accept_terms": "Би нөхцөл, болзлыг зөвшөөрч байна", "country_label": "Улс сонгоно уу", "language_label": "Хэлийг сонгоно уу", "continue_button": "Үргэлжлүүлэх", "welcome_heading": "CONNECTA-д тавтай морилно уу", "welcome_subtitle": "Та QR кодоо оруулна уу эсвэл урамшууллын кодыг оруулна уу", "terms_and_conditions": "Нөхцөл, болзол"}	\N	mongolian
07bae78e-ad2a-4488-b332-4955c74b8e9b	{"upload_qr": "QR कोड अपलोड गर्नुहोस्", "enter_code": "सन्दर्भ कोड प्रविष्ट गर्नुहोस्", "state_label": "राज्य चयन गर्नुहोस्", "accept_terms": "म सर्तहरू र नियमहरू स्वीकार गर्छु", "country_label": "देश चयन गर्नुहोस्", "language_label": "भाषा चयन गर्नुहोस्", "continue_button": "जारी राख्नुहोस्", "welcome_heading": "CONNECTA मा स्वागत छ", "welcome_subtitle": "कृपया आफ्नो QR कोड अपलोड गर्नुहोस् वा सन्दर्भ कोड प्रविष्ट गर्नुहोस्", "terms_and_conditions": "सर्तहरू र नियमहरू"}	\N	nepali
27d29314-ab9a-4def-85cb-71deacd177d7	{"upload_qr": "Last opp QR-kode", "enter_code": "Skriv inn henvisningskode", "state_label": "Velg stat", "accept_terms": "Jeg godtar vilkårene og betingelsene", "country_label": "Velg land", "language_label": "Velg språk", "continue_button": "Fortsett", "welcome_heading": "Velkommen til CONNECTA", "welcome_subtitle": "Last opp QR-koden din eller skriv inn henvisningskoden", "terms_and_conditions": "Vilkår og betingelser"}	\N	norwegian
ad7e32a0-921a-4f8d-b213-57954e03c21f	{"upload_qr": "آپلود کد QR", "enter_code": "وارد کردن کد معرفی", "state_label": "انتخاب ایالت", "accept_terms": "من شرایط و ضوابط را می‌پذیرم", "country_label": "انتخاب کشور", "language_label": "انتخاب زبان", "continue_button": "ادامه دهید", "welcome_heading": "به CONNECTA خوش آمدید", "welcome_subtitle": "لطفاً کد QR خود را آپلود کنید یا کد معرفی را وارد کنید", "terms_and_conditions": "شرایط و ضوابط"}	\N	persian
546f900e-84e6-424d-86f7-eb86dfb4365d	{"upload_qr": "Prześlij kod QR", "enter_code": "Wprowadź kod polecający", "state_label": "Wybierz stan", "accept_terms": "Akceptuję warunki i zasady", "country_label": "Wybierz kraj", "language_label": "Wybierz język", "continue_button": "Kontynuuj", "welcome_heading": "Witamy w CONNECTA", "welcome_subtitle": "Prześlij swój kod QR lub wprowadź kod polecający", "terms_and_conditions": "Warunki i Zasady"}	\N	polish
406144c7-ebe0-41b8-88dd-3b3713e0dc16	{"upload_qr": "Enviar código QR", "enter_code": "Inserir código de referência", "state_label": "Selecionar estado", "accept_terms": "Eu aceito os termos e condições", "country_label": "Selecionar país", "language_label": "Selecionar idioma", "continue_button": "Continuar", "welcome_heading": "Bem-vindo ao CONNECTA", "welcome_subtitle": "Por favor, envie seu código QR ou insira o código de referência", "terms_and_conditions": "Termos e Condições"}	\N	portuguese
b1cb3bc2-5e5a-408e-b53c-51921a9e1f34	{"upload_qr": "QR ਕੋਡ ਅੱਪਲੋਡ ਕਰੋ", "enter_code": "ਰੈਫਰਲ ਕੋਡ ਦਰਜ ਕਰੋ", "state_label": "ਰਾਜ ਚੁਣੋ", "accept_terms": "ਮੈਂ ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ ਨੂੰ ਮਨਜ਼ੂਰ ਕਰਦਾ/ਕਰਦੀ ਹਾਂ", "country_label": "ਦੇਸ਼ ਚੁਣੋ", "language_label": "ਭਾਸ਼ਾ ਚੁਣੋ", "continue_button": "ਜਾਰੀ ਰੱਖੋ", "welcome_heading": "CONNECTA ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ", "welcome_subtitle": "ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ QR ਕੋਡ ਅੱਪਲੋਡ ਕਰੋ ਜਾਂ ਰੈਫਰਲ ਕੋਡ ਦਰਜ ਕਰੋ", "terms_and_conditions": "ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ"}	\N	punjabi
ac7b1940-e55c-40bd-8d2e-f1116d61b584	{"upload_qr": "Chargia il code QR", "enter_code": "Endatescha il code da referenza", "state_label": "Tscherna il stadi", "accept_terms": "Jau accept las cundiziuns generalas", "country_label": "Tscherna il pajais", "language_label": "Tscherna la lingua", "continue_button": "Proseguir", "welcome_heading": "Bainvegni tar CONNECTA", "welcome_subtitle": "Per plaschair chargia il code QR u endatescha il code da referenza", "terms_and_conditions": "Cundiziuns generalas"}	\N	romansh
c794f8ca-2c02-48f4-b7e4-2399b3a4b770	{"upload_qr": "Загрузить QR-код", "enter_code": "Введите реферальный код", "state_label": "Выберите штат/регион", "accept_terms": "Я принимаю условия и положения", "country_label": "Выберите страну", "language_label": "Выберите язык", "continue_button": "Продолжить", "welcome_heading": "Добро пожаловать в CONNECTA", "welcome_subtitle": "Пожалуйста, загрузите свой QR-код или введите реферальный код", "terms_and_conditions": "Условия и положения"}	\N	russian
3cec0d3e-e6c5-4ff3-9f05-da284d6a52ec	{"upload_qr": "Otpremi QR kod", "enter_code": "Unesi referalni kod", "state_label": "Izaberite pokrajinu", "accept_terms": "Prihvatam uslove korišćenja", "country_label": "Izaberite državu", "language_label": "Izaberite jezik", "continue_button": "Nastavi", "welcome_heading": "Dobrodošli u CONNECTA", "welcome_subtitle": "Molimo vas da otpremite svoj QR kod ili unesete referalni kod", "terms_and_conditions": "Uslovi korišćenja"}	\N	serbian
f4f46abb-d4d1-466d-a9f5-a8a73294eab0	{"upload_qr": "QR කේතය උඩුගත කරන්න", "enter_code": "යොමු කේතය ඇතුලත් කරන්න", "state_label": "ප්‍රාන්තය තෝරන්න", "accept_terms": "මම නියමයන් සහ කොන්දේසි පිළිගන්නෙමි", "country_label": "රට තෝරන්න", "language_label": "භාෂාව තෝරන්න", "continue_button": "ඉදිරියට යන්න", "welcome_heading": "CONNECTA වෙත පිළිගනිමු", "welcome_subtitle": "කරුණාකර ඔබගේ QR කේතය උඩුගත කරන්න හෝ යොමු කේතය ඇතුලත් කරන්න", "terms_and_conditions": "නියමයන් සහ කොන්දේසි"}	\N	sinhala
10b11409-1aa6-4a0b-a519-ec3a33b5703f	{"upload_qr": "Nahrať QR kód", "enter_code": "Zadajte odporúčací kód", "state_label": "Vyberte štát", "accept_terms": "Súhlasím s podmienkami", "country_label": "Vyberte krajinu", "language_label": "Vyberte jazyk", "continue_button": "Pokračovať", "welcome_heading": "Vitajte v CONNECTA", "welcome_subtitle": "Nahrajte svoj QR kód alebo zadajte odporúčací kód", "terms_and_conditions": "Podmienky a pravidlá"}	\N	slovak
bb797ab2-baa9-4a36-8fa9-fb872e2c3611	{"upload_qr": "Naloži QR kodo", "enter_code": "Vnesi referenčno kodo", "state_label": "Izberite zvezno državo", "accept_terms": "Sprejemam pogoje in določila", "country_label": "Izberite državo", "language_label": "Izberite jezik", "continue_button": "Nadaljuj", "welcome_heading": "Dobrodošli v CONNECTA", "welcome_subtitle": "Naložite svojo QR kodo ali vnesite referenčno kodo", "terms_and_conditions": "Pogoji in določila"}	\N	slovenian
65a811eb-e8e6-4563-93f0-eec4775f9d98	{"upload_qr": "Subir código QR", "enter_code": "Introducir código de referencia", "state_label": "Seleccionar estado", "accept_terms": "Acepto los términos y condiciones", "country_label": "Seleccionar país", "language_label": "Seleccionar idioma", "continue_button": "Continuar", "welcome_heading": "Bienvenido a CONNECTA", "welcome_subtitle": "Por favor, suba su código QR o introduzca el código de referencia", "terms_and_conditions": "Términos y Condiciones"}	\N	spanish
ab8ebd12-9b8f-4a2a-b67e-1d6cd77e0c65	{"upload_qr": "Pakia Msimbo wa QR", "enter_code": "Weka Nambari ya Rufaa", "state_label": "Chagua Jimbo", "accept_terms": "Nakubali masharti na vigezo", "country_label": "Chagua Nchi", "language_label": "Chagua Lugha", "continue_button": "Endelea", "welcome_heading": "Karibu CONNECTA", "welcome_subtitle": "Tafadhali pakia msimbo wako wa QR au ingiza nambari ya rufaa", "terms_and_conditions": "Masharti na Vigezo"}	\N	swahili
40a5ce6f-4bc2-4beb-bf3b-cc2d7b32397a	{"upload_qr": "Ladda upp QR-kod", "enter_code": "Ange referenskod", "state_label": "Välj delstat", "accept_terms": "Jag accepterar villkoren", "country_label": "Välj land", "language_label": "Välj språk", "continue_button": "Fortsätt", "welcome_heading": "Välkommen till CONNECTA", "welcome_subtitle": "Ladda upp din QR-kod eller ange referenskoden", "terms_and_conditions": "Villkor"}	\N	swedish
78fd0eb2-c340-46db-a473-b35417c3b171	{"upload_qr": "QR కోడ్‌ను అప్‌లోడ్ చేయండి", "enter_code": "రెఫరల్ కోడ్‌ను నమోదు చేయండి", "state_label": "రాష్ట్రాన్ని ఎంచుకోండి", "accept_terms": "నేను నిబంధనలు మరియు షరతులను అంగీకరిస్తున్నాను", "country_label": "దేశాన్ని ఎంచుకోండి", "language_label": "భాషను ఎంచుకోండి", "continue_button": "కొనసాగించు", "welcome_heading": "CONNECTA కు స్వాగతం", "welcome_subtitle": "దయచేసి మీ QR కోడ్‌ను అప్‌లోడ్ చేయండి లేదా రిఫerral కోడ్‌ను నమోదు చేయండి", "terms_and_conditions": "నిబంధనలు మరియు షరతులు"}	\N	telugu
231c0951-0886-43c8-a391-ae8e4ff7a10a	{"upload_qr": "Laai QR-kode op", "enter_code": "Voer verwysingskode in", "state_label": "Kies Staat", "accept_terms": "Ek aanvaar die bepalings en voorwaardes", "country_label": "Kies Land", "language_label": "Kies Taal", "continue_button": "Gaan voort", "welcome_heading": "Welkom by CONNECTA", "welcome_subtitle": "Laai asseblief jou QR-kode op of voer die verwysingskode in", "terms_and_conditions": "Bepalings en Voorwaardes"}	\N	afrikaans
ae89a053-4701-476e-afaf-65decc66b21b	{"upload_qr": "QR ကုဒ် အပ်လုဒ်လုပ်ပါ", "enter_code": "ရည်ညွှန်းကုဒ် ထည့်ပါ", "state_label": "ပြည်နယ် ရွေးချယ်ပါ", "accept_terms": "ကျွန်ုပ်သည် စည်းကမ်းနှင့်သတ်မှတ်ချက်များကို လက်ခံပါသည်", "country_label": "နိုင်ငံ ရွေးချယ်ပါ", "language_label": "ဘာသာစကား ရွေးချယ်ပါ", "continue_button": "ဆက်လက်လုပ်ဆောင်ရန်", "welcome_heading": "CONNECTA မှ ကြိုဆိုပါသည်", "welcome_subtitle": "ကျေးဇူးပြု၍ သင်၏ QR ကုဒ်ကို အပ်လုဒ်လုပ်ပါ သို့မဟုတ် ရည်ညွှန်းကုဒ်ကို ထည့်ပါ", "terms_and_conditions": "စည်းကမ်းများနှင့် သတ်မှတ်ချက်များ"}	\N	burmese
730420c4-9b7f-4938-9623-b3162bbb3c3d	{}	\N	chinese_simplified
57aa1099-b737-4f5d-8f4d-c7ca9d220718	{}	\N	chinese_traditional
bfe55a51-5573-4f22-b978-470d0a28e3f0	{"upload_qr": "Nahrát QR kód", "enter_code": "Zadejte doporučující kód", "state_label": "Vyberte stát", "accept_terms": "Souhlasím s podmínkami", "country_label": "Vyberte zemi", "language_label": "Vyberte jazyk", "continue_button": "Pokračovat", "welcome_heading": "Vítejte v CONNECTA", "welcome_subtitle": "Nahrajte prosím svůj QR kód nebo zadejte doporučující kód", "terms_and_conditions": "Podmínky a ujednání"}	\N	czech
c6e9ab7f-ea77-4b90-8795-5c1315f83e1f	{}	\N	egyptian_arabic
cb61768f-b78e-4974-9b9b-93234ad57513	{}	\N	french_canada
65db5835-c840-4764-b3ce-52745f24ff9f	{}	\N	french_france
588fb687-892c-4ae7-9c69-1e07a54fae66	{"upload_qr": "QR-Code hochladen", "enter_code": "Empfehlungscode eingeben", "state_label": "Bundesland auswählen", "accept_terms": "Ich akzeptiere die Allgemeinen Geschäftsbedingungen", "country_label": "Land auswählen", "language_label": "Sprache auswählen", "continue_button": "Weiter", "welcome_heading": "Willkommen bei CONNECTA", "welcome_subtitle": "Bitte laden Sie Ihren QR-Code hoch oder geben Sie den Empfehlungscode ein", "terms_and_conditions": "Allgemeine Geschäftsbedingungen"}	\N	german
c2ba59a6-49af-47b9-a753-ffeb9874797b	{"upload_qr": "QR-kód feltöltése", "enter_code": "Ajánlókód megadása", "state_label": "Válasszon államot", "accept_terms": "Elfogadom a feltételeket", "country_label": "Válasszon országot", "language_label": "Válasszon nyelvet", "continue_button": "Folytatás", "welcome_heading": "Üdvözöljük a CONNECTA-nál", "welcome_subtitle": "Kérjük, töltse fel QR-kódját, vagy írja be az ajánlókódot", "terms_and_conditions": "Feltételek és kikötések"}	\N	hungarian
58f56eac-72c1-4e89-bf1a-07459011c9e0	{"upload_qr": "QR ಕೋಡ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ", "enter_code": "ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ", "state_label": "ರಾಜ್ಯ ಆಯ್ಕೆಮಾಡಿ", "accept_terms": "ನಾನು ನಿಬಂಧನೆಗಳು ಮತ್ತು ಶರತ್ತುಗಳನ್ನು ಒಪ್ಪುತ್ತೇನೆ", "country_label": "ದೇಶ ಆಯ್ಕೆಮಾಡಿ", "language_label": "ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ", "continue_button": "ಮುಂದುವರಿಸಿ", "welcome_heading": "CONNECTA ಗೆ ಸುಸ್ವಾಗತ", "welcome_subtitle": "ದಯವಿಟ್ಟು ನಿಮ್ಮ QR ಕೋಡ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ಅಥವಾ ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ", "terms_and_conditions": "ನಿಬಂಧನೆಗಳು ಮತ್ತು ಶರತ್ತುಗಳು"}	\N	kannada
e26cc61a-f1e4-4627-bb02-d14eaf73c371	{}	\N	korean (1)
afcbffb3-5ac2-4ed4-9bb4-5edba15f4802	{"upload_qr": "Поставете QR код", "enter_code": "Внесете референтен код", "state_label": "Изберете сојузна држава", "accept_terms": "Јас ги прифаќам условите и правилата", "country_label": "Изберете држава", "language_label": "Изберете јазик", "continue_button": "Продолжи", "welcome_heading": "Добредојдовте во CONNECTA", "welcome_subtitle": "Ве молиме поставете го вашиот QR код или внесете го референтниот код", "terms_and_conditions": "Услови и правила"}	\N	macedonian
eef69c46-6e60-4100-b7a9-2440c9f962f3	{}	\N	malay_malaysia
448c97d1-8fe4-486b-9a39-fb41c463a239	{}	\N	mandarin_chinese
ef465c44-e315-412c-8879-6b74c3f5bd54	{}	\N	nigerian_pidgin
1fadd6e4-c4bd-47f5-acea-d545e5b5e03d	{}	\N	portuguese_brazil
503199f5-7c72-4237-ae99-a9f5da0af04e	{}	\N	portuguese_portugal
5e26df02-0292-4766-bb77-9e52d73f645d	{"upload_qr": "Încărcați codul QR", "enter_code": "Introduceți codul de recomandare", "state_label": "Selectați statul", "accept_terms": "Accept termenii și condițiile", "country_label": "Selectați țara", "language_label": "Selectați limba", "continue_button": "Continuați", "welcome_heading": "Bine ați venit la CONNECTA", "welcome_subtitle": "Vă rugăm să încărcați codul QR sau să introduceți codul de recomandare", "terms_and_conditions": "Termeni și Condiții"}	\N	romanian
532ef757-1536-45cb-aaea-bca66af1eae7	{}	\N	romansh (1)
90ff10a3-2d96-4136-936c-3fd768657ced	{}	\N	spanish_latam
66753d43-c137-4f9c-a791-07a855078ecf	{}	\N	spanish_spain
b99b6ac8-cc27-4b11-a280-cbd7be415213	{"upload_qr": "Tải mã QR lên", "enter_code": "Nhập mã giới thiệu", "state_label": "Chọn tiểu bang", "accept_terms": "Tôi đồng ý với các điều khoản và điều kiện", "country_label": "Chọn quốc gia", "language_label": "Chọn ngôn ngữ", "continue_button": "Tiếp tục", "welcome_heading": "Chào mừng đến với CONNECTA", "welcome_subtitle": "Vui lòng tải lên mã QR của bạn hoặc nhập mã giới thiệu", "terms_and_conditions": "Điều khoản và điều kiện"}	\N	vietnamese
e98579a4-6922-4076-8783-92142816ce89	{"upload_qr": "Layisha ikhodi ye-QR", "enter_code": "Faka ikhodi yokudlulisa", "state_label": "Khetha isifundazwe", "accept_terms": "Ngiyavuma imigomo nemibandela", "country_label": "Khetha izwe", "language_label": "Khetha ulimi", "continue_button": "Qhubeka", "welcome_heading": "Siyakwamukela ku-CONNECTA", "welcome_subtitle": "Sicela ulayishe ikhodi yakho ye-QR noma ufake ikhodi yokudlulisa", "terms_and_conditions": "Imigomo nemibandela"}	\N	zulu
88ca2984-2bbf-4cdb-a561-32b7b81bc413	{"upload_qr": "QR குறியீட்டை பதிவேற்றவும்", "enter_code": "பரிந்துரை குறியீட்டை உள்ளிடவும்", "state_label": "மாநிலத்தைத் தேர்ந்தெடுக்கவும்", "accept_terms": "நான் விதிமுறைகள் மற்றும் நிபந்தனைகளை ஏற்கின்றேன்", "country_label": "நாட்டைத் தேர்ந்தெடுக்கவும்", "language_label": "மொழியைத் தேர்ந்தெடுக்கவும்", "continue_button": "தொடரவும்", "welcome_heading": "CONNECTA வரவேற்கிறது", "welcome_subtitle": "தயவுசெய்து உங்கள் QR குறியீட்டை பதிவேற்றவும் அல்லது பரிந்துரை குறியீட்டை உள்ளிடவும்", "terms_and_conditions": "விதிமுறைகள் மற்றும் நிபந்தனைகள்"}	\N	tamil
60f1d39a-49ff-4425-ae59-caadc590d388	{"upload_qr": "QR کوڈ اپ لوڈ کریں", "enter_code": "ریفرل کوڈ درج کریں", "state_label": "ریاست منتخب کریں", "accept_terms": "میں شرائط و ضوابط سے اتفاق کرتا ہوں", "country_label": "ملک منتخب کریں", "language_label": "زبان منتخب کریں", "continue_button": "جاری رکھیں", "welcome_heading": "CONNECTA میں خوش آمدید", "welcome_subtitle": "براہ کرم اپنا QR کوڈ اپ لوڈ کریں یا ریفرل کوڈ درج کریں", "terms_and_conditions": "شرائط و ضوابط"}	\N	urdu
\.


--
-- Data for Name: translations_backup_27july; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.translations_backup_27july (id, translations, created_at, language_code, base_translations, keys, language_iso_code) FROM stdin;
9f3839c1-224f-4a11-a4c5-85e81e3b999c	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:22.941	basque	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	eu-ES\n
ded588eb-bd3f-46b0-8c1f-f2da370d3398	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.382	chinese_hk	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	zh-HK\n
00e88464-92f3-4315-a045-bd4c3ea81bda	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:07.266	ukrainian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	uk
1dddb0d5-1dd5-4e1d-9377-a90f29545642	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.765	danish	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	da
cd48866d-0e9b-4668-9291-8569b046ed3b	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.755	hebrew	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	he
b88b971d-ee25-4e1b-9910-4ccfa53ac1e2	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.502	khmer	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	km
eef69c46-6e60-4100-b7a9-2440c9f962f3	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.317	malay_malaysia	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ms-MY\n
ef465c44-e315-412c-8879-6b74c3f5bd54	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.694	nigerian_pidgin	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	pcm
ac7b1940-e55c-40bd-8d2e-f1116d61b584	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.619	romansh	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	rm
f4f46abb-d4d1-466d-a9f5-a8a73294eab0	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.862	sinhala	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	si-LK\n
ae89a053-4701-476e-afaf-65decc66b21b	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.194	burmese	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	my-MM\n
448c97d1-8fe4-486b-9a39-fb41c463a239	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.401	mandarin_chinese	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	zh\n
66753d43-c137-4f9c-a791-07a855078ecf	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.269	spanish_spain	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	es-ES\n
cb61768f-b78e-4974-9b9b-93234ad57513	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.22	french_canada	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	fr-CA\n
65db5835-c840-4764-b3ce-52745f24ff9f	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.285	french_france	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	fr-FR
b880e6ec-2e28-4cc8-b209-d33c08bf94c0	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:05.595	arabic	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ar
1fadd6e4-c4bd-47f5-acea-d545e5b5e03d	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.14	portuguese_brazil	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	pt-BR\n
90ff10a3-2d96-4136-936c-3fd768657ced	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.185	spanish_latam	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	es-419\n
10b11409-1aa6-4a0b-a519-ec3a33b5703f	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.954	slovak	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	sk
65a811eb-e8e6-4563-93f0-eec4775f9d98	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.103	spanish	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	es
231c0951-0886-43c8-a391-ae8e4ff7a10a	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:21.88	afrikaans	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	af
c6e9ab7f-ea77-4b90-8795-5c1315f83e1f	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.914	egyptian_arabic	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	arz
99cff182-dd8a-41a0-8a22-108d7643f98d	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:22.637	amharic	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	am
503199f5-7c72-4237-ae99-a9f5da0af04e	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.244	portuguese_portugal	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	pt-PT\n
3390db72-da74-4d8c-9cf8-74d035293681	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.002	estonian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["upload_qr", "enter_code", "state_label", "accept_terms", "country_label", "language_label", "continue_button", "welcome_heading", "welcome_subtitle", "terms_and_conditions"]	et
75e5b36a-9fa0-473c-8419-4f9b76818bef	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.749	kyrgyz	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ky
14457ea6-106e-4181-8003-fda8fc8161e7	{"upload_qr": "QR-Code hochladen", "enter_code": "Empfehlungscode eingeben", "state_label": "Bundesland auswählen", "accept_terms": "Ich akzeptiere die Allgemeinen Geschäftsbedingungen", "country_label": "Land auswählen", "language_label": "Sprache auswählen", "continue_button": "Weiter", "welcome_heading": "Willkommen bei CONNECTA", "welcome_subtitle": "Bitte laden Sie Ihren QR-Code hoch oder geben Sie den Empfehlungscode ein", "terms_and_conditions": "Allgemeine Geschäftsbedingungen"}	\N	de	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["upload_qr", "enter_code", "state_label", "accept_terms", "country_label", "language_label", "continue_button", "welcome_heading", "welcome_subtitle", "terms_and_conditions"]	de
e43ef93e-7170-4b6d-bce6-588903f31ff0	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:05.811	belarusian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	be\n
b92a1cf7-47e4-415b-a493-db27633f96cc	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:06.06	english (australia)	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	en-AU\n
2f4f2b82-d555-4313-9fd5-39f17b3da981	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:06.134	english (canada)	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	en-CA\n
8020a187-842a-4806-aef9-9b650d0df2ed	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:06.28	english (united kingdom)	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	en-GB\n
e8448795-eb43-4722-aff1-754b5a0695d9	{"upload_qr": "QR কোড আপলোড করুন", "enter_code": "কোড লিখুন", "state_label": "রাজ্য", "accept_terms": "শর্তাবলী মেনে ", "country_label": "দেশ", "language_label": "ভাষা", "continue_button": "চালিয়ে যান", "welcome_heading": "CONNECTA-  কোড লিখুন কোড লিখুন", "welcome_subtitle": "আপনার QR কোড আপলোড করুন অথবা রেফারেল কোড লিখুন", "terms_and_conditions": "কোড লিখুন"}	2025-07-13 12:57:05.909	bangla	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	bn-BD\n
58f56eac-72c1-4e89-bf1a-07459011c9e0	{"upload_qr": "QR ಕೋಡ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ", "enter_code": "ಕೋಡ್ ನಮೂದಿಸಿ", "state_label": "ರಾಜ್ಯ", "accept_terms": "ನಾನು ನಿಯಮಗಳನ್ನು ಮತ್ತು ಶರತ್ತುಗಳನ್ನು ಒಪ್ಪಿಕೊಳ್ಳುತ್ತೇನೆ", "country_label": "ದೇಶ", "language_label": "ಭಾಷೆ", "continue_button": "ಮುಂದುವರಿಸಿ", "welcome_heading": "CONNECTA ಗೆ ಸ್ವಾಗತ", "welcome_subtitle": "ದಯವಿಟ್ಟು ನಿಮ್ಮ QR ಕೋಡ್ ಅನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ಅಥವಾ ರೆಫರಲ್ ಕೋಡ್ ಅನ್ನು ನಮೂದಿಸಿ", "terms_and_conditions": "ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು"}	2025-07-14 12:51:25.33	kannada	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	kn
e6b44b72-cd62-460c-8aae-28bcc75c4b0f	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:22.538	albanian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	sq
ec6a0034-4c35-47aa-80fc-ff206ac1cf7e	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:22.738	armenian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	hy
5c444a05-c3f2-4935-b966-dcd66913ac47	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:22.847	azerbaijani	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	az
5e3d38d5-b31c-4816-b763-0f8d32a91b07	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.026	bengali	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	bn
d83ac501-e189-4d91-986e-c9d137d7a80a	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.124	bulgarian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	bg
7578e633-3796-4baf-af3b-054e18a87549	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.287	catalan	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ca
730420c4-9b7f-4938-9623-b3162bbb3c3d	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.449	chinese_simplified	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	zh-CN
57aa1099-b737-4f5d-8f4d-c7ca9d220718	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.547	chinese_traditional	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	zh-TW
ae65ac95-1984-4cdb-bd8a-e463f33811de	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.618	croatian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	hr
bfe55a51-5573-4f22-b978-470d0a28e3f0	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.683	czech	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	cs
274a9fe2-2834-4870-a771-3791c84a3379	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:23.829	dutch	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	nl
e08e9f9f-c8a6-48bb-9a9b-0ba62e22be2d	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:05.99	english	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	en
85d35275-5327-4963-bf5d-6981e19e9952	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:06.608	filipino	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	tl
39cd4881-6408-4301-af73-f75c013120ed	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.084	finnish	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	fi
ae133435-d47f-4890-9ec6-e329c049d349	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.151	french	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	fr
c3a862cc-8e41-434c-aae1-5d2183667a01	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.374	galician	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	gl
9bd07900-0a17-42b4-bd70-273aa2ec379b	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.442	georgian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ka
588fb687-892c-4ae7-9c69-1e07a54fae66	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.513	german	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	de
3b56d9f5-f0e5-4c95-8252-d17b7280bfc0	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.596	greek	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	el
ee2b5de1-c36f-428e-8751-f71945745937	{"upload_qr": "QR કોડ અપલોડ કરો", "enter_code": "કોડ દાખલ કરો", "state_label": "રાજ્ય", "accept_terms": "હું નિયમો અને શરતો સ્વીકારું છું", "country_label": "દેશ", "language_label": "ભાષા", "continue_button": "ચાલુ રાખો", "welcome_heading": "CONNECTA માં આપનું સ્વાગત છે", "welcome_subtitle": "કૃપા કરીને તમારો QR કોડ અપલોડ કરો અથવા રેફરલ કોડ દાખલ કરો", "terms_and_conditions": "નિયમો અને શરતો"}	2025-07-14 12:51:24.669	gujarati	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	gu
198c782f-c612-4342-b512-b22d5b0600dd	{"upload_qr": "क्यूआर कोड अपलोड करें", "enter_code": "कोड दर्ज करें", "state_label": "राज्य", "accept_terms": "मैं नियम और शर्तें स्वीकार करता हूँ", "country_label": "देश", "language_label": "भाषा", "continue_button": "जारी रखें", "welcome_heading": "CONNECTA में आपका स्वागत है", "welcome_subtitle": "कृपया अपना क्यूआर कोड अपलोड करें या रेफरल कोड दर्ज करें", "terms_and_conditions": "नियम और शर्तें"}	2025-07-14 12:51:24.838	hindi	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	hi
c2ba59a6-49af-47b9-a753-ffeb9874797b	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:24.921	hungarian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	hu
4a36c91d-ff51-470d-8169-a27f55fb1fbb	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25	icelandic	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	is
69dd35a4-7ef2-4561-8345-8934c32da1b4	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.065	indonesian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	id
80cd0597-f724-4772-80e3-d9ac43e9310c	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.164	italian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	it
3204017e-a929-47b3-9b1c-a0616e545233	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.24	japanese	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ja
1c0f9fe4-07a2-4a5d-a4e8-ee26661ec076	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.412	kazakh	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	kk
57ff975c-53f3-4992-b255-011439a94d61	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.655	korean	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ko
281363c0-71fd-48af-ae99-157d09471735	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.843	lao	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	lo
ffaf8edc-1da5-41c2-b692-aad08a84bee2	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:25.938	latvian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	lv
2b12f701-9457-4aa6-8496-d3b78622b82e	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.003	lithuanian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	lt
afcbffb3-5ac2-4ed4-9bb4-5edba15f4802	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.083	macedonian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	mk
05b3790a-e372-4cb8-83fa-92a514f9d50e	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.161	malay	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ms
dde2f81b-e441-4aa2-928a-bf007509fa70	{"upload_qr": "QR കോഡ് അപ്‌ലോഡ് ചെയ്യുക", "enter_code": "കോഡ് നൽകുക", "state_label": "സംസ്ഥാനം", "accept_terms": "ഞാൻ നിബന്ധനകളും വ്യവസ്ഥകളും അംഗീകരിക്കുന്നു", "country_label": "രാജ്യം", "language_label": "ഭാഷ", "continue_button": "തുടരുക", "welcome_heading": "CONNECTA-വിലേക്ക് സ്വാഗതം", "welcome_subtitle": "ദയവായി നിങ്ങളുടെ QR കോഡ് അപ്‌ലോഡ് ചെയ്യുക അല്ലെങ്കിൽ റഫറൽ കോഡ് നൽകുക", "terms_and_conditions": "നിയമങ്ങളും നിബന്ധനകളും"}	2025-07-14 12:51:26.247	malayalam	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ml
ed0393c1-d856-4795-8656-ff5b47213e96	{"upload_qr": "QR कोड अपलोड करा", "enter_code": "कोड टाका", "state_label": "राज्य", "accept_terms": "मी नियम व अटी स्वीकारतो", "country_label": "देश", "language_label": "भाषा", "continue_button": "सुरू ठेवा", "welcome_heading": "CONNECTA मध्ये आपले स्वागत आहे", "welcome_subtitle": "कृपया आपला QR कोड अपलोड करा किंवा रेफरल कोड टाका", "terms_and_conditions": "नियम व अटी"}	2025-07-14 12:51:26.473	marathi	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	mr
a40f8a05-adb7-4df3-9455-9afd206d2660	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.546	mongolian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	mn
07bae78e-ad2a-4488-b332-4955c74b8e9b	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.626	nepali	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ne
27d29314-ab9a-4def-85cb-71deacd177d7	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.759	norwegian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	no
ad7e32a0-921a-4f8d-b213-57954e03c21f	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.856	persian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	fa
546f900e-84e6-424d-86f7-eb86dfb4365d	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:26.947	polish	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	pl
406144c7-ebe0-41b8-88dd-3b3713e0dc16	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.045	portuguese	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	pt
b1cb3bc2-5e5a-408e-b53c-51921a9e1f34	{"upload_qr": "QR ਕੋਡ ਅਪਲੋਡ ਕਰੋ", "enter_code": "ਕੋਡ ਦਾਖਲ ਕਰੋ", "state_label": "ਸੂਬਾ", "accept_terms": "ਮੈਂ ਨਿਯਮਾਂ ਅਤੇ ਸ਼ਰਤਾਂ ਨੂੰ ਸਵੀਕਾਰ ਕਰਦਾ ਹਾਂ", "country_label": "ਦੇਸ਼", "language_label": "ਭਾਸ਼ਾ", "continue_button": "ਜਾਰੀ ਰੱਖੋ", "welcome_heading": "CONNECTA ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ", "welcome_subtitle": "ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ QR ਕੋਡ ਅਪਲੋਡ ਕਰੋ ਜਾਂ ਰੈਫਰਲ ਕੋਡ ਦਾਖਲ ਕਰੋ", "terms_and_conditions": "ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ"}	2025-07-14 12:51:27.354	punjabi	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	pa
5e26df02-0292-4766-bb77-9e52d73f645d	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.429	romanian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ro
c794f8ca-2c02-48f4-b7e4-2399b3a4b770	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.711	russian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ru
3cec0d3e-e6c5-4ff3-9f05-da284d6a52ec	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:27.796	serbian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	sr
bb797ab2-baa9-4a36-8fa9-fb872e2c3611	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.028	slovenian	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	sl
ab8ebd12-9b8f-4a2a-b67e-1d6cd77e0c65	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.381	swahili	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	sw
40a5ce6f-4bc2-4beb-bf3b-cc2d7b32397a	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.474	swedish	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	sv
88ca2984-2bbf-4cdb-a561-32b7b81bc413	{"upload_qr": "QR குறியீட்டை பதிவேற்றவும்", "enter_code": "குறிப்பை உள்ளிடவும்", "state_label": "மாநிலம்", "accept_terms": "நிபந்தனைகளை ஏற்கிறேன்", "country_label": "நாடு", "language_label": "மொழி", "continue_button": "தொடரவும்", "welcome_heading": "CONNECTA-க்கு வரவேற்பு", "welcome_subtitle": "உங்கள் QR குறியீட்டை பதிவேற்றவும் அல்லது பரிந்துரை குறியீட்டை உள்ளிடவும்", "terms_and_conditions": "விதிமுறைகள் மற்றும் நிபந்தனைகள்"}	2025-07-14 12:51:28.557	tamil	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ta
78fd0eb2-c340-46db-a473-b35417c3b171	{"upload_qr": "QR కోడ్ అప్లోడ్ చేయండి", "enter_code": "కోడ్ నమోదు చేయండి", "state_label": "రాష్ట్రం", "accept_terms": "నేను నిబంధనలు మరియు షరతులను అంగీకరిస్తున్నాను", "country_label": "దేశం", "language_label": "భాష", "continue_button": "కొనసాగించండి", "welcome_heading": "CONNECTA కి స్వాగతం", "welcome_subtitle": "దయచేసి మీ QR కోడ్‌ను అప్లోడ్ చేయండి లేదా రిఫరల్ కోడ్‌ను నమోదు చేయండి", "terms_and_conditions": "నిబంధనలు మరియు షరతులు"}	2025-07-14 12:51:28.624	telugu	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	te
7336582e-106c-480d-b6cd-bc0b0e1c6ac6	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:07.055	thai	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	th
7a09ec8a-a37f-4c05-b252-83046b0d9def	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-13 12:57:07.198	turkish	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	tr
60f1d39a-49ff-4425-ae59-caadc590d388	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.713	urdu	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	ur
b99b6ac8-cc27-4b11-a280-cbd7be415213	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.806	vietnamese	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	vi
e98579a4-6922-4076-8783-92142816ce89	{"upload_qr": "", "enter_code": "", "state_label": "", "accept_terms": "", "country_label": "", "language_label": "", "continue_button": "", "welcome_heading": "", "welcome_subtitle": "", "terms_and_conditions": ""}	2025-07-14 12:51:28.897	zulu	{"upload_qr": "Upload QR Code", "enter_code": "Enter Referral Code", "state_label": "Select State", "accept_terms": "I accept the terms and conditions", "country_label": "Select Country", "language_label": "Select Language", "continue_button": "Continue", "welcome_heading": "Welcome to CONNECTA", "welcome_subtitle": "Please upload your QR code or enter the referral code", "terms_and_conditions": "Terms and Conditions"}	["welcome_heading", "welcome_subtitle", "upload_qr", "enter_code", "continue_button", "accept_terms", "terms_and_conditions", "language_label", "country_label", "state_label"]	zu
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2025-07-01 09:31:58
20211116045059	2025-07-01 09:31:59
20211116050929	2025-07-01 09:32:00
20211116051442	2025-07-01 09:32:01
20211116212300	2025-07-01 09:32:01
20211116213355	2025-07-01 09:32:02
20211116213934	2025-07-01 09:32:03
20211116214523	2025-07-01 09:32:03
20211122062447	2025-07-01 09:32:04
20211124070109	2025-07-01 09:32:05
20211202204204	2025-07-01 09:32:05
20211202204605	2025-07-01 09:32:06
20211210212804	2025-07-01 09:32:08
20211228014915	2025-07-01 09:32:09
20220107221237	2025-07-01 09:32:09
20220228202821	2025-07-01 09:32:10
20220312004840	2025-07-01 09:32:11
20220603231003	2025-07-01 09:32:12
20220603232444	2025-07-01 09:32:12
20220615214548	2025-07-01 09:32:13
20220712093339	2025-07-01 09:32:14
20220908172859	2025-07-01 09:32:14
20220916233421	2025-07-01 09:32:15
20230119133233	2025-07-01 09:32:15
20230128025114	2025-07-01 09:32:16
20230128025212	2025-07-01 09:32:17
20230227211149	2025-07-01 09:32:18
20230228184745	2025-07-01 09:32:18
20230308225145	2025-07-01 09:32:19
20230328144023	2025-07-01 09:32:19
20231018144023	2025-07-01 09:32:20
20231204144023	2025-07-01 09:32:21
20231204144024	2025-07-01 09:32:22
20231204144025	2025-07-01 09:32:22
20240108234812	2025-07-01 09:32:23
20240109165339	2025-07-01 09:32:24
20240227174441	2025-07-01 09:32:25
20240311171622	2025-07-01 09:32:26
20240321100241	2025-07-01 09:32:27
20240401105812	2025-07-01 09:32:29
20240418121054	2025-07-01 09:32:30
20240523004032	2025-07-01 09:32:32
20240618124746	2025-07-01 09:32:33
20240801235015	2025-07-01 09:32:33
20240805133720	2025-07-01 09:32:34
20240827160934	2025-07-01 09:32:35
20240919163303	2025-07-01 09:32:35
20240919163305	2025-07-01 09:32:36
20241019105805	2025-07-01 09:32:37
20241030150047	2025-07-01 09:32:39
20241108114728	2025-07-01 09:32:40
20241121104152	2025-07-01 09:32:41
20241130184212	2025-07-01 09:32:41
20241220035512	2025-07-01 09:32:42
20241220123912	2025-07-01 09:32:43
20241224161212	2025-07-01 09:32:43
20250107150512	2025-07-01 09:32:44
20250110162412	2025-07-01 09:32:44
20250123174212	2025-07-01 09:32:45
20250128220012	2025-07-01 09:32:46
20250506224012	2025-07-01 09:32:46
20250523164012	2025-07-01 09:32:47
20250714121412	2025-07-21 23:42:32
20250905041441	2025-09-26 09:47:00
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
business-images	business-images	\N	2025-08-29 01:19:58.022656+00	2025-08-29 01:19:58.022656+00	t	f	\N	\N	\N	STANDARD
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_analytics (id, type, format, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2025-07-01 09:31:58.423512
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2025-07-01 09:31:58.427486
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2025-07-01 09:31:58.429757
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2025-07-01 09:31:58.441678
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2025-07-01 09:31:58.448377
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2025-07-01 09:31:58.450861
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2025-07-01 09:31:58.454613
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2025-07-01 09:31:58.457112
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2025-07-01 09:31:58.459484
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2025-07-01 09:31:58.462195
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2025-07-01 09:31:58.465767
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2025-07-01 09:31:58.468581
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2025-07-01 09:31:58.472033
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2025-07-01 09:31:58.474555
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2025-07-01 09:31:58.477517
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2025-07-01 09:31:58.491169
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2025-07-01 09:31:58.493889
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2025-07-01 09:31:58.496393
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2025-07-01 09:31:58.499414
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2025-07-01 09:31:58.504093
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2025-07-01 09:31:58.506834
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2025-07-01 09:31:58.511803
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2025-07-01 09:31:58.522054
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2025-07-01 09:31:58.5309
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2025-07-01 09:31:58.533933
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2025-07-01 09:31:58.537679
26	objects-prefixes	ef3f7871121cdc47a65308e6702519e853422ae2	2025-08-26 17:02:55.680974
27	search-v2	33b8f2a7ae53105f028e13e9fcda9dc4f356b4a2	2025-08-26 17:02:55.982153
28	object-bucket-name-sorting	ba85ec41b62c6a30a3f136788227ee47f311c436	2025-08-26 17:02:56.276192
29	create-prefixes	a7b1a22c0dc3ab630e3055bfec7ce7d2045c5b7b	2025-08-26 17:02:56.482526
30	update-object-levels	6c6f6cc9430d570f26284a24cf7b210599032db7	2025-08-26 17:02:56.490536
31	objects-level-index	33f1fef7ec7fea08bb892222f4f0f5d79bab5eb8	2025-08-26 17:02:56.596727
32	backward-compatible-index-on-objects	2d51eeb437a96868b36fcdfb1ddefdf13bef1647	2025-08-26 17:02:56.779858
33	backward-compatible-index-on-prefixes	fe473390e1b8c407434c0e470655945b110507bf	2025-08-26 17:02:56.886823
34	optimize-search-function-v1	82b0e469a00e8ebce495e29bfa70a0797f7ebd2c	2025-08-26 17:02:56.888791
35	add-insert-trigger-prefixes	63bb9fd05deb3dc5e9fa66c83e82b152f0caf589	2025-08-26 17:02:56.987151
36	optimise-existing-functions	81cf92eb0c36612865a18016a38496c530443899	2025-08-26 17:02:57.083465
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2025-08-26 17:02:57.281385
38	iceberg-catalog-flag-on-buckets	19a8bd89d5dfa69af7f222a46c726b7c41e462c5	2025-08-26 17:02:57.391375
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata, level) FROM stdin;
044a2aac-694d-4ab4-9a4e-ee4fea9de494	business-images	logos/1756430508637-cgo3n1-chpf-logo.jpg	\N	2025-08-29 01:21:49.695829+00	2025-08-29 01:21:49.695829+00	2025-08-29 01:21:49.695829+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T01:21:50.000Z", "contentLength": 57881, "httpStatusCode": 200}	098e2ca6-c77e-408d-aa1a-fb40f290f584	\N	{}	2
d9e98227-20f1-4d29-8325-5a2ba848b8f3	business-images	logos/1757811186328-ui9k58-chpf-logo.jpg	\N	2025-09-14 00:53:07.222598+00	2025-09-14 00:53:07.222598+00	2025-09-14 00:53:07.222598+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T00:53:08.000Z", "contentLength": 57881, "httpStatusCode": 200}	16aaf316-0468-4d4e-ac44-3e82d82309de	\N	{}	2
b71ded16-4a69-487f-a3a1-4e7a8553d064	business-images	logos/1756431540538-smg65u-chpf-logo.jpg	\N	2025-08-29 01:39:01.65552+00	2025-08-29 01:39:01.65552+00	2025-08-29 01:39:01.65552+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T01:39:02.000Z", "contentLength": 57881, "httpStatusCode": 200}	1ee9bac5-0848-49d0-933d-f790d8f97ed3	\N	{}	2
06eea5a4-90bc-45ba-a00e-672fa42ba7b2	business-images	logos/1756431571581-2ge6b5-chpf-logo.jpg	\N	2025-08-29 01:39:32.524019+00	2025-08-29 01:39:32.524019+00	2025-08-29 01:39:32.524019+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T01:39:33.000Z", "contentLength": 57881, "httpStatusCode": 200}	e15f7cb7-ea78-46e5-afbe-8276088483a3	\N	{}	2
d35f1d34-93e5-4f84-9fe8-7d5fd5701c2e	business-images	logos/1757934227576-drwi2z-chpf-logo.jpg	\N	2025-09-15 11:03:49.148092+00	2025-09-15 11:03:49.148092+00	2025-09-15 11:03:49.148092+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-15T11:03:50.000Z", "contentLength": 57881, "httpStatusCode": 200}	457dae89-1d3c-4e9d-9c4d-8c2223b79635	\N	{}	2
ac4ed2f5-a645-4b31-9ab5-afd3f5cda72a	business-images	logos/1756434609363-9o4czc-chpf-logo.jpg	\N	2025-08-29 02:30:10.401869+00	2025-08-29 02:30:10.401869+00	2025-08-29 02:30:10.401869+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T02:30:11.000Z", "contentLength": 57881, "httpStatusCode": 200}	fb03c58e-a136-416f-89fb-aac75f746a9c	\N	{}	2
bc4ab53d-81e8-451c-b04b-3f3498d9cc1b	business-images	logos/1756434760151-jkp3wl-chpf-logo.jpg	\N	2025-08-29 02:32:41.055748+00	2025-08-29 02:32:41.055748+00	2025-08-29 02:32:41.055748+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T02:32:42.000Z", "contentLength": 57881, "httpStatusCode": 200}	83f0117a-7e9e-4a10-a26c-a44c9ffe999d	\N	{}	2
71d826f0-130c-4b64-be9c-6f1eeb8dd8ee	business-images	logos/1756437076028-d2n60j-chpf-logo.jpg	\N	2025-08-29 03:11:17.144375+00	2025-08-29 03:11:17.144375+00	2025-08-29 03:11:17.144375+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T03:11:18.000Z", "contentLength": 57881, "httpStatusCode": 200}	f4091c57-a649-47c5-b8dc-da733df27724	\N	{}	2
23689b14-6b69-4ad4-97f9-7e050341a576	business-images	logos/1756460666445-aktczr-chpf-logo.jpg	\N	2025-08-29 09:44:29.816875+00	2025-08-29 09:44:29.816875+00	2025-08-29 09:44:29.816875+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T09:44:30.000Z", "contentLength": 57881, "httpStatusCode": 200}	47b84796-fe55-43ee-8e36-80b823d4a8da	\N	{}	2
41544b47-3169-4880-9957-5aa075312e8a	business-images	logos/1756462222717-ran480-chpf-logo.jpg	\N	2025-08-29 10:10:23.820716+00	2025-08-29 10:10:23.820716+00	2025-08-29 10:10:23.820716+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T10:10:24.000Z", "contentLength": 57881, "httpStatusCode": 200}	c8785de0-d6b7-4e7e-baef-8f04748366ea	\N	{}	2
80df0563-b671-4896-91d1-02fb4236e855	business-images	logos/1756463109468-wjvm95-chpf-logo.jpg	\N	2025-08-29 10:25:10.733243+00	2025-08-29 10:25:10.733243+00	2025-08-29 10:25:10.733243+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T10:25:11.000Z", "contentLength": 57881, "httpStatusCode": 200}	5765f9bb-72d5-4ee9-9d19-4382cd9b385d	\N	{}	2
2cf04443-505c-4c14-8a0f-ee20776da8b4	business-images	logos/1756463908979-qhrq01-chpf-logo.jpg	\N	2025-08-29 10:38:30.258543+00	2025-08-29 10:38:30.258543+00	2025-08-29 10:38:30.258543+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T10:38:31.000Z", "contentLength": 57881, "httpStatusCode": 200}	cd18caa8-75cc-404e-bd37-d21c41f286f6	\N	{}	2
19edc671-30c0-44ec-9549-c1f1630ae816	business-images	logos/1756464934933-0nrz81-chpf-logo.jpg	\N	2025-08-29 10:55:36.202152+00	2025-08-29 10:55:36.202152+00	2025-08-29 10:55:36.202152+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T10:55:37.000Z", "contentLength": 57881, "httpStatusCode": 200}	4e9775a3-8cf4-4082-a302-0cba87a8941d	\N	{}	2
ba4ceba3-ac1d-48f5-8577-ad234d3be553	business-images	logos/1756465481131-rrcqg7-chpf-logo.jpg	\N	2025-08-29 11:04:42.244617+00	2025-08-29 11:04:42.244617+00	2025-08-29 11:04:42.244617+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T11:04:43.000Z", "contentLength": 57881, "httpStatusCode": 200}	d9f541da-6b61-445e-84ef-7edede77ff8d	\N	{}	2
5d2ca179-bc7b-4255-85e8-8b2953a6df40	business-images	logos/1757848406434-mtkih4-chpf-logo.jpg	\N	2025-09-14 11:13:27.493428+00	2025-09-14 11:13:27.493428+00	2025-09-14 11:13:27.493428+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T11:13:28.000Z", "contentLength": 57881, "httpStatusCode": 200}	9e9aeae5-518c-4eaa-916a-d262917f9294	\N	{}	2
87d0315e-eaaf-4ab2-8467-6f067809d529	business-images	logos/1756465910256-vf8lx3-chpf-logo.jpg	\N	2025-08-29 11:11:51.443219+00	2025-08-29 11:11:51.443219+00	2025-08-29 11:11:51.443219+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T11:11:52.000Z", "contentLength": 57881, "httpStatusCode": 200}	d4f63bf6-d45c-426b-a102-504e98eda0fc	\N	{}	2
fce25500-7d91-4783-a86e-691413318a21	business-images	logos/1756466442392-eclmnj-chpf-logo.jpg	\N	2025-08-29 11:20:43.500417+00	2025-08-29 11:20:43.500417+00	2025-08-29 11:20:43.500417+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T11:20:44.000Z", "contentLength": 57881, "httpStatusCode": 200}	24a0d212-7d1d-4993-a943-a2d6502df7e1	\N	{}	2
b4682aea-0dce-419b-a261-ef1093905559	business-images	logos/1757935207698-0idalv-a.jpg	\N	2025-09-15 11:20:08.948158+00	2025-09-15 11:20:08.948158+00	2025-09-15 11:20:08.948158+00	{"eTag": "\\"e0924b0388e1928857bb748c3fa8ebf3\\"", "size": 266902, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-15T11:20:09.000Z", "contentLength": 266902, "httpStatusCode": 200}	e1ef1f76-c86d-4feb-a5c7-51deb4fc614c	\N	{}	2
df9e28b9-f64e-4564-99a0-b0ca3e380b21	business-images	logos/1756466896415-ob20r4-chpf-logo.jpg	\N	2025-08-29 11:28:17.635665+00	2025-08-29 11:28:17.635665+00	2025-08-29 11:28:17.635665+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-29T11:28:18.000Z", "contentLength": 57881, "httpStatusCode": 200}	1652620b-b090-4a66-a509-38a8847bd7a1	\N	{}	2
09021b08-5160-4f98-b7b5-2faf7eabb1b9	business-images	logos/1756513116093-4bem83-chpf-logo.jpg	\N	2025-08-30 00:18:37.415254+00	2025-08-30 00:18:37.415254+00	2025-08-30 00:18:37.415254+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T00:18:38.000Z", "contentLength": 57881, "httpStatusCode": 200}	ee1ff30a-6da7-4d43-8624-ce3dead893a3	\N	{}	2
260a6399-0fa5-4249-a86f-14394a706301	business-images	logos/1756513868329-3r8j38-chpf-logo.jpg	\N	2025-08-30 00:31:14.523169+00	2025-08-30 00:31:14.523169+00	2025-08-30 00:31:14.523169+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T00:31:15.000Z", "contentLength": 57881, "httpStatusCode": 200}	b87083b6-371e-4da0-98dd-861121680831	\N	{}	2
240ba91d-9de5-4309-a64a-10c900f767e7	business-images	logos/1756513884169-3czg28-chpf-logo.jpg	\N	2025-08-30 00:31:27.721453+00	2025-08-30 00:31:27.721453+00	2025-08-30 00:31:27.721453+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T00:31:28.000Z", "contentLength": 57881, "httpStatusCode": 200}	29159fb1-d412-4b9f-939f-b9f437ad88ae	\N	{}	2
3d986fd0-68de-42aa-a679-d372a8eb73a6	business-images	logos/1756513956734-y3qdoi-chpf-logo.jpg	\N	2025-08-30 00:32:38.209745+00	2025-08-30 00:32:38.209745+00	2025-08-30 00:32:38.209745+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T00:32:39.000Z", "contentLength": 57881, "httpStatusCode": 200}	37a66ace-c75b-4c58-867e-c2d3ad2c413b	\N	{}	2
900c771c-19a9-490d-98d0-424fbccc6027	business-images	logos/1756514985983-9yyuh3-chpf-logo.jpg	\N	2025-08-30 00:49:47.318719+00	2025-08-30 00:49:47.318719+00	2025-08-30 00:49:47.318719+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T00:49:48.000Z", "contentLength": 57881, "httpStatusCode": 200}	46e4502a-14a6-49ef-8463-6709375edfce	\N	{}	2
78e3917d-7857-4273-94b7-adcdee6037de	business-images	logos/1756518855754-rne5hd-chpf-logo.jpg	\N	2025-08-30 01:54:17.295601+00	2025-08-30 01:54:17.295601+00	2025-08-30 01:54:17.295601+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T01:54:18.000Z", "contentLength": 57881, "httpStatusCode": 200}	7170f1d4-5cee-4259-a3dd-49593e49551e	\N	{}	2
67323675-42d4-45ff-832d-fa46b8cb16bf	business-images	logos/1756519202283-wj9y60-chpf-logo.jpg	\N	2025-08-30 02:00:04.198624+00	2025-08-30 02:00:04.198624+00	2025-08-30 02:00:04.198624+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-30T02:00:05.000Z", "contentLength": 57881, "httpStatusCode": 200}	ff6de260-52c5-4cc1-82a9-662d26a942ec	\N	{}	2
70642517-5a68-49e9-8c76-0317c4eb0d38	business-images	logos/1756633851683-z72wez-connecta-logo.png	\N	2025-08-31 09:50:52.448702+00	2025-08-31 09:50:52.448702+00	2025-08-31 09:50:52.448702+00	{"eTag": "\\"0edeedf1f2bf9ae2fd5d3f5904268f3a\\"", "size": 47680, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T09:50:53.000Z", "contentLength": 47680, "httpStatusCode": 200}	e872f065-5957-46ef-a730-cf318e063fe4	\N	{}	2
c72cbf79-e62a-45e3-9113-26609db048c0	business-images	logos/1757849643530-zpn1y2-chpf-logo.jpg	\N	2025-09-14 11:34:04.603793+00	2025-09-14 11:34:04.603793+00	2025-09-14 11:34:04.603793+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T11:34:05.000Z", "contentLength": 57881, "httpStatusCode": 200}	23f091cb-55d7-4a0d-b0ac-a4a5a15d2fc1	\N	{}	2
efe98744-ea91-4226-bfb1-2dd6865155e4	business-images	logos/1756634051396-2elrda-connecta-logo.png	\N	2025-08-31 09:54:12.127422+00	2025-08-31 09:54:12.127422+00	2025-08-31 09:54:12.127422+00	{"eTag": "\\"0edeedf1f2bf9ae2fd5d3f5904268f3a\\"", "size": 47680, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T09:54:13.000Z", "contentLength": 47680, "httpStatusCode": 200}	d421b482-064b-429e-936b-2c9a575308d1	\N	{}	2
5ef8dd89-016b-4aa0-9590-c564d6031177	business-images	logos/1756634249051-89h7sn-connecta-logo.png	\N	2025-08-31 09:57:29.774678+00	2025-08-31 09:57:29.774678+00	2025-08-31 09:57:29.774678+00	{"eTag": "\\"0edeedf1f2bf9ae2fd5d3f5904268f3a\\"", "size": 47680, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T09:57:30.000Z", "contentLength": 47680, "httpStatusCode": 200}	ff4350cc-725a-43cc-bbfc-ac4228e45dc5	\N	{}	2
9df62594-8431-4bac-b199-c6bd7c0edfd8	business-images	logos/1757850123547-qrdwm7-chpf-logo.jpg	\N	2025-09-14 11:42:04.702395+00	2025-09-14 11:42:04.702395+00	2025-09-14 11:42:04.702395+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T11:42:05.000Z", "contentLength": 57881, "httpStatusCode": 200}	a0e348f8-2543-4bcb-a8e0-fd5ebc44a2f8	\N	{}	2
11d3726b-3bb8-400f-a5d2-f418e65edf88	business-images	logos/1756635534977-0rgom5-chpf-logo.jpg	\N	2025-08-31 10:18:55.77776+00	2025-08-31 10:18:55.77776+00	2025-08-31 10:18:55.77776+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T10:18:56.000Z", "contentLength": 57881, "httpStatusCode": 200}	222336fd-9792-48f0-a4a2-429bc8bd74ba	\N	{}	2
b1030184-bf41-4148-8945-b5e7116668aa	business-images	logos/1756638792108-58pyd1-chpf-logo.jpg	\N	2025-08-31 11:13:12.910819+00	2025-08-31 11:13:12.910819+00	2025-08-31 11:13:12.910819+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T11:13:13.000Z", "contentLength": 57881, "httpStatusCode": 200}	da5674f6-6c73-4c76-8624-6c7a9f59334e	\N	{}	2
f4b1d826-14f4-4d03-be72-b75f67267450	business-images	logos/1757850587286-tek19d-chpf-logo.jpg	\N	2025-09-14 11:49:48.593475+00	2025-09-14 11:49:48.593475+00	2025-09-14 11:49:48.593475+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T11:49:49.000Z", "contentLength": 57881, "httpStatusCode": 200}	a2596e2e-e04d-46e9-b999-15370860367e	\N	{}	2
da2e9039-3c9b-4714-9c50-c062f33ebbca	business-images	logos/1756641463578-5bj470-chpf-logo.jpg	\N	2025-08-31 11:57:44.427415+00	2025-08-31 11:57:44.427415+00	2025-08-31 11:57:44.427415+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T11:57:45.000Z", "contentLength": 57881, "httpStatusCode": 200}	32cea9bc-167a-4750-9a40-6135c89b3874	\N	{}	2
eb1b869c-69ca-4788-844b-f61c94e7772b	business-images	logos/1756644268248-ej8q9r-chpf-logo.jpg	\N	2025-08-31 12:44:29.184462+00	2025-08-31 12:44:29.184462+00	2025-08-31 12:44:29.184462+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T12:44:30.000Z", "contentLength": 57881, "httpStatusCode": 200}	46ea3395-8263-4558-8e63-350c403e225c	\N	{}	2
f3eec077-425f-411b-a0b7-5ef852523c4b	business-images	logos/1756645248989-0dur3n-chpf-logo.jpg	\N	2025-08-31 13:00:49.840893+00	2025-08-31 13:00:49.840893+00	2025-08-31 13:00:49.840893+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T13:00:50.000Z", "contentLength": 57881, "httpStatusCode": 200}	4c1d6cae-e544-421c-a913-87535d55293e	\N	{}	2
010146b0-16ae-4351-ad1b-8c1ce1af2781	business-images	logos/1756645445676-5bv7wo-chpf-logo.jpg	\N	2025-08-31 13:04:06.573246+00	2025-08-31 13:04:06.573246+00	2025-08-31 13:04:06.573246+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T13:04:07.000Z", "contentLength": 57881, "httpStatusCode": 200}	42f65eb5-1381-4aae-a7f3-10164a83d08a	\N	{}	2
518efa1e-b5dd-45d1-96fd-71da1d289faf	business-images	logos/1756645644149-vqixtg-chpf-logo.jpg	\N	2025-08-31 13:07:25.043535+00	2025-08-31 13:07:25.043535+00	2025-08-31 13:07:25.043535+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-31T13:07:26.000Z", "contentLength": 57881, "httpStatusCode": 200}	4c435b95-776a-462f-ac79-f7c309f78b2c	\N	{}	2
62cb05be-84f2-43aa-a5e6-ba199f8b586d	business-images	logos/1756685811835-g070ky-chpf-logo.jpg	\N	2025-09-01 00:16:52.025306+00	2025-09-01 00:16:52.025306+00	2025-09-01 00:16:52.025306+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T00:16:52.000Z", "contentLength": 57881, "httpStatusCode": 200}	e0b3e9f4-2682-4ff0-adf7-d1d23edbdaf9	\N	{}	2
d685407f-0a68-43b9-badc-67e3e4eae58d	business-images	logos/1756686161893-7nbeyt-chpf-logo.jpg	\N	2025-09-01 00:22:42.145443+00	2025-09-01 00:22:42.145443+00	2025-09-01 00:22:42.145443+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T00:22:43.000Z", "contentLength": 57881, "httpStatusCode": 200}	bcf2fcc4-a449-4fba-b9d6-46fd6dcaed24	\N	{}	2
2c47071c-657b-4a01-aae5-ada109561206	business-images	logos/1757906496647-yji645-connecta-logo.png	\N	2025-09-15 03:21:37.993325+00	2025-09-15 03:21:37.993325+00	2025-09-15 03:21:37.993325+00	{"eTag": "\\"0edeedf1f2bf9ae2fd5d3f5904268f3a\\"", "size": 47680, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-09-15T03:21:38.000Z", "contentLength": 47680, "httpStatusCode": 200}	48b8f99c-28bf-4986-8e46-b483152dc597	\N	{}	2
602cfabe-a479-432f-87a4-01402d905529	business-images	logos/1756686423272-v5stf5-chpf-logo.jpg	\N	2025-09-01 00:27:03.545775+00	2025-09-01 00:27:03.545775+00	2025-09-01 00:27:03.545775+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T00:27:04.000Z", "contentLength": 57881, "httpStatusCode": 200}	3479e7c9-19f3-4fe8-a805-c82da2a5e441	\N	{}	2
602992d9-71de-4d2d-bff5-433c05af871e	business-images	logos/1758013699180-2mkwfq-chpf-logo.jpg	\N	2025-09-16 09:08:20.905256+00	2025-09-16 09:08:20.905256+00	2025-09-16 09:08:20.905256+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-16T09:08:21.000Z", "contentLength": 57881, "httpStatusCode": 200}	f70981f2-947c-4d7d-bde7-1e0dfebd4962	\N	{}	2
9002ce9b-c28b-4819-9509-68b163ae2a48	business-images	logos/1756687445103-clvhzb-chpf-logo.jpg	\N	2025-09-01 00:44:05.309917+00	2025-09-01 00:44:05.309917+00	2025-09-01 00:44:05.309917+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T00:44:06.000Z", "contentLength": 57881, "httpStatusCode": 200}	e9889a45-51d2-46b5-a99d-27e2df6e6b3c	\N	{}	2
d0a7d5f6-c62b-4a49-8fef-7ebada722d6b	business-images	logos/1756688198660-zos0w4-chpf-logo.jpg	\N	2025-09-01 00:56:38.734118+00	2025-09-01 00:56:38.734118+00	2025-09-01 00:56:38.734118+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T00:56:39.000Z", "contentLength": 57881, "httpStatusCode": 200}	483fb41d-750f-4974-bf19-09cb3a58b129	\N	{}	2
fb247d76-d2e6-48f8-afdf-694b787955bf	business-images	logos/1756688505667-ewczz3-chpf-logo.jpg	\N	2025-09-01 01:01:45.873992+00	2025-09-01 01:01:45.873992+00	2025-09-01 01:01:45.873992+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T01:01:46.000Z", "contentLength": 57881, "httpStatusCode": 200}	acaf2a34-65c0-41ea-b94c-cafe8383f35f	\N	{}	2
0afa6e18-e0f5-4602-8364-37033b5bc1ca	business-images	logos/1756689542186-9ds2d0-chpf-logo.jpg	\N	2025-09-01 01:19:02.495175+00	2025-09-01 01:19:02.495175+00	2025-09-01 01:19:02.495175+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T01:19:03.000Z", "contentLength": 57881, "httpStatusCode": 200}	fe780153-4888-4bd1-9fc7-1db191075bb8	\N	{}	2
2a0bcf6f-2cb1-4012-bfd4-bc435e7093ae	business-images	logos/1756690164568-heheuv-chpf-logo.jpg	\N	2025-09-01 01:29:24.825621+00	2025-09-01 01:29:24.825621+00	2025-09-01 01:29:24.825621+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-01T01:29:25.000Z", "contentLength": 57881, "httpStatusCode": 200}	ccbc8e9d-9b9b-428b-a702-f142937630d8	\N	{}	2
5f67d6cb-1bbf-4332-a9bb-55cbe53d4225	business-images	logos/1756808822689-z2baia-chpf-logo.jpg	\N	2025-09-02 10:27:03.388488+00	2025-09-02 10:27:03.388488+00	2025-09-02 10:27:03.388488+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-02T10:27:04.000Z", "contentLength": 57881, "httpStatusCode": 200}	5eb0dafe-6524-43a0-b572-627068caeb14	\N	{}	2
607ea7ed-f408-4c7b-a1da-b9cda2793369	business-images	logos/1756809340340-f398fo-chpf-logo.jpg	\N	2025-09-02 10:35:41.134926+00	2025-09-02 10:35:41.134926+00	2025-09-02 10:35:41.134926+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-02T10:35:42.000Z", "contentLength": 57881, "httpStatusCode": 200}	f4b1f987-9c64-4f5c-b3f2-612083e14532	\N	{}	2
8df7cf20-1e8b-4fb4-9278-0cd3e9746ea2	business-images	logos/1756903250510-42s0w3-connecta-logo.png	\N	2025-09-03 12:40:51.549645+00	2025-09-03 12:40:51.549645+00	2025-09-03 12:40:51.549645+00	{"eTag": "\\"0edeedf1f2bf9ae2fd5d3f5904268f3a\\"", "size": 47680, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-09-03T12:40:52.000Z", "contentLength": 47680, "httpStatusCode": 200}	2118e770-dccf-48ee-b231-32b0444c3a4a	\N	{}	2
e7f2dc4d-96af-4889-89dc-e0515b0265c1	business-images	logos/1756987107954-1kcc52-a.jpg	\N	2025-09-04 11:58:28.701747+00	2025-09-04 11:58:28.701747+00	2025-09-04 11:58:28.701747+00	{"eTag": "\\"e0924b0388e1928857bb748c3fa8ebf3\\"", "size": 266902, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-04T11:58:29.000Z", "contentLength": 266902, "httpStatusCode": 200}	bd11e1fe-d0c5-4569-b9ad-737301d4d6be	\N	{}	2
739461d4-9d4c-4154-8eb6-dd5ad8bc2eee	business-images	logos/1757118264307-h4t36b-chpf-logo.jpg	\N	2025-09-06 00:24:24.087863+00	2025-09-06 00:24:24.087863+00	2025-09-06 00:24:24.087863+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-06T00:24:25.000Z", "contentLength": 57881, "httpStatusCode": 200}	4dff806a-aec6-47a1-8640-ee9dbcf66f20	\N	{}	2
c7491bfa-06a0-472b-847f-6edc4532519b	business-images	logos/1757907195657-qkj14d-connecta-logo.png	\N	2025-09-15 03:33:16.828262+00	2025-09-15 03:33:16.828262+00	2025-09-15 03:33:16.828262+00	{"eTag": "\\"0edeedf1f2bf9ae2fd5d3f5904268f3a\\"", "size": 47680, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-09-15T03:33:17.000Z", "contentLength": 47680, "httpStatusCode": 200}	1ceb107e-4659-4381-9ee7-8f1b5dd0b187	\N	{}	2
3a54dadb-8d59-482b-8c4f-3fc7edee5740	business-images	logos/1757120523032-hq15bc-chpf-logo.jpg	\N	2025-09-06 01:02:02.741055+00	2025-09-06 01:02:02.741055+00	2025-09-06 01:02:02.741055+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-06T01:02:03.000Z", "contentLength": 57881, "httpStatusCode": 200}	c8a905d5-b72f-4cbb-9411-bc82c6c6ba57	\N	{}	2
218d0828-a62f-4cd6-ba57-a18fe88265a7	business-images	logos/1757122218636-ymgh4w-chpf-logo.jpg	\N	2025-09-06 01:30:18.257728+00	2025-09-06 01:30:18.257728+00	2025-09-06 01:30:18.257728+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-06T01:30:19.000Z", "contentLength": 57881, "httpStatusCode": 200}	c55c08c5-bdb9-4fbb-83ba-213bf8487221	\N	{}	2
6cbf340a-68bb-4a3c-bf4d-99e5d1c3d327	business-images	logos/1757808177886-ys13qh-chpf-logo.jpg	\N	2025-09-14 00:02:58.825018+00	2025-09-14 00:02:58.825018+00	2025-09-14 00:02:58.825018+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T00:02:59.000Z", "contentLength": 57881, "httpStatusCode": 200}	7df1f86e-1039-4a74-a368-f47d4ba49e3a	\N	{}	2
4af1caeb-eea4-4dc2-b54b-07b5f4044a06	business-images	logos/1757808471791-h7hrxh-chpf-logo.jpg	\N	2025-09-14 00:07:52.779843+00	2025-09-14 00:07:52.779843+00	2025-09-14 00:07:52.779843+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T00:07:53.000Z", "contentLength": 57881, "httpStatusCode": 200}	cf20a561-12f3-497a-86f8-850bee736392	\N	{}	2
4112c599-3146-4276-82cd-884b66fed2b1	business-images	logos/1757808661910-2y064y-chpf-logo.jpg	\N	2025-09-14 00:11:02.899803+00	2025-09-14 00:11:02.899803+00	2025-09-14 00:11:02.899803+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T00:11:03.000Z", "contentLength": 57881, "httpStatusCode": 200}	505430e9-b03c-4eb5-b80a-4eb493164532	\N	{}	2
b6155076-faf7-4e40-aa67-d40904cbeb62	business-images	logos/1757810558398-7hrhnc-chpf-logo.jpg	\N	2025-09-14 00:42:39.285676+00	2025-09-14 00:42:39.285676+00	2025-09-14 00:42:39.285676+00	{"eTag": "\\"9c2e04c80b621bc98d4ba3021c249829\\"", "size": 57881, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-09-14T00:42:40.000Z", "contentLength": 57881, "httpStatusCode": 200}	55f6b998-3f5d-4ef2-9114-7e539682007c	\N	{}	2
\.


--
-- Data for Name: prefixes; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.prefixes (bucket_id, name, created_at, updated_at) FROM stdin;
business-images	logos	2025-08-29 01:21:49.695829+00	2025-08-29 01:21:49.695829+00
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 1, false);


--
-- Name: aa_connectors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.aa_connectors_id_seq', 167, true);


--
-- Name: connecta_global_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.connecta_global_seq', 1, false);


--
-- Name: connectors_connectaid_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.connectors_connectaid_seq', 53, true);


--
-- Name: pending_classifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pending_classifications_id_seq', 5, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: aa_connectors aa_connectors_mobile_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aa_connectors
    ADD CONSTRAINT aa_connectors_mobile_key UNIQUE (mobile);


--
-- Name: aa_connectors aa_connectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aa_connectors
    ADD CONSTRAINT aa_connectors_pkey PRIMARY KEY (id);


--
-- Name: connectors chk_referral_matches_connectaid; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.connectors
    ADD CONSTRAINT chk_referral_matches_connectaid CHECK ((("referralCode" IS NULL) OR (level_sequence IS NULL) OR ("left"("referralCode", length(((((((COALESCE(country, ''::text) || '_'::text) || COALESCE(state, ''::text)) || '_'::text) || public.region_tag(country, state)) || upper((COALESCE(level, 'AA'::bpchar))::text)) || to_char(level_sequence, 'FM000000000'::text)))) = ((((((COALESCE(country, ''::text) || '_'::text) || COALESCE(state, ''::text)) || '_'::text) || public.region_tag(country, state)) || upper((COALESCE(level, 'AA'::bpchar))::text)) || to_char(level_sequence, 'FM000000000'::text))))) NOT VALID;


--
-- Name: commission_splits commission_splits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_splits
    ADD CONSTRAINT commission_splits_pkey PRIMARY KEY (id);


--
-- Name: commissions commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commissions
    ADD CONSTRAINT commissions_pkey PRIMARY KEY (id);


--
-- Name: connector_counters connector_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_counters
    ADD CONSTRAINT connector_counters_pkey PRIMARY KEY (parent_id, child_level);


--
-- Name: connector_prospects connector_prospects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_prospects
    ADD CONSTRAINT connector_prospects_pkey PRIMARY KEY (id);


--
-- Name: connectors connectors_mobile_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connectors
    ADD CONSTRAINT connectors_mobile_number_key UNIQUE (mobile_number);


--
-- Name: connectors connectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connectors
    ADD CONSTRAINT connectors_pkey PRIMARY KEY (id);


--
-- Name: country_codes country_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_codes
    ADD CONSTRAINT country_codes_pkey PRIMARY KEY (country);


--
-- Name: country_states country_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_states
    ADD CONSTRAINT country_states_pkey PRIMARY KEY (id);


--
-- Name: id_counters id_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_counters
    ADD CONSTRAINT id_counters_pkey PRIMARY KEY (scope);


--
-- Name: iso_country_overrides iso_country_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iso_country_overrides
    ADD CONSTRAINT iso_country_overrides_pkey PRIMARY KEY (country_norm);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: meeting_attendance meeting_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meeting_attendance
    ADD CONSTRAINT meeting_attendance_pkey PRIMARY KEY (meeting_id, attendee_connector_id);


--
-- Name: meetings meetings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meetings
    ADD CONSTRAINT meetings_pkey PRIMARY KEY (id);


--
-- Name: pending_classifications pending_classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_classifications
    ADD CONSTRAINT pending_classifications_pkey PRIMARY KEY (id);


--
-- Name: pincode_rules pincode_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pincode_rules
    ADD CONSTRAINT pincode_rules_pkey PRIMARY KEY (country);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: purchase_commissions purchase_commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_commissions
    ADD CONSTRAINT purchase_commissions_pkey PRIMARY KEY (id);


--
-- Name: state_codes state_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.state_codes
    ADD CONSTRAINT state_codes_pkey PRIMARY KEY (country, state);


--
-- Name: translations translations_language_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_language_code_key UNIQUE (language_code);


--
-- Name: translations translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (id);


--
-- Name: country_states unique_country; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_states
    ADD CONSTRAINT unique_country UNIQUE (country);


--
-- Name: translations unique_language_iso_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT unique_language_iso_code UNIQUE (language_iso_code);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: prefixes prefixes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT prefixes_pkey PRIMARY KEY (bucket_id, level, name);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: idx_aa_joining_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aa_joining_code ON public.aa_connectors USING btree (aa_joining_code);


--
-- Name: idx_connectors_geo_level_createdat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connectors_geo_level_createdat ON public.connectors USING btree (country, state, level, "createdAt");


--
-- Name: idx_connectors_recovery_mobile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connectors_recovery_mobile ON public.connectors USING btree ("recoveryMobile");


--
-- Name: idx_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_country ON public.pincode_rules USING btree (country);


--
-- Name: idx_prospects_inviter_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospects_inviter_ref ON public.connector_prospects USING btree (inviter_referral_code);


--
-- Name: ix_connectors_connectaid_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_connectors_connectaid_prefix ON public.connectors USING btree ("connectaID" text_pattern_ops);


--
-- Name: ix_connectors_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_connectors_parent ON public.connectors USING btree (parent_connector_id);


--
-- Name: ix_connectors_path_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_connectors_path_ids ON public.connectors USING gin (path_ids public.gin_trgm_ops);


--
-- Name: unique_language_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_language_code ON public.translations USING btree (language_code);


--
-- Name: uq_aa_connectors_mobile; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_aa_connectors_mobile ON public.aa_connectors USING btree (mobile);


--
-- Name: ux_connectors_active_branch_serial; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_connectors_active_branch_serial ON public.connectors USING btree (regexp_replace(split_part("referralCode", '_'::text, 3), '\d.*$'::text, ''::text), "connectaID") WHERE (("referralCode" IS NOT NULL) AND (is_active = true));


--
-- Name: ux_connectors_active_refseg; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_connectors_active_refseg ON public.connectors USING btree (split_part("referralCode", '_'::text, 3)) WHERE (("referralCode" IS NOT NULL) AND (is_active = true));


--
-- Name: ux_connectors_global_connecta_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_connectors_global_connecta_id ON public.connectors USING btree (global_connecta_id) WHERE (global_connecta_id IS NOT NULL);


--
-- Name: ux_connectors_referralcode_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_connectors_referralcode_unique ON public.connectors USING btree ("referralCode") WHERE ("referralCode" IS NOT NULL);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_key ON realtime.subscription USING btree (subscription_id, entity, filters);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_name_bucket_level_unique; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX idx_name_bucket_level_unique ON storage.objects USING btree (name COLLATE "C", bucket_id, level);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_lower_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_lower_name ON storage.objects USING btree ((path_tokens[level]), lower(name) text_pattern_ops, bucket_id, level);


--
-- Name: idx_prefixes_lower_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_prefixes_lower_name ON storage.prefixes USING btree (bucket_id, level, ((string_to_array(name, '/'::text))[level]), lower(name) text_pattern_ops);


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: objects_bucket_id_level_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX objects_bucket_id_level_idx ON storage.objects USING btree (bucket_id, level, name COLLATE "C");


--
-- Name: connectors trg_assign_connecta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_assign_connecta BEFORE INSERT ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.assign_connecta_fields();

ALTER TABLE public.connectors DISABLE TRIGGER trg_assign_connecta;


--
-- Name: connectors trg_connectors_connectaid_seq; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_connectors_connectaid_seq BEFORE INSERT ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.ensure_connectaid_before_ins();

ALTER TABLE public.connectors DISABLE TRIGGER trg_connectors_connectaid_seq;


--
-- Name: connectors trg_connectors_global_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_connectors_global_id BEFORE INSERT OR UPDATE OF level, level_sequence, parent_connector_id, short_name, shortname, payload_json, company_name, "connectaID_full" ON public.connectors FOR EACH ROW EXECUTE FUNCTION connecta.tg_connectors_set_global_id();


--
-- Name: connectors trg_connectors_parent_ref_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_connectors_parent_ref_changed AFTER UPDATE OF "referralCode" ON public.connectors FOR EACH ROW EXECUTE FUNCTION connecta.tg_connectors_parent_ref_changed();


--
-- Name: connectors trg_enforce_level_progression; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_enforce_level_progression BEFORE INSERT OR UPDATE OF level, parent_connector_id ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.enforce_level_progression();


--
-- Name: connectors trg_fill_level_sequence; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_fill_level_sequence BEFORE INSERT OR UPDATE OF "connectaID", parent_connector_id, level ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.fill_level_sequence_from_connectaid();

ALTER TABLE public.connectors DISABLE TRIGGER trg_fill_level_sequence;


--
-- Name: connectors trg_fill_path_ids_ins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_fill_path_ids_ins BEFORE INSERT ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.fill_path_ids();


--
-- Name: connectors trg_fill_path_ids_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_fill_path_ids_upd BEFORE UPDATE OF parent_connector_id ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.fill_path_ids();


--
-- Name: connectors trg_prevent_cycles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_prevent_cycles BEFORE INSERT OR UPDATE OF parent_connector_id ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.prevent_cycles();


--
-- Name: connectors trg_set_global_connecta_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_global_connecta_id BEFORE INSERT OR UPDATE OF "referralCode", parent_connector_id ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.trg_set_global_connecta_id();

ALTER TABLE public.connectors DISABLE TRIGGER trg_set_global_connecta_id;


--
-- Name: connectors trg_zz_build_referral_code; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_zz_build_referral_code BEFORE INSERT OR UPDATE ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.build_referralcode();

ALTER TABLE public.connectors DISABLE TRIGGER trg_zz_build_referral_code;


--
-- Name: connectors trg_zz_fill_connectaid_full; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_zz_fill_connectaid_full BEFORE INSERT OR UPDATE OF country, state, level, "connectaID" ON public.connectors FOR EACH ROW EXECUTE FUNCTION public.fill_connectaid_full();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: objects objects_delete_delete_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_delete_delete_prefix AFTER DELETE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects objects_insert_create_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_insert_create_prefix BEFORE INSERT ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.objects_insert_prefix_trigger();


--
-- Name: objects objects_update_create_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_update_create_prefix BEFORE UPDATE ON storage.objects FOR EACH ROW WHEN (((new.name <> old.name) OR (new.bucket_id <> old.bucket_id))) EXECUTE FUNCTION storage.objects_update_prefix_trigger();


--
-- Name: prefixes prefixes_create_hierarchy; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER prefixes_create_hierarchy BEFORE INSERT ON storage.prefixes FOR EACH ROW WHEN ((pg_trigger_depth() < 1)) EXECUTE FUNCTION storage.prefixes_insert_trigger();


--
-- Name: prefixes prefixes_delete_hierarchy; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER prefixes_delete_hierarchy AFTER DELETE ON storage.prefixes FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: commission_splits commission_splits_commission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_splits
    ADD CONSTRAINT commission_splits_commission_id_fkey FOREIGN KEY (commission_id) REFERENCES public.commissions(id) ON DELETE CASCADE;


--
-- Name: commission_splits commission_splits_recipient_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_splits
    ADD CONSTRAINT commission_splits_recipient_connector_id_fkey FOREIGN KEY (recipient_connector_id) REFERENCES public.connectors(id);


--
-- Name: commissions commissions_buyer_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commissions
    ADD CONSTRAINT commissions_buyer_connector_id_fkey FOREIGN KEY (buyer_connector_id) REFERENCES public.connectors(id);


--
-- Name: connectors connectors_parent_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connectors
    ADD CONSTRAINT connectors_parent_connector_id_fkey FOREIGN KEY (parent_connector_id) REFERENCES public.connectors(id) ON DELETE CASCADE;


--
-- Name: connectors fk_connectors_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connectors
    ADD CONSTRAINT fk_connectors_parent FOREIGN KEY (parent_connector_id) REFERENCES public.connectors(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: meeting_attendance meeting_attendance_attendee_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meeting_attendance
    ADD CONSTRAINT meeting_attendance_attendee_connector_id_fkey FOREIGN KEY (attendee_connector_id) REFERENCES public.connectors(id);


--
-- Name: meeting_attendance meeting_attendance_meeting_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meeting_attendance
    ADD CONSTRAINT meeting_attendance_meeting_id_fkey FOREIGN KEY (meeting_id) REFERENCES public.meetings(id) ON DELETE CASCADE;


--
-- Name: meetings meetings_organizer_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meetings
    ADD CONSTRAINT meetings_organizer_connector_id_fkey FOREIGN KEY (organizer_connector_id) REFERENCES public.connectors(id);


--
-- Name: pending_classifications pending_classifications_suggested_by_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_classifications
    ADD CONSTRAINT pending_classifications_suggested_by_connector_id_fkey FOREIGN KEY (suggested_by_connector_id) REFERENCES public.connectors(id) ON DELETE SET NULL;


--
-- Name: products products_connector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_connector_id_fkey FOREIGN KEY (connector_id) REFERENCES public.connectors(id) ON DELETE CASCADE;


--
-- Name: state_codes state_codes_country_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.state_codes
    ADD CONSTRAINT state_codes_country_fkey FOREIGN KEY (country) REFERENCES public.country_codes(country);


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: prefixes prefixes_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT "prefixes_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: aa_connectors Allow all deletes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all deletes" ON public.aa_connectors FOR DELETE USING (true);


--
-- Name: translations Allow insert for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow insert for authenticated users" ON public.translations FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: translations Allow insert translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow insert translations" ON public.translations FOR INSERT WITH CHECK (true);


--
-- Name: translations Allow public read on translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public read on translations" ON public.translations FOR SELECT USING (true);


--
-- Name: translations Allow select translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow select translations" ON public.translations FOR SELECT USING (true);


--
-- Name: translations Allow update for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow update for authenticated users" ON public.translations FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: translations Allow update translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow update translations" ON public.translations FOR UPDATE WITH CHECK (true);


--
-- Name: aa_connectors DELETE; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "DELETE" ON public.aa_connectors FOR SELECT USING (true);


--
-- Name: aa_connectors Public Insert Access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public Insert Access" ON public.aa_connectors FOR INSERT WITH CHECK (true);


--
-- Name: aa_connectors SELECT; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "SELECT" ON public.aa_connectors FOR SELECT USING (true);


--
-- Name: aa_connectors UPDATE; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "UPDATE" ON public.aa_connectors FOR UPDATE USING (true) WITH CHECK (true);


--
-- Name: aa_connectors; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.aa_connectors ENABLE ROW LEVEL SECURITY;

--
-- Name: connector_prospects allow all via service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "allow all via service role" ON public.connector_prospects USING (true);


--
-- Name: connector_prospects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.connector_prospects ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: objects Auth insert for media; Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "Auth insert for media" ON storage.objects FOR INSERT TO authenticated WITH CHECK ((bucket_id = 'media'::text));


--
-- Name: objects Public insert for business-images (dev); Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "Public insert for business-images (dev)" ON storage.objects FOR INSERT WITH CHECK ((bucket_id = 'business-images'::text));


--
-- Name: objects Public read for business-images; Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "Public read for business-images" ON storage.objects FOR SELECT USING ((bucket_id = 'business-images'::text));


--
-- Name: objects Public read for media; Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "Public read for media" ON storage.objects FOR SELECT USING ((bucket_id = 'media'::text));


--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: prefixes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.prefixes ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

