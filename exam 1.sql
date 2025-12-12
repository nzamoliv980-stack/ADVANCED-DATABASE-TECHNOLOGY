--
-- PostgreSQL database dump
--

\restrict iT7EC6q9pwsYrCV8P7CefV1R0hKMeWRBTeez75dF19wb937GFJsvD29r907a59b

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

-- Started on 2025-12-12 10:34:46

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
-- TOC entry 7 (class 2615 OID 16493)
-- Name: node_a; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA node_a;


ALTER SCHEMA node_a OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 16494)
-- Name: node_b; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA node_b;


ALTER SCHEMA node_b OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16517)
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- TOC entry 5026 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- TOC entry 248 (class 1255 OID 16718)
-- Name: fn_should_alert(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_should_alert(new_amount numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_threshold NUMERIC;
    v_total NUMERIC;
BEGIN
    -- Get active rule threshold
    SELECT threshold INTO v_threshold
    FROM BUSINESS_LIMITS
    WHERE active = 'Y'
    LIMIT 1;

    -- Calculate total existing expenses
    SELECT COALESCE(SUM(amount), 0) INTO v_total
    FROM EXPENSE;

    -- Check if new total would exceed threshold
    IF v_total + new_amount > v_threshold THEN
        RETURN 1;  -- violation
    ELSE
        RETURN 0;  -- safe
    END IF;
END;
$$;


ALTER FUNCTION public.fn_should_alert(new_amount numeric) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16691)
-- Name: recompute_project_totals(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.recompute_project_totals() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_bef_total NUMERIC(10,2);
    v_aft_total NUMERIC(10,2);
BEGIN
    -- Compute the total before change
    SELECT COALESCE(SUM(amount),0) INTO v_bef_total
    FROM expense;

    -- Wait for the operation to complete
    PERFORM pg_sleep(0.1);  -- (just for timing clarity in logs)

    -- Update each project’s total_expense
    UPDATE project p
    SET total_expense = COALESCE((
        SELECT SUM(e.amount)
        FROM expense e
        WHERE e.project_id = p.project_id
    ),0);

    -- Compute the total after change
    SELECT COALESCE(SUM(amount),0) INTO v_aft_total
    FROM expense;

    -- Log change in audit table
    INSERT INTO project_audit (bef_total, aft_total, key_col)
    VALUES (v_bef_total, v_aft_total, TG_OP || ' on expense');

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.recompute_project_totals() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16719)
-- Name: trg_expense_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_expense_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF fn_should_alert(NEW.amount) = 1 THEN
        RAISE EXCEPTION 'Expense limit exceeded: cannot insert or update record';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_expense_check() OWNER TO postgres;

--
-- TOC entry 2120 (class 1417 OID 16524)
-- Name: proj_link; Type: SERVER; Schema: -; Owner: postgres
--

CREATE SERVER proj_link FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'CCR',
    host 'localhost',
    port '5432'
);


ALTER SERVER proj_link OWNER TO postgres;

--
-- TOC entry 5027 (class 0 OID 0)
-- Name: USER MAPPING postgres SERVER proj_link; Type: USER MAPPING; Schema: -; Owner: postgres
--

CREATE USER MAPPING FOR postgres SERVER proj_link OPTIONS (
    password '1234',
    "user" 'postgres'
);


--
-- TOC entry 222 (class 1259 OID 16531)
-- Name: contractor; Type: FOREIGN TABLE; Schema: node_a; Owner: postgres
--

CREATE FOREIGN TABLE node_a.contractor (
    contractor_id integer NOT NULL,
    contractor_name character varying(50)
)
SERVER proj_link
OPTIONS (
    schema_name 'node_b',
    table_name 'contractor'
);
ALTER FOREIGN TABLE node_a.contractor ALTER COLUMN contractor_id OPTIONS (
    column_name 'contractor_id'
);
ALTER FOREIGN TABLE node_a.contractor ALTER COLUMN contractor_name OPTIONS (
    column_name 'contractor_name'
);


ALTER FOREIGN TABLE node_a.contractor OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16495)
-- Name: expense_a; Type: TABLE; Schema: node_a; Owner: postgres
--

CREATE TABLE node_a.expense_a (
    expense_id integer NOT NULL,
    project_id integer NOT NULL,
    contractor_id integer,
    amount numeric(12,2) NOT NULL,
    expense_date date NOT NULL,
    description text,
    CONSTRAINT expense_a_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT expense_a_expense_id_check CHECK (((expense_id >= 1) AND (expense_id <= 5)))
);


ALTER TABLE node_a.expense_a OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16504)
-- Name: expense_b; Type: TABLE; Schema: node_b; Owner: postgres
--

CREATE TABLE node_b.expense_b (
    expense_id integer NOT NULL,
    project_id integer NOT NULL,
    contractor_id integer,
    amount numeric(12,2) NOT NULL,
    expense_date date NOT NULL,
    description text,
    CONSTRAINT expense_b_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT expense_b_expense_id_check CHECK (((expense_id >= 6) AND (expense_id <= 10)))
);


ALTER TABLE node_b.expense_b OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16513)
-- Name: expense_all; Type: VIEW; Schema: node_a; Owner: postgres
--

CREATE VIEW node_a.expense_all AS
 SELECT expense_a.expense_id,
    expense_a.project_id,
    expense_a.contractor_id,
    expense_a.amount,
    expense_a.expense_date,
    expense_a.description
   FROM node_a.expense_a
UNION ALL
 SELECT expense_b.expense_id,
    expense_b.project_id,
    expense_b.contractor_id,
    expense_b.amount,
    expense_b.expense_date,
    expense_b.description
   FROM node_b.expense_b;


ALTER VIEW node_a.expense_all OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16526)
-- Name: contractor; Type: TABLE; Schema: node_b; Owner: postgres
--

CREATE TABLE node_b.contractor (
    contractor_id integer NOT NULL,
    contractor_name character varying(50)
);


ALTER TABLE node_b.contractor OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16710)
-- Name: business_limits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_limits (
    rule_key character varying(64),
    threshold numeric,
    active character(1),
    CONSTRAINT business_limits_active_check CHECK ((active = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


ALTER TABLE public.business_limits OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16669)
-- Name: expense; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense (
    expense_id integer NOT NULL,
    project_id integer,
    amount numeric(10,2) NOT NULL,
    description character varying(100),
    CONSTRAINT expense_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.expense OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16538)
-- Name: expense_a; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense_a (
    id integer NOT NULL,
    category character varying(50),
    amount numeric
);


ALTER TABLE public.expense_a OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16537)
-- Name: expense_a_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_a_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_a_id_seq OWNER TO postgres;

--
-- TOC entry 5028 (class 0 OID 0)
-- Dependencies: 224
-- Name: expense_a_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_a_id_seq OWNED BY public.expense_a.id;


--
-- TOC entry 227 (class 1259 OID 16547)
-- Name: expense_b; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense_b (
    id integer NOT NULL,
    category character varying(50),
    amount numeric
);


ALTER TABLE public.expense_b OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16555)
-- Name: expense_all; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.expense_all AS
 SELECT expense_a.id,
    expense_a.category,
    expense_a.amount
   FROM public.expense_a
UNION ALL
 SELECT expense_b.id,
    expense_b.category,
    expense_b.amount
   FROM public.expense_b;


ALTER VIEW public.expense_all OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16546)
-- Name: expense_b_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_b_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_b_id_seq OWNER TO postgres;

--
-- TOC entry 5029 (class 0 OID 0)
-- Dependencies: 226
-- Name: expense_b_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_b_id_seq OWNED BY public.expense_b.id;


--
-- TOC entry 223 (class 1259 OID 16534)
-- Name: expense_b_remote; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.expense_b_remote (
    expense_id integer,
    project_id integer,
    amount numeric,
    description text
)
SERVER proj_link
OPTIONS (
    schema_name 'public',
    table_name 'expense_b'
);


ALTER FOREIGN TABLE public.expense_b_remote OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16668)
-- Name: expense_expense_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_expense_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_expense_id_seq OWNER TO postgres;

--
-- TOC entry 5030 (class 0 OID 0)
-- Dependencies: 235
-- Name: expense_expense_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_expense_id_seq OWNED BY public.expense.expense_id;


--
-- TOC entry 230 (class 1259 OID 16560)
-- Name: expense_local; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense_local (
    id integer NOT NULL,
    category character varying(50),
    amount numeric
);


ALTER TABLE public.expense_local OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16559)
-- Name: expense_local_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_local_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_local_id_seq OWNER TO postgres;

--
-- TOC entry 5031 (class 0 OID 0)
-- Dependencies: 229
-- Name: expense_local_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_local_id_seq OWNED BY public.expense_local.id;


--
-- TOC entry 232 (class 1259 OID 16569)
-- Name: expense_remote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense_remote (
    id integer NOT NULL,
    category character varying(50),
    amount numeric
);


ALTER TABLE public.expense_remote OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16568)
-- Name: expense_remote_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_remote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_remote_id_seq OWNER TO postgres;

--
-- TOC entry 5032 (class 0 OID 0)
-- Dependencies: 231
-- Name: expense_remote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_remote_id_seq OWNED BY public.expense_remote.id;


--
-- TOC entry 239 (class 1259 OID 16704)
-- Name: hier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hier (
    parent_id integer,
    child_id integer
);


ALTER TABLE public.hier OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16659)
-- Name: project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project (
    project_id integer NOT NULL,
    project_name text NOT NULL,
    total_expense numeric(10,2) DEFAULT 0
);


ALTER TABLE public.project OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16694)
-- Name: project_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_audit (
    audit_id integer NOT NULL,
    bef_total numeric(10,2),
    aft_total numeric(10,2),
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    key_col text
);


ALTER TABLE public.project_audit OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16693)
-- Name: project_audit_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_audit_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_audit_audit_id_seq OWNER TO postgres;

--
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 237
-- Name: project_audit_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_audit_audit_id_seq OWNED BY public.project_audit.audit_id;


--
-- TOC entry 233 (class 1259 OID 16658)
-- Name: project_project_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_project_id_seq OWNER TO postgres;

--
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 233
-- Name: project_project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_project_id_seq OWNED BY public.project.project_id;


--
-- TOC entry 240 (class 1259 OID 16707)
-- Name: triple; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.triple (
    s character varying(64),
    p character varying(64),
    o character varying(64)
);


ALTER TABLE public.triple OWNER TO postgres;

--
-- TOC entry 4824 (class 2604 OID 16672)
-- Name: expense expense_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense ALTER COLUMN expense_id SET DEFAULT nextval('public.expense_expense_id_seq'::regclass);


--
-- TOC entry 4818 (class 2604 OID 16541)
-- Name: expense_a id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_a ALTER COLUMN id SET DEFAULT nextval('public.expense_a_id_seq'::regclass);


--
-- TOC entry 4819 (class 2604 OID 16550)
-- Name: expense_b id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_b ALTER COLUMN id SET DEFAULT nextval('public.expense_b_id_seq'::regclass);


--
-- TOC entry 4820 (class 2604 OID 16563)
-- Name: expense_local id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_local ALTER COLUMN id SET DEFAULT nextval('public.expense_local_id_seq'::regclass);


--
-- TOC entry 4821 (class 2604 OID 16572)
-- Name: expense_remote id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_remote ALTER COLUMN id SET DEFAULT nextval('public.expense_remote_id_seq'::regclass);


--
-- TOC entry 4822 (class 2604 OID 16662)
-- Name: project project_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project ALTER COLUMN project_id SET DEFAULT nextval('public.project_project_id_seq'::regclass);


--
-- TOC entry 4825 (class 2604 OID 16697)
-- Name: project_audit audit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_audit ALTER COLUMN audit_id SET DEFAULT nextval('public.project_audit_audit_id_seq'::regclass);


--
-- TOC entry 5001 (class 0 OID 16495)
-- Dependencies: 218
-- Data for Name: expense_a; Type: TABLE DATA; Schema: node_a; Owner: postgres
--

COPY node_a.expense_a (expense_id, project_id, contractor_id, amount, expense_date, description) FROM stdin;
1	101	1001	120.00	2025-10-01	Office supplies
2	101	1002	500.00	2025-10-02	Site materials
3	102	1001	250.00	2025-10-03	Transport
4	103	1003	600.00	2025-10-04	Consulting
5	103	1004	75.50	2025-10-05	Misc
\.


--
-- TOC entry 5003 (class 0 OID 16526)
-- Dependencies: 221
-- Data for Name: contractor; Type: TABLE DATA; Schema: node_b; Owner: postgres
--

COPY node_b.contractor (contractor_id, contractor_name) FROM stdin;
2001	BuildCo Ltd
2002	SteelWorks
2003	QuickFix Services
2004	ProConstruct
\.


--
-- TOC entry 5002 (class 0 OID 16504)
-- Dependencies: 219
-- Data for Name: expense_b; Type: TABLE DATA; Schema: node_b; Owner: postgres
--

COPY node_b.expense_b (expense_id, project_id, contractor_id, amount, expense_date, description) FROM stdin;
6	201	2001	80.00	2025-10-01	Fuel
7	201	2002	300.00	2025-10-02	Equipment rental
8	202	2001	430.00	2025-10-03	Subcontractor
9	203	2003	150.00	2025-10-04	Safety gear
10	203	2004	220.00	2025-10-05	Catering
\.


--
-- TOC entry 5020 (class 0 OID 16710)
-- Dependencies: 241
-- Data for Name: business_limits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.business_limits (rule_key, threshold, active) FROM stdin;
MAX_EXPENSE_LIMIT	1000	Y
\.


--
-- TOC entry 5015 (class 0 OID 16669)
-- Dependencies: 236
-- Data for Name: expense; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense (expense_id, project_id, amount, description) FROM stdin;
1	1	1500.00	\N
\.


--
-- TOC entry 5005 (class 0 OID 16538)
-- Dependencies: 225
-- Data for Name: expense_a; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_a (id, category, amount) FROM stdin;
1	Labor	5000
2	Material	8000
3	Transport	1500
4	Equipment	3000
5	Misc	700
\.


--
-- TOC entry 5007 (class 0 OID 16547)
-- Dependencies: 227
-- Data for Name: expense_b; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_b (id, category, amount) FROM stdin;
1	Labor	4000
2	Material	6000
3	Transport	1200
4	Equipment	2800
5	Misc	600
\.


--
-- TOC entry 5009 (class 0 OID 16560)
-- Dependencies: 230
-- Data for Name: expense_local; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_local (id, category, amount) FROM stdin;
3	Transport	1200
4	Equipment	2000
\.


--
-- TOC entry 5011 (class 0 OID 16569)
-- Dependencies: 232
-- Data for Name: expense_remote; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_remote (id, category, amount) FROM stdin;
3	Transport	1200
4	Equipment	2000
\.


--
-- TOC entry 5018 (class 0 OID 16704)
-- Dependencies: 239
-- Data for Name: hier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hier (parent_id, child_id) FROM stdin;
1	2
1	3
2	4
2	5
3	6
4	7
\.


--
-- TOC entry 5013 (class 0 OID 16659)
-- Dependencies: 234
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project (project_id, project_name, total_expense) FROM stdin;
1	Bridge Repair	1500.00
2	Hospital Extension	0.00
\.


--
-- TOC entry 5017 (class 0 OID 16694)
-- Dependencies: 238
-- Data for Name: project_audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_audit (audit_id, bef_total, aft_total, changed_at, key_col) FROM stdin;
1	3000.00	3000.00	2025-10-28 22:50:01.262495	INSERT on expense
2	3500.00	3500.00	2025-10-28 22:50:01.262495	UPDATE on expense
3	1500.00	1500.00	2025-10-28 22:50:01.262495	DELETE on expense
\.


--
-- TOC entry 5019 (class 0 OID 16707)
-- Dependencies: 240
-- Data for Name: triple; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.triple (s, p, o) FROM stdin;
Dog	isA	Mammal
Cat	isA	Mammal
Mammal	isA	Animal
Bird	isA	Animal
Animal	isA	Organism
Eagle	isA	Bird
Whale	isA	Mammal
Penguin	isA	Bird
Organism	isA	LivingBeing
\.


--
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 224
-- Name: expense_a_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_a_id_seq', 5, true);


--
-- TOC entry 5036 (class 0 OID 0)
-- Dependencies: 226
-- Name: expense_b_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_b_id_seq', 5, true);


--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 235
-- Name: expense_expense_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_expense_id_seq', 9, true);


--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 229
-- Name: expense_local_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_local_id_seq', 4, true);


--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 231
-- Name: expense_remote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_remote_id_seq', 4, true);


--
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 237
-- Name: project_audit_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_audit_audit_id_seq', 3, true);


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 233
-- Name: project_project_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_project_id_seq', 2, true);


--
-- TOC entry 4834 (class 2606 OID 16503)
-- Name: expense_a expense_a_pkey; Type: CONSTRAINT; Schema: node_a; Owner: postgres
--

ALTER TABLE ONLY node_a.expense_a
    ADD CONSTRAINT expense_a_pkey PRIMARY KEY (expense_id);


--
-- TOC entry 4838 (class 2606 OID 16530)
-- Name: contractor contractor_pkey; Type: CONSTRAINT; Schema: node_b; Owner: postgres
--

ALTER TABLE ONLY node_b.contractor
    ADD CONSTRAINT contractor_pkey PRIMARY KEY (contractor_id);


--
-- TOC entry 4836 (class 2606 OID 16512)
-- Name: expense_b expense_b_pkey; Type: CONSTRAINT; Schema: node_b; Owner: postgres
--

ALTER TABLE ONLY node_b.expense_b
    ADD CONSTRAINT expense_b_pkey PRIMARY KEY (expense_id);


--
-- TOC entry 4840 (class 2606 OID 16545)
-- Name: expense_a expense_a_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_a
    ADD CONSTRAINT expense_a_pkey PRIMARY KEY (id);


--
-- TOC entry 4842 (class 2606 OID 16554)
-- Name: expense_b expense_b_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_b
    ADD CONSTRAINT expense_b_pkey PRIMARY KEY (id);


--
-- TOC entry 4844 (class 2606 OID 16567)
-- Name: expense_local expense_local_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_local
    ADD CONSTRAINT expense_local_pkey PRIMARY KEY (id);


--
-- TOC entry 4850 (class 2606 OID 16675)
-- Name: expense expense_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_pkey PRIMARY KEY (expense_id);


--
-- TOC entry 4846 (class 2606 OID 16576)
-- Name: expense_remote expense_remote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_remote
    ADD CONSTRAINT expense_remote_pkey PRIMARY KEY (id);


--
-- TOC entry 4852 (class 2606 OID 16702)
-- Name: project_audit project_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_audit
    ADD CONSTRAINT project_audit_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 4848 (class 2606 OID 16667)
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (project_id);


--
-- TOC entry 4854 (class 2620 OID 16720)
-- Name: expense expense_limit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER expense_limit_trigger BEFORE INSERT OR UPDATE ON public.expense FOR EACH ROW EXECUTE FUNCTION public.trg_expense_check();


--
-- TOC entry 4855 (class 2620 OID 16703)
-- Name: expense trg_expense_recompute; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_expense_recompute AFTER INSERT OR DELETE OR UPDATE ON public.expense FOR EACH STATEMENT EXECUTE FUNCTION public.recompute_project_totals();


--
-- TOC entry 4853 (class 2606 OID 16676)
-- Name: expense expense_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(project_id) ON DELETE CASCADE;


-- Completed on 2025-12-12 10:34:46

--
-- PostgreSQL database dump complete
--

\unrestrict iT7EC6q9pwsYrCV8P7CefV1R0hKMeWRBTeez75dF19wb937GFJsvD29r907a59b

