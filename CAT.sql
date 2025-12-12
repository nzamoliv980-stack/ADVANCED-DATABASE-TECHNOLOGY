--
-- PostgreSQL database dump
--

\restrict w3QtwOFEa8RvCLLFcGMacPyLNDDZnEUcK3Nx1L8gNIm1Xjlqzt5O4xLt7o18p9H

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

-- Started on 2025-12-12 10:49:39

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
-- TOC entry 228 (class 1255 OID 16481)
-- Name: check_project_budget(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_project_budget() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  total_expenses NUMERIC(10,2);
  project_budget NUMERIC(10,2);
BEGIN
  -- Get current total expenses for the project
  SELECT COALESCE(SUM(amount), 0)
  INTO total_expenses
  FROM expense
  WHERE projectid = NEW.projectid;
  SELECT budget
  INTO project_budget
  FROM project
  WHERE projectid = NEW.projectid;
  IF (total_expenses + NEW.amount) > project_budget THEN
    RAISE EXCEPTION 'Error: Total expenses exceed the project budget.';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_project_budget() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16399)
-- Name: contractor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contractor (
    contractorid integer NOT NULL,
    name character varying(50) NOT NULL,
    contact character varying(20) NOT NULL,
    company character varying(100) NOT NULL,
    experienceyears integer NOT NULL
);


ALTER TABLE public.contractor OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16398)
-- Name: contractor_contractorid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contractor_contractorid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contractor_contractorid_seq OWNER TO postgres;

--
-- TOC entry 4953 (class 0 OID 0)
-- Dependencies: 215
-- Name: contractor_contractorid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contractor_contractorid_seq OWNED BY public.contractor.contractorid;


--
-- TOC entry 222 (class 1259 OID 16421)
-- Name: equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment (
    equipmentid integer NOT NULL,
    projectid integer,
    name character varying(200),
    costperday numeric(10,2) NOT NULL,
    status character varying(50) NOT NULL
);


ALTER TABLE public.equipment OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16420)
-- Name: equipment_equipmentid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipment_equipmentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_equipmentid_seq OWNER TO postgres;

--
-- TOC entry 4954 (class 0 OID 0)
-- Dependencies: 221
-- Name: equipment_equipmentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipment_equipmentid_seq OWNED BY public.equipment.equipmentid;


--
-- TOC entry 226 (class 1259 OID 16456)
-- Name: expense; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense (
    expenseid integer NOT NULL,
    projectid integer,
    description character varying(250),
    amount numeric(10,2) NOT NULL,
    exp_date date NOT NULL
);


ALTER TABLE public.expense OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16455)
-- Name: expense_expenseid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_expenseid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_expenseid_seq OWNER TO postgres;

--
-- TOC entry 4955 (class 0 OID 0)
-- Dependencies: 225
-- Name: expense_expenseid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_expenseid_seq OWNED BY public.expense.expenseid;


--
-- TOC entry 220 (class 1259 OID 16414)
-- Name: material; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material (
    materialid integer NOT NULL,
    projectid integer,
    materialname character varying(200) NOT NULL,
    cost numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    supplier character varying(200)
);


ALTER TABLE public.material OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16413)
-- Name: material_materialid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_materialid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_materialid_seq OWNER TO postgres;

--
-- TOC entry 4956 (class 0 OID 0)
-- Dependencies: 219
-- Name: material_materialid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_materialid_seq OWNED BY public.material.materialid;


--
-- TOC entry 224 (class 1259 OID 16428)
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    paymentid integer NOT NULL,
    contractorid integer,
    projectid integer,
    amount numeric(10,2) NOT NULL,
    paymentdate timestamp without time zone NOT NULL,
    method character varying(50) NOT NULL
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16427)
-- Name: payment_paymentid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_paymentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_paymentid_seq OWNER TO postgres;

--
-- TOC entry 4957 (class 0 OID 0)
-- Dependencies: 223
-- Name: payment_paymentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_paymentid_seq OWNED BY public.payment.paymentid;


--
-- TOC entry 218 (class 1259 OID 16406)
-- Name: project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project (
    projectid integer NOT NULL,
    contractorid integer,
    name character varying(150) NOT NULL,
    location character varying(50) NOT NULL,
    startdate date NOT NULL,
    enddate date NOT NULL,
    budget numeric(10,2) NOT NULL,
    CONSTRAINT project_budget_check CHECK ((budget > (0)::numeric))
);


ALTER TABLE public.project OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16405)
-- Name: project_projectid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_projectid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_projectid_seq OWNER TO postgres;

--
-- TOC entry 4958 (class 0 OID 0)
-- Dependencies: 217
-- Name: project_projectid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_projectid_seq OWNED BY public.project.projectid;


--
-- TOC entry 227 (class 1259 OID 16477)
-- Name: total_payment; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.total_payment AS
 SELECT contractorid,
    sum(budget) AS total_budget
   FROM public.project
  GROUP BY contractorid;


ALTER VIEW public.total_payment OWNER TO postgres;

--
-- TOC entry 4765 (class 2604 OID 16402)
-- Name: contractor contractorid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contractor ALTER COLUMN contractorid SET DEFAULT nextval('public.contractor_contractorid_seq'::regclass);


--
-- TOC entry 4768 (class 2604 OID 16424)
-- Name: equipment equipmentid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment ALTER COLUMN equipmentid SET DEFAULT nextval('public.equipment_equipmentid_seq'::regclass);


--
-- TOC entry 4770 (class 2604 OID 16459)
-- Name: expense expenseid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense ALTER COLUMN expenseid SET DEFAULT nextval('public.expense_expenseid_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 16417)
-- Name: material materialid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material ALTER COLUMN materialid SET DEFAULT nextval('public.material_materialid_seq'::regclass);


--
-- TOC entry 4769 (class 2604 OID 16431)
-- Name: payment paymentid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN paymentid SET DEFAULT nextval('public.payment_paymentid_seq'::regclass);


--
-- TOC entry 4766 (class 2604 OID 16409)
-- Name: project projectid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project ALTER COLUMN projectid SET DEFAULT nextval('public.project_projectid_seq'::regclass);


--
-- TOC entry 4937 (class 0 OID 16399)
-- Dependencies: 216
-- Data for Name: contractor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contractor (contractorid, name, contact, company, experienceyears) FROM stdin;
1	John kenned	0788509213	horizon	10
2	KAYITARE Aman	0788563354	NPD	15
3	RWAGASORE	0780694975	CWC Rwanda	5
\.


--
-- TOC entry 4943 (class 0 OID 16421)
-- Dependencies: 222
-- Data for Name: equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment (equipmentid, projectid, name, costperday, status) FROM stdin;
\.


--
-- TOC entry 4947 (class 0 OID 16456)
-- Dependencies: 226
-- Data for Name: expense; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense (expenseid, projectid, description, amount, exp_date) FROM stdin;
1	1	Site preparation	40.00	2024-02-15
2	1	Materials purchase	55.00	2024-03-10
3	2	Equipment rental	60.00	2023-06-05
4	3	Labor wages	80.00	2023-08-20
5	3	Transport costs	15.00	2023-09-12
\.


--
-- TOC entry 4941 (class 0 OID 16414)
-- Dependencies: 220
-- Data for Name: material; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.material (materialid, projectid, materialname, cost, quantity, supplier) FROM stdin;
1	1	Cement	10.00	5	Supplier A
2	2	Steel Rods	20.00	3	Supplier B
3	3	Bricks	1.50	40	Supplier C
4	4	Sand	5.00	10	Supplier D
5	5	Gravel	8.00	8	Supplier E
\.


--
-- TOC entry 4945 (class 0 OID 16428)
-- Dependencies: 224
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (paymentid, contractorid, projectid, amount, paymentdate, method) FROM stdin;
\.


--
-- TOC entry 4939 (class 0 OID 16406)
-- Dependencies: 218
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project (projectid, contractorid, name, location, startdate, enddate, budget) FROM stdin;
1	1	kigali green Project	kigali CBD	2024-01-01	2027-12-31	30.00
2	1	Akanyaru Multipurpose Dam	Akanyaru river	2022-01-01	2025-12-31	44.00
3	2	Rusumo HydroElectric power station	rusumo falls	2017-01-01	2030-12-31	100.00
4	2	Kigali Innovation City (KIC)	Special Economic Zone	2025-01-01	2030-12-31	27.00
5	3	Kigali Urban Transport Improvement project(KUTI)	Kigali	2025-01-01	2030-12-31	60.00
\.


--
-- TOC entry 4959 (class 0 OID 0)
-- Dependencies: 215
-- Name: contractor_contractorid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contractor_contractorid_seq', 3, true);


--
-- TOC entry 4960 (class 0 OID 0)
-- Dependencies: 221
-- Name: equipment_equipmentid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_equipmentid_seq', 1, false);


--
-- TOC entry 4961 (class 0 OID 0)
-- Dependencies: 225
-- Name: expense_expenseid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_expenseid_seq', 5, true);


--
-- TOC entry 4962 (class 0 OID 0)
-- Dependencies: 219
-- Name: material_materialid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_materialid_seq', 5, true);


--
-- TOC entry 4963 (class 0 OID 0)
-- Dependencies: 223
-- Name: payment_paymentid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_paymentid_seq', 1, false);


--
-- TOC entry 4964 (class 0 OID 0)
-- Dependencies: 217
-- Name: project_projectid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_projectid_seq', 5, true);


--
-- TOC entry 4773 (class 2606 OID 16404)
-- Name: contractor contractor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contractor
    ADD CONSTRAINT contractor_pkey PRIMARY KEY (contractorid);


--
-- TOC entry 4779 (class 2606 OID 16426)
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (equipmentid);


--
-- TOC entry 4783 (class 2606 OID 16461)
-- Name: expense expense_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_pkey PRIMARY KEY (expenseid);


--
-- TOC entry 4777 (class 2606 OID 16419)
-- Name: material material_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_pkey PRIMARY KEY (materialid);


--
-- TOC entry 4781 (class 2606 OID 16433)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (paymentid);


--
-- TOC entry 4775 (class 2606 OID 16412)
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (projectid);


--
-- TOC entry 4791 (class 2620 OID 16482)
-- Name: expense check_project_budget; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_project_budget BEFORE INSERT ON public.expense FOR EACH ROW EXECUTE FUNCTION public.check_project_budget();


--
-- TOC entry 4786 (class 2606 OID 16445)
-- Name: equipment equipment_projectid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_projectid_fkey FOREIGN KEY (projectid) REFERENCES public.project(projectid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4787 (class 2606 OID 16450)
-- Name: equipment equipment_projectid_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_projectid_fkey1 FOREIGN KEY (projectid) REFERENCES public.project(projectid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4790 (class 2606 OID 16462)
-- Name: expense expense_projectid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_projectid_fkey FOREIGN KEY (projectid) REFERENCES public.project(projectid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4785 (class 2606 OID 16440)
-- Name: material material_projectid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_projectid_fkey FOREIGN KEY (projectid) REFERENCES public.project(projectid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4788 (class 2606 OID 16472)
-- Name: payment payment_contractorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_contractorid_fkey FOREIGN KEY (contractorid) REFERENCES public.contractor(contractorid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4789 (class 2606 OID 16467)
-- Name: payment payment_projectid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_projectid_fkey FOREIGN KEY (projectid) REFERENCES public.project(projectid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4784 (class 2606 OID 16435)
-- Name: project project_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_ibfk_1 FOREIGN KEY (contractorid) REFERENCES public.contractor(contractorid) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2025-12-12 10:49:39

--
-- PostgreSQL database dump complete
--

\unrestrict w3QtwOFEa8RvCLLFcGMacPyLNDDZnEUcK3Nx1L8gNIm1Xjlqzt5O4xLt7o18p9H

