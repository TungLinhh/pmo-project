--
-- PostgreSQL database dump
--

\restrict 96pXhuueXxD0c8vfdZCKpPjADaV3W1WExRBgrFVyUTu7mMJabTnrBOfeLvWAbBb

-- Dumped from database version 16.15 (Homebrew)
-- Dumped by pg_dump version 16.15 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: area_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.area_level AS ENUM (
    'project',
    'building',
    'zone',
    'floor',
    'area',
    'work_item'
);


--
-- Name: health_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.health_status AS ENUM (
    'ON_TRACK',
    'WATCH',
    'BEHIND',
    'CRITICAL'
);


--
-- Name: master_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.master_status AS ENUM (
    'ACTIVE',
    'INACTIVE',
    'MERGED'
);


--
-- Name: notification_channel; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_channel AS ENUM (
    'in_app',
    'email',
    'zalo_oa',
    'telegram',
    'push'
);


--
-- Name: notification_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_status AS ENUM (
    'pending',
    'sent',
    'delivered',
    'failed',
    'not_implemented'
);


--
-- Name: sync_conflict; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sync_conflict AS ENUM (
    'NONE',
    'CLIENT_NEWER',
    'SERVER_NEWER',
    'EQUAL'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'pm',
    'pmo',
    'site',
    'procurement',
    'accounting',
    'data_admin',
    'editor',
    'viewer'
);


--
-- Name: workflow_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.workflow_status AS ENUM (
    'DRAFT',
    'PENDING',
    'SUBMITTED',
    'REVIEW',
    'APPROVED',
    'REJECTED',
    'OVERDUE',
    'CLOSED'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: area_hierarchy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.area_hierarchy (
    id integer NOT NULL,
    project_id integer NOT NULL,
    parent_id integer,
    level public.area_level NOT NULL,
    code character varying(100),
    name_vi text,
    name_en text,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: area_hierarchy_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.area_hierarchy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_hierarchy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.area_hierarchy_id_seq OWNED BY public.area_hierarchy.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer,
    action character varying(50) NOT NULL,
    resource_type character varying(50),
    resource_id integer,
    before jsonb,
    after jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    user_name text,
    field_name text,
    old_value text,
    new_value text,
    note text
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: business_process_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_process_steps (
    id integer NOT NULL,
    process_id integer NOT NULL,
    ordinal integer NOT NULL,
    name_vi text,
    content_vi text,
    responsibility_vi text,
    verification_vi text
);


--
-- Name: business_process_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.business_process_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_process_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.business_process_steps_id_seq OWNED BY public.business_process_steps.id;


--
-- Name: business_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_processes (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(100) NOT NULL,
    name_vi text,
    name_en text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: business_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.business_processes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.business_processes_id_seq OWNED BY public.business_processes.id;


--
-- Name: construction_schedule_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.construction_schedule_items (
    id integer NOT NULL,
    project_id integer NOT NULL,
    zone_id integer NOT NULL,
    source_sheet text,
    level_roman character varying(10),
    level_arabic integer,
    sublevel integer,
    ordinal integer,
    name_vi text,
    name_en text,
    progress_pct real,
    status character varying(50),
    plan_start_date date,
    actual_start_date date,
    plan_end_date date,
    actual_end_date date,
    plan_duration_days integer,
    baseline_version integer DEFAULT 1,
    baseline_id integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: construction_schedule_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.construction_schedule_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: construction_schedule_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.construction_schedule_items_id_seq OWNED BY public.construction_schedule_items.id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id integer NOT NULL,
    project_id integer NOT NULL,
    vendor_id integer,
    contract_no character varying(100) NOT NULL,
    contract_name text,
    signed_date date,
    total_value numeric(18,2),
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contracts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contracts_id_seq OWNED BY public.contracts.id;


--
-- Name: cost_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cost_codes (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(50),
    name text NOT NULL,
    category character varying(100),
    unit character varying(20),
    unit_price numeric(18,2),
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: cost_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cost_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cost_codes_id_seq OWNED BY public.cost_codes.id;


--
-- Name: daily_acceptance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_acceptance (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    ordinal integer,
    name_vi text,
    quantity real,
    unit character varying(20),
    notes text
);


--
-- Name: daily_acceptance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_acceptance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_acceptance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_acceptance_id_seq OWNED BY public.daily_acceptance.id;


--
-- Name: daily_infos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_infos (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    category character varying(100),
    description text
);


--
-- Name: daily_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_infos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_infos_id_seq OWNED BY public.daily_infos.id;


--
-- Name: daily_manpower; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_manpower (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    role_code character varying(50),
    role_name_vi text,
    headcount integer DEFAULT 0,
    notes text
);


--
-- Name: daily_manpower_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_manpower_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_manpower_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_manpower_id_seq OWNED BY public.daily_manpower.id;


--
-- Name: daily_materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_materials (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    material_code character varying(50),
    name_vi text,
    unit character varying(20),
    quantity real,
    notes text
);


--
-- Name: daily_materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_materials_id_seq OWNED BY public.daily_materials.id;


--
-- Name: daily_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_recommendations (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    ordinal integer,
    text text
);


--
-- Name: daily_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_recommendations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_recommendations_id_seq OWNED BY public.daily_recommendations.id;


--
-- Name: daily_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_reports (
    id integer NOT NULL,
    project_id integer NOT NULL,
    report_date date NOT NULL,
    source_sheet_name character varying(255),
    prepared_by text,
    weather_am text,
    weather_pm text,
    work_items_count integer DEFAULT 0,
    manpower_count integer DEFAULT 0,
    materials_count integer DEFAULT 0,
    acceptance_count integer DEFAULT 0,
    status public.workflow_status DEFAULT 'DRAFT'::public.workflow_status,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    submitted_at timestamp without time zone
);


--
-- Name: daily_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_reports_id_seq OWNED BY public.daily_reports.id;


--
-- Name: daily_safety; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_safety (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    category character varying(100),
    description text
);


--
-- Name: daily_safety_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_safety_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_safety_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_safety_id_seq OWNED BY public.daily_safety.id;


--
-- Name: daily_safety_observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_safety_observations (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    category text,
    description text
);


--
-- Name: daily_safety_observations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_safety_observations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_safety_observations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_safety_observations_id_seq OWNED BY public.daily_safety_observations.id;


--
-- Name: daily_work_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_work_items (
    id integer NOT NULL,
    daily_report_id integer NOT NULL,
    parent_id integer,
    ordinal integer,
    name_vi text,
    system_vi text,
    progress_pct real,
    plan_start_date date,
    plan_end_date date,
    actual_start_date date,
    actual_end_date date,
    lag_days integer,
    notes text
);


--
-- Name: daily_work_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_work_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_work_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_work_items_id_seq OWNED BY public.daily_work_items.id;


--
-- Name: directives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directives (
    id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    project_id integer NOT NULL,
    issue_id integer,
    from_user_id integer,
    from_user_name text,
    body text NOT NULL,
    notify_to_user_ids text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: directives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directives_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directives_id_seq OWNED BY public.directives.id;


--
-- Name: file_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.file_uploads (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    project_id integer,
    original_filename text NOT NULL,
    storage_key text,
    file_size bigint,
    file_hash character varying(64),
    mime_type character varying(100),
    expected_doc_type character varying(50),
    status character varying(20) DEFAULT 'PROCESSING'::character varying,
    total_rows integer DEFAULT 0,
    ok_rows integer DEFAULT 0,
    error_rows integer DEFAULT 0,
    report_json jsonb,
    error_message text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: file_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.file_uploads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: file_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.file_uploads_id_seq OWNED BY public.file_uploads.id;


--
-- Name: generic_sheets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generic_sheets (
    id integer NOT NULL,
    project_id integer,
    doc_type character varying(50),
    source_sheet text,
    zone_id integer,
    ordinal integer,
    col_1 text,
    col_2 text,
    col_3 text,
    col_4 text,
    col_5 text,
    col_6 text,
    col_7 text,
    col_8 text,
    col_9 text,
    col_10 text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: generic_sheets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.generic_sheets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generic_sheets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.generic_sheets_id_seq OWNED BY public.generic_sheets.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id integer NOT NULL,
    contract_id integer NOT NULL,
    invoice_no character varying(100) NOT NULL,
    invoice_date date,
    amount numeric(18,2),
    vat_amount numeric(18,2),
    status public.workflow_status DEFAULT 'DRAFT'::public.workflow_status,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoices_id_seq OWNED BY public.invoices.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues (
    id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    project_id integer NOT NULL,
    source_resource text,
    source_id integer,
    title text NOT NULL,
    body text,
    category text,
    severity text DEFAULT 'MEDIUM'::text,
    status text DEFAULT 'OPEN'::text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;


--
-- Name: kpi_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kpi_targets (
    id integer NOT NULL,
    project_id integer NOT NULL,
    kpi_code character varying(100),
    name_vi text,
    target_value numeric(18,4),
    actual_value numeric(18,4),
    unit character varying(20),
    period_start date,
    period_end date,
    version integer DEFAULT 1,
    effective_from date,
    effective_to date,
    approved_by integer,
    approved_at timestamp without time zone,
    period_lock boolean DEFAULT false,
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: kpi_targets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.kpi_targets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kpi_targets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.kpi_targets_id_seq OWNED BY public.kpi_targets.id;


--
-- Name: material_submittals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_submittals (
    id integer NOT NULL,
    project_id integer NOT NULL,
    material_id integer,
    submittal_code character varying(100),
    status public.workflow_status DEFAULT 'DRAFT'::public.workflow_status,
    sla_days integer DEFAULT 7,
    sla_deadline date,
    revision_number integer DEFAULT 0,
    parent_submittal_id integer,
    rejection_reason text,
    submitted_by integer,
    approved_by integer,
    submitted_date date,
    approved_date date,
    rejected_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: material_submittals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_submittals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_submittals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_submittals_id_seq OWNED BY public.material_submittals.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials (
    id integer NOT NULL,
    project_id integer NOT NULL,
    zone_id integer NOT NULL,
    source_sheet text,
    material_code character varying(100),
    name_vi text,
    name_en text,
    progress_pct real,
    request_date_1 date,
    delivery_date_1 date,
    request_date_2 date,
    delivery_date_2 date,
    request_date_3 date,
    delivery_date_3 date,
    request_date_4 date,
    delivery_date_4 date,
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer,
    project_id integer,
    issue_id integer,
    channel public.notification_channel DEFAULT 'in_app'::public.notification_channel,
    delivery_status public.notification_status DEFAULT 'pending'::public.notification_status,
    sent_at timestamp without time zone,
    delivered_at timestamp without time zone,
    severity character varying(20) DEFAULT 'info'::character varying,
    title text,
    body text,
    resource_type character varying(50),
    resource_id integer,
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: offline_sync_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offline_sync_queue (
    id integer NOT NULL,
    user_id integer NOT NULL,
    device_id character varying(100),
    client_id character varying(200),
    resource_type character varying(50),
    resource_json jsonb,
    client_timestamp timestamp without time zone NOT NULL,
    client_created_at timestamp without time zone,
    conflict_resolution public.sync_conflict DEFAULT 'NONE'::public.sync_conflict,
    server_record_id integer,
    superseded_at timestamp without time zone,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    error_message text,
    synced_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: offline_sync_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offline_sync_queue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offline_sync_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offline_sync_queue_id_seq OWNED BY public.offline_sync_queue.id;


--
-- Name: payment_milestones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_milestones (
    id integer NOT NULL,
    project_id integer NOT NULL,
    milestone_code text,
    name_vi text,
    amount real,
    paid_amount real DEFAULT 0,
    due_date date,
    status text DEFAULT 'DRAFT'::text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: payment_milestones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_milestones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_milestones_id_seq OWNED BY public.payment_milestones.id;


--
-- Name: payment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_requests (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    request_no character varying(100) NOT NULL,
    request_date date,
    amount numeric(18,2),
    retention_amount numeric(18,2) DEFAULT '0'::numeric,
    due_date date,
    status public.workflow_status DEFAULT 'DRAFT'::public.workflow_status,
    approved_by integer,
    approved_date date,
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: payment_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_requests_id_seq OWNED BY public.payment_requests.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    project_id integer NOT NULL,
    payment_request_id integer,
    vendor_id integer,
    contract_no character varying(100),
    invoice_no character varying(100),
    amount numeric(18,2),
    paid_amount numeric(18,2),
    retention_amount numeric(18,2),
    retention_held numeric(18,2) DEFAULT '0'::numeric,
    vat_amount numeric(18,2),
    vat_paid numeric(18,2) DEFAULT '0'::numeric,
    due_date date,
    paid_at timestamp without time zone,
    paid_method character varying(50),
    status public.workflow_status DEFAULT 'DRAFT'::public.workflow_status,
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(50) NOT NULL,
    name_vi text,
    name_en text,
    package character varying(100),
    rev_prefix character varying(50),
    start_date date,
    end_date date,
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resources (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(50),
    name text NOT NULL,
    type character varying(50),
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resources_id_seq OWNED BY public.resources.id;


--
-- Name: rfa_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rfa_log (
    id integer NOT NULL,
    project_id integer NOT NULL,
    source_sheet text,
    ordinal integer,
    rfa_code text NOT NULL,
    description_vi text,
    discipline text,
    area text,
    submitted_date date,
    reviewer text,
    reviewer_status text,
    reviewer_comment text,
    response_date date,
    final_status text,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: rfa_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rfa_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rfa_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rfa_log_id_seq OWNED BY public.rfa_log.id;


--
-- Name: schedule_baselines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schedule_baselines (
    id integer NOT NULL,
    project_id integer NOT NULL,
    version integer NOT NULL,
    effective_date date NOT NULL,
    created_by integer,
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: schedule_baselines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schedule_baselines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_baselines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schedule_baselines_id_seq OWNED BY public.schedule_baselines.id;


--
-- Name: shop_drawings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_drawings (
    id integer NOT NULL,
    project_id integer NOT NULL,
    zone_id integer NOT NULL,
    source_sheet text,
    drawing_code character varying(100) NOT NULL,
    name_vi text,
    name_en text,
    progress_pct real,
    status public.workflow_status DEFAULT 'DRAFT'::public.workflow_status,
    planned_submit_date date,
    actual_submit_date date,
    bql_l1_response character varying(5),
    bql_l1_date date,
    bql_l1_comment text,
    bql_l2_response character varying(5),
    bql_l2_date date,
    bql_l2_comment text,
    bql_l3_response character varying(5),
    bql_l3_date date,
    bql_l3_comment text,
    bql_l4_response character varying(5),
    bql_l4_date date,
    bql_l4_comment text,
    bql_l5_response character varying(5),
    bql_l5_date date,
    bql_l5_comment text,
    rs1_planned_date date,
    rs1_actual_date date,
    rs2_planned_date date,
    rs2_actual_date date,
    approval_date date,
    rejected_reason text,
    rejected_by integer,
    rejected_at timestamp without time zone,
    reverted_to_draft_at timestamp without time zone,
    reverted_to_draft_by integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: shop_drawings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shop_drawings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_drawings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shop_drawings_id_seq OWNED BY public.shop_drawings.id;


--
-- Name: subcontractors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subcontractors (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    name text NOT NULL,
    capability_summary text,
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    is_internal_team boolean DEFAULT false,
    source_sheet text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: subcontractors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subcontractors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subcontractors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subcontractors_id_seq OWNED BY public.subcontractors.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    name text NOT NULL,
    system character varying(100),
    category character varying(100),
    contact text,
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    source_sheet text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(50),
    name text NOT NULL,
    lead_worker_id integer,
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    legacy_code character varying(100),
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id integer NOT NULL,
    code character varying(50) NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants_id_seq OWNED BY public.tenants.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    email character varying(255) NOT NULL,
    name text,
    is_ceo boolean DEFAULT false,
    role public.user_role DEFAULT 'viewer'::public.user_role NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vendors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(50),
    name text NOT NULL,
    tax_id character varying(50),
    contact text,
    category character varying(100),
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    legacy_code character varying(100),
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: vendors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors_id_seq OWNED BY public.vendors.id;


--
-- Name: wbs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wbs (
    id integer NOT NULL,
    project_id integer NOT NULL,
    parent_id integer,
    code character varying(100),
    name_vi text,
    name_en text,
    level integer DEFAULT 0,
    sort_order integer DEFAULT 0
);


--
-- Name: wbs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wbs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wbs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wbs_id_seq OWNED BY public.wbs.id;


--
-- Name: work_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_items (
    id integer NOT NULL,
    project_id integer NOT NULL,
    wbs_id integer,
    code character varying(100),
    name_vi text,
    name_en text,
    unit character varying(20),
    planned_qty numeric(18,4),
    actual_qty numeric(18,4),
    unit_price numeric(18,2),
    baseline_version integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: work_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_items_id_seq OWNED BY public.work_items.id;


--
-- Name: workers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workers (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    code character varying(50),
    full_name text NOT NULL,
    team_id integer,
    phone character varying(20),
    role character varying(50),
    status public.master_status DEFAULT 'ACTIVE'::public.master_status,
    legacy_code character varying(100),
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: workers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workers_id_seq OWNED BY public.workers.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id integer NOT NULL,
    project_id integer NOT NULL,
    code character varying(50) NOT NULL,
    name_vi text,
    name_en text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zones_id_seq OWNED BY public.zones.id;


--
-- Name: area_hierarchy id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_hierarchy ALTER COLUMN id SET DEFAULT nextval('public.area_hierarchy_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: business_process_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_process_steps ALTER COLUMN id SET DEFAULT nextval('public.business_process_steps_id_seq'::regclass);


--
-- Name: business_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_processes ALTER COLUMN id SET DEFAULT nextval('public.business_processes_id_seq'::regclass);


--
-- Name: construction_schedule_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.construction_schedule_items ALTER COLUMN id SET DEFAULT nextval('public.construction_schedule_items_id_seq'::regclass);


--
-- Name: contracts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts ALTER COLUMN id SET DEFAULT nextval('public.contracts_id_seq'::regclass);


--
-- Name: cost_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cost_codes ALTER COLUMN id SET DEFAULT nextval('public.cost_codes_id_seq'::regclass);


--
-- Name: daily_acceptance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_acceptance ALTER COLUMN id SET DEFAULT nextval('public.daily_acceptance_id_seq'::regclass);


--
-- Name: daily_infos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_infos ALTER COLUMN id SET DEFAULT nextval('public.daily_infos_id_seq'::regclass);


--
-- Name: daily_manpower id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_manpower ALTER COLUMN id SET DEFAULT nextval('public.daily_manpower_id_seq'::regclass);


--
-- Name: daily_materials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_materials ALTER COLUMN id SET DEFAULT nextval('public.daily_materials_id_seq'::regclass);


--
-- Name: daily_recommendations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_recommendations ALTER COLUMN id SET DEFAULT nextval('public.daily_recommendations_id_seq'::regclass);


--
-- Name: daily_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_reports ALTER COLUMN id SET DEFAULT nextval('public.daily_reports_id_seq'::regclass);


--
-- Name: daily_safety id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_safety ALTER COLUMN id SET DEFAULT nextval('public.daily_safety_id_seq'::regclass);


--
-- Name: daily_safety_observations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_safety_observations ALTER COLUMN id SET DEFAULT nextval('public.daily_safety_observations_id_seq'::regclass);


--
-- Name: daily_work_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_work_items ALTER COLUMN id SET DEFAULT nextval('public.daily_work_items_id_seq'::regclass);


--
-- Name: directives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directives ALTER COLUMN id SET DEFAULT nextval('public.directives_id_seq'::regclass);


--
-- Name: file_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_uploads ALTER COLUMN id SET DEFAULT nextval('public.file_uploads_id_seq'::regclass);


--
-- Name: generic_sheets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generic_sheets ALTER COLUMN id SET DEFAULT nextval('public.generic_sheets_id_seq'::regclass);


--
-- Name: invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices ALTER COLUMN id SET DEFAULT nextval('public.invoices_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);


--
-- Name: kpi_targets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_targets ALTER COLUMN id SET DEFAULT nextval('public.kpi_targets_id_seq'::regclass);


--
-- Name: material_submittals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals ALTER COLUMN id SET DEFAULT nextval('public.material_submittals_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: offline_sync_queue id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sync_queue ALTER COLUMN id SET DEFAULT nextval('public.offline_sync_queue_id_seq'::regclass);


--
-- Name: payment_milestones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_milestones ALTER COLUMN id SET DEFAULT nextval('public.payment_milestones_id_seq'::regclass);


--
-- Name: payment_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_requests ALTER COLUMN id SET DEFAULT nextval('public.payment_requests_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: resources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resources ALTER COLUMN id SET DEFAULT nextval('public.resources_id_seq'::regclass);


--
-- Name: rfa_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rfa_log ALTER COLUMN id SET DEFAULT nextval('public.rfa_log_id_seq'::regclass);


--
-- Name: schedule_baselines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_baselines ALTER COLUMN id SET DEFAULT nextval('public.schedule_baselines_id_seq'::regclass);


--
-- Name: shop_drawings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_drawings ALTER COLUMN id SET DEFAULT nextval('public.shop_drawings_id_seq'::regclass);


--
-- Name: subcontractors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subcontractors ALTER COLUMN id SET DEFAULT nextval('public.subcontractors_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vendors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors ALTER COLUMN id SET DEFAULT nextval('public.vendors_id_seq'::regclass);


--
-- Name: wbs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wbs ALTER COLUMN id SET DEFAULT nextval('public.wbs_id_seq'::regclass);


--
-- Name: work_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_items ALTER COLUMN id SET DEFAULT nextval('public.work_items_id_seq'::regclass);


--
-- Name: workers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers ALTER COLUMN id SET DEFAULT nextval('public.workers_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Data for Name: area_hierarchy; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.area_hierarchy (id, project_id, parent_id, level, code, name_vi, name_en, sort_order, created_at) FROM stdin;
1	1	\N	project	BTE-WP4-HBC	Khu du lịch sinh thái Bãi Tràm	\N	0	2026-08-29 09:10:22.632502
2	2	\N	project	LAWRENCE-STING-2	Trường Lawrence Sting 2	\N	0	2026-08-29 09:10:22.65023
3	1	\N	zone	BOH		\N	0	2026-08-29 09:10:22.665556
4	1	\N	zone	BPV		\N	0	2026-08-29 09:10:22.679946
5	1	\N	zone	BPV-1BR		\N	0	2026-08-29 09:10:22.694406
6	1	\N	zone	BPV-2BR		\N	0	2026-08-29 09:10:22.709645
7	1	\N	zone	BSN		\N	0	2026-08-29 09:10:22.72388
8	1	\N	zone	BUT		\N	0	2026-08-29 09:10:22.738707
9	1	\N	zone	BZONE		\N	0	2026-08-29 09:10:22.754163
10	1	\N	zone	CLU		\N	0	2026-08-29 09:10:22.768627
11	1	\N	zone	GEN		\N	0	2026-08-29 09:10:22.785463
12	1	\N	zone	HPV		\N	0	2026-08-29 09:10:22.79971
13	1	\N	zone	HPV-1BR		\N	0	2026-08-29 09:10:22.814326
14	1	\N	zone	HPV-2BR		\N	0	2026-08-29 09:10:22.828876
15	1	\N	zone	INF		\N	0	2026-08-29 09:10:22.843281
16	1	\N	zone	KID		\N	0	2026-08-29 09:10:22.857917
17	1	\N	zone	LOB-SPA		\N	0	2026-08-29 09:10:22.872446
18	1	\N	zone	RES		\N	0	2026-08-29 09:10:22.886239
19	1	\N	zone	RES-3BR		\N	0	2026-08-29 09:10:22.900515
20	1	\N	zone	RES-4BR		\N	0	2026-08-29 09:10:22.914185
21	1	\N	zone	VNR		\N	0	2026-08-29 09:10:22.928745
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, tenant_id, user_id, action, resource_type, resource_id, before, after, created_at, user_name, field_name, old_value, new_value, note) FROM stdin;
3	1	1	CREATE	shop_drawing	1	\N	\N	2026-08-27 08:40:18	Admin HBG	\N	\N	\N	Upload Shop BOH.xlsx
4	1	1	UPDATE	construction_item	1	\N	\N	2026-08-28 20:40:18	Admin HBG	progress_pct	0.3	0.47	\N
5	1	1	STATUS_CHANGE	shop_drawing	1	\N	\N	2026-08-29 02:40:18	Admin HBG	status	PENDING	REVIEW	\N
6	1	1	DIRECTIVE	issue	1	\N	\N	2026-08-29 05:40:18	Admin HBG	\N	\N	\N	CEO directive: Ưu tiên vendor HVAC mới, họp lại tuần sau
7	1	1	CREATE	project	1	\N	\N	2026-07-30 08:40:18	Admin HBG	\N	\N	\N	Project BTE-WP4-HBC created
8	1	1	DIRECTIVE	issue	1	\N	\N	2026-08-29 08:43:53	Admin HBG	\N	\N	\N	Test directive from API
9	1	1	DIRECTIVE	issue	1	\N	\N	2026-08-29 08:51:41	Admin HBG	\N	\N	\N	Test directive từ UI
10	1	1	STATUS_CHANGE	material_submittal	1	\N	\N	2026-08-29 09:17:04	Admin HBG	status	DRAFT	SUBMITTED	\N
11	1	1	REJECT	material_submittal	1	\N	\N	2026-08-29 09:17:04	Admin HBG	status	SUBMITTED	REJECTED	Test reject mục 43.4
12	1	1	UPDATE	daily_report	1	\N	\N	2026-08-29 09:17:04	Admin HBG	conflict	CLIENT	SERVER	Client cli-1 bị override bởi server
13	1	1	STATUS_CHANGE	shop_drawing	1	\N	\N	2026-08-29 09:18:56	Admin HBG	status	REVIEW	REJECTED	Test 43.3
14	1	1	STATUS_CHANGE	shop_drawing	1	\N	\N	2026-08-29 09:18:56	Admin HBG	status	REJECTED	DRAFT	Reverted to DRAFT
\.


--
-- Data for Name: business_process_steps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.business_process_steps (id, process_id, ordinal, name_vi, content_vi, responsibility_vi, verification_vi) FROM stdin;
1	2	1	Bắt đầu	-Tiếp nhận thông báo trúng thầu, nhận giao thầu từ CĐT	- Phòng SXKD\r\n- Phòng TCHC	- TGĐ kí HĐ A-B\r\n- PTGĐ phụ trách SXKD : Phê duyệt quyết định, giao nhiệm vụ
2	2	2	Lập Kế hoạch triển khai	+ Kế hoạch tài chính:\r\n- Lập danh sách chủng loại vật tư công ty sẽ cấp xuống công trường. Lựa chọn đơn vị sẽ cung cấp.\r\n- Lập danh sách chủng loại vật tư sẽ mua trực tiếp tại địa phương, khảo sát đơn vị cung cấp và giá thành.\r\n- Khảo sát, tìm kiếm, lựa chọn các đội công nhân, nhà thầu phụ…\r\n+ Kế hoạch triển khai tại hiện trường:\r\n- Lập biện pháp thi công, tiến độ thi công\r\n- Trình ban giám đốc phê duyệt	- Chỉ huy trưởng công trường tìm hiểu và đề xuất kế hoạch.\r\n- Cán bộ phòng SXKD phụ trách khu vực lập.	Tr. Phòng SXKD: Kiểm tra và trình Ban GĐ\r\n- TGĐ: Phê duyệt Kế hoạch tài chính\r\n- P.TGĐ phụ trách SXKD: Phê duyệt Kế hoạch triển khai tại hiện trường.
3	2	3	Kí kết với các đơn vị cung cấp vật tư, gia công phụ kiện, thầu phụ và các tổ công nhân…	- Thương thảo Hợp đồng.\r\n- Kí kết Hợp đồng.	Chỉ huy trưởng Công trường kí hợp đồng với các tổ công nhân.\r\n- Cán bộ phòng SXKD phụ trách khu vực soạn HĐ với đơn vị cung cấp vật tư, gia công phụ  kiện và nhà thầu phụ	Tr. Phòng SXKD: Kiểm tra và trình Ban GĐ.\r\n- TGĐ: kí HĐ với đơn vị cung cấp vật tư, gia công phụ kiện và nhà thầu phụ.
4	2	4	Chuẩn bị triển khai	- Kiểm tra, chuẩn bị mặt bằng thi công.\r\n- Thông báo cho tất cả các biên liên quan.\r\n- Hoàn tất tất cả các thủ tục pháp lí cần thiết để được triển\r\nkhai.\r\n- Phổ biến thủ tục, quy định về kỹ thuật, chất lượng, an toàn… cho công nhân, thầu phụ và nhà cung cấp vật tư	- Chỉ huy trưởng Công trường.\r\n- Công nhân, thầu phụ và nhà cung cấp vật tư.\r\n- Cán bộ phòng SXKD phụ trách khu vực chỉ đạotriển khai	Tr.phòng SXKD: hướng dẫn thực hiện và kiểm tra.
5	2	5	- Triển khai hợp đồng thi công	-Triển khai và nghiệm thu từng công việc, hạng mục, bộ phận theo các quy trình nghiệm thu của CĐT, TVGS.	- Các tổ công nhân.\r\n- Các đơn vị cung cấp vật tư, gia công phụ kiện\r\n- Các nhà thầu phụ	-Các cá nhân, phòng ban có liên quan
6	2	6	Nghiệm thu hoàn thành và bàn giao công trình	- Kiểm tra, đánh giá:\r\n+ Điều kiện đưa công trình vào sử dụng.\r\n+ Đánh giá chất lượng.\r\n+ Sự phù hợp của công trình với hồ sơ thiết kế, hồ sơ dự thầu.\r\n- Tổ chức nghiệm thu với CĐT, TVGS và bàn giao công trình.	- Chỉ huy trưởng Công\r\ntrường.\r\n- Cán bộ phòng SXKD phụ trách khu vực.	Tr.phòng SXKD: hướng dẫn thực hiện và kiểm tra
7	2	7	Quyết toán, thanh lý hợp đồng	-Tổng hợp tài liệu, chứng từ,...\r\n- Tổng hợp khối lượng công việc hoàn thành.\r\n- Lập hồ sơ quyết toán.\r\n- Lập biên bản thanh lí HĐ\r\n- Trình Ban GĐ phê duyệt!	- Cán bộ phòng SXKD phụ trách khu vực.	- Tr. Phòng SXKD:\r\nKiểm tra và trình.\r\n- TGĐ: Kí quyết toán và\r\nthanh lý hợp đồng\r\n- P.TGĐ phụ trách SXKD: Kí hồ sơ, tài liệu quản lí chất lượng
8	2	8	Kết thúc	- Lập báo cáo tổng kết.\r\n- Họp tổng kết (nếu cần)\r\n- Nộp lưu trữ.	- Tất cả các bên tham gia.	-Ban GĐ nhận xét đánh giá.
\.


--
-- Data for Name: business_processes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.business_processes (id, tenant_id, code, name_vi, name_en, created_at) FROM stdin;
2	1	project_execution	\N	\N	2026-08-29 09:06:15.611699
\.


--
-- Data for Name: construction_schedule_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.construction_schedule_items (id, project_id, zone_id, source_sheet, level_roman, level_arabic, sublevel, ordinal, name_vi, name_en, progress_pct, status, plan_start_date, actual_start_date, plan_end_date, actual_end_date, plan_duration_days, baseline_version, baseline_id, created_at) FROM stdin;
13	1	16	TĐ RESIDENTIAL VILLA - 3BR	\N	\N	\N	\N	0.25	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:09
14	1	16	TĐ RESIDENTIAL VILLA - 3BR	\N	\N	\N	\N	0.3	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:09
15	1	16	TĐ RESIDENTIAL VILLA - 4BR 	\N	\N	\N	\N	0.25	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:09
16	1	16	TĐ RESIDENTIAL VILLA - 4BR 	\N	\N	\N	\N	0.3	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:09
25	1	1	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(Basement)( Phần âm)	\N	\N	\N	2019-03-13	2019-03-13	2019-09-08	2019-09-08	\N	1	\N	2026-08-29 06:43:10
26	1	1	\N	\N	1	\N	1	Bể nước sinh hoạt, phòng cháy chữa cháy: Lắp đặt ống slevee inox,slevee  ống Upvc/Domestic water tank, Fire fighting, sleeve pipe installation, UPVC pipe	\N	0.65	DONE	2019-03-13	2019-03-13	2019-03-14	2019-03-14	2	1	\N	2026-08-29 06:43:10
27	1	1	\N	\N	2	\N	2	Lắp đặt đường ống thoát âm sàn phòng bơm/Floor recessed pipe installation for pumper room	\N	0.8	DONE	2019-04-17	2019-04-17	2019-04-26	2019-04-26	10	1	\N	2026-08-29 06:43:10
28	1	1	\N	\N	3	\N	3	Bể STP: Lắp đặt ống slevee upvc	\N	0.9	DONE	2019-04-01	2019-04-01	2019-04-20	2019-04-20	20	1	\N	2026-08-29 06:43:10
29	1	1	\N	\N	4	\N	4	Lắp đặt đường ống cấp, máy bơm,van... /Water supply pipe installation, pumper, valve	\N	0	DONE	2019-06-30	2019-06-30	2019-07-30	2019-07-30	31	1	\N	2026-08-29 06:43:10
30	1	1	\N	\N	5	\N	5	Lắp đặt bơm nước mưa/Rain water pumper installation	\N	0	DONE	2019-08-20	2019-08-20	2019-09-03	2019-09-03	15	1	\N	2026-08-29 06:43:10
31	1	1	\N	II	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system( Retaining wall & Car parking)	\N	0	DONE	2019-05-21	2019-05-21	2019-05-20	2019-05-20	\N	1	\N	2026-08-29 06:43:10
32	1	1	\N	\N	1	\N	1	Lắp đặt ống Upvc chờ /Sleeve pipe installation installation	\N	0	DONE	2019-06-23	2019-06-23	2019-07-22	2019-07-22	30	1	\N	2026-08-29 06:43:10
33	1	1	\N	III	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(Zone A)	\N	0	DONE	2019-05-21	2019-05-21	2019-05-20	2019-05-20	\N	1	\N	2026-08-29 06:43:10
34	1	1	\N	\N	1	\N	1	Lắp đặt đường ống nước cấp nước thoát/Water supply pipe system installation	\N	0	DONE	2019-05-21	2019-05-21	2019-06-09	2019-06-09	20	1	\N	2026-08-29 06:43:10
35	1	1	\N	\N	2	\N	2	Kiểm tra thử kín, thử áp hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-06-09	2019-06-09	2019-06-11	2019-06-11	3	1	\N	2026-08-29 06:43:10
36	1	1	\N	\N	3	\N	3	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-06-15	2019-06-15	2019-07-04	2019-07-04	20	1	\N	2026-08-29 06:43:10
37	1	1	\N	\N	4	\N	4	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-07-04	2019-07-04	2019-07-04	2019-07-04	1	1	\N	2026-08-29 06:43:10
38	1	1	\N	IV	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(Zone B)	\N	0	DONE	2019-06-30	2019-06-30	2019-06-29	2019-06-29	\N	1	\N	2026-08-29 06:43:10
39	1	1	\N	\N	1	\N	1	Lắp đặt đường ống nước cấp nước thoát/Water supply pipe system installation	\N	0	DONE	2019-06-30	2019-06-30	2019-07-19	2019-07-19	20	1	\N	2026-08-29 06:43:10
40	1	1	\N	\N	2	\N	2	Kiểm tra thử kín, thử áp hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-07-17	2019-07-17	2019-07-19	2019-07-19	3	1	\N	2026-08-29 06:43:10
41	1	1	\N	\N	3	\N	3	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-07-27	2019-07-27	2019-08-15	2019-08-15	20	1	\N	2026-08-29 06:43:10
42	1	1	\N	\N	4	\N	4	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-08-16	2019-08-16	2019-08-16	2019-08-16	1	1	\N	2026-08-29 06:43:10
43	1	1	\N	V	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(Zone C)	\N	0	DONE	2019-07-15	2019-07-15	2019-07-14	2019-07-14	\N	1	\N	2026-08-29 06:43:10
44	1	1	\N	\N	1	\N	1	Lắp đặt đường ống nước cấp nước thoát/Water supply pipe system installation	\N	0	DONE	2019-07-27	2019-07-27	2019-08-15	2019-08-15	20	1	\N	2026-08-29 06:43:10
45	1	1	\N	\N	2	\N	2	Kiểm tra thử kín, thử áp hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-07-15	2019-07-15	2019-07-17	2019-07-17	3	1	\N	2026-08-29 06:43:10
46	1	1	\N	\N	3	\N	3	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-08-19	2019-08-19	2019-09-02	2019-09-02	15	1	\N	2026-08-29 06:43:10
47	1	1	\N	\N	4	\N	4	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-09-08	2019-09-08	2019-09-08	2019-09-08	1	1	\N	2026-08-29 06:43:10
48	1	1	\N	VI	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(Zone D)	\N	0	DONE	2019-08-03	2019-08-03	2019-08-02	2019-08-02	\N	1	\N	2026-08-29 06:43:10
49	1	1	\N	\N	1	\N	1	Lắp đặt đường ống nước cấp nước thoát/Water supply pipe system installation	\N	0	DONE	2019-08-03	2019-08-03	2019-08-22	2019-08-22	20	1	\N	2026-08-29 06:43:10
50	1	1	\N	\N	2	\N	2	Kiểm tra thử kín, thử áp hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-08-22	2019-08-22	2019-08-24	2019-08-24	3	1	\N	2026-08-29 06:43:10
51	1	1	\N	\N	3	\N	3	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-08-24	2019-08-24	2019-09-07	2019-09-07	15	1	\N	2026-08-29 06:43:10
52	1	1	\N	\N	4	\N	4	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-09-08	2019-09-08	2019-09-08	2019-09-08	1	1	\N	2026-08-29 06:43:10
53	1	1	\N	\N	2	\N	2	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-05-21	2019-05-21	2019-09-20	2019-09-20	\N	1	\N	2026-08-29 06:43:10
54	1	1	\N	A	\N	\N	\N	Zone A	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:10
55	1	1	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-12	2019-08-12	1	1	\N	2026-08-29 06:43:10
56	1	1	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-08-14	2019-08-14	2019-08-16	2019-08-16	3	1	\N	2026-08-29 06:43:10
57	1	1	\N	\N	3	\N	3	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-05-21	2019-05-21	2019-05-21	2019-05-21	1	1	\N	2026-08-29 06:43:10
58	1	1	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-05-31	2019-05-31	2019-06-02	2019-06-02	3	1	\N	2026-08-29 06:43:10
59	1	1	\N	\N	5	\N	5	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
60	1	1	\N	\N	6	\N	6	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T2/Installing air duct and heat insulation floor2	\N	0	DONE	2019-08-15	2019-08-15	2019-08-17	2019-08-17	3	1	\N	2026-08-29 06:43:10
61	1	1	\N	\N	7	\N	7	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-06-23	2019-06-23	2019-06-23	2019-06-23	1	1	\N	2026-08-29 06:43:10
62	1	1	\N	\N	8	\N	8	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor2	\N	0	DONE	2019-06-25	2019-06-25	2019-06-27	2019-06-27	3	1	\N	2026-08-29 06:43:10
63	1	1	\N	\N	9	\N	9	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-14	2019-08-14	2019-08-15	2019-08-15	2	1	\N	2026-08-29 06:43:10
64	1	1	\N	\N	10	\N	10	Thử áp đường ống đồng tầng T2/Testing pressure copper pipe floor2	\N	0	DONE	2019-08-18	2019-08-18	2019-08-19	2019-08-19	2	1	\N	2026-08-29 06:43:10
65	1	1	\N	\N	11	\N	11	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-05-23	2019-05-23	2019-05-23	2019-05-23	1	1	\N	2026-08-29 06:43:10
66	1	1	\N	\N	12	\N	12	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor2	\N	0	DONE	2019-06-04	2019-06-04	2019-06-04	2019-06-04	1	1	\N	2026-08-29 06:43:10
67	1	1	\N	\N	13	\N	13	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-17	2019-08-17	3	1	\N	2026-08-29 06:43:10
68	1	1	\N	\N	14	\N	14	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor2	\N	0	DONE	2019-08-19	2019-08-19	2019-08-20	2019-08-20	2	1	\N	2026-08-29 06:43:10
69	1	1	\N	\N	15	\N	15	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-15	2019-08-15	1	1	\N	2026-08-29 06:43:10
70	1	1	\N	\N	16	\N	16	Lắp đặt thiết bị điều hòa không khí tầng T2/Installing air conditional equipment floor2	\N	0	DONE	2019-08-17	2019-08-17	2019-08-20	2019-08-20	4	1	\N	2026-08-29 06:43:10
71	1	1	\N	\N	17	\N	17	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-22	2019-08-22	2019-08-22	2019-08-22	1	1	\N	2026-08-29 06:43:10
72	1	1	\N	\N	18	\N	18	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor2	\N	0	DONE	2019-08-24	2019-08-24	2019-08-25	2019-08-25	2	1	\N	2026-08-29 06:43:10
73	1	1	\N	\N	19	\N	19	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-08-17	2019-08-17	2019-08-17	2019-08-17	1	1	\N	2026-08-29 06:43:10
74	1	1	\N	\N	20	\N	20	Lắp đặt cửa gió tầng T2/Installing air diffuser floor2	\N	0	DONE	2019-08-22	2019-08-22	2019-08-22	2019-08-22	1	1	\N	2026-08-29 06:43:10
75	1	1	\N	\N	21	\N	21	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-09-10	2019-09-10	2019-09-10	2019-09-10	1	1	\N	2026-08-29 06:43:10
76	1	1	\N	B	\N	\N	\N	Zone B	\N	\N	DONE	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:10
77	1	1	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-12	2019-08-12	1	1	\N	2026-08-29 06:43:10
78	1	1	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-08-12	2019-08-12	2019-08-14	2019-08-14	3	1	\N	2026-08-29 06:43:10
79	1	1	\N	\N	3	\N	3	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-05-21	2019-05-21	2019-05-21	2019-05-21	1	1	\N	2026-08-29 06:43:10
80	1	1	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-05-21	2019-05-21	2019-05-22	2019-05-22	2	1	\N	2026-08-29 06:43:10
81	1	1	\N	\N	5	\N	5	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
82	1	1	\N	\N	6	\N	6	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T2/Installing air duct and heat insulation floor2	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
83	1	1	\N	\N	7	\N	7	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-06-23	2019-06-23	2019-06-24	2019-06-24	2	1	\N	2026-08-29 06:43:10
84	1	1	\N	\N	8	\N	8	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor2	\N	0	DONE	2019-06-23	2019-06-23	2019-06-25	2019-06-25	3	1	\N	2026-08-29 06:43:10
85	1	1	\N	\N	9	\N	9	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-13	2019-08-13	2019-08-15	2019-08-15	3	1	\N	2026-08-29 06:43:10
86	1	1	\N	\N	10	\N	10	Thử áp đường ống đồng tầng T2/Testing pressure copper pipe floor2	\N	0	DONE	2019-08-16	2019-08-16	2019-08-16	2019-08-16	1	1	\N	2026-08-29 06:43:10
87	1	1	\N	\N	11	\N	11	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor1	\N	0	DONE	2019-05-22	2019-05-22	2019-05-23	2019-05-23	2	1	\N	2026-08-29 06:43:10
88	1	1	\N	\N	12	\N	12	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor2	\N	0	DONE	2019-05-24	2019-05-24	2019-05-24	2019-05-24	1	1	\N	2026-08-29 06:43:10
89	1	1	\N	\N	13	\N	13	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-05-24	2019-05-24	2019-05-25	2019-05-25	2	1	\N	2026-08-29 06:43:10
90	1	1	\N	\N	14	\N	14	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor2	\N	0	DONE	2019-06-14	2019-06-14	2019-06-14	2019-06-14	1	1	\N	2026-08-29 06:43:10
91	1	1	\N	\N	15	\N	15	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
92	1	1	\N	\N	16	\N	16	Lắp đặt thiết bị điều hòa không khí tầng T2/Installing air conditional equipment floor2	\N	0	DONE	2019-08-13	2019-08-13	2019-08-14	2019-08-14	2	1	\N	2026-08-29 06:43:10
93	1	1	\N	\N	17	\N	17	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-13	2019-08-13	2019-08-15	2019-08-15	3	1	\N	2026-08-29 06:43:10
94	1	1	\N	\N	18	\N	18	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor2	\N	0	DONE	2019-08-16	2019-08-16	2019-08-16	2019-08-16	1	1	\N	2026-08-29 06:43:10
95	1	1	\N	\N	19	\N	19	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-08-13	2019-08-13	2019-08-14	2019-08-14	2	1	\N	2026-08-29 06:43:10
96	1	1	\N	\N	20	\N	20	Lắp đặt cửa gió tầng T2/Installing air diffuser floor2	\N	0	DONE	2019-08-18	2019-08-18	2019-08-18	2019-08-18	1	1	\N	2026-08-29 06:43:10
97	1	1	\N	\N	21	\N	21	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-09-20	2019-09-20	2019-09-20	2019-09-20	1	1	\N	2026-08-29 06:43:10
98	1	1	\N	C	\N	\N	\N	Zone C	\N	\N	DONE	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:10
99	1	1	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
100	1	1	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-08-15	2019-08-15	2019-08-16	2019-08-16	2	1	\N	2026-08-29 06:43:10
101	1	1	\N	\N	3	\N	3	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-05-21	2019-05-21	2019-05-22	2019-05-22	2	1	\N	2026-08-29 06:43:10
102	1	1	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-05-24	2019-05-24	2019-05-25	2019-05-25	2	1	\N	2026-08-29 06:43:10
103	1	1	\N	\N	5	\N	5	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
104	1	1	\N	\N	6	\N	6	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T2/Installing air duct and heat insulation floor2	\N	0	DONE	2019-08-13	2019-08-13	2019-08-14	2019-08-14	2	1	\N	2026-08-29 06:43:10
105	1	1	\N	\N	7	\N	7	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-06-23	2019-06-23	2019-06-24	2019-06-24	2	1	\N	2026-08-29 06:43:10
106	1	1	\N	\N	8	\N	8	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor2	\N	0	DONE	2019-06-26	2019-06-26	2019-06-28	2019-06-28	3	1	\N	2026-08-29 06:43:10
107	1	1	\N	\N	9	\N	9	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-15	2019-08-15	1	1	\N	2026-08-29 06:43:10
108	1	1	\N	\N	10	\N	10	Thử áp đường ống đồng tầng T2/Testing pressure copper pipe floor2	\N	0	DONE	2019-08-18	2019-08-18	2019-08-18	2019-08-18	1	1	\N	2026-08-29 06:43:10
109	1	1	\N	\N	11	\N	11	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-05-24	2019-05-24	2019-05-24	2019-05-24	1	1	\N	2026-08-29 06:43:10
110	1	1	\N	\N	12	\N	12	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor2	\N	0	DONE	2019-05-27	2019-05-27	2019-05-27	2019-05-27	1	1	\N	2026-08-29 06:43:10
111	1	1	\N	\N	13	\N	13	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-05-24	2019-05-24	2019-05-24	2019-05-24	1	1	\N	2026-08-29 06:43:10
112	1	1	\N	\N	14	\N	14	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor2	\N	0	DONE	2019-06-14	2019-06-14	2019-06-15	2019-06-15	2	1	\N	2026-08-29 06:43:10
113	1	1	\N	\N	15	\N	15	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-08-17	2019-08-17	2019-08-17	2019-08-17	1	1	\N	2026-08-29 06:43:10
114	1	1	\N	\N	16	\N	16	Lắp đặt thiết bị điều hòa không khí tầng T2/Installing air conditional equipment floor2	\N	0	DONE	2019-08-20	2019-08-20	2019-08-21	2019-08-21	2	1	\N	2026-08-29 06:43:10
115	1	1	\N	\N	17	\N	17	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-19	2019-08-19	2019-08-19	2019-08-19	1	1	\N	2026-08-29 06:43:10
116	1	1	\N	\N	18	\N	18	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor2	\N	0	DONE	2019-08-21	2019-08-21	2019-08-21	2019-08-21	1	1	\N	2026-08-29 06:43:10
117	1	1	\N	\N	19	\N	19	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-09-06	2019-09-06	2019-09-06	2019-09-06	1	1	\N	2026-08-29 06:43:10
118	1	1	\N	\N	20	\N	20	Lắp đặt cửa gió tầng T2/Installing air diffuser floor2	\N	0	DONE	2019-09-08	2019-09-08	2019-09-08	2019-09-08	1	1	\N	2026-08-29 06:43:10
119	1	1	\N	\N	21	\N	21	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-09-10	2019-09-10	2019-09-10	2019-09-10	1	1	\N	2026-08-29 06:43:10
120	1	1	\N	D	\N	\N	\N	Zone D	\N	\N	DONE	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:10
121	1	1	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
122	1	1	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-08-15	2019-08-15	2019-08-19	2019-08-19	5	1	\N	2026-08-29 06:43:10
123	1	1	\N	\N	3	\N	3	Thi công lắp đặt ống đồng và bảo ôn tầng mái/Installing copper pipe and heat insulation floor3	\N	0	DONE	2019-08-21	2019-08-21	2019-08-25	2019-08-25	5	1	\N	2026-08-29 06:43:10
124	1	1	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-05-21	2019-05-21	2019-05-21	2019-05-21	1	1	\N	2026-08-29 06:43:10
125	1	1	\N	\N	5	\N	5	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-05-23	2019-05-23	2019-05-27	2019-05-27	5	1	\N	2026-08-29 06:43:10
126	1	1	\N	\N	6	\N	6	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor3	\N	0	DONE	2019-05-29	2019-05-29	2019-06-02	2019-06-02	5	1	\N	2026-08-29 06:43:10
127	1	1	\N	\N	7	\N	7	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-08-12	2019-08-12	2019-08-13	2019-08-13	2	1	\N	2026-08-29 06:43:10
128	1	1	\N	\N	8	\N	8	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor2	\N	0	DONE	2019-08-15	2019-08-15	2019-08-19	2019-08-19	5	1	\N	2026-08-29 06:43:10
129	1	1	\N	\N	9	\N	9	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor3	\N	0	DONE	2019-08-21	2019-08-21	2019-08-25	2019-08-25	5	1	\N	2026-08-29 06:43:10
130	1	1	\N	\N	10	\N	10	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-15	2019-08-15	1	1	\N	2026-08-29 06:43:10
131	1	1	\N	\N	11	\N	11	Thử áp đường ống đồng tầng T2/Testing pressure copper pipe floor2	\N	0	DONE	2019-08-21	2019-08-21	2019-08-21	2019-08-21	1	1	\N	2026-08-29 06:43:10
132	1	1	\N	\N	12	\N	12	Thử áp đường ống đồng tầng T3/Testing pressure copper pipe floor2	\N	0	DONE	2019-08-27	2019-08-27	2019-08-27	2019-08-27	1	1	\N	2026-08-29 06:43:10
133	1	1	\N	\N	13	\N	13	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-05-23	2019-05-23	2019-05-23	2019-05-23	1	1	\N	2026-08-29 06:43:10
134	1	1	\N	\N	14	\N	14	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor2	\N	0	DONE	2019-05-29	2019-05-29	2019-05-29	2019-05-29	1	1	\N	2026-08-29 06:43:10
135	1	1	\N	\N	15	\N	15	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor3	\N	0	DONE	2019-06-04	2019-06-04	2019-06-04	2019-06-04	1	1	\N	2026-08-29 06:43:10
136	1	1	\N	\N	16	\N	16	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-08-27	2019-08-27	2019-08-28	2019-08-28	2	1	\N	2026-08-29 06:43:10
137	1	1	\N	\N	17	\N	17	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor2	\N	0	DONE	2019-08-27	2019-08-27	2019-08-28	2019-08-28	2	1	\N	2026-08-29 06:43:10
138	1	1	\N	\N	18	\N	18	Lắp đặt thiết bị quạt thông gió tầng mái/Installing air duct fan equipment rooftop	\N	0	DONE	2019-08-30	2019-08-30	2019-08-31	2019-08-31	2	1	\N	2026-08-29 06:43:10
139	1	1	\N	\N	19	\N	19	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-08-27	2019-08-27	2019-08-28	2019-08-27	2	1	\N	2026-08-29 06:43:10
140	1	1	\N	\N	20	\N	20	Lắp đặt thiết bị điều hòa không khí tầng T2/Installing air conditional equipment floor2	\N	0	DONE	2019-08-29	2019-08-29	2019-08-31	2019-08-29	3	1	\N	2026-08-29 06:43:10
141	1	1	\N	\N	21	\N	21	Lắp đặt thiết bị điều hòa không khí tầng mái/Installing air conditional equipment rooftop	\N	0	DONE	2019-09-01	2019-09-01	2019-09-03	2019-09-01	3	1	\N	2026-08-29 06:43:10
142	1	1	\N	\N	22	\N	22	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-27	2019-08-27	2019-08-27	2019-08-27	1	1	\N	2026-08-29 06:43:10
143	1	1	\N	\N	23	\N	23	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor2	\N	0	DONE	2019-08-29	2019-08-29	2019-08-29	2019-08-29	1	1	\N	2026-08-29 06:43:10
144	1	1	\N	\N	24	\N	24	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor3	\N	0	DONE	2019-08-31	2019-08-31	2019-08-31	2019-08-31	1	1	\N	2026-08-29 06:43:10
145	1	1	\N	\N	25	\N	25	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-09-05	2019-09-05	2019-09-05	2019-09-05	1	1	\N	2026-08-29 06:43:10
146	1	3	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-05-04	2019-04-24	2019-12-03	2019-12-03	\N	1	\N	2026-08-29 06:43:10
147	1	3	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	\N	DONE	2019-08-08	2019-08-08	2019-08-27	2019-08-27	20	1	\N	2026-08-29 06:43:10
148	1	3	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0.05	DONE	2019-05-04	2019-04-24	2019-05-08	2019-04-28	5	1	\N	2026-08-29 06:43:10
149	1	3	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	\N	DONE	2019-08-15	2019-08-15	2019-08-24	2019-08-24	10	1	\N	2026-08-29 06:43:10
150	1	3	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	\N	DONE	2019-05-09	2019-05-09	2019-05-18	2019-05-18	10	1	\N	2026-08-29 06:43:10
151	1	3	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	\N	DONE	2019-11-08	2019-11-08	2019-12-02	2019-12-02	25	1	\N	2026-08-29 06:43:10
152	1	3	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	\N	DONE	2019-11-24	2019-11-24	2019-12-03	2019-12-03	10	1	\N	2026-08-29 06:43:10
153	1	3	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-07-21	2019-07-21	2019-10-05	2019-10-05	\N	1	\N	2026-08-29 06:43:10
154	1	3	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	\N	DONE	2019-07-21	2019-07-21	2019-07-22	2019-07-22	2	1	\N	2026-08-29 06:43:10
155	1	3	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	\N	DONE	2019-07-21	2019-07-21	2019-07-21	2019-07-21	1	1	\N	2026-08-29 06:43:10
156	1	3	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	\N	DONE	2019-08-09	2019-08-09	2019-08-10	2019-08-10	2	1	\N	2026-08-29 06:43:10
157	1	3	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	\N	DONE	2019-07-24	2019-07-24	2019-07-25	2019-07-25	2	1	\N	2026-08-29 06:43:10
158	1	3	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	\N	DONE	2019-07-24	2019-07-24	2019-07-24	2019-07-24	1	1	\N	2026-08-29 06:43:10
159	1	3	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	\N	DONE	2019-07-23	2019-07-23	2019-07-23	2019-07-23	1	1	\N	2026-08-29 06:43:10
160	1	3	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	\N	DONE	2019-08-12	2019-08-12	2019-08-12	2019-08-12	1	1	\N	2026-08-29 06:43:10
161	1	3	\N	\N	\N	\N	\N	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	\N	DONE	2019-07-24	2019-07-24	2019-07-24	2019-07-24	1	1	\N	2026-08-29 06:43:10
162	1	3	\N	\N	\N	\N	\N	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	\N	DONE	2019-07-25	2019-07-25	2019-07-25	2019-07-25	1	1	\N	2026-08-29 06:43:10
163	1	3	\N	\N	\N	\N	\N	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	\N	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:10
164	1	3	\N	\N	\N	\N	\N	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	\N	DONE	2019-10-05	2019-10-05	2019-10-05	2019-10-05	1	1	\N	2026-08-29 06:43:10
165	1	4	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-05-29	2019-05-29	2019-12-05	2019-12-05	\N	1	\N	2026-08-29 06:43:10
166	1	4	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-08-15	2019-08-15	2019-09-03	2019-09-03	20	1	\N	2026-08-29 06:43:10
167	1	4	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-05-29	2019-05-29	2019-06-02	2019-06-02	5	1	\N	2026-08-29 06:43:10
168	1	4	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-08-27	2019-08-27	2019-09-05	2019-09-05	10	1	\N	2026-08-29 06:43:10
169	1	4	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-06-03	2019-06-03	2019-06-12	2019-06-12	10	1	\N	2026-08-29 06:43:10
170	1	4	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-11-21	2019-11-21	2019-12-05	2019-12-05	15	1	\N	2026-08-29 06:43:10
171	1	4	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-11-26	2019-11-26	2019-12-05	2019-12-05	10	1	\N	2026-08-29 06:43:10
172	1	4	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-07-21	2019-07-21	2019-10-05	2019-10-05	\N	1	\N	2026-08-29 06:43:10
173	1	4	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-07-21	2019-07-21	2019-07-22	2019-07-22	2	1	\N	2026-08-29 06:43:10
174	1	4	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-07-21	2019-07-21	2019-07-21	2019-07-21	1	1	\N	2026-08-29 06:43:10
175	1	4	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-08-09	2019-08-09	2019-08-12	2019-08-12	4	1	\N	2026-08-29 06:43:10
176	1	4	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-07-24	2019-07-24	2019-07-25	2019-07-25	2	1	\N	2026-08-29 06:43:10
177	1	4	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-07-24	2019-07-24	2019-07-24	2019-07-24	1	1	\N	2026-08-29 06:43:10
178	1	4	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-07-23	2019-07-23	2019-07-23	2019-07-23	1	1	\N	2026-08-29 06:43:10
179	1	4	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-08-14	2019-08-14	2019-08-14	2019-08-14	1	1	\N	2026-08-29 06:43:10
180	1	4	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-07-24	2019-07-24	2019-07-24	2019-07-24	1	1	\N	2026-08-29 06:43:10
181	1	4	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-07-25	2019-07-25	2019-07-25	2019-07-25	1	1	\N	2026-08-29 06:43:10
182	1	4	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:10
183	1	4	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-10-05	2019-10-05	2019-10-05	2019-10-05	1	1	\N	2026-08-29 06:43:10
184	1	5	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-07-04	2019-07-04	2019-11-18	2019-11-18	\N	1	\N	2026-08-29 06:43:10
185	1	5	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-08-15	2019-08-15	2019-08-24	2019-08-24	10	1	\N	2026-08-29 06:43:10
186	1	5	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-07-04	2019-07-04	2019-07-08	2019-07-08	5	1	\N	2026-08-29 06:43:10
187	1	5	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-08-25	2019-08-25	2019-08-27	2019-08-27	3	1	\N	2026-08-29 06:43:10
188	1	5	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-07-10	2019-07-10	2019-07-12	2019-07-12	3	1	\N	2026-08-29 06:43:10
189	1	5	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-11-12	2019-11-12	2019-11-18	2019-11-18	7	1	\N	2026-08-29 06:43:10
190	1	5	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-11-16	2019-11-16	2019-11-18	2019-11-18	3	1	\N	2026-08-29 06:43:10
191	1	5	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-07-14	2019-07-14	2019-11-15	2019-11-15	\N	1	\N	2026-08-29 06:43:10
192	1	5	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-16	2019-08-16	2	1	\N	2026-08-29 06:43:10
193	1	5	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-15	2019-08-15	1	1	\N	2026-08-29 06:43:10
194	1	5	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-07-14	2019-07-14	2019-07-16	2019-07-16	3	1	\N	2026-08-29 06:43:10
195	1	5	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-08-15	2019-08-15	2019-08-16	2019-08-16	2	1	\N	2026-08-29 06:43:10
196	1	5	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-18	2019-08-18	2019-08-18	2019-08-18	1	1	\N	2026-08-29 06:43:10
197	1	5	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-17	2019-08-17	2019-08-17	2019-08-17	1	1	\N	2026-08-29 06:43:10
198	1	5	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-09-09	2019-09-09	2019-09-09	2019-09-09	1	1	\N	2026-08-29 06:43:10
199	1	5	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-09-09	2019-09-09	2019-09-09	2019-09-09	1	1	\N	2026-08-29 06:43:10
200	1	5	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-09-10	2019-09-10	2019-09-10	2019-09-10	1	1	\N	2026-08-29 06:43:10
201	1	5	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-11-13	2019-11-13	2019-11-13	2019-11-13	1	1	\N	2026-08-29 06:43:10
202	1	5	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-11-15	2019-11-15	2019-11-15	2019-11-15	1	1	\N	2026-08-29 06:43:10
203	1	6	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-07-04	2019-07-04	2019-11-18	2019-11-18	\N	1	\N	2026-08-29 06:43:10
204	1	6	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-08-15	2019-08-15	2019-08-24	2019-08-24	10	1	\N	2026-08-29 06:43:10
205	1	6	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-07-04	2019-07-04	2019-07-08	2019-07-08	5	1	\N	2026-08-29 06:43:10
206	1	6	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-08-25	2019-08-25	2019-08-27	2019-08-27	3	1	\N	2026-08-29 06:43:10
207	1	6	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-07-10	2019-07-10	2019-07-12	2019-07-12	3	1	\N	2026-08-29 06:43:10
208	1	6	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-11-12	2019-11-12	2019-11-18	2019-11-18	7	1	\N	2026-08-29 06:43:10
209	1	6	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-11-16	2019-11-16	2019-11-18	2019-11-18	3	1	\N	2026-08-29 06:43:10
210	1	6	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-07-25	2019-07-25	2019-11-26	2019-11-26	\N	1	\N	2026-08-29 06:43:10
211	1	6	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-26	2019-08-26	2019-08-27	2019-08-27	2	1	\N	2026-08-29 06:43:10
212	1	6	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-26	2019-08-26	2019-08-26	2019-08-26	1	1	\N	2026-08-29 06:43:10
213	1	6	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-07-25	2019-07-25	2019-07-27	2019-07-27	3	1	\N	2026-08-29 06:43:10
214	1	6	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-08-26	2019-08-26	2019-08-27	2019-08-27	2	1	\N	2026-08-29 06:43:10
215	1	6	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-29	2019-08-29	2019-08-29	2019-08-29	1	1	\N	2026-08-29 06:43:10
216	1	6	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-28	2019-08-28	2019-08-28	2019-08-28	1	1	\N	2026-08-29 06:43:10
217	1	6	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-09-20	2019-09-20	2019-09-20	2019-09-20	1	1	\N	2026-08-29 06:43:10
218	1	6	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-09-20	2019-09-20	2019-09-20	2019-09-20	1	1	\N	2026-08-29 06:43:10
219	1	6	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-09-20	2019-09-20	2019-09-20	2019-09-20	1	1	\N	2026-08-29 06:43:10
220	1	6	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-11-24	2019-11-24	2019-11-24	2019-11-24	1	1	\N	2026-08-29 06:43:10
221	1	6	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-11-26	2019-11-26	2019-11-26	2019-11-26	1	1	\N	2026-08-29 06:43:10
222	1	7	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-04-08	2019-04-08	2019-12-04	2019-12-04	\N	1	\N	2026-08-29 06:43:10
223	1	7	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-07-25	2019-07-25	2019-08-03	2019-08-03	10	1	\N	2026-08-29 06:43:10
224	1	7	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-04-08	2019-04-08	2019-04-12	2019-04-12	5	1	\N	2026-08-29 06:43:10
225	1	7	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-08-04	2019-08-04	2019-08-06	2019-08-06	3	1	\N	2026-08-29 06:43:10
226	1	7	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-08-07	2019-08-07	2019-08-09	2019-08-09	3	1	\N	2026-08-29 06:43:10
227	1	7	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-11-20	2019-11-20	2019-12-04	2019-12-04	15	1	\N	2026-08-29 06:43:10
228	1	7	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-12-02	2019-12-02	2019-12-04	2019-12-04	3	1	\N	2026-08-29 06:43:10
229	1	7	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-06-29	2019-06-29	2019-10-06	2019-10-06	\N	1	\N	2026-08-29 06:43:10
230	1	7	\N	A	\N	\N	\N	BEACH RESTAURANT	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:10
231	1	7	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-04	2019-08-04	2019-08-05	2019-08-05	2	1	\N	2026-08-29 06:43:10
232	1	7	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-04	2019-08-04	2019-08-04	2019-08-04	1	1	\N	2026-08-29 06:43:10
233	1	7	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-06-29	2019-06-29	2019-06-30	2019-06-30	2	1	\N	2026-08-29 06:43:10
234	1	7	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-08-04	2019-08-04	2019-08-05	2019-08-05	2	1	\N	2026-08-29 06:43:10
235	1	7	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-07	2019-08-07	2019-08-07	2019-08-07	1	1	\N	2026-08-29 06:43:10
236	1	7	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-06	2019-08-06	2019-08-06	2019-08-06	1	1	\N	2026-08-29 06:43:10
237	1	7	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-07-02	2019-07-02	2019-07-02	2019-07-02	1	1	\N	2026-08-29 06:43:10
238	1	7	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-08-07	2019-08-07	2019-08-07	2019-08-07	1	1	\N	2026-08-29 06:43:10
239	1	7	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-09	2019-08-09	2019-08-09	2019-08-09	1	1	\N	2026-08-29 06:43:10
240	1	7	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:10
241	1	7	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-10-06	2019-10-06	2019-10-06	2019-10-06	1	1	\N	2026-08-29 06:43:10
242	1	7	\N	B	\N	\N	\N	BEACH SPORT	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	2026-08-29 06:43:10
243	1	7	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-04	2019-08-04	2019-08-05	2019-08-05	2	1	\N	2026-08-29 06:43:10
244	1	7	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-04	2019-08-04	2019-08-04	2019-08-04	1	1	\N	2026-08-29 06:43:10
245	1	7	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-06-29	2019-06-29	2019-06-30	2019-06-30	2	1	\N	2026-08-29 06:43:10
246	1	7	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-08-04	2019-08-04	2019-08-05	2019-08-05	2	1	\N	2026-08-29 06:43:10
247	1	7	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-07	2019-08-07	2019-08-07	2019-08-07	1	1	\N	2026-08-29 06:43:10
248	1	7	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-06	2019-08-06	2019-08-06	2019-08-06	1	1	\N	2026-08-29 06:43:10
249	1	7	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-07-02	2019-07-02	2019-07-02	2019-07-02	1	1	\N	2026-08-29 06:43:10
250	1	7	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-08-07	2019-08-07	2019-08-07	2019-08-07	1	1	\N	2026-08-29 06:43:10
251	1	7	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-09	2019-08-09	2019-08-09	2019-08-09	1	1	\N	2026-08-29 06:43:10
252	1	7	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:10
253	1	7	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-10-06	2019-10-06	2019-10-06	2019-10-06	1	1	\N	2026-08-29 06:43:10
254	1	8	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system35-48)	\N	\N	\N	2019-06-12	2019-06-12	2019-12-09	2019-12-09	\N	1	\N	2026-08-29 06:43:11
255	1	8	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-08-23	2019-08-23	2019-09-06	2019-09-06	15	1	\N	2026-08-29 06:43:11
256	1	8	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-06-12	2019-06-12	2019-06-16	2019-06-16	5	1	\N	2026-08-29 06:43:11
257	1	8	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-11-17	2019-11-17	2019-11-19	2019-11-19	3	1	\N	2026-08-29 06:43:11
258	1	8	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-11-17	2019-11-17	2019-11-19	2019-11-19	3	1	\N	2026-08-29 06:43:11
259	1	8	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-11-14	2019-11-14	2019-11-23	2019-11-23	10	1	\N	2026-08-29 06:43:11
260	1	8	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-11-22	2019-11-22	2019-11-24	2019-11-24	3	1	\N	2026-08-29 06:43:11
261	1	8	\N	II	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(27-37 & 70-73)	\N	\N	\N	2019-07-07	2019-07-07	2019-07-06	2019-07-06	\N	1	\N	2026-08-29 06:43:11
262	1	8	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-09-17	2019-09-17	2019-10-06	2019-10-06	20	1	\N	2026-08-29 06:43:11
263	1	8	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-07-07	2019-07-07	2019-07-11	2019-07-11	5	1	\N	2026-08-29 06:43:11
264	1	8	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-10-07	2019-10-07	2019-10-09	2019-10-09	3	1	\N	2026-08-29 06:43:11
265	1	8	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-07-12	2019-07-12	2019-07-14	2019-07-14	3	1	\N	2026-08-29 06:43:11
266	1	8	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-12-03	2019-12-03	2019-12-09	2019-12-09	7	1	\N	2026-08-29 06:43:11
267	1	8	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-12-07	2019-12-07	2019-12-09	2019-12-09	3	1	\N	2026-08-29 06:43:11
268	1	8	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-09-07	2019-09-07	2019-11-08	2019-11-08	\N	1	\N	2026-08-29 06:43:11
269	1	8	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-09-17	2019-09-17	2019-09-17	2019-09-17	1	1	\N	2026-08-29 06:43:11
270	1	8	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-09-10	2019-09-10	2019-09-10	2019-09-10	1	1	\N	2026-08-29 06:43:11
271	1	8	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-09-07	2019-09-07	2019-09-08	2019-09-08	2	1	\N	2026-08-29 06:43:11
272	1	8	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-09-17	2019-09-17	2019-09-17	2019-09-17	1	1	\N	2026-08-29 06:43:11
273	1	8	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-09-19	2019-09-19	2019-09-19	2019-09-19	1	1	\N	2026-08-29 06:43:11
274	1	8	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-09-12	2019-09-12	2019-09-12	2019-09-12	1	1	\N	2026-08-29 06:43:11
275	1	8	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-09-21	2019-09-21	2019-09-21	2019-09-21	1	1	\N	2026-08-29 06:43:11
276	1	8	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-09-21	2019-09-21	2019-09-21	2019-09-21	1	1	\N	2026-08-29 06:43:11
277	1	8	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-09-22	2019-09-22	2019-09-22	2019-09-22	1	1	\N	2026-08-29 06:43:11
278	1	8	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-11-06	2019-11-06	2019-11-06	2019-11-06	1	1	\N	2026-08-29 06:43:11
279	1	8	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-11-08	2019-11-08	2019-11-08	2019-11-08	1	1	\N	2026-08-29 06:43:11
280	1	9	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-07-01	2019-07-01	2019-11-30	2019-11-30	\N	1	\N	2026-08-29 06:43:11
281	1	9	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-08-26	2019-08-26	2019-09-04	2019-09-04	10	1	\N	2026-08-29 06:43:11
282	1	9	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-07-01	2019-07-01	2019-07-05	2019-07-05	5	1	\N	2026-08-29 06:43:11
283	1	9	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-09-05	2019-09-05	2019-09-07	2019-09-07	3	1	\N	2026-08-29 06:43:11
284	1	9	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-07-06	2019-07-06	2019-07-08	2019-07-08	3	1	\N	2026-08-29 06:43:11
285	1	9	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-11-24	2019-11-24	2019-11-30	2019-11-30	7	1	\N	2026-08-29 06:43:11
286	1	9	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-11-28	2019-11-28	2019-11-30	2019-11-30	3	1	\N	2026-08-29 06:43:11
287	1	9	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-08-28	2019-07-14	2019-12-09	2019-11-15	\N	1	\N	2026-08-29 06:43:11
288	1	9	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-09-28	2019-08-15	2019-09-29	2019-08-16	2	1	\N	2026-08-29 06:43:11
289	1	9	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-09-28	2019-08-15	2019-09-28	2019-08-15	1	1	\N	2026-08-29 06:43:11
290	1	9	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-08-28	2019-07-14	2019-08-30	2019-07-16	3	1	\N	2026-08-29 06:43:11
291	1	9	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-09-28	2019-08-15	2019-09-29	2019-08-16	2	1	\N	2026-08-29 06:43:11
292	1	9	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-10-01	2019-08-18	2019-10-01	2019-08-18	1	1	\N	2026-08-29 06:43:11
293	1	9	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-09-30	2019-08-17	2019-09-30	2019-08-17	1	1	\N	2026-08-29 06:43:11
294	1	9	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-10-23	2019-09-09	2019-10-23	2019-09-09	1	1	\N	2026-08-29 06:43:11
295	1	9	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-10-23	2019-09-09	2019-10-23	2019-09-09	1	1	\N	2026-08-29 06:43:11
296	1	9	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-10-23	2019-09-10	2019-10-23	2019-09-10	1	1	\N	2026-08-29 06:43:11
297	1	9	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-12-07	2019-11-13	2019-12-07	2019-11-13	1	1	\N	2026-08-29 06:43:11
298	1	9	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-12-09	2019-11-15	2019-12-09	2019-11-15	1	1	\N	2026-08-29 06:43:11
299	1	11	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(1-13)	\N	\N	\N	2019-07-04	2019-07-04	2019-11-09	2019-11-09	\N	1	\N	2026-08-29 06:43:11
300	1	11	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-07-04	2019-07-04	2019-07-23	2019-07-23	20	1	\N	2026-08-29 06:43:11
301	1	11	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-07-23	2019-07-23	2019-07-27	2019-07-27	5	1	\N	2026-08-29 06:43:11
302	1	11	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-07-24	2019-07-24	2019-07-30	2019-07-30	7	1	\N	2026-08-29 06:43:11
303	1	11	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-07-28	2019-07-28	2019-08-03	2019-08-03	7	1	\N	2026-08-29 06:43:11
304	1	11	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-10-21	2019-10-21	2019-11-09	2019-11-09	20	1	\N	2026-08-29 06:43:11
305	1	11	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-11-03	2019-11-03	2019-11-09	2019-11-09	7	1	\N	2026-08-29 06:43:11
306	1	11	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-07-24	2019-07-24	2019-10-14	2019-10-14	\N	1	\N	2026-08-29 06:43:11
307	1	11	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-07-29	2019-07-29	2019-07-30	2019-07-30	2	1	\N	2026-08-29 06:43:11
308	1	11	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-01	2019-08-01	2019-08-01	2019-08-01	1	1	\N	2026-08-29 06:43:11
309	1	11	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-07-24	2019-07-24	2019-07-28	2019-07-28	5	1	\N	2026-08-29 06:43:11
310	1	11	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-07-29	2019-07-29	2019-07-29	2019-07-29	1	1	\N	2026-08-29 06:43:11
311	1	11	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-01	2019-08-01	2019-08-01	2019-08-01	1	1	\N	2026-08-29 06:43:11
312	1	11	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-03	2019-08-03	2019-08-03	2019-08-03	1	1	\N	2026-08-29 06:43:11
313	1	11	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-07-30	2019-07-30	2019-07-30	2019-07-30	1	1	\N	2026-08-29 06:43:11
314	1	11	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-07-30	2019-07-30	2019-07-30	2019-07-30	1	1	\N	2026-08-29 06:43:11
315	1	11	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-07-30	2019-07-30	2019-07-30	2019-07-30	1	1	\N	2026-08-29 06:43:11
316	1	11	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-10-12	2019-10-12	2019-10-12	2019-10-12	1	1	\N	2026-08-29 06:43:11
317	1	11	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-10-14	2019-10-14	2019-10-14	2019-10-14	1	1	\N	2026-08-29 06:43:11
318	1	12	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(14-26)	\N	\N	\N	2019-05-18	2019-05-18	2019-10-25	2019-10-25	\N	1	\N	2026-08-29 06:43:11
319	1	12	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-07-31	2019-07-31	2019-08-24	2019-08-24	25	1	\N	2026-08-29 06:43:11
320	1	12	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-05-18	2019-05-18	2019-05-22	2019-05-22	5	1	\N	2026-08-29 06:43:11
321	1	12	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-08-25	2019-08-25	2019-08-27	2019-08-27	3	1	\N	2026-08-29 06:43:11
322	1	12	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-05-23	2019-05-23	2019-05-25	2019-05-25	3	1	\N	2026-08-29 06:43:11
323	1	12	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-10-19	2019-10-19	2019-10-25	2019-10-25	7	1	\N	2026-08-29 06:43:11
324	1	12	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-10-23	2019-10-23	2019-10-25	2019-10-25	3	1	\N	2026-08-29 06:43:11
325	1	12	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-07-24	2019-07-24	2019-10-14	2019-10-14	\N	1	\N	2026-08-29 06:43:11
326	1	12	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-07-29	2019-07-29	2019-07-30	2019-07-30	2	1	\N	2026-08-29 06:43:11
327	1	12	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-01	2019-08-01	2019-08-01	2019-08-01	1	1	\N	2026-08-29 06:43:11
328	1	12	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-07-24	2019-07-24	2019-07-26	2019-07-26	3	1	\N	2026-08-29 06:43:11
329	1	12	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-07-29	2019-07-29	2019-07-30	2019-07-30	2	1	\N	2026-08-29 06:43:11
330	1	12	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-01	2019-08-01	2019-08-01	2019-08-01	1	1	\N	2026-08-29 06:43:11
331	1	12	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-03	2019-08-03	2019-08-03	2019-08-03	1	1	\N	2026-08-29 06:43:11
332	1	12	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-07-28	2019-07-28	2019-07-28	2019-07-28	1	1	\N	2026-08-29 06:43:11
333	1	12	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-07-28	2019-07-28	2019-07-28	2019-07-28	1	1	\N	2026-08-29 06:43:11
334	1	12	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-07-28	2019-07-28	2019-07-28	2019-07-28	1	1	\N	2026-08-29 06:43:11
335	1	12	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-10-12	2019-10-12	2019-10-12	2019-10-12	1	1	\N	2026-08-29 06:43:11
336	1	12	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-10-14	2019-10-14	2019-10-14	2019-10-14	1	1	\N	2026-08-29 06:43:11
337	1	13	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system (D5)	\N	\N	\N	2019-04-01	2019-04-01	2019-12-25	2019-12-31	\N	1	\N	2026-08-29 06:43:11
338	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-01	2019-04-01	2019-06-09	2019-06-09	70	1	\N	2026-08-29 06:43:11
339	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-04-10	2019-04-10	2019-07-28	2019-07-28	110	1	\N	2026-08-29 06:43:11
340	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-07-20	2019-07-20	2019-09-02	2019-09-02	45	1	\N	2026-08-29 06:43:11
341	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-05-15	2019-05-15	2019-08-02	2019-08-02	80	1	\N	2026-08-29 06:43:11
342	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-08-24	2019-08-24	2019-12-01	2019-12-01	100	1	\N	2026-08-29 06:43:11
343	1	13	\N	II	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(N2-N3)	\N	0	DONE	2019-04-01	2019-04-01	2019-03-31	2019-03-31	\N	1	\N	2026-08-29 06:43:11
344	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-01	2019-04-01	2019-05-25	2019-05-25	55	1	\N	2026-08-29 06:43:11
345	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-04-08	2019-04-08	2019-05-27	2019-05-27	50	1	\N	2026-08-29 06:43:11
346	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-07-20	2019-07-20	2019-09-22	2019-09-22	65	1	\N	2026-08-29 06:43:11
347	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-05-15	2019-05-15	2019-05-29	2019-05-29	15	1	\N	2026-08-29 06:43:11
348	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	PENDING	2019-09-23	2019-09-23	2019-11-21	2019-12-31	60	1	\N	2026-08-29 06:43:11
349	1	13	\N	III	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D1)	\N	0	DONE	2019-04-15	2019-04-15	2019-04-14	2019-04-14	\N	1	\N	2026-08-29 06:43:11
350	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-15	2019-04-15	2019-06-13	2019-06-13	60	1	\N	2026-08-29 06:43:11
351	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-04-25	2019-04-25	2019-09-16	2019-08-12	145	1	\N	2026-08-29 06:43:11
352	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-08-25	2019-08-25	2019-11-02	2019-11-02	70	1	\N	2026-08-29 06:43:11
353	1	13	\N	\N	4	\N	4	Kiểm tra thử kín, thử áp hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-09-05	2019-09-05	2019-11-08	2019-09-19	65	1	\N	2026-08-29 06:43:11
354	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-10-02	2019-10-02	2019-11-30	2019-11-30	60	1	\N	2026-08-29 06:43:11
355	1	13	\N	IV	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D3)	\N	0	DONE	2019-04-05	2019-04-05	2019-04-04	2019-04-04	\N	1	\N	2026-08-29 06:43:11
356	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-05	2019-04-05	2019-05-09	2019-05-09	35	1	\N	2026-08-29 06:43:11
357	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-04-30	2019-04-30	2019-07-28	2019-07-28	90	1	\N	2026-08-29 06:43:11
358	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-06-05	2019-06-05	2019-08-03	2019-08-03	60	1	\N	2026-08-29 06:43:11
359	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-06-02	2019-06-02	2019-08-05	2019-06-16	65	1	\N	2026-08-29 06:43:11
360	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-08-07	2019-08-07	2019-09-25	2019-09-25	50	1	\N	2026-08-29 06:43:11
361	1	13	\N	V	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D6)	\N	0	DONE	2019-04-01	2019-04-01	2019-03-31	2019-03-31	\N	1	\N	2026-08-29 06:43:11
362	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill ( Cấp nước d 110)	\N	0.2	DONE	2019-04-01	2019-04-01	2019-05-15	2019-05-15	45	1	\N	2026-08-29 06:43:11
363	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước,)Underground pipe system execution(water supply)	\N	0.2	DONE	2019-04-26	2019-04-26	2019-08-18	2019-08-18	115	1	\N	2026-08-29 06:43:11
364	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-08-09	2019-06-05	2019-10-27	2019-08-23	80	1	\N	2026-08-29 06:43:11
365	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp  nước/testing water supply system	\N	0	DONE	2019-08-20	2019-08-20	2019-10-28	2019-10-28	70	1	\N	2026-08-29 06:43:11
366	1	13	\N	\N	5	\N	5	Thi công đào, lấp đất/Excavation, backfill( Thoát nước)	\N	0	DONE	2019-04-01	2019-04-01	2019-05-15	2019-05-15	45	1	\N	2026-08-29 06:43:11
367	1	13	\N	\N	6	\N	6	Thi công hệ thống ống âm đất (thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-04-26	2019-04-26	2019-08-18	2019-08-18	115	1	\N	2026-08-29 06:43:11
368	1	13	\N	\N	7	\N	7	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-08-09	2019-06-05	2019-10-27	2019-08-23	80	1	\N	2026-08-29 06:43:11
369	1	13	\N	\N	8	\N	8	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-08-20	2019-08-20	2019-10-28	2019-10-28	70	1	\N	2026-08-29 06:43:11
370	1	13	\N	\N	9	\N	9	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-10-20	2019-10-20	2019-12-25	2019-12-25	67	1	\N	2026-08-29 06:43:11
371	1	13	\N	\N	10	\N	10	Gia công lắp đặt nghiệm thu cốt thép hố ga tuyến D6	\N	0.7058824	PENDING	2019-04-11	2019-04-12	2019-04-15	2019-04-17	5	1	\N	2026-08-29 06:43:11
372	1	13	\N	\N	11	\N	11	Gia công lắp đặt nghiệm thu cốp pha hố ga tuyến D6	\N	0.1	PENDING	2019-04-13	2019-04-14	2019-04-20	2019-04-22	8	1	\N	2026-08-29 06:43:11
373	1	13	\N	\N	12	\N	12	Đổ bê tông hố ga tuyến D6	\N	0	PENDING	2019-04-13	2019-04-16	2019-04-20	2019-04-22	8	1	\N	2026-08-29 06:43:11
374	1	13	\N	\N	13	\N	13	Nghiêm thu công tác đổ bê tông hố ga tuyến D6	\N	0	PENDING	2019-04-18	2019-04-21	2019-04-25	2019-04-27	8	1	\N	2026-08-29 06:43:11
375	1	13	\N	VI	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D8)	\N	0	DONE	2019-04-16	2019-04-16	2019-04-15	2019-04-15	\N	1	\N	2026-08-29 06:43:11
376	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill ( Cấp nước d 110)	\N	0.6	DONE	2019-04-01	2019-04-01	2019-05-15	2019-05-15	45	1	\N	2026-08-29 06:43:11
377	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước,)Underground pipe system execution(water supply)	\N	0.6	DONE	2019-04-26	2019-04-26	2019-08-18	2019-08-18	115	1	\N	2026-08-29 06:43:11
378	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-08-09	2019-06-05	2019-10-27	2019-08-23	80	1	\N	2026-08-29 06:43:11
379	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp  nước/testing water supply system	\N	0	DONE	2019-08-20	2019-08-20	2019-10-28	2019-10-28	70	1	\N	2026-08-29 06:43:11
380	1	13	\N	\N	5	\N	5	Thi công đào, lấp đất/Excavation, backfill( Thoát nước)	\N	0.5	DONE	2019-04-01	2019-04-01	2019-05-15	2019-05-15	45	1	\N	2026-08-29 06:43:11
381	1	13	\N	\N	6	\N	6	Thi công hệ thống ống âm đất (thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0.5	DONE	2019-04-26	2019-04-26	2019-08-18	2019-08-18	115	1	\N	2026-08-29 06:43:11
382	1	13	\N	\N	7	\N	7	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-08-09	2019-06-05	2019-10-27	2019-08-23	80	1	\N	2026-08-29 06:43:11
383	1	13	\N	\N	8	\N	8	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-08-20	2019-08-20	2019-10-28	2019-10-28	70	1	\N	2026-08-29 06:43:11
384	1	13	\N	\N	9	\N	9	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-10-20	2019-10-20	2019-12-25	2019-12-25	67	1	\N	2026-08-29 06:43:11
385	1	13	\N	VII	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D4)	\N	0	DONE	2019-04-16	2019-04-16	2019-04-15	2019-04-15	\N	1	\N	2026-08-29 06:43:11
386	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-16	2019-04-16	2019-05-15	2019-05-15	30	1	\N	2026-08-29 06:43:11
387	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-05-11	2019-05-11	2019-07-09	2019-07-09	60	1	\N	2026-08-29 06:43:11
388	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-07-15	2019-07-15	2019-09-07	2019-09-07	55	1	\N	2026-08-29 06:43:11
389	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-07-25	2019-07-25	2019-09-09	2019-09-09	47	1	\N	2026-08-29 06:43:11
390	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-08-14	2019-08-14	2019-09-18	2019-09-18	36	1	\N	2026-08-29 06:43:11
391	1	13	\N	VIII	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D2)	\N	0	DONE	2019-04-01	2019-04-01	2019-03-31	2019-03-31	\N	1	\N	2026-08-29 06:43:11
392	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-01	2019-04-01	2019-05-05	2019-05-05	35	1	\N	2026-08-29 06:43:11
393	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-04-26	2019-04-26	2019-07-24	2019-07-24	90	1	\N	2026-08-29 06:43:11
394	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-07-20	2019-07-20	2019-10-02	2019-10-02	75	1	\N	2026-08-29 06:43:11
395	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-07-27	2019-07-27	2019-10-04	2019-10-04	70	1	\N	2026-08-29 06:43:11
396	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-09-22	2019-09-22	2019-10-31	2019-10-31	40	1	\N	2026-08-29 06:43:11
397	1	13	\N	VIII	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system(D2)	\N	0	DONE	2019-04-06	2019-04-06	2019-04-05	2019-04-05	\N	1	\N	2026-08-29 06:43:11
398	1	13	\N	\N	1	\N	1	Thi công đào, lấp đất/Excavation, backfill	\N	0	DONE	2019-04-06	2019-04-06	2019-05-10	2019-05-10	35	1	\N	2026-08-29 06:43:11
399	1	13	\N	\N	2	\N	2	Thi công hệ thống ống âm đất (cấp nước, thoát nước, thoát nước thải)Underground pipe system execution(water supply, drainage, sewage)	\N	0	DONE	2019-05-01	2019-05-01	2019-07-24	2019-07-24	85	1	\N	2026-08-29 06:43:11
400	1	13	\N	\N	3	\N	3	Thi công hệ thống valve, vòi, trụ/ Valve system, ejector, pillar installation	\N	0	DONE	2019-07-15	2019-07-15	2019-09-17	2019-09-17	65	1	\N	2026-08-29 06:43:11
401	1	13	\N	\N	4	\N	4	Kiểm tra hệ thống cấp thoát nước/testing water supply system	\N	0	DONE	2019-07-20	2019-07-20	2019-09-17	2019-09-17	60	1	\N	2026-08-29 06:43:11
402	1	13	\N	\N	5	\N	5	Thi công hệ thống bơm (nước cấp, nước thoát, bù áp)/ Pump system installtion (water supply, drainage, pump pressure)	\N	0	DONE	2019-08-31	2019-08-31	2019-11-03	2019-11-03	65	1	\N	2026-08-29 06:43:11
403	1	13	\N	B	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	0	DONE	2019-07-24	2019-07-24	2019-07-23	2019-07-23	\N	1	\N	2026-08-29 06:43:11
404	1	13	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-08-03	2019-08-03	2019-08-04	2019-08-04	2	1	\N	2026-08-29 06:43:11
405	1	13	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-08-01	2019-08-01	2019-08-01	2019-08-01	1	1	\N	2026-08-29 06:43:11
406	1	13	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-07-24	2019-07-24	2019-07-28	2019-07-28	5	1	\N	2026-08-29 06:43:11
407	1	13	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-07-29	2019-07-29	2019-07-29	2019-07-29	1	1	\N	2026-08-29 06:43:11
408	1	13	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-08-01	2019-08-01	2019-08-01	2019-08-01	1	1	\N	2026-08-29 06:43:11
409	1	13	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-08-03	2019-08-03	2019-08-03	2019-08-03	1	1	\N	2026-08-29 06:43:11
410	1	13	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-07-30	2019-07-30	2019-07-30	2019-07-30	1	1	\N	2026-08-29 06:43:11
411	1	13	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-07-30	2019-07-30	2019-07-30	2019-07-30	1	1	\N	2026-08-29 06:43:11
412	1	13	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-07-30	2019-07-30	2019-07-30	2019-07-30	1	1	\N	2026-08-29 06:43:11
413	1	13	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-10-12	2019-10-12	2019-10-12	2019-10-12	1	1	\N	2026-08-29 06:43:11
414	1	13	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-10-14	2019-10-14	2019-10-14	2019-10-14	1	1	\N	2026-08-29 06:43:11
415	1	14	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-07-24	2019-07-24	2019-12-13	2019-12-13	\N	1	\N	2026-08-29 06:43:11
416	1	14	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-09-28	2019-09-28	2019-10-07	2019-10-07	10	1	\N	2026-08-29 06:43:11
417	1	14	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-07-24	2019-07-24	2019-07-28	2019-07-28	5	1	\N	2026-08-29 06:43:11
418	1	14	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-10-08	2019-10-08	2019-10-10	2019-10-10	3	1	\N	2026-08-29 06:43:11
419	1	14	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-07-29	2019-07-29	2019-07-31	2019-07-31	3	1	\N	2026-08-29 06:43:11
420	1	14	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-12-07	2019-12-07	2019-12-13	2019-12-13	7	1	\N	2026-08-29 06:43:11
421	1	14	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-12-11	2019-12-11	2019-12-13	2019-12-13	3	1	\N	2026-08-29 06:43:11
422	1	14	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-08-28	2019-07-14	2019-12-09	2019-11-15	\N	1	\N	2026-08-29 06:43:11
423	1	14	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-09-28	2019-08-15	2019-09-29	2019-08-16	2	1	\N	2026-08-29 06:43:11
424	1	14	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-09-28	2019-08-15	2019-09-28	2019-08-15	1	1	\N	2026-08-29 06:43:11
425	1	14	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-08-28	2019-07-14	2019-08-30	2019-07-16	3	1	\N	2026-08-29 06:43:11
426	1	14	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-09-28	2019-08-15	2019-09-29	2019-08-16	2	1	\N	2026-08-29 06:43:11
427	1	14	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-10-01	2019-08-18	2019-10-01	2019-08-18	1	1	\N	2026-08-29 06:43:11
428	1	14	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-09-30	2019-08-17	2019-09-30	2019-08-17	1	1	\N	2026-08-29 06:43:11
429	1	14	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-10-23	2019-09-09	2019-10-23	2019-09-09	1	1	\N	2026-08-29 06:43:11
430	1	14	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-10-23	2019-09-09	2019-10-23	2019-09-09	1	1	\N	2026-08-29 06:43:11
431	1	14	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-10-23	2019-09-10	2019-10-23	2019-09-10	1	1	\N	2026-08-29 06:43:11
432	1	14	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-12-07	2019-11-13	2019-12-07	2019-11-13	1	1	\N	2026-08-29 06:43:11
433	1	14	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-12-09	2019-11-15	2019-12-09	2019-11-15	1	1	\N	2026-08-29 06:43:11
434	1	15	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-06-10	2019-06-10	2019-12-16	2019-12-16	\N	1	\N	2026-08-29 06:43:11
435	1	15	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-10-15	2019-10-15	2019-10-24	2019-10-24	10	1	\N	2026-08-29 06:43:11
436	1	15	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-06-10	2019-06-10	2019-06-14	2019-06-14	5	1	\N	2026-08-29 06:43:11
437	1	15	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-10-25	2019-10-25	2019-10-27	2019-10-27	3	1	\N	2026-08-29 06:43:11
438	1	15	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-06-15	2019-06-15	2019-06-17	2019-06-17	3	1	\N	2026-08-29 06:43:11
439	1	15	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-12-09	2019-12-09	2019-12-15	2019-12-15	7	1	\N	2026-08-29 06:43:11
440	1	15	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-12-16	2019-12-16	2019-12-16	2019-12-16	1	1	\N	2026-08-29 06:43:11
441	1	15	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-09-03	2019-09-03	2019-12-25	2019-12-25	\N	1	\N	2026-08-29 06:43:11
442	1	15	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng 1 /Installing copper pipe and heat insulation floor 1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-23	2019-10-23	9	1	\N	2026-08-29 06:43:11
443	1	15	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-10-25	2019-10-25	2019-10-30	2019-10-30	6	1	\N	2026-08-29 06:43:11
444	1	15	\N	\N	3	\N	3	Thi công lắp đặt ống nước ngưng và bảo ôn tầng 1/Installing sealing water pipe and heat insulation floor 1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-22	2019-10-22	8	1	\N	2026-08-29 06:43:11
445	1	15	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-10-24	2019-10-24	2019-10-28	2019-10-28	5	1	\N	2026-08-29 06:43:11
446	1	15	\N	\N	5	\N	5	Thi công lắp đặt đường ống thông gió và bảo ôn tầng 1/Installing air duct and heat insulation floor 1	\N	0	DONE	2019-09-03	2019-09-03	2019-09-14	2019-09-14	12	1	\N	2026-08-29 06:43:11
447	1	15	\N	\N	6	\N	6	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T2/Installing air duct and heat insulation floor2	\N	0	DONE	2019-09-16	2019-09-16	2019-09-22	2019-09-22	7	1	\N	2026-08-29 06:43:11
448	1	15	\N	\N	7	\N	7	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng 1/Installing signal of conduit and controlling floor 1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-17	2019-10-17	3	1	\N	2026-08-29 06:43:11
449	1	15	\N	\N	8	\N	8	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng 2 /Installing signal of conduit and controlling floor2	\N	0	DONE	2019-10-25	2019-10-25	2019-10-27	2019-10-27	3	1	\N	2026-08-29 06:43:11
450	1	15	\N	\N	9	\N	9	Thử áp đường ống đồng tầng 1 /Testing pressure copper pipe floor 1	\N	0	DONE	2019-10-25	2019-10-25	2019-10-25	2019-10-25	1	1	\N	2026-08-29 06:43:11
451	1	15	\N	\N	10	\N	10	Thử áp đường ống đồng tầng 2 /Testing pressure copper pipe floor2	\N	0	DONE	2019-11-01	2019-11-01	2019-11-01	2019-11-01	1	1	\N	2026-08-29 06:43:11
452	1	15	\N	\N	11	\N	11	Thử kín đường ống nước ngưng tầng 1/Testing sealing water pipe floor 1	\N	0	DONE	2019-10-24	2019-10-24	2019-10-24	2019-10-24	1	1	\N	2026-08-29 06:43:11
453	1	15	\N	\N	12	\N	12	Thử kín đường ống nước ngưng tầng 2/Testing sealing water pipe floor2	\N	0	DONE	2019-10-30	2019-10-30	2019-10-30	2019-10-30	1	1	\N	2026-08-29 06:43:11
454	1	15	\N	\N	13	\N	13	Lắp đặt thiết bị quạt thông gió tầng 1/Installing air duct fan equipment floor 1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-16	2019-10-16	2	1	\N	2026-08-29 06:43:11
455	1	15	\N	\N	14	\N	14	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor1	\N	0	DONE	2019-10-18	2019-10-18	2019-10-19	2019-10-19	2	1	\N	2026-08-29 06:43:11
456	1	15	\N	\N	15	\N	15	Lắp đặt nón che mua tầng mái/Installing air hat roof floor	\N	0	DONE	2019-10-21	2019-10-21	2019-10-22	2019-10-22	2	1	\N	2026-08-29 06:43:11
457	1	15	\N	\N	16	\N	16	Lắp đặt thiết bị điều hòa không khí tầng 1/Installing air conditional equipment floor 1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-21	2019-10-21	7	1	\N	2026-08-29 06:43:11
458	1	15	\N	\N	17	\N	17	Lắp đặt thiết bị điều hòa không khí tầng 2 /Installing air conditional equipment floor2	\N	0	DONE	2019-10-23	2019-10-23	2019-10-26	2019-10-26	4	1	\N	2026-08-29 06:43:11
459	1	15	\N	\N	18	\N	18	Lắp đặt thiết bị điều khiển tầng 1/Installing controling equipment floor 1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-16	2019-10-16	2	1	\N	2026-08-29 06:43:11
460	1	15	\N	\N	19	\N	19	Lắp đặt thiết bị điều khiển tầng 2 /Installing controling equipment floor1	\N	0	DONE	2019-10-23	2019-10-23	2019-10-23	2019-10-23	1	1	\N	2026-08-29 06:43:11
461	1	15	\N	\N	20	\N	20	Lắp đặt cửa gió tầng 1 /Installing air diffuser baseman floor	\N	0	DONE	2019-12-19	2019-12-19	2019-12-20	2019-12-20	2	1	\N	2026-08-29 06:43:11
462	1	15	\N	\N	21	\N	21	Lắp đặt cửa gió tầng 2 /Installing air diffuser floor1	\N	0	DONE	2019-12-22	2019-12-22	2019-12-23	2019-12-23	2	1	\N	2026-08-29 06:43:11
463	1	15	\N	\N	22	\N	22	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-12-25	2019-12-25	2019-12-25	2019-12-25	1	1	\N	2026-08-29 06:43:11
464	1	17	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-08-10	2019-08-10	2019-12-13	2019-12-13	\N	1	\N	2026-08-29 06:43:11
465	1	17	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-10-01	2019-10-01	2019-10-10	2019-10-10	10	1	\N	2026-08-29 06:43:11
466	1	17	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-08-10	2019-08-10	2019-08-14	2019-08-14	5	1	\N	2026-08-29 06:43:11
467	1	17	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-10-11	2019-10-11	2019-10-13	2019-10-13	3	1	\N	2026-08-29 06:43:11
468	1	17	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-08-15	2019-08-15	2019-08-17	2019-08-17	3	1	\N	2026-08-29 06:43:11
469	1	17	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-12-07	2019-12-07	2019-12-13	2019-12-13	7	1	\N	2026-08-29 06:43:11
470	1	17	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-12-11	2019-12-11	2019-12-13	2019-12-13	3	1	\N	2026-08-29 06:43:11
471	1	17	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-09-06	2019-09-06	2019-11-28	2019-11-28	\N	1	\N	2026-08-29 06:43:11
472	1	17	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-10-01	2019-10-01	2019-10-02	2019-10-02	2	1	\N	2026-08-29 06:43:11
473	1	17	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
474	1	17	\N	\N	3	\N	3	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-10-01	2019-10-01	2019-10-02	2019-10-02	2	1	\N	2026-08-29 06:43:11
475	1	17	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
476	1	17	\N	\N	5	\N	5	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-09-06	2019-09-06	2019-09-08	2019-09-08	3	1	\N	2026-08-29 06:43:11
477	1	17	\N	\N	\N	\N	\N	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T2/Installing air duct and heat insulation floor2	\N	0	DONE	2019-09-10	2019-09-10	2019-09-10	2019-09-10	1	1	\N	2026-08-29 06:43:11
478	1	17	\N	\N	\N	\N	\N	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-10-01	2019-10-01	2019-10-02	2019-10-02	2	1	\N	2026-08-29 06:43:11
479	1	17	\N	\N	\N	\N	\N	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor2	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
480	1	17	\N	\N	\N	\N	\N	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
481	1	17	\N	\N	\N	\N	\N	Thử áp đường ống đồng tầng T2/Testing pressure copper pipe floor2	\N	0	DONE	2019-10-06	2019-10-06	2019-10-06	2019-10-06	1	1	\N	2026-08-29 06:43:11
482	1	17	\N	\N	\N	\N	\N	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
483	1	17	\N	\N	\N	\N	\N	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor2	\N	0	DONE	2019-10-06	2019-10-06	2019-10-06	2019-10-06	1	1	\N	2026-08-29 06:43:11
484	1	17	\N	\N	\N	\N	\N	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-15	2019-10-15	1	1	\N	2026-08-29 06:43:11
485	1	17	\N	\N	\N	\N	\N	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor2	\N	0	DONE	2019-10-17	2019-10-17	2019-10-17	2019-10-17	1	1	\N	2026-08-29 06:43:11
486	1	17	\N	\N	\N	\N	\N	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-10-14	2019-10-14	2019-10-14	2019-10-14	1	1	\N	2026-08-29 06:43:11
487	1	17	\N	\N	\N	\N	\N	Lắp đặt thiết bị điều hòa không khí tầng T2/Installing air conditional equipment floor2	\N	0	DONE	2019-10-16	2019-10-16	2019-10-16	2019-10-16	1	1	\N	2026-08-29 06:43:11
488	1	17	\N	\N	\N	\N	\N	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-10-18	2019-10-18	2019-10-18	2019-10-18	1	1	\N	2026-08-29 06:43:11
489	1	17	\N	\N	6	\N	6	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor2	\N	0	DONE	2019-10-18	2019-10-18	2019-10-18	2019-10-18	1	1	\N	2026-08-29 06:43:11
490	1	17	\N	\N	7	\N	7	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-11-26	2019-11-26	2019-11-26	2019-11-26	1	1	\N	2026-08-29 06:43:11
491	1	17	\N	\N	8	\N	8	Lắp đặt cửa gió tầng T2/Installing air diffuser floor2	\N	0	DONE	2019-11-26	2019-11-26	2019-11-26	2019-11-26	1	1	\N	2026-08-29 06:43:11
492	1	17	\N	\N	9	\N	9	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-11-28	2019-11-28	2019-11-28	2019-11-28	1	1	\N	2026-08-29 06:43:11
493	1	18	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-08-10	2019-08-10	2019-12-13	2019-12-13	\N	1	\N	2026-08-29 06:43:11
494	1	18	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-10-01	2019-10-01	2019-10-10	2019-10-10	10	1	\N	2026-08-29 06:43:11
495	1	18	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-08-10	2019-08-10	2019-08-14	2019-08-14	5	1	\N	2026-08-29 06:43:11
496	1	18	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-10-11	2019-10-11	2019-10-13	2019-10-13	3	1	\N	2026-08-29 06:43:11
497	1	18	\N	\N	4	\N	4	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-08-15	2019-08-15	2019-08-17	2019-08-17	3	1	\N	2026-08-29 06:43:11
498	1	18	\N	\N	5	\N	5	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-12-07	2019-12-07	2019-12-13	2019-12-13	7	1	\N	2026-08-29 06:43:11
499	1	18	\N	\N	6	\N	6	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-12-11	2019-12-11	2019-12-13	2019-12-13	3	1	\N	2026-08-29 06:43:11
500	1	18	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-09-06	2019-09-06	2019-11-28	2019-11-28	\N	1	\N	2026-08-29 06:43:11
501	1	18	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-10-01	2019-10-01	2019-10-02	2019-10-02	2	1	\N	2026-08-29 06:43:11
502	1	18	\N	\N	2	\N	2	Thi công lắp đặt ống đồng và bảo ôn tầng T2/Installing copper pipe and heat insulation floor2	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
503	1	18	\N	\N	3	\N	3	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-10-01	2019-10-01	2019-10-02	2019-10-02	2	1	\N	2026-08-29 06:43:11
504	1	18	\N	\N	4	\N	4	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T2/Installing sealing water pipe and heat insulation floor2	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
505	1	18	\N	\N	5	\N	5	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-09-06	2019-09-06	2019-09-08	2019-09-08	3	1	\N	2026-08-29 06:43:11
506	1	18	\N	\N	6	\N	6	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T2/Installing air duct and heat insulation floor2	\N	0	DONE	2019-09-10	2019-09-10	2019-09-10	2019-09-10	1	1	\N	2026-08-29 06:43:11
507	1	18	\N	\N	7	\N	7	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-10-01	2019-10-01	2019-10-02	2019-10-02	2	1	\N	2026-08-29 06:43:11
508	1	18	\N	\N	8	\N	8	Thi công lắp đặt ống luồn dây tiến hiệu và điều khiển tầng T2/Installing signal of conduit and controlling floor2	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
509	1	18	\N	\N	9	\N	9	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
510	1	18	\N	\N	10	\N	10	Thử áp đường ống đồng tầng T2/Testing pressure copper pipe floor2	\N	0	DONE	2019-10-06	2019-10-06	2019-10-06	2019-10-06	1	1	\N	2026-08-29 06:43:11
511	1	18	\N	\N	11	\N	11	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-10-04	2019-10-04	2019-10-04	2019-10-04	1	1	\N	2026-08-29 06:43:11
512	1	18	\N	\N	12	\N	12	Thử kín đường ống nước ngưng tầng T2/Testing sealing water pipe floor2	\N	0	DONE	2019-10-06	2019-10-06	2019-10-06	2019-10-06	1	1	\N	2026-08-29 06:43:11
513	1	18	\N	\N	13	\N	13	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-10-15	2019-10-15	2019-10-15	2019-10-15	1	1	\N	2026-08-29 06:43:11
514	1	18	\N	\N	14	\N	14	Lắp đặt thiết bị quạt thông gió tầng T2/Installing air duct fan equipment floor2	\N	0	DONE	2019-10-17	2019-10-17	2019-10-17	2019-10-17	1	1	\N	2026-08-29 06:43:11
515	1	18	\N	\N	15	\N	15	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-10-14	2019-10-14	2019-10-14	2019-10-14	1	1	\N	2026-08-29 06:43:11
516	1	18	\N	\N	16	\N	16	Lắp đặt thiết bị điều hòa không khí tầng T2/Installing air conditional equipment floor2	\N	0	DONE	2019-10-16	2019-10-16	2019-10-16	2019-10-16	1	1	\N	2026-08-29 06:43:11
517	1	18	\N	\N	17	\N	17	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-10-18	2019-10-18	2019-10-18	2019-10-18	1	1	\N	2026-08-29 06:43:11
518	1	18	\N	\N	18	\N	18	Lắp đặt thiết bị điều khiển tầng T2/Installing controling equipment floor2	\N	0	DONE	2019-10-18	2019-10-18	2019-10-18	2019-10-18	1	1	\N	2026-08-29 06:43:11
519	1	18	\N	\N	19	\N	19	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-11-26	2019-11-26	2019-11-26	2019-11-26	1	1	\N	2026-08-29 06:43:11
520	1	18	\N	\N	20	\N	20	Lắp đặt cửa gió tầng T2/Installing air diffuser floor2	\N	0	DONE	2019-11-26	2019-11-26	2019-11-26	2019-11-26	1	1	\N	2026-08-29 06:43:11
521	1	18	\N	\N	21	\N	21	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-11-28	2019-11-28	2019-11-28	2019-11-28	1	1	\N	2026-08-29 06:43:11
522	1	19	\N	I	\N	\N	\N	Hệ thống cấp thoát nước/Water supply and drainage system	\N	\N	\N	2019-03-23	2019-03-23	2019-09-26	2019-09-26	\N	1	\N	2026-08-29 06:43:11
523	1	19	\N	\N	1	\N	1	Thi công lắp đặt đường ống cấp nước /Installing water pipe	\N	0	DONE	2019-07-26	2019-07-26	2019-08-04	2019-08-04	10	1	\N	2026-08-29 06:43:11
524	1	19	\N	\N	2	\N	2	Thi công lắp đặt đường ống thoát nước/Installing drainpipe	\N	0	DONE	2019-03-23	2019-03-23	2019-03-27	2019-03-27	5	1	\N	2026-08-29 06:43:11
525	1	19	\N	\N	3	\N	3	Kiểm tra thử áp đường ống cấp nước/ Testing pressure of drainpipe	\N	0	DONE	2019-08-05	2019-08-05	2019-08-07	2019-08-07	3	1	\N	2026-08-29 06:43:11
526	1	19	\N	\N	4	\N	4	Thi công lắp đặt slevee hố bơm, bể tách mỡ /Installing water pipe	\N	0.8	DONE	2019-04-07	2019-04-07	2019-04-08	2019-04-08	2	1	\N	2026-08-29 06:43:11
527	1	19	\N	\N	5	\N	5	Kiểm tra thử kín đường ống thoát nước/Testing drainpipe	\N	0	DONE	2019-04-02	2019-04-02	2019-04-04	2019-04-04	3	1	\N	2026-08-29 06:43:11
528	1	19	\N	\N	6	\N	6	Thi công lắp đặt thiết bị vệ sinh/Installig sanitary equipment	\N	0	DONE	2019-09-21	2019-09-21	2019-09-25	2019-09-25	5	1	\N	2026-08-29 06:43:11
529	1	19	\N	\N	7	\N	7	Kiểm tra, chạy thử hệ thống/Teestng and running system	\N	0	DONE	2019-09-26	2019-09-26	2019-09-26	2019-09-26	1	1	\N	2026-08-29 06:43:11
530	1	19	\N	II	\N	\N	\N	Hệ thống thông gió và điều hòa không khí/HVAC System	\N	\N	\N	2019-06-14	2019-06-14	2019-09-23	2019-09-23	\N	1	\N	2026-08-29 06:43:11
531	1	19	\N	\N	1	\N	1	Thi công lắp đặt ống đồng và bảo ôn tầng T1/Installing copper pipe and heat insulation floor1	\N	0	DONE	2019-07-26	2019-07-26	2019-07-27	2019-07-27	2	1	\N	2026-08-29 06:43:11
532	1	19	\N	\N	2	\N	2	Thi công lắp đặt ống nước ngưng và bảo ôn tầng T1/Installing sealing water pipe and heat insulation floor1	\N	0	DONE	2019-07-26	2019-07-26	2019-07-26	2019-07-26	1	1	\N	2026-08-29 06:43:11
533	1	19	\N	\N	3	\N	3	Thi công lắp đặt đường ống thông gió và bảo ôn tầng T1/Installing air duct and heat insulation floor1	\N	0	DONE	2019-06-14	2019-06-14	2019-06-15	2019-06-15	2	1	\N	2026-08-29 06:43:11
534	1	19	\N	\N	4	\N	4	Thi công lắp đặt ống luồn dây tin hiệu và điều khiển tầng T1/Installing signal of conduit and controlling floor1	\N	0	DONE	2019-07-26	2019-07-26	2019-07-26	2019-07-26	1	1	\N	2026-08-29 06:43:11
535	1	19	\N	\N	5	\N	5	Thử áp đường ống đồng tầng T1/Testing pressure copper pipe floor1	\N	0	DONE	2019-07-29	2019-07-29	2019-07-29	2019-07-29	1	1	\N	2026-08-29 06:43:11
536	1	19	\N	\N	6	\N	6	Thử kín đường ống nước ngưng tầng T1/Testing sealing water pipe floor1	\N	0	DONE	2019-07-28	2019-07-28	2019-07-28	2019-07-28	1	1	\N	2026-08-29 06:43:11
537	1	19	\N	\N	7	\N	7	Lắp đặt thiết bị quạt thông gió tầng T1/Installing air duct fan equipment floor1	\N	0	DONE	2019-06-17	2019-06-17	2019-06-17	2019-06-17	1	1	\N	2026-08-29 06:43:11
538	1	19	\N	\N	8	\N	8	Lắp đặt thiết bị điều hòa không khí tầng T1/Installing air conditional equipment floor1	\N	0	DONE	2019-07-31	2019-07-31	2019-07-31	2019-07-31	1	1	\N	2026-08-29 06:43:11
539	1	19	\N	\N	9	\N	9	Lắp đặt thiết bị điều khiển tầng T1/Installing controling equipment floor1	\N	0	DONE	2019-08-02	2019-08-02	2019-08-02	2019-08-02	1	1	\N	2026-08-29 06:43:11
540	1	19	\N	\N	10	\N	10	Lắp đặt cửa gió tầng T1/Installing air diffuser floor1	\N	0	DONE	2019-09-21	2019-09-21	2019-09-21	2019-09-21	1	1	\N	2026-08-29 06:43:11
541	1	19	\N	\N	11	\N	11	Kiểm tra, chạy thử hệ thống/Testing, running system	\N	0	DONE	2019-09-23	2019-09-23	2019-09-23	2019-09-23	1	1	\N	2026-08-29 06:43:11
\.


--
-- Data for Name: contracts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contracts (id, project_id, vendor_id, contract_no, contract_name, signed_date, total_value, status, created_at) FROM stdin;
\.


--
-- Data for Name: cost_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cost_codes (id, tenant_id, code, name, category, unit, unit_price, status, created_at) FROM stdin;
\.


--
-- Data for Name: daily_acceptance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_acceptance (id, daily_report_id, ordinal, name_vi, quantity, unit, notes) FROM stdin;
1	1	4	\N	\N	\N	\N
2	1	5	\N	\N	\N	\N
3	1	6	\N	\N	\N	\N
4	1	7	\N	\N	\N	\N
5	1	8	\N	\N	\N	\N
6	1	9	\N	\N	\N	\N
7	1	10	\N	\N	\N	\N
8	1	11	\N	\N	\N	\N
9	1	12	\N	\N	\N	\N
10	1	13	\N	\N	\N	\N
11	1	14	\N	\N	\N	\N
12	2	4	\N	\N	\N	\N
13	2	5	\N	\N	\N	\N
14	2	6	\N	\N	\N	\N
15	2	7	\N	\N	\N	\N
16	2	8	\N	\N	\N	\N
17	2	9	\N	\N	\N	\N
18	2	10	\N	\N	\N	\N
19	2	11	\N	\N	\N	\N
20	2	12	\N	\N	\N	\N
21	2	13	\N	\N	\N	\N
22	2	14	\N	\N	\N	\N
\.


--
-- Data for Name: daily_infos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_infos (id, daily_report_id, category, description) FROM stdin;
\.


--
-- Data for Name: daily_manpower; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_manpower (id, daily_report_id, role_code, role_name_vi, headcount, notes) FROM stdin;
1	1	\N	\N	0	\N
2	1	\N	\N	0	\N
3	1	\N	\N	0	\N
4	1	\N	\N	0	\N
5	1	\N	\N	0	\N
6	1	\N	\N	0	\N
7	1	\N	\N	0	\N
8	1	\N	\N	0	\N
9	1	\N	\N	0	\N
10	1	\N	\N	0	\N
11	1	\N	\N	0	\N
12	1	\N	\N	0	\N
13	1	\N	\N	0	\N
14	1	\N	\N	0	\N
15	1	\N	\N	0	\N
16	1	\N	\N	0	\N
17	2	\N	\N	0	\N
18	2	\N	\N	0	\N
19	2	\N	\N	0	\N
20	2	\N	\N	0	\N
21	2	\N	\N	0	\N
22	2	\N	\N	0	\N
23	2	\N	\N	0	\N
24	2	\N	\N	0	\N
25	2	\N	\N	0	\N
26	2	\N	\N	0	\N
27	2	\N	\N	0	\N
28	2	\N	\N	0	\N
29	2	\N	\N	0	\N
30	2	\N	\N	0	\N
31	2	\N	\N	0	\N
32	2	\N	\N	0	\N
\.


--
-- Data for Name: daily_materials; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_materials (id, daily_report_id, material_code, name_vi, unit, quantity, notes) FROM stdin;
1	1	\N	cáp chống sét	\N	\N	\N
2	2	\N	cáp chống sét	\N	\N	\N
\.


--
-- Data for Name: daily_recommendations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_recommendations (id, daily_report_id, ordinal, text) FROM stdin;
\.


--
-- Data for Name: daily_reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_reports (id, project_id, report_date, source_sheet_name, prepared_by, weather_am, weather_pm, work_items_count, manpower_count, materials_count, acceptance_count, status, created_at, submitted_at) FROM stdin;
1	2	2021-05-23	23.5.2021	Nguyễn Văn Định	\N	\N	0	0	0	0	DRAFT	2026-08-29 06:43:11	\N
2	2	2021-05-22	22.5.2021	\N	\N	\N	0	0	0	0	DRAFT	2026-08-29 06:43:11	\N
\.


--
-- Data for Name: daily_safety; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_safety (id, daily_report_id, category, description) FROM stdin;
\.


--
-- Data for Name: daily_safety_observations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_safety_observations (id, daily_report_id, category, description) FROM stdin;
\.


--
-- Data for Name: daily_work_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_work_items (id, daily_report_id, parent_id, ordinal, name_vi, system_vi, progress_pct, plan_start_date, plan_end_date, actual_start_date, actual_end_date, lag_days, notes) FROM stdin;
1	1	\N	2	Thư ký	\N	\N	\N	\N	\N	\N	\N	\N
2	1	\N	2	Thi công hệ thống kho bãi	\N	\N	\N	\N	\N	\N	\N	\N
3	1	2	1	San lấp mặt bằng và đường đi lại	\N	\N	\N	\N	\N	\N	\N	\N
4	1	2	2	Xây dựng kho bãi	\N	\N	\N	\N	\N	\N	\N	\N
5	1	\N	3	Tầng hầm C20	\N	\N	\N	\N	\N	\N	\N	\N
6	1	5	1	Lắp đặt sleeve cho hệ thống cấp thoát nước tầng hầm	\N	0	\N	\N	\N	\N	\N	\N
7	2	\N	2	Thư ký	\N	\N	\N	\N	\N	\N	\N	\N
8	2	\N	2	Thi công hệ thống kho bãi	\N	\N	\N	\N	\N	\N	\N	\N
9	2	8	1	San lấp mặt bằng và đường đi lại	\N	\N	\N	\N	\N	\N	\N	\N
10	2	8	2	Xây dựng kho bãi	\N	\N	\N	\N	\N	\N	\N	\N
11	2	\N	3	Tầng hầm C20	\N	\N	\N	\N	\N	\N	\N	\N
12	2	11	1	Lắp đặt sleeve cho hệ thống cấp thoát nước tầng hầm	\N	0	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: directives; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.directives (id, tenant_id, project_id, issue_id, from_user_id, from_user_name, body, notify_to_user_ids, created_at) FROM stdin;
1	1	1	1	1	Admin HBG (CEO)	Ưu tiên nhà cung cấp HVAC đã thẩm định. Họp lại thứ 6 tuần sau với vendor X để chốt timeline mới. PM BTE chuẩn bị slide tổng hợp.	[2,3]	2026-08-29 05:40:09
2	1	1	2	1	Admin HBG (CEO)	Vấn đề overdue 463 items BOH cần escalate. Đề xuất tách nhóm nhỏ (5 tổ đội), mỗi nhóm phụ trách 1 cluster zone. PM báo cáo mỗi 2 ngày.	[2]	2026-08-29 00:40:09
3	1	1	5	1	Admin HBG (CEO)	Material delay 5 ngày: chấp nhận được vì không ảnh hưởng critical path. Nhưng cần lock-in alternative supplier cho MEP zone BOH ngay trong tuần này.	[2,4]	2026-08-28 08:40:09
4	1	1	\N	1	Admin HBG (PMO)	Tuần này tập trung: 1) dọn shopdrawing backlog 2) chốt payment milestone 5 3) review quality issue BOH. CEO sẽ review dashboard thứ 4 hàng tuần.	[2,3,4]	2026-08-27 20:40:09
5	1	1	1	1	Admin HBG	Test directive from API	[]	2026-08-29 08:43:53
6	1	1	1	1	Admin HBG	Test directive từ UI	[]	2026-08-29 08:51:41
\.


--
-- Data for Name: file_uploads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.file_uploads (id, tenant_id, project_id, original_filename, storage_key, file_size, file_hash, mime_type, expected_doc_type, status, total_rows, ok_rows, error_rows, report_json, error_message, created_at) FROM stdin;
\.


--
-- Data for Name: generic_sheets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.generic_sheets (id, project_id, doc_type, source_sheet, zone_id, ordinal, col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10, created_at) FROM stdin;
3	1	other_approved	SHOP OTH	\N	2	\N	\N	\N	\N	BTE-WP4-HBC-MDS-MEP-PLB-002-REV 1	BIỆN PHÁP THI CÔNG CẤP THOÁT NƯỚC HẠ TẦNG	1	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Mon Mar 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	2026-08-29 06:43:06
4	1	other_approved	SHOP OTH	\N	1	\N	\N	\N	\N	BTE-WP4-HBC-OTH-MEP-005-REV00	QUY TRÌNH ITP	1	Mon Mar 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Mon Mar 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	2026-08-29 06:43:06
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices (id, contract_id, invoice_no, invoice_date, amount, vat_amount, status, created_at) FROM stdin;
\.


--
-- Data for Name: issues; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.issues (id, tenant_id, project_id, source_resource, source_id, title, body, category, severity, status, created_at, updated_at) FROM stdin;
1	1	1	construction_schedule_items	1	Construction chậm 6% so với plan	Zone BOH construction schedule đang ở 47% (planned 53%). 6% delta đã kéo dài 3 tuần.	PROGRESS	CRITICAL	OPEN	2026-08-29 06:39:53	2026-08-29 06:39:53
2	1	1	construction_schedule_items	50	Overdue 463 items (BOH)	463 items tại zone BOH đã quá plan_end_date mà chưa hoàn thành. Cần ưu tiên review với site team.	PROGRESS	CRITICAL	OPEN	2026-08-29 03:39:53	2026-08-29 03:39:53
3	1	1	shop_drawings	1	Shopdrawing HVAC chưa approved (15 drawings)	15 drawings HVAC zone BOH đã submit nhưng chưa được BQL review. Có thể ảnh hưởng construction MEP.	DESIGN	HIGH	IN_PROGRESS	2026-08-28 08:39:53	2026-08-28 08:39:53
4	1	1	shop_drawings	7	BQL yêu cầu revision drawing BTE-SHD-STR-FND-BOH-003	L1 response = R. Lý do: missing anchor bolt details cho zone BOH foundation.	DESIGN	HIGH	OPEN	2026-08-28 02:39:53	2026-08-28 02:39:53
5	1	1	materials	1	Material MEP zone BOH delivery delayed 5 ngày	MEP material (HVAC ducts, electrical conduits) bị delay do supplier logistics issue. ETA lùi 5 ngày.	MATERIAL	HIGH	ACK	2026-08-28 14:39:53	2026-08-28 14:39:53
6	1	1	materials	5	8 materials vượt thời gian lead time	Danh sách vật tư có 8 items đã vượt lead time dự kiến. Cần verify với procurement.	MATERIAL	MEDIUM	IN_PROGRESS	2026-08-27 08:39:53	2026-08-27 08:39:53
7	1	1	materials	12	3 materials critical ảnh hưởng trực tiếp BOH	Material Submittal cho BOH chưa duyệt: structural steel grade A36, fire damper, anchor bolts.	MATERIAL	CRITICAL	OPEN	2026-08-28 20:39:53	2026-08-28 20:39:53
8	1	1	payment_milestones	1	2 payment requests overdue (80 triệu)	2 payment milestones đã vượt due date 14 ngày, tổng giá trị 80 triệu VND. NCC chưa nhận được.	PAYMENT	HIGH	OPEN	2026-08-26 08:39:53	2026-08-26 08:39:53
9	1	1	payment_milestones	5	Payment milestone 5 thiếu quality docs	Milestone #5 value 45 triệu chưa có chứng từ chất lượng. Cần bổ sung từ QC team.	PAYMENT	MEDIUM	OPEN	2026-08-25 08:39:53	2026-08-25 08:39:53
10	1	1	\N	\N	Quality issue: bê tông thương phẩm zone RES-3BR	Sample bê tông ngày 18/5/2021 chưa đạt 28-day strength theo QC report. Đề xuất test lại.	QUALITY	HIGH	IN_PROGRESS	2026-08-27 20:39:53	2026-08-27 20:39:53
11	1	2	construction_schedule_items	600	LAWRENCE: 12 items overdue	12 construction items tại Lawrence Sting 2 quá plan_end_date. So với tổng 0 items (chưa ingest cho project 2).	PROGRESS	HIGH	OPEN	2026-08-29 04:39:53	2026-08-29 04:39:53
12	1	2	shop_drawings	105	LAWRENCE: 0 shop drawings	Project Lawrence chưa có shop drawing nào trong hệ thống. Cần đẩy từ team.	DESIGN	MEDIUM	OPEN	2026-08-29 02:39:53	2026-08-29 02:39:53
\.


--
-- Data for Name: kpi_targets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.kpi_targets (id, project_id, kpi_code, name_vi, target_value, actual_value, unit, period_start, period_end, version, effective_from, effective_to, approved_by, approved_at, period_lock, notes, created_at) FROM stdin;
\.


--
-- Data for Name: material_submittals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_submittals (id, project_id, material_id, submittal_code, status, sla_days, sla_deadline, revision_number, parent_submittal_id, rejection_reason, submitted_by, approved_by, submitted_date, approved_date, rejected_at, created_at) FROM stdin;
1	1	\N	TEST-MS-001	REJECTED	5	2026-09-03	0	\N	Test reject mục 43.4	1	\N	2026-08-29	\N	2026-08-29 09:17:04	2026-08-29 09:17:04
\.


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.materials (id, project_id, zone_id, source_sheet, material_code, name_vi, name_en, progress_pct, request_date_1, delivery_date_1, request_date_2, delivery_date_2, request_date_3, delivery_date_3, request_date_4, delivery_date_4, notes, created_at) FROM stdin;
1	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
2	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
3	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
4	1	1	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
5	1	1	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
6	1	1	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
7	1	1	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
8	1	1	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
9	1	1	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
10	1	1	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
11	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
12	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	0.5	2019-04-04	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
13	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
14	1	1	\N	AUTO-25	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
15	1	1	\N	AUTO-26	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
16	1	1	\N	AUTO-27	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
17	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
18	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
19	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
20	1	2	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
21	1	2	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
22	1	2	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
23	1	2	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
24	1	2	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
25	1	2	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
26	1	2	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
27	1	2	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
28	1	2	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
29	1	2	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
30	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	0.7	2019-04-04	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
31	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
32	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
33	1	2	\N	AUTO-25	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
34	1	2	\N	AUTO-26	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
35	1	2	\N	AUTO-27	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
36	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
37	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
38	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
39	1	5	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
40	1	5	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
41	1	5	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
42	1	5	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
43	1	5	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
44	1	5	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
45	1	5	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
46	1	5	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
47	1	5	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
48	1	5	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
49	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
50	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
51	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
52	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
53	1	5	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
54	1	5	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
55	1	5	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
56	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
57	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
58	1	5	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
59	1	6	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
60	1	6	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
61	1	6	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
62	1	6	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
63	1	6	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
64	1	6	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
65	1	6	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
66	1	6	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
67	1	6	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
68	1	6	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
69	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
70	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
71	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
72	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
73	1	6	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
74	1	6	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
75	1	6	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
76	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
77	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
78	1	6	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
79	1	7	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
80	1	7	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
81	1	7	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
82	1	7	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
83	1	7	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
84	1	7	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
85	1	7	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
86	1	7	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
87	1	7	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
88	1	7	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
89	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
90	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
91	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
92	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
93	1	7	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
94	1	7	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
95	1	7	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
96	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
97	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
98	1	7	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
99	1	8	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
100	1	8	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
101	1	8	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
102	1	8	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
103	1	8	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
104	1	8	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
105	1	8	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
106	1	8	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
107	1	8	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
108	1	8	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
109	1	8	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
110	1	8	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	0.7	2019-04-04	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
111	1	8	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
112	1	8	\N	AUTO-25	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
113	1	8	\N	AUTO-26	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
114	1	8	\N	AUTO-27	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
115	1	8	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
116	1	8	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
117	1	8	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
118	1	9	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
119	1	9	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
120	1	9	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
121	1	9	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
122	1	9	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
123	1	9	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
124	1	9	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
125	1	9	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
126	1	9	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
127	1	9	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
128	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
129	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
130	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
131	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
132	1	9	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
133	1	9	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
134	1	9	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
135	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
136	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
137	1	9	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
138	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
139	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
140	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
141	1	10	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
142	1	10	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
143	1	10	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
144	1	10	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
145	1	10	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
146	1	10	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
147	1	10	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
148	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
149	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
150	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
151	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
152	1	10	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
153	1	10	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
154	1	10	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
155	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
156	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
157	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
158	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	0.6	2019-03-26	\N	2019-03-26	\N	2019-03-26	\N	\N	\N	\N	2026-08-29 06:43:07
159	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
160	1	13	\N	AUTO-14	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
161	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
162	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
163	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
164	1	14	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
165	1	14	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
166	1	14	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
167	1	14	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
168	1	14	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
169	1	14	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
170	1	14	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
171	1	14	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
172	1	14	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
173	1	14	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
174	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
175	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
176	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
177	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
178	1	14	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
179	1	14	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
180	1	14	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
181	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
182	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
183	1	14	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
184	1	15	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
185	1	15	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
186	1	15	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
187	1	15	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
188	1	15	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
189	1	15	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
190	1	15	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
191	1	15	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
192	1	15	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
193	1	15	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
194	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
195	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
196	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
197	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
198	1	15	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
199	1	15	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
200	1	15	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
201	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
202	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
203	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
204	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
205	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
206	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
207	1	16	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
208	1	16	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
209	1	16	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
210	1	16	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
211	1	16	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
212	1	16	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
213	1	16	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
214	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRA-001	Ống thoát nước hdpe và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
215	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
216	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
217	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
218	1	16	\N	AUTO-26	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
219	1	16	\N	AUTO-27	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
220	1	16	\N	AUTO-28	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
221	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
222	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
223	1	16	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
224	1	19	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-001	Ống đồng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
225	1	19	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-002	Ống nước ngưng và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
226	1	19	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BPV-003	Bảo ôn ống đồng, nước ngưng, ống gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
227	1	19	\N	AUTO-15	Ống gió mạ kẽm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
228	1	19	\N	AUTO-16	Ống gió mềm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
229	1	19	\N	AUTO-17	Thiết bị điều hòa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
230	1	19	\N	AUTO-18	Thiết bị quạt gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
231	1	19	\N	AUTO-19	Van gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
232	1	19	\N	AUTO-20	Cửa gió	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
233	1	19	\N	AUTO-21	Hệ nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
234	1	19	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRA-001	Ống cấp nước ppr và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
235	1	19	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-1BRB-001	Ống thoát nước upvc và phụ kiện	\N	0.8	2019-04-04	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
236	1	19	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	Ống cấp nước và phụ kiện	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
237	1	19	\N	AUTO-25	Bảo ôn ống nước nóng và thoát nước	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
238	1	19	\N	AUTO-26	Van, vòi	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
239	1	19	\N	AUTO-27	Thiết bị vệ sinh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
240	1	19	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	Bơm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
241	1	19	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC\r\nWATER SUPPLY PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
242	1	19	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC\r\nDRAINAGE WATER SYSTEM PLAN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, tenant_id, user_id, project_id, issue_id, channel, delivery_status, sent_at, delivered_at, severity, title, body, resource_type, resource_id, read_at, created_at) FROM stdin;
1	1	\N	\N	\N	in_app	pending	\N	\N	critical	Construction chậm 6% so với plan	Click để xem chi tiết issue #ID1	issue	1	2026-08-29 08:53:50	2026-08-29 01:39:53
2	1	\N	\N	\N	in_app	pending	\N	\N	critical	Overdue 463 items (BOH)	Click để xem chi tiết issue #ID2	issue	2	2026-08-29 09:24:01	2026-08-28 17:39:53
3	1	\N	\N	\N	in_app	pending	\N	\N	warning	Shopdrawing HVAC chưa approved (15 drawings)	Click để xem chi tiết issue #ID3	issue	3	2026-08-29 09:24:06	2026-08-28 19:39:53
4	1	\N	\N	\N	in_app	pending	\N	\N	warning	BQL yêu cầu revision drawing BTE-SHD-STR-FND-BOH-003	Click để xem chi tiết issue #ID4	issue	4	\N	2026-08-28 20:39:53
5	1	\N	\N	\N	in_app	pending	\N	\N	warning	Material MEP zone BOH delivery delayed 5 ngày	Click để xem chi tiết issue #ID5	issue	5	\N	2026-08-29 03:39:53
6	1	\N	\N	\N	in_app	pending	\N	\N	info	8 materials vượt thời gian lead time	Click để xem chi tiết issue #ID6	issue	6	\N	2026-08-28 11:39:53
7	1	\N	\N	\N	in_app	pending	\N	\N	critical	3 materials critical ảnh hưởng trực tiếp BOH	Click để xem chi tiết issue #ID7	issue	7	\N	2026-08-28 15:39:53
8	1	\N	\N	\N	in_app	pending	\N	\N	warning	2 payment requests overdue (80 triệu)	Click để xem chi tiết issue #ID8	issue	8	\N	2026-08-28 15:39:53
9	1	\N	\N	\N	in_app	pending	\N	\N	info	Payment milestone 5 thiếu quality docs	Click để xem chi tiết issue #ID9	issue	9	\N	2026-08-28 09:39:53
10	1	\N	\N	\N	in_app	pending	\N	\N	warning	Quality issue: bê tông thương phẩm zone RES-3BR	Click để xem chi tiết issue #ID10	issue	10	\N	2026-08-28 13:39:53
11	1	\N	\N	\N	in_app	pending	\N	\N	warning	LAWRENCE: 12 items overdue	Click để xem chi tiết issue #ID11	issue	11	\N	2026-08-28 16:39:53
12	1	\N	\N	\N	in_app	pending	\N	\N	info	LAWRENCE: 0 shop drawings	Click để xem chi tiết issue #ID12	issue	12	\N	2026-08-28 14:39:53
13	1	\N	\N	\N	in_app	pending	\N	\N	info	Daily report submitted	Nguyễn Văn Định nộp báo cáo C20 ngày 23.5.2021	daily_report	\N	\N	2026-08-28 08:39:53
14	1	\N	\N	\N	in_app	pending	\N	\N	info	Shopdrawing approved	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-015 đã được BQL L2 approve	shop_drawing	1	\N	2026-08-27 08:39:53
15	1	\N	\N	\N	in_app	pending	\N	\N	warning	Material submittal overdue	MEP-PLB-001 chưa nộp sau 14 ngày từ khi tạo	material_submittal	1	2026-08-29 09:24:11	2026-08-29 00:39:53
16	1	\N	\N	\N	in_app	pending	\N	\N	warning	Chỉ thị mới từ Admin HBG	Test directive from API	directive	5	2026-08-29 09:34:42	2026-08-29 08:43:53
17	1	\N	\N	\N	in_app	pending	\N	\N	warning	Chỉ thị mới từ Admin HBG	Test directive từ UI	directive	6	2026-08-29 09:34:42	2026-08-29 08:51:41
18	1	1	\N	\N	in_app	pending	\N	\N	info	Test in_app	\N	\N	\N	2026-08-29 09:34:42	2026-08-29 09:17:04
19	1	1	\N	\N	in_app	pending	\N	\N	info	Test email	\N	\N	\N	2026-08-29 09:34:42	2026-08-29 09:17:04
20	1	1	\N	\N	in_app	pending	\N	\N	info	Test zalo	\N	\N	\N	2026-08-29 09:34:42	2026-08-29 09:17:04
\.


--
-- Data for Name: offline_sync_queue; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.offline_sync_queue (id, user_id, device_id, client_id, resource_type, resource_json, client_timestamp, client_created_at, conflict_resolution, server_record_id, superseded_at, status, error_message, synced_at, created_at) FROM stdin;
1	1	\N	cli-1	daily_report	{"date": "2026-08-29"}	2026-08-29 08:00:00	2026-08-29 08:00:00	SERVER_NEWER	1	\N	SYNCED	\N	\N	2026-08-29 09:17:04
2	1	\N	cli-2	daily_report	{"date": "2026-08-30"}	2026-08-30 10:00:00	2026-08-30 10:00:00	CLIENT_NEWER	1	\N	SYNCED	\N	\N	2026-08-29 09:17:04
\.


--
-- Data for Name: payment_milestones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_milestones (id, project_id, milestone_code, name_vi, amount, paid_amount, due_date, status, created_at) FROM stdin;
\.


--
-- Data for Name: payment_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_requests (id, invoice_id, request_no, request_date, amount, retention_amount, due_date, status, approved_by, approved_date, notes, created_at) FROM stdin;
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payments (id, project_id, payment_request_id, vendor_id, contract_no, invoice_no, amount, paid_amount, retention_amount, retention_held, vat_amount, vat_paid, due_date, paid_at, paid_method, status, notes, created_at) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.projects (id, tenant_id, code, name_vi, name_en, package, rev_prefix, start_date, end_date, status, created_at) FROM stdin;
1	1	BTE-WP4-HBC	Khu du lịch sinh thái Bãi Tràm	Bãi Tràm Estates	MEP	BTE-HBG	\N	\N	ACTIVE	2026-08-29 06:43:05
2	1	LAWRENCE-STING-2	Trường Lawrence Sting 2	LAWRENCE STING SCHOOL 2	MEP	HBG-LS	\N	\N	ACTIVE	2026-08-29 06:43:05
\.


--
-- Data for Name: resources; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.resources (id, tenant_id, code, name, type, status, created_at) FROM stdin;
\.


--
-- Data for Name: rfa_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rfa_log (id, project_id, source_sheet, ordinal, rfa_code, description_vi, discipline, area, submitted_date, reviewer, reviewer_status, reviewer_comment, response_date, final_status, notes, created_at) FROM stdin;
1	1	RFA-Submission_Delivery	1	BTE-WP4-HBC-MAA-MEP-PLB--001\r\nHệ thống cấp  nước / Water supply  system	\N	Tue Mar 12 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Mar 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Fri Apr 19 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Sat Apr 27 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
2	1	RFA-Submission_Delivery	2	BTE-WP4-HBC-MAA-MEP-PLB--002\r\nHệ thống thoát nước / Water drainage system	\N	Tue Mar 12 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Mar 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Fri Mar 22 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Mon Mar 25 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
3	1	RFA-Submission_Delivery	3	BTE-WP4-HBC-MAA-MEP-PLB--003\r\nHệ thống cấp thoát nước / Water supply and drainage system	HB01-BTE/2019/HĐNT HB-TĐ	Tue Mar 12 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Mar 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Mon Mar 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Fri Mar 22 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
4	1	RFA-Submission_Delivery	4	BTE-WP4-HBC-MAA-MEP-PLB--004\r\nHệ thống cấp thoát nước / Hệ thống cấp thoát nước / Water supply and drainage system	\N	Tue Apr 02 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	2019-04-22	\N	\N	2026-08-29 06:43:06
5	1	RFA-Submission_Delivery	5	BTE-WP4-HBC-MAA-MEP-PLB--005\r\nHệ thống cấp thoát nước / Water supply and drainage system	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Tue Apr 09 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Tue Apr 16 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	R	2019-04-22	\N	\N	2026-08-29 06:43:06
6	1	RFA-Submission_Delivery	6	BTE-WP4-HBC-MAA-MEP-PLB-011\r\nHệ thống cấp thoát nước / Water supply and drainage system	\N	Wed Apr 03 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Mon Apr 08 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 11 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	R	\N	\N	\N	2026-08-29 06:43:06
7	1	RFA-Submission_Delivery	7	BTE-WP4-HBC-MAA-MEP-PLB-015\r\nBảo ôn cấp thoát nước./ Insulation water supply & draigane system	\N	Sun Apr 07 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Apr 10 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Thu Apr 11 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Sun Apr 14 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
8	1	RFA-Submission_Delivery	8	BTE-WP4-HBC-MAA-MEP-PLB-017\r\nHệ thống cấp thoát nước / Water supply and drainage system	\N	Thu Apr 11 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Tue Apr 16 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Mon Apr 22 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	2026-08-29 06:43:06
9	1	RFA-Submission_Delivery	9	BTE-WP4-HBC-MAA-MEP-PLB-009\r\nBình nước nóng /Hot water bottle	\N	Wed Apr 03 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Thu Apr 11 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Sun Apr 14 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
10	1	RFA-Submission_Delivery	10	BTE-WP4-HBC-MAA-MEP-PLB-010\r\nThoát sàn /Floor drain	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
11	1	RFA-Submission_Delivery	11	BTE-WP4-HBC-MAA-MEP-PLB-009\r\nBăng cảnh báo	\N	Tue Apr 02 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Tue Apr 09 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
12	1	RFA-Submission_Delivery	12	BTE-WP4-HBC-MAA-MEP-PLB-018\r\nBình Tích áp	\N	Tue Apr 16 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
13	1	RFA-Submission_Delivery	13	BTE-WP4-HBC-MAA-MEP-PLB-016\r\nCầu thu nước mái, Thông tắc sàn/ Roof drain,Floor Clean out	\N	Thu Apr 11 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Mon Apr 22 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
14	1	RFA-Submission_Delivery	14	BTE-WP4-HBC-MAA-MEP-PLB-013\r\nHệ thống xử lý nước cấp/ Water treatment plant	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
15	1	RFA-Submission_Delivery	1	BTE-WP4-HBC-MAA-MEP-HVAC-002/\r\nỐng dẫn môi chất lạnh	\N	Sat Mar 16 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Mon Mar 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Mon Apr 01 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
16	1	RFA-Submission_Delivery	2	BTE-WP4-HBC-MAA-MEP-HVAC-005\r\nBảo ôn ống Gas, ống nước ngưng, ống gió	\N	Mon Mar 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Mar 20 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Tue Apr 02 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	A	\N	\N	\N	2026-08-29 06:43:06
17	1	RFA-Submission_Delivery	3	BTE-WP4-HBC-MAA-MEP-HVAC-007\r\nPiping and fitting/ Đường ống và phụ kiện	\N	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
18	1	RFA-Submission_Delivery	4	BTE-WP4-HBC-MAA-MEP-HVAC-004\r\nPiping and fitting/ Đường ống và phụ kiện	\N	Mon Apr 01 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Tue Apr 02 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Sat Apr 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Tue Apr 09 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	B	\N	\N	\N	2026-08-29 06:43:06
19	1	RFA-Submission_Delivery	5	BTE-WP4-HBC-MAA-MEP-HVAC-008\r\nPiping and fitting/ Đường ống và phụ kiện	\N	Tue Apr 09 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Apr 10 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	Thu Apr 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Fri Apr 19 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	R	2019-04-27	\N	\N	2026-08-29 06:43:06
20	1	RFA-Submission_Delivery	4	BTE-WP4-HBC-MAA-MEP-HVAC-007\r\nQuạt/ Fan	\N	Thu Apr 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
21	1	RFA-Submission_Delivery	5	BTE-WP4-HBC-MAA-MEP-HVAC-008\r\nBộ chia gas	\N	Tue Apr 16 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 18 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
22	1	RFA-Submission_Delivery	6	BTE-WP4-HBC-MAA-MEP-HVAC-009  Dây cáp điều khiển	\N	Sat Apr 27 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
23	1	RFA-Submission_Delivery	7	BTE-WP4-HBC-MAA-MEP-HVAC-0010 Van gió cửa gió	Wed Mar 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Wed Mar 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Sat Apr 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
24	1	RFA-Submission_Delivery	8	BTE-WP4-HBC-MAA-MEP-HVAC-0011 Ống luồn dây	Sat Apr 13 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Mon Apr 22 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Tue Apr 23 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
25	1	RFA-Submission_Delivery	9	BTE-WP4-HBC-MAA-MEP-HVAC-0012 Tiêu âm	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
26	1	RFA-Submission_Delivery	1	BTE-WP4-HBC-MAA-MEP-WT-001	Wed Apr 03 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	Thu Apr 04 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	R	2019-04-08	\N	\N	Grunfos, Wilo, Salmson, Ebara	\N	\N	\N	2026-08-29 06:43:06
27	1	RFA-Submission_Delivery	2	BTE-WP4-HBC-MAA-MEP-WT-002	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
28	1	RFA-Submission_Delivery	3	BTE-WP4-HBC-MAA-MEP-WT-003	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
29	1	RFA-Submission_Delivery	4	BTE-WP4-HBC-MAA-MEP-WT-004	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
30	1	RFA-Submission_Delivery	1	Bê tông thương phẩm	19416/MRMC	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
31	1	RFA-Submission_Delivery	2	Thép hố ga	HB10-BTE/2019/HĐNT HB-VPD, HB05-BTE/HĐKT HB-HP	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
32	1	RFA-Submission_Delivery	3	Xi măng	B10-BTE/2019/HĐNT HB-VPD	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:06
\.


--
-- Data for Name: schedule_baselines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schedule_baselines (id, project_id, version, effective_date, created_by, notes, created_at) FROM stdin;
1	1	1	2026-09-01	1	Initial baseline	2026-08-29 09:17:04
2	1	2	2026-10-01	1	Update after re-plan	2026-08-29 09:17:04
\.


--
-- Data for Name: shop_drawings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shop_drawings (id, project_id, zone_id, source_sheet, drawing_code, name_vi, name_en, progress_pct, status, planned_submit_date, actual_submit_date, bql_l1_response, bql_l1_date, bql_l1_comment, bql_l2_response, bql_l2_date, bql_l2_comment, bql_l3_response, bql_l3_date, bql_l3_comment, bql_l4_response, bql_l4_date, bql_l4_comment, bql_l5_response, bql_l5_date, bql_l5_comment, rs1_planned_date, rs1_actual_date, rs2_planned_date, rs2_actual_date, approval_date, rejected_reason, rejected_by, rejected_at, reverted_to_draft_at, reverted_to_draft_by, created_at) FROM stdin;
1	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-015	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
2	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-016	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
3	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-017	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
4	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-018	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
5	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-019	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
6	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-020	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
7	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-021	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
8	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-022	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
9	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-023	MẶT BẰNG HỆ THỐNG ĐHKK & THÔNG GIÓ - CAO ĐỘ F\r\nAIR CONDITIONING AND VENTILATION SYSTEM PLAN - LEVEL F	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
10	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-024	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
11	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-025	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
12	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-026	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
13	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-027	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
14	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-028	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
15	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-029	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
16	1	1	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-030	\N	\N	\N	DRAFT	2019-03-26	2019-03-29	R	2019-04-22	\N	\N	\N	\N	\N	\N	Mon May 06 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
17	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-001	SƠ ĐỒ NGUYÊN LÝ HỆ THỐNG CẤP NƯỚC, THOÁT NƯỚC THẢI\r\nWATER SUPPLY AND DRAINAGE WATER SYSTEM - SINGLE LINE DIAGRAM	\N	1	DRAFT	2019-03-26	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
18	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BOH-001	MẶT BẰNG HỆ THỐNG CẤP NƯỚC - CAO ĐỘ A, C\r\nWATER SUPPLY SYSTEM PLAN - LEVEL A, C	\N	1	DRAFT	2019-03-26	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
19	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BOH-002	MẶT BẰNG HỆ THỐNG CẤP NƯỚC - CAO ĐỘ E, F\r\nWATER SUPPLY SYSTEM PLAN - LEVEL E, F	\N	\N	DRAFT	2019-04-15	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
20	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BOH-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC THẢI - CAO ĐỘ C\r\nWASTE WATER DRAINAGE SYSTEM PLAN - LEVEL C	\N	1	DRAFT	2019-03-26	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
21	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BOH-002	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC THẢI - CAO ĐỘ E, F\r\nWASTE WATER DRAINAGE SYSTEM PLAN - LEVEL E, F	\N	\N	DRAFT	2019-04-15	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
23	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BOH-003	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC MƯA - CAO ĐÔ E\r\nRAIN WATER DRAINAGE SYSTEM PLAN - LEVEL E	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
24	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BOH-004	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC MƯA - CAO ĐÔ F, MÁI\r\nRAIN WATER DRAINAGE SYSTEM PLAN - LEVEL F, ROOF	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
25	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-002	CHI TIẾT CẤP THOÁT NƯỚC VỆ SINH - CAO ĐỘ +20.10M & +23.30MM\r\nSANITARY SEWER DETAILS - LEVEL +20.10M & +23.30MM	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
26	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-003	CHI TIẾT CẤP THOÁT NƯỚC VỆ SINH - CAO ĐỘ +20.10M & +23.30MM\r\nSANITARY SEWER DETAILS - LEVEL +20.10M & +23.30MM	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
27	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-004	CHI TIẾT THOÁT NƯỚC VỆ SINH BẾP\r\n SANITARY SEWER DETAILS	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
28	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-005	CHI TIẾT CẤP NƯỚC PHÒNG GIẶT\r\nPLUMBING & SANITARY DETAILS OF LAUNDRY ROOM	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
29	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-006	CHI TIẾT THOÁT NƯỚC PHÒNG GIẶT\r\nPLUMBING & SANITARY DETAILS OF LAUNDRY ROOM	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
30	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-007	CHI TIẾT BỂ NƯỚC SINH HOẠT + PCCC (1)\r\nDETAIL OF DOMESTIC WATER TANK,FIRE TANK (1)	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
31	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-008	CHI TIẾT BỂ NƯỚC SINH HOẠT + PCCC (2)\r\nDETAIL OF DOMESTIC WATER TANK,FIRE TANK (2)	\N	\N	DRAFT	2019-04-12	\N	\N	\N	\N	\N	\N	\N	\N	\N	Tue Apr 30 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
32	1	1	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BOH-009	CHI TIẾT BỂ TỰ HOẠI, BỂ TÁCH DẦU, STP\r\nDETAIL OF SEPTIC TANK, GREASE TRAP, STP	\N	1	DRAFT	2019-03-26	2019-03-27	R	2019-03-27	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
33	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-1BRB-001	MẶT BẰNG THOÁT NƯỚC BEACH POOL VILLA - 1BRB\r\n- SƠ ĐỒ NGUYÊN LÝ BEACH POOL VILLA - 1BRB\r\nDRAINAGE WATER SYSTEM PLAN BEACH POOL VILLA - 1BRB\r\n - SCHEMATIC DIAGRAM BEACH POOL VILLA - 1BRB	\N	\N	DRAFT	2019-03-25	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
34	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV-2BR-001	HỆ THỐNG CẤP THOÁT NƯỚC BEACH POOL VILLA - 2BR \r\n- SƠ ĐỒ NGUYÊN LÝ BEACH POOL VILLA - 2BR\r\nPLUMBING AND SANITARY SYSTEM BEACH POOL VILLA - 2BR\r\n - SCHEMATIC DIAGRAM BEACH POOL VILLA - 2BR	\N	\N	DRAFT	2019-03-25	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
35	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-BPV-2BR-001	MẶT BẰNG CẤP NƯỚC BEACH POOL VILLA - 2BR\r\nWATER SUPPLY PLAN BEACH POOL VILLA - 2BR	\N	\N	DRAFT	2019-03-25	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
36	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-BPV-2BR-001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC BEACH POOL VILLA - 2BR\r\nDRAINAGE WATER SYSTEM PLAN BEACH POOL VILLA - 2BR	\N	\N	DRAFT	2019-03-25	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
37	1	2	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-BPV - 001	CHI TIẾT LẮP ĐẶT ĐIỂN HÌNH\r\nTYPICAL INSTALL DETAIL	\N	\N	DRAFT	2019-03-25	2019-03-25	R	2019-03-26	A	\N	\N	\N	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Mar 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
38	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0013	HỆ THỐNG ĐHKK & THÔNG GIÓ - DANH MỤC THIẾT BỊ\r\nAIR CONDITIONING AND VENTILATION SYSTEM - EQUIPMENT SCHEDULES	\N	\N	DRAFT	2019-04-14	2019-04-16	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
39	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0014	HỆ THỐNG ĐHKK & THÔNG GIÓ - SƠ ĐỒ NGUYÊN LÝ \r\nAIR CONDITIONING AND VENTILATION SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-14	2019-04-16	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
40	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0015	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nAIR CONDITIONING AND VENTILATION SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
41	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0016	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT CẮT 1-1\r\nAIR CONDITIONING AND VENTILATION SYSTEM - SECTION 1-1	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
42	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0017	HỆ THỐNG ĐHKK & THÔNG GIÓ - DANH MỤC THIẾT BỊ\r\nAIR CONDITIONING AND VENTILATION SYSTEM - EQUIPMENT SCHEDULES	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
43	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0018	HỆ THỐNG ĐHKK & THÔNG GIÓ - SƠ ĐỒ NGUYÊN LÝ \r\nAIR CONDITIONING AND VENTILATION SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
44	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0019	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nAIR CONDITIONING AND VENTILATION SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
45	1	10	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-HPV-0020	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT CẮT 1-1\r\nAIR CONDITIONING AND VENTILATION SYSTEM - SECTION 1-1	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
46	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-HPV - 1BR -001	HỆ THỐNG CẤP THOÁT NƯỚC - SƠ ĐỒ NGUYÊN LÝ\r\nPLUMBING AND SANITARY SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
47	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-HPV - 1BR -001	MẶT BẰNG HỆ THỐNG CẤP NƯỚC\r\nWATER SUPPLY SYSTEM PLAN	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
48	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-HPV - 1BR -001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC (01)\r\nDRAINAGE WATER SYSTEM PLAN (01)	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
49	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-HPV - 1BR -002	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC (02)\r\nDRAINAGE WATER SYSTEM PLAN (02)	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
50	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-HPV - 2BR -001	MẶT BẰNG HỆ THỐNG CẤP NƯỚC  - SƠ ĐỒ NGUYÊN LÝ \r\nWATER SUPPLY SYSTEM PLAN - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
51	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-HPV - 2BR -001	MẶT BẰNG HỆ THỐNG THOÁT NƯỚC - SƠ ĐỒ NGUYÊN LÝ\r\nDRAINAGE WATER SYSTEM PLAN - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
52	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-HPV - 3BR -001	HỆ THỐNG CẤP THOÁT NƯỚC - SƠ ĐỒ NGUYÊN LÝ\r\nPLUMBING AND SANITARY SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
53	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-HPV - 3BR -001	HỆ THỐNG CẤP NƯỚC - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nWATER SUPPLY SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
54	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-HPV - 3BR -001	HỆ THỐNG THOÁT NƯỚC - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nDRAINAGE WATER SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-05	2019-04-10	R	2019-04-11	\N	\N	\N	\N	\N	\N	Mon Apr 29 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
55	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-HPV - 4BR -001	HỆ THỐNG CẤP THOÁT NƯỚC - SƠ ĐỒ NGUYÊN LÝ\r\nPLUMBING AND SANITARY SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-05	\N	\N	\N	\N	\N	\N	\N	\N	\N	Fri May 03 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
56	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-HPV - 4BR -001	HỆ THỐNG CẤP NƯỚC - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nWATER SUPPLY SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-05	\N	\N	\N	\N	\N	\N	\N	\N	\N	Fri May 03 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
57	1	10	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-HPV - 4BR -001	HỆ THỐNG THOÁT NƯỚC - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nDRAINAGE WATER SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-05	\N	\N	\N	\N	\N	\N	\N	\N	\N	Fri May 03 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
61	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3016	ĐƯỜNG D8 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC\r\nROAD D8 - WATER SUPPLY PLAN AND PROFILE	\N	\N	DRAFT	2019-03-15	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
62	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-0001	GHI CHÚ CHUNG, CHÚ THÍCH, KÝ HIỆU & DANH SÁCH BẢN VẼ \r\nGENERAL NOTES, LEGENDS, SYMBOLS & DRAWING LIST	\N	\N	DRAFT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
63	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-2001	SƠ ĐỒ NGUYÊN LÝ HỆ THỐNG CẤP NƯỚC\r\nWATER SUPPLY SYSTEM SCHEMATIC DIAGRAM	\N	\N	DRAFT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
64	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PED-INF-2001	SƠ ĐỒ NGUYÊN LÝ HỆ THỐNG THOÁT NƯỚC\r\nWATER SUPPLY SYSTEM SCHEMATIC DIAGRAM	\N	\N	DRAFT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
65	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3001	MẶT BẰNG BỐ TRÍ HỆ THỐNG CẤP NƯỚC\r\nWATER SUPPLY SYSTEM LAYOUT PLAN	\N	\N	DRAFT	2019-04-04	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
66	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3002	ĐƯỜNG D1 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 1\r\nROAD D1 - WATER SUPPLY PLAN AND PROFILE - SHEET 1	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
67	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3003	ĐƯỜNG D1 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 2\r\nROAD D1 - WATER SUPPLY PLAN AND PROFILE - SHEET 2	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
68	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3004	ĐƯỜNG D1 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 3\r\nROAD D1 - WATER SUPPLY PLAN AND PROFILE - SHEET 3	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
69	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3005	ĐƯỜNG D1 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 4\r\nROAD D1 - WATER SUPPLY PLAN AND PROFILE - SHEET 4	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
70	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3006	ĐƯỜNG D1 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 5\r\nROAD D1 - WATER SUPPLY PLAN AND PROFILE - SHEET 5	\N	\N	DRAFT	2019-04-10	2019-04-10	\N	2019-04-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
71	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3007	ĐƯỜNG D2, D3 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC\r\nROAD D2, D3 - WATER SUPPLY PLAN AND PROFILE	\N	\N	DRAFT	2019-04-10	2019-04-10	\N	2019-04-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
72	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3008	ĐƯỜNG D4 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 1\r\nROAD D4 - WATER SUPPLY PLAN AND PROFILE - SHEET 1	\N	\N	DRAFT	2019-03-20	2019-03-20	\N	2019-04-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
73	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3009	ĐƯỜNG D4 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 2\r\nROAD D4 - WATER SUPPLY PLAN AND PROFILE - SHEET 2	\N	\N	DRAFT	2019-03-20	2019-03-20	\N	2019-04-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
74	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3010	ĐƯỜNG D5 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 1\r\nROAD D5 - WATER SUPPLY PLAN AND PROFILE - TỜ 1	\N	\N	DRAFT	2019-03-20	2019-03-20	\N	2019-04-10	\N	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
75	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3011	ĐƯỜNG D5 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 2\r\nROAD D5 - WATER SUPPLY PLAN AND PROFILE - SHEET 2	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
76	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3012	ĐƯỜNG D5 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 3\r\nROAD D5 - WATER SUPPLY PLAN AND PROFILE - SHEET 3	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
77	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3013	ĐƯỜNG D6 - MẶT BẰNG VÀ TRẮC DỌC HỆ THỐNG CẤP NƯỚC\r\nROAD D6 - WATER SUPPLY PLAN AND PROFILE	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
78	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3014	ĐƯỜNG D7 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 1\r\nROAD D7 - WATER SUPPLY PLAN AND PROFILE - SHEET 1	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	Fri Apr 05 2019 00:00:00 GMT+0000 (Coordinated Universal Time)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
79	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-INF-3015	ĐƯỜNG D7 - MẶT BẰNG VÀ TRẮC DỌC CẤP NƯỚC - TỜ 2\r\nROAD D7 - WATER SUPPLY PLAN AND PROFILE - SHEET 2	\N	\N	DRAFT	2019-04-10	2019-04-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
80	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-4001	MẶT BẰNG PHỐI HỢP CẤP THOÁT NƯỚC\r\nPLUMBING COMBINATION PLAN	\N	\N	DRAFT	2019-04-10	2019-04-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
81	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-4002	ĐƯỜNG D1 - MẶT CẮT NGANG TUYẾN ỐNG CẤP, THOÁT NƯỚC ĐIỂN HÌNH\r\nROAD D1 - TYPICAL SECTION OF WATER SUPPLY, SEWER DRAINAGE ROUTE	\N	1	DRAFT	2019-03-26	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
82	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-4003	ĐƯỜNG D2, D3, D4, D5, D6, D8 - MẶT CẮT NGANG TUYẾN ỐNG CẤP, THOÁT NƯỚC ĐIỂN HÌNH\r\nROAD D2, D3, D4, D5, D6, D8 - TYPICAL SECTION OF WATER SUPPLY, SEWER DRAINAGE ROUTE	\N	1	DRAFT	2019-03-29	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
83	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-4004	ĐƯỜNG D7 - MẶT CẮT NGANG TUYẾN ỐNG CẤP, THOÁT NƯỚC ĐIỂN HÌNH\r\nROAD D7 - TYPICAL SECTION OF WATER SUPPLY, SEWER DRAINAGE ROUTE	\N	1	DRAFT	2019-03-29	2019-03-18	R	2019-03-19	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
84	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-5001	CHI TIẾT ĐIỂN HÌNH HỆ THỐNG CẤP THOÁT NƯỚC\r\nTYPICAL DETAILS PLUMBING SYSTEM	\N	\N	DRAFT	2019-03-10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
85	1	13	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-INF-5002	CHI TIẾT ĐIỂN HÌNH  HỐ GA DETAIL PARTICULAR MANHOLE	\N	1	DRAFT	2019-03-10	2019-03-18	A	2019-03-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
86	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-LOB -003	MẶT BẰNG CẤP NƯỚC TẦNG TRỆT (2)\r\nWATER SUPPLY PLAN - GROUND FLOOR (2)	\N	\N	DRAFT	2019-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
87	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PWS-LOB -004	MẶT BẰNG CẤP NƯỚC TẦNG TRỆT MÁI\r\nWATER SUPPLY PLAN - ROOF FLOOR	\N	\N	DRAFT	2019-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
88	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -001	MẶT BẰNG THOÁT NƯỚC THẢI TẦNG HẦM\r\nWASTE WATER DRAINAGE PLAN - BASEMENT FLOOR	\N	\N	DRAFT	2019-04-19	2019-04-06	R	2019-04-26	\N	\N	\N	\N	\N	\N	26-04-2019	\N	\N	26-04-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
89	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -002	MẶT BẰNG THOÁT NƯỚC THẢI TẦNG TRỆT \r\nWASTE WATER DRAINAGE PLAN - GROUND FLOOR	\N	\N	DRAFT	2019-04-19	2019-04-19	R	2019-04-26	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
90	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -003	MẶT BẰNG THOÁT NƯỚC THẢI TẦNG MÁI\r\nWASTE WATER DRAINAGE PLAN - ROOF FLOOR	\N	\N	DRAFT	2019-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
91	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -004	MẶT BẰNG THOÁT NƯỚC MƯA TẦNG HẦM (1)\r\nRAIN WATER DRAINAGE PLAN - BASEMENT FLOOR (1)	\N	\N	DRAFT	2019-04-19	2019-04-26	\N	\N	\N	\N	\N	\N	\N	\N	26-04-2019	\N	\N	26-04-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
92	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -005	MẶT BẰNG THOÁT NƯỚC MƯA TẦNG HẦM (2)\r\nRAIN WATER DRAINAGE PLAN - BASEMENT FLOOR (2)	\N	\N	DRAFT	2019-04-19	2019-04-26	\N	\N	\N	\N	\N	\N	\N	\N	26-04-2019	\N	\N	26-04-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
93	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -006	MẶT BẰNG THOÁT NƯỚC MƯA TẦNG TRỆT (1)\r\nRAIN WATER DRAINAGE PLAN - GROUND FLOOR(1)	\N	\N	DRAFT	2019-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
94	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -007	MẶT BẰNG THOÁT NƯỚC MƯA TẦNG TRỆT (2)\r\nRAIN WATER DRAINAGE PLAN - GROUND FLOOR(2)	\N	\N	DRAFT	2019-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
95	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PID-LOB -008	MẶT BẰNG THOÁT NƯỚC MƯA TẦNG MÁI\r\nRAIN WATER DRAINAGE PLAN - ROO FLOOR	\N	\N	DRAFT	2019-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
97	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-LOB -003	CHI TIẾT CẤP NƯỚC KHU VỆ SINH\r\nWATER SUPPLY DETAIL FOR WC	\N	\N	DRAFT	2019-04-19	2019-04-19	R	2019-04-26	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
98	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-LOB -004	CHI TIẾT THOÁT NƯỚC KHU VỆ SINH\r\nWASTE WATER DRAINAGE DETAIL FOR WC	\N	\N	DRAFT	2019-04-19	2019-04-19	R	2019-04-26	\N	\N	\N	\N	\N	\N	05-05-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
99	1	15	\N	BTE-WP4-HBC-SHD- MEP-PLB-PL-LOB -005	CHI TIẾT BỆ TỰ HOẠI, BỂ TÁCH MỠ, HỐ BƠM\r\nDETAIL OF SEPTIC TANK, OIL INTERCEPTOR TANK AND PUMP PIT	\N	\N	DRAFT	2019-04-19	2019-04-06	R	2019-04-26	\N	\N	\N	\N	\N	\N	26-04-2019	\N	\N	26-04-2019	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
100	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-013	HỆ THỐNG ĐHKK & THÔNG GIÓ - DANH MỤC THIẾT BỊ\r\nAIR CONDITIONING AND VENTILATION SYSTEM - EQUIPMENT SCHEDULES	\N	\N	DRAFT	2019-04-14	2019-04-16	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
101	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-014	HỆ THỐNG ĐHKK & THÔNG GIÓ - SƠ ĐỒ NGUYÊN LÝ \r\nAIR CONDITIONING AND VENTILATION SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-14	2019-04-16	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
102	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-015	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nAIR CONDITIONING AND VENTILATION SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
103	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-016	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT CẮT 1-1\r\nAIR CONDITIONING AND VENTILATION SYSTEM - SECTION 1-1	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
104	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-017	HỆ THỐNG ĐHKK & THÔNG GIÓ - DANH MỤC THIẾT BỊ\r\nAIR CONDITIONING AND VENTILATION SYSTEM - EQUIPMENT SCHEDULES	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
105	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-018	HỆ THỐNG ĐHKK & THÔNG GIÓ - SƠ ĐỒ NGUYÊN LÝ \r\nAIR CONDITIONING AND VENTILATION SYSTEM - SCHEMATIC DIAGRAM	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
106	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-019	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT BẰNG TẦNG HẦM & TẦNG TRỆT\r\nAIR CONDITIONING AND VENTILATION SYSTEM - BASEMENT & GROUND FLOOR PLAN	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
107	1	16	\N	BTE-WP4-HBC-SHD-MEP-HVAC-HVA-RSD-020	HỆ THỐNG ĐHKK & THÔNG GIÓ - MẶT CẮT 1-1\r\nAIR CONDITIONING AND VENTILATION SYSTEM - SECTION 1-1	\N	\N	DRAFT	2019-04-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-08-29 06:43:07
\.


--
-- Data for Name: subcontractors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.subcontractors (id, tenant_id, name, capability_summary, status, is_internal_team, source_sheet, created_at) FROM stdin;
1	1	NỘI DUNG CÔNG VIỆC	ĐƠN VỊ TỔ ĐỘI	ACTIVE	f	\N	2026-08-29 06:43:06
2	1	CẤP THOÁT NƯỚC TRONG NHÀ	\N	ACTIVE	f	\N	2026-08-29 06:43:06
4	1	Hệ thống cấp nước lạnh	\N	ACTIVE	f	\N	2026-08-29 06:43:06
5	1	Hệ thống cấp nước nóng	\N	ACTIVE	f	\N	2026-08-29 06:43:06
6	1	Hệ thống nước mưa	\N	ACTIVE	f	\N	2026-08-29 06:43:06
7	1	Hệ thống nước thải	\N	ACTIVE	f	\N	2026-08-29 06:43:06
8	1	Thiết bị ( van, vệ sinh)	\N	ACTIVE	f	\N	2026-08-29 06:43:06
9	1	CẤP THOÁT NƯỚC HẠ TẦNG	\N	ACTIVE	f	\N	2026-08-29 06:43:06
10	1	HỆ THỐNG CẤP THOÁT NƯỚC	A.Quỳnh	ACTIVE	f	\N	2026-08-29 06:43:06
11	1	Hệ thống cấp nước	\N	ACTIVE	f	\N	2026-08-29 06:43:06
12	1	Hệ thống thoát nước	\N	ACTIVE	f	\N	2026-08-29 06:43:06
13	1	Thi công hố ga	\N	ACTIVE	f	\N	2026-08-29 06:43:06
14	1	Lắp đặt van	\N	ACTIVE	f	\N	2026-08-29 06:43:06
15	1	Hệ thống xử lý nước thải	\N	ACTIVE	f	\N	2026-08-29 06:43:06
16	1	Hệ thống xử lý nước cấp	\N	ACTIVE	f	\N	2026-08-29 06:43:06
17	1	Hệ thống nước đóng chai công suất 1000l/h	\N	ACTIVE	f	\N	2026-08-29 06:43:06
18	1	Lắp đặt hố ga	A. Tuấn Anh	ACTIVE	f	\N	2026-08-29 06:43:06
19	1	NGƯỜI LẬP	\N	ACTIVE	f	\N	2026-08-29 06:43:06
20	1	Họ và tên	Số điện thoại	ACTIVE	f	\N	2026-08-29 06:43:06
21	1	Tổ đội/ Thầu phụ	\N	ACTIVE	f	\N	2026-08-29 06:43:06
22	1	A. Vương	0965.100.081	ACTIVE	f	\N	2026-08-29 06:43:06
23	1	A. Sinh	0836.909.500	ACTIVE	f	\N	2026-08-29 06:43:06
24	1	A. Hóa ( CT V.Teco)	0913.979.762	ACTIVE	f	\N	2026-08-29 06:43:06
25	1	A. Thịnh	0974.582.659	ACTIVE	f	\N	2026-08-29 06:43:06
26	1	A. Lùng	0987.484.677	ACTIVE	f	\N	2026-08-29 06:43:06
27	1	A. Hòa ( CT Tín Nghĩa)	0965.331.777	ACTIVE	f	\N	2026-08-29 06:43:06
28	1	Công ty Công ty TNHH giải pháp môi trường (Ensol )	0906.977.281	ACTIVE	f	\N	2026-08-29 06:43:06
29	1	Công ty Vinaceeco VietNam	0988.387.885	ACTIVE	f	\N	2026-08-29 06:43:06
30	1	Công ty TNHH nước và môi trường VN	0988.476.435	ACTIVE	f	\N	2026-08-29 06:43:06
31	1	Công ty Stronger	0902.448.997	ACTIVE	f	\N	2026-08-29 06:43:06
32	1	ENVIRONMENTAL ADTECH COMPANY LIMITED	0903.285.869	ACTIVE	f	\N	2026-08-29 06:43:06
33	1	A. Tịnh	0903.354.399	ACTIVE	f	\N	2026-08-29 06:43:06
34	1	A. Vĩnh	077(5)562.379	ACTIVE	f	\N	2026-08-29 06:43:06
35	1	A. Quỳnh	0989.800.806	ACTIVE	f	\N	2026-08-29 06:43:06
36	1	A. Dũng	0985.302.779	ACTIVE	f	\N	2026-08-29 06:43:06
37	1	Thầu phụ/ Tổ đội	Hệ thống	ACTIVE	f	\N	2026-08-29 06:43:11
38	1	Công ty cơ điện Nguyễn Hiền	Hệ thống điều hòa thông gió\r\nHệ thống chữa cháy	ACTIVE	f	\N	2026-08-29 06:43:11
39	1	Công ty tín nghĩa	Hệ thống điện	ACTIVE	f	\N	2026-08-29 06:43:11
40	1	Đào Viết Toàn	Hệ thống cấp thoát nước	ACTIVE	f	\N	2026-08-29 06:43:11
41	1	Lê Đức Nam	Hệ thống điện	ACTIVE	f	\N	2026-08-29 06:43:11
42	1	Nguyễn Trọng Thắng	Hệ thống cấp thoát nước	ACTIVE	f	\N	2026-08-29 06:43:11
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.suppliers (id, tenant_id, name, system, category, contact, status, source_sheet, created_at) FROM stdin;
1	1	Nhà cung cấp	Hệ thống	Hạng mục cung cấp	\N	ACTIVE	\N	2026-08-29 06:43:11
2	1	Công ty nhựa tiền phong	Hệ thống cấp thoát nước	- Ống cấp nước lạnh, nóng, thoát nước mưa, nước thải	\N	ACTIVE	\N	2026-08-29 06:43:11
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.teams (id, tenant_id, code, name, lead_worker_id, status, legacy_code, created_at) FROM stdin;
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenants (id, code, name, created_at) FROM stdin;
1	hbg	HBG Construction	2026-08-29 06:43:05
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, tenant_id, email, name, is_ceo, role, created_at) FROM stdin;
1	1	admin@hbg.com	Admin HBG	f	admin	2026-08-29 06:43:05
\.


--
-- Data for Name: vendors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vendors (id, tenant_id, code, name, tax_id, contact, category, status, legacy_code, created_at) FROM stdin;
\.


--
-- Data for Name: wbs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wbs (id, project_id, parent_id, code, name_vi, name_en, level, sort_order) FROM stdin;
\.


--
-- Data for Name: work_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_items (id, project_id, wbs_id, code, name_vi, name_en, unit, planned_qty, actual_qty, unit_price, baseline_version, created_at) FROM stdin;
\.


--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.workers (id, tenant_id, code, full_name, team_id, phone, role, status, legacy_code, created_at) FROM stdin;
\.


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zones (id, project_id, code, name_vi, name_en, created_at) FROM stdin;
1	1	BOH	\N	Back of House	2026-08-29 06:43:05
2	1	BPV	\N	Beach Pool Villa	2026-08-29 06:43:05
3	1	BPV-1BR	\N	Beach Pool Villa 1BR	2026-08-29 06:43:05
4	1	BPV-2BR	\N	Beach Pool Villa 2BR	2026-08-29 06:43:05
5	1	BSN	\N	Business	2026-08-29 06:43:05
6	1	BUT	\N	Butler	2026-08-29 06:43:05
7	1	BZONE	\N	Zone B	2026-08-29 06:43:05
8	1	CLU	\N	Cluster Villa	2026-08-29 06:43:05
9	1	GEN	\N	General	2026-08-29 06:43:05
10	1	HPV	\N	HPV	2026-08-29 06:43:05
11	1	HPV-1BR	\N	HPV 1BR	2026-08-29 06:43:06
12	1	HPV-2BR	\N	HPV 2BR	2026-08-29 06:43:06
13	1	INF	\N	Infrastructure	2026-08-29 06:43:06
14	1	KID	\N	Kid Club	2026-08-29 06:43:06
15	1	LOB-SPA	\N	Lobby & Spa	2026-08-29 06:43:06
16	1	RES	\N	Resort	2026-08-29 06:43:06
17	1	RES-3BR	\N	Resort 3BR	2026-08-29 06:43:06
18	1	RES-4BR	\N	Resort 4BR	2026-08-29 06:43:06
19	1	VNR	\N	Vietnam Residences	2026-08-29 06:43:06
\.


--
-- Name: area_hierarchy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.area_hierarchy_id_seq', 21, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1, false);


--
-- Name: business_process_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.business_process_steps_id_seq', 1, false);


--
-- Name: business_processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.business_processes_id_seq', 2, true);


--
-- Name: construction_schedule_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.construction_schedule_items_id_seq', 1, false);


--
-- Name: contracts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contracts_id_seq', 1, false);


--
-- Name: cost_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cost_codes_id_seq', 1, false);


--
-- Name: daily_acceptance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_acceptance_id_seq', 1, false);


--
-- Name: daily_infos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_infos_id_seq', 1, false);


--
-- Name: daily_manpower_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_manpower_id_seq', 1, false);


--
-- Name: daily_materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_materials_id_seq', 1, false);


--
-- Name: daily_recommendations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_recommendations_id_seq', 1, false);


--
-- Name: daily_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_reports_id_seq', 1, false);


--
-- Name: daily_safety_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_safety_id_seq', 1, false);


--
-- Name: daily_safety_observations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_safety_observations_id_seq', 1, false);


--
-- Name: daily_work_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_work_items_id_seq', 1, false);


--
-- Name: directives_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directives_id_seq', 1, false);


--
-- Name: file_uploads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.file_uploads_id_seq', 1, false);


--
-- Name: generic_sheets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.generic_sheets_id_seq', 1, false);


--
-- Name: invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoices_id_seq', 1, false);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.issues_id_seq', 1, false);


--
-- Name: kpi_targets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.kpi_targets_id_seq', 1, false);


--
-- Name: material_submittals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_submittals_id_seq', 1, false);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.materials_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: offline_sync_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.offline_sync_queue_id_seq', 1, false);


--
-- Name: payment_milestones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payment_milestones_id_seq', 1, false);


--
-- Name: payment_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payment_requests_id_seq', 1, false);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payments_id_seq', 1, false);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.projects_id_seq', 1, false);


--
-- Name: resources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.resources_id_seq', 1, false);


--
-- Name: rfa_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rfa_log_id_seq', 1, false);


--
-- Name: schedule_baselines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.schedule_baselines_id_seq', 1, false);


--
-- Name: shop_drawings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shop_drawings_id_seq', 1, false);


--
-- Name: subcontractors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.subcontractors_id_seq', 1, false);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.suppliers_id_seq', 1, false);


--
-- Name: teams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.teams_id_seq', 1, false);


--
-- Name: tenants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenants_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: vendors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vendors_id_seq', 1, false);


--
-- Name: wbs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.wbs_id_seq', 1, false);


--
-- Name: work_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_items_id_seq', 1, false);


--
-- Name: workers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.workers_id_seq', 1, false);


--
-- Name: zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zones_id_seq', 1, false);


--
-- Name: area_hierarchy area_hierarchy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_hierarchy
    ADD CONSTRAINT area_hierarchy_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: business_process_steps business_process_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_process_steps
    ADD CONSTRAINT business_process_steps_pkey PRIMARY KEY (id);


--
-- Name: business_processes business_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_processes
    ADD CONSTRAINT business_processes_pkey PRIMARY KEY (id);


--
-- Name: construction_schedule_items construction_schedule_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.construction_schedule_items
    ADD CONSTRAINT construction_schedule_items_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: cost_codes cost_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cost_codes
    ADD CONSTRAINT cost_codes_pkey PRIMARY KEY (id);


--
-- Name: daily_acceptance daily_acceptance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_acceptance
    ADD CONSTRAINT daily_acceptance_pkey PRIMARY KEY (id);


--
-- Name: daily_infos daily_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_infos
    ADD CONSTRAINT daily_infos_pkey PRIMARY KEY (id);


--
-- Name: daily_manpower daily_manpower_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_manpower
    ADD CONSTRAINT daily_manpower_pkey PRIMARY KEY (id);


--
-- Name: daily_materials daily_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_materials
    ADD CONSTRAINT daily_materials_pkey PRIMARY KEY (id);


--
-- Name: daily_recommendations daily_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_recommendations
    ADD CONSTRAINT daily_recommendations_pkey PRIMARY KEY (id);


--
-- Name: daily_reports daily_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_reports
    ADD CONSTRAINT daily_reports_pkey PRIMARY KEY (id);


--
-- Name: daily_safety_observations daily_safety_observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_safety_observations
    ADD CONSTRAINT daily_safety_observations_pkey PRIMARY KEY (id);


--
-- Name: daily_safety daily_safety_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_safety
    ADD CONSTRAINT daily_safety_pkey PRIMARY KEY (id);


--
-- Name: daily_work_items daily_work_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_work_items
    ADD CONSTRAINT daily_work_items_pkey PRIMARY KEY (id);


--
-- Name: directives directives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directives
    ADD CONSTRAINT directives_pkey PRIMARY KEY (id);


--
-- Name: file_uploads file_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_pkey PRIMARY KEY (id);


--
-- Name: generic_sheets generic_sheets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generic_sheets
    ADD CONSTRAINT generic_sheets_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: kpi_targets kpi_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_targets
    ADD CONSTRAINT kpi_targets_pkey PRIMARY KEY (id);


--
-- Name: material_submittals material_submittals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals
    ADD CONSTRAINT material_submittals_pkey PRIMARY KEY (id);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: offline_sync_queue offline_sync_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sync_queue
    ADD CONSTRAINT offline_sync_queue_pkey PRIMARY KEY (id);


--
-- Name: payment_milestones payment_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_milestones
    ADD CONSTRAINT payment_milestones_pkey PRIMARY KEY (id);


--
-- Name: payment_requests payment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_requests
    ADD CONSTRAINT payment_requests_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: resources resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id);


--
-- Name: rfa_log rfa_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rfa_log
    ADD CONSTRAINT rfa_log_pkey PRIMARY KEY (id);


--
-- Name: schedule_baselines schedule_baselines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_baselines
    ADD CONSTRAINT schedule_baselines_pkey PRIMARY KEY (id);


--
-- Name: shop_drawings shop_drawings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_drawings
    ADD CONSTRAINT shop_drawings_pkey PRIMARY KEY (id);


--
-- Name: subcontractors subcontractors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subcontractors
    ADD CONSTRAINT subcontractors_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_code_unique UNIQUE (code);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: wbs wbs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wbs
    ADD CONSTRAINT wbs_pkey PRIMARY KEY (id);


--
-- Name: work_items work_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_items
    ADD CONSTRAINT work_items_pkey PRIMARY KEY (id);


--
-- Name: workers workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: area_level_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX area_level_idx ON public.area_hierarchy USING btree (project_id, level);


--
-- Name: area_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX area_project_idx ON public.area_hierarchy USING btree (project_id);


--
-- Name: audit_resource_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_resource_idx ON public.audit_log USING btree (resource_type, resource_id);


--
-- Name: audit_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_user_idx ON public.audit_log USING btree (user_id, created_at);


--
-- Name: bp_step_ordinal_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bp_step_ordinal_idx ON public.business_process_steps USING btree (process_id, ordinal);


--
-- Name: bp_tenant_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bp_tenant_code_idx ON public.business_processes USING btree (tenant_id, code);


--
-- Name: contract_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contract_project_idx ON public.contracts USING btree (project_id);


--
-- Name: contract_project_no_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX contract_project_no_idx ON public.contracts USING btree (project_id, contract_no);


--
-- Name: contract_vendor_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contract_vendor_idx ON public.contracts USING btree (vendor_id);


--
-- Name: cs_baseline_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cs_baseline_idx ON public.construction_schedule_items USING btree (baseline_id);


--
-- Name: cs_project_zone_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cs_project_zone_idx ON public.construction_schedule_items USING btree (project_id, zone_id);


--
-- Name: idx_audit_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_resource ON public.audit_log USING btree (resource_type, resource_id);


--
-- Name: idx_issues_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_issues_project ON public.issues USING btree (project_id);


--
-- Name: idx_issues_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_issues_severity ON public.issues USING btree (severity);


--
-- Name: idx_notif_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notif_user ON public.notifications USING btree (user_id, read_at);


--
-- Name: invoice_contract_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_contract_idx ON public.invoices USING btree (contract_id);


--
-- Name: invoice_contract_no_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invoice_contract_no_idx ON public.invoices USING btree (contract_id, invoice_no);


--
-- Name: kpi_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kpi_code_idx ON public.kpi_targets USING btree (kpi_code);


--
-- Name: kpi_period_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kpi_period_idx ON public.kpi_targets USING btree (period_start, period_end);


--
-- Name: kpi_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kpi_project_idx ON public.kpi_targets USING btree (project_id);


--
-- Name: mat_project_zone_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mat_project_zone_idx ON public.materials USING btree (project_id, zone_id);


--
-- Name: ms_deadline_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ms_deadline_idx ON public.material_submittals USING btree (sla_deadline);


--
-- Name: ms_material_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ms_material_idx ON public.material_submittals USING btree (material_id);


--
-- Name: ms_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ms_project_idx ON public.material_submittals USING btree (project_id);


--
-- Name: ms_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ms_status_idx ON public.material_submittals USING btree (status);


--
-- Name: notif_channel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notif_channel_idx ON public.notifications USING btree (channel, delivery_status);


--
-- Name: notif_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notif_project_idx ON public.notifications USING btree (project_id);


--
-- Name: notif_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notif_user_idx ON public.notifications USING btree (user_id, read_at);


--
-- Name: pay_due_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pay_due_idx ON public.payments USING btree (due_date);


--
-- Name: pay_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pay_project_idx ON public.payments USING btree (project_id);


--
-- Name: pay_request_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pay_request_idx ON public.payments USING btree (payment_request_id);


--
-- Name: pay_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pay_status_idx ON public.payments USING btree (status);


--
-- Name: preq_due_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX preq_due_idx ON public.payment_requests USING btree (due_date);


--
-- Name: preq_invoice_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX preq_invoice_idx ON public.payment_requests USING btree (invoice_id);


--
-- Name: preq_invoice_no_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX preq_invoice_no_idx ON public.payment_requests USING btree (invoice_id, request_no);


--
-- Name: preq_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX preq_status_idx ON public.payment_requests USING btree (status);


--
-- Name: projects_tenant_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX projects_tenant_code_idx ON public.projects USING btree (tenant_id, code);


--
-- Name: sb_project_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sb_project_idx ON public.schedule_baselines USING btree (project_id);


--
-- Name: sb_project_version_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sb_project_version_idx ON public.schedule_baselines USING btree (project_id, version);


--
-- Name: shop_project_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX shop_project_code_idx ON public.shop_drawings USING btree (project_id, drawing_code);


--
-- Name: shop_project_zone_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shop_project_zone_idx ON public.shop_drawings USING btree (project_id, zone_id);


--
-- Name: shop_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shop_status_idx ON public.shop_drawings USING btree (status);


--
-- Name: sync_client_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sync_client_idx ON public.offline_sync_queue USING btree (client_id, resource_type);


--
-- Name: sync_resource_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sync_resource_idx ON public.offline_sync_queue USING btree (resource_type, server_record_id);


--
-- Name: sync_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sync_user_idx ON public.offline_sync_queue USING btree (user_id, status);


--
-- Name: uploads_tenant_hash_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uploads_tenant_hash_idx ON public.file_uploads USING btree (tenant_id, file_hash);


--
-- Name: users_tenant_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tenant_email_idx ON public.users USING btree (tenant_id, email);


--
-- Name: zones_project_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX zones_project_code_idx ON public.zones USING btree (project_id, code);


--
-- Name: area_hierarchy area_hierarchy_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_hierarchy
    ADD CONSTRAINT area_hierarchy_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: area_hierarchy area_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_hierarchy
    ADD CONSTRAINT area_parent_fk FOREIGN KEY (parent_id) REFERENCES public.area_hierarchy(id);


--
-- Name: audit_log audit_log_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: audit_log audit_log_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: business_process_steps business_process_steps_process_id_business_processes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_process_steps
    ADD CONSTRAINT business_process_steps_process_id_business_processes_id_fk FOREIGN KEY (process_id) REFERENCES public.business_processes(id);


--
-- Name: business_processes business_processes_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_processes
    ADD CONSTRAINT business_processes_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: construction_schedule_items construction_schedule_items_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.construction_schedule_items
    ADD CONSTRAINT construction_schedule_items_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: construction_schedule_items construction_schedule_items_zone_id_zones_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.construction_schedule_items
    ADD CONSTRAINT construction_schedule_items_zone_id_zones_id_fk FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: contracts contracts_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: contracts contracts_vendor_id_vendors_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_vendor_id_vendors_id_fk FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: cost_codes cost_codes_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cost_codes
    ADD CONSTRAINT cost_codes_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: daily_acceptance daily_acceptance_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_acceptance
    ADD CONSTRAINT daily_acceptance_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: daily_infos daily_infos_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_infos
    ADD CONSTRAINT daily_infos_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: daily_manpower daily_manpower_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_manpower
    ADD CONSTRAINT daily_manpower_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: daily_materials daily_materials_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_materials
    ADD CONSTRAINT daily_materials_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: daily_recommendations daily_recommendations_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_recommendations
    ADD CONSTRAINT daily_recommendations_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: daily_reports daily_reports_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_reports
    ADD CONSTRAINT daily_reports_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: daily_safety daily_safety_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_safety
    ADD CONSTRAINT daily_safety_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: daily_work_items daily_work_items_daily_report_id_daily_reports_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_work_items
    ADD CONSTRAINT daily_work_items_daily_report_id_daily_reports_id_fk FOREIGN KEY (daily_report_id) REFERENCES public.daily_reports(id) ON DELETE CASCADE;


--
-- Name: file_uploads file_uploads_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: file_uploads file_uploads_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: generic_sheets generic_sheets_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generic_sheets
    ADD CONSTRAINT generic_sheets_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: generic_sheets generic_sheets_zone_id_zones_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generic_sheets
    ADD CONSTRAINT generic_sheets_zone_id_zones_id_fk FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: invoices invoices_contract_id_contracts_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_contract_id_contracts_id_fk FOREIGN KEY (contract_id) REFERENCES public.contracts(id);


--
-- Name: kpi_targets kpi_targets_approved_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_targets
    ADD CONSTRAINT kpi_targets_approved_by_users_id_fk FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: kpi_targets kpi_targets_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_targets
    ADD CONSTRAINT kpi_targets_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: material_submittals material_submittals_approved_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals
    ADD CONSTRAINT material_submittals_approved_by_users_id_fk FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: material_submittals material_submittals_material_id_materials_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals
    ADD CONSTRAINT material_submittals_material_id_materials_id_fk FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: material_submittals material_submittals_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals
    ADD CONSTRAINT material_submittals_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: material_submittals material_submittals_submitted_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals
    ADD CONSTRAINT material_submittals_submitted_by_users_id_fk FOREIGN KEY (submitted_by) REFERENCES public.users(id);


--
-- Name: materials materials_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: materials materials_zone_id_zones_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_zone_id_zones_id_fk FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: material_submittals ms_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_submittals
    ADD CONSTRAINT ms_parent_fk FOREIGN KEY (parent_submittal_id) REFERENCES public.material_submittals(id);


--
-- Name: notifications notifications_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: notifications notifications_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: notifications notifications_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: offline_sync_queue offline_sync_queue_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sync_queue
    ADD CONSTRAINT offline_sync_queue_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_requests payment_requests_approved_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_requests
    ADD CONSTRAINT payment_requests_approved_by_users_id_fk FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: payment_requests payment_requests_invoice_id_invoices_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_requests
    ADD CONSTRAINT payment_requests_invoice_id_invoices_id_fk FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: payments payments_payment_request_id_payment_requests_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_payment_request_id_payment_requests_id_fk FOREIGN KEY (payment_request_id) REFERENCES public.payment_requests(id);


--
-- Name: payments payments_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: payments payments_vendor_id_vendors_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_vendor_id_vendors_id_fk FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: projects projects_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: resources resources_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: schedule_baselines schedule_baselines_created_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_baselines
    ADD CONSTRAINT schedule_baselines_created_by_users_id_fk FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: schedule_baselines schedule_baselines_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_baselines
    ADD CONSTRAINT schedule_baselines_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: shop_drawings shop_drawings_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_drawings
    ADD CONSTRAINT shop_drawings_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: shop_drawings shop_drawings_rejected_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_drawings
    ADD CONSTRAINT shop_drawings_rejected_by_users_id_fk FOREIGN KEY (rejected_by) REFERENCES public.users(id);


--
-- Name: shop_drawings shop_drawings_reverted_to_draft_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_drawings
    ADD CONSTRAINT shop_drawings_reverted_to_draft_by_users_id_fk FOREIGN KEY (reverted_to_draft_by) REFERENCES public.users(id);


--
-- Name: shop_drawings shop_drawings_zone_id_zones_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_drawings
    ADD CONSTRAINT shop_drawings_zone_id_zones_id_fk FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: subcontractors subcontractors_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subcontractors
    ADD CONSTRAINT subcontractors_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: suppliers suppliers_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: teams teams_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: users users_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: vendors vendors_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: wbs wbs_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wbs
    ADD CONSTRAINT wbs_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: work_items work_items_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_items
    ADD CONSTRAINT work_items_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: work_items work_items_wbs_id_wbs_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_items
    ADD CONSTRAINT work_items_wbs_id_wbs_id_fk FOREIGN KEY (wbs_id) REFERENCES public.wbs(id);


--
-- Name: workers workers_team_id_teams_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_team_id_teams_id_fk FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: workers workers_tenant_id_tenants_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_tenant_id_tenants_id_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: zones zones_project_id_projects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_project_id_projects_id_fk FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 96pXhuueXxD0c8vfdZCKpPjADaV3W1WExRBgrFVyUTu7mMJabTnrBOfeLvWAbBb

