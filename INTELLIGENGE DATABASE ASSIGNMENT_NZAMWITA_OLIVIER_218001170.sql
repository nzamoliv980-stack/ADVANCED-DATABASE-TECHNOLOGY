--
-- PostgreSQL database dump
--

\restrict yztgJ1gIuhQ0cgJdnpFxW9C6qrZEHrK23wMgyO1DgrmXOQLDlXsA3bidgXn6wvh

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

-- Started on 2025-12-12 12:40:57

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
-- TOC entry 6 (class 2615 OID 16839)
-- Name: healthnet; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA healthnet;


ALTER SCHEMA healthnet OWNER TO postgres;

--
-- TOC entry 228 (class 1255 OID 16841)
-- Name: update_bill_totals(); Type: FUNCTION; Schema: healthnet; Owner: postgres
--

CREATE FUNCTION healthnet.update_bill_totals() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- On INSERT
    IF TG_OP = 'INSERT' THEN
        UPDATE bill
        SET total = COALESCE((
            SELECT SUM(amount)
            FROM bill_item
            WHERE bill_id = NEW.bill_id
        ), 0)
        WHERE id = NEW.bill_id;

    -- On DELETE
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE bill
        SET total = COALESCE((
            SELECT SUM(amount)
            FROM bill_item
            WHERE bill_id = OLD.bill_id
        ), 0)
        WHERE id = OLD.bill_id;

    -- On UPDATE
    ELSIF TG_OP = 'UPDATE' THEN

        IF NEW.bill_id IS DISTINCT FROM OLD.bill_id THEN
            UPDATE bill
            SET total = COALESCE((
                SELECT SUM(amount)
                FROM bill_item
                WHERE bill_id = OLD.bill_id
            ), 0)
            WHERE id = OLD.bill_id;

            UPDATE bill
            SET total = COALESCE((
                SELECT SUM(amount)
                FROM bill_item
                WHERE bill_id = NEW.bill_id
            ), 0)
            WHERE id = NEW.bill_id;

        ELSE
            UPDATE bill
            SET total = COALESCE((
                SELECT SUM(amount)
                FROM bill_item
                WHERE bill_id = NEW.bill_id
            ), 0)
            WHERE id = NEW.bill_id;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION healthnet.update_bill_totals() OWNER TO postgres;

--
-- TOC entry 229 (class 1255 OID 16842)
-- Name: update_bill_totals_row(); Type: FUNCTION; Schema: healthnet; Owner: postgres
--

CREATE FUNCTION healthnet.update_bill_totals_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE bill b
  SET total = COALESCE((
      SELECT SUM(amount)
      FROM bill_item bi
      WHERE bi.bill_id = b.id
  ), 0)
  WHERE b.id = COALESCE(NEW.bill_id, OLD.bill_id);

  RETURN NULL;
END;
$$;


ALTER FUNCTION healthnet.update_bill_totals_row() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16843)
-- Name: bill; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.bill (
    id integer NOT NULL,
    total numeric(12,2) DEFAULT 0
);


ALTER TABLE healthnet.bill OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16847)
-- Name: bill_audit; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.bill_audit (
    bill_id integer,
    old_total numeric(12,2),
    new_total numeric(12,2),
    changed_at timestamp without time zone DEFAULT now()
);


ALTER TABLE healthnet.bill_audit OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16851)
-- Name: bill_id_seq; Type: SEQUENCE; Schema: healthnet; Owner: postgres
--

CREATE SEQUENCE healthnet.bill_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE healthnet.bill_id_seq OWNER TO postgres;

--
-- TOC entry 4952 (class 0 OID 0)
-- Dependencies: 218
-- Name: bill_id_seq; Type: SEQUENCE OWNED BY; Schema: healthnet; Owner: postgres
--

ALTER SEQUENCE healthnet.bill_id_seq OWNED BY healthnet.bill.id;


--
-- TOC entry 219 (class 1259 OID 16852)
-- Name: bill_item; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.bill_item (
    bill_id integer,
    amount numeric(12,2),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE healthnet.bill_item OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16856)
-- Name: clinic; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.clinic (
    id integer NOT NULL,
    name character varying(100),
    lon double precision,
    lat double precision
);


ALTER TABLE healthnet.clinic OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16859)
-- Name: clinic_id_seq; Type: SEQUENCE; Schema: healthnet; Owner: postgres
--

CREATE SEQUENCE healthnet.clinic_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE healthnet.clinic_id_seq OWNER TO postgres;

--
-- TOC entry 4953 (class 0 OID 0)
-- Dependencies: 221
-- Name: clinic_id_seq; Type: SEQUENCE OWNED BY; Schema: healthnet; Owner: postgres
--

ALTER SEQUENCE healthnet.clinic_id_seq OWNED BY healthnet.clinic.id;


--
-- TOC entry 222 (class 1259 OID 16860)
-- Name: patient; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.patient (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE healthnet.patient OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16863)
-- Name: patient_id_seq; Type: SEQUENCE; Schema: healthnet; Owner: postgres
--

CREATE SEQUENCE healthnet.patient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE healthnet.patient_id_seq OWNER TO postgres;

--
-- TOC entry 4954 (class 0 OID 0)
-- Dependencies: 223
-- Name: patient_id_seq; Type: SEQUENCE OWNED BY; Schema: healthnet; Owner: postgres
--

ALTER SEQUENCE healthnet.patient_id_seq OWNED BY healthnet.patient.id;


--
-- TOC entry 224 (class 1259 OID 16864)
-- Name: patient_med; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.patient_med (
    patient_med_id integer NOT NULL,
    patient_id integer NOT NULL,
    med_name character varying(80) NOT NULL,
    dose_mg numeric(6,2),
    start_dt date NOT NULL,
    end_dt date NOT NULL,
    CONSTRAINT ck_rx_dates CHECK ((start_dt <= end_dt)),
    CONSTRAINT patient_med_dose_mg_check CHECK ((dose_mg >= (0)::numeric))
);


ALTER TABLE healthnet.patient_med OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16869)
-- Name: patient_med_patient_med_id_seq; Type: SEQUENCE; Schema: healthnet; Owner: postgres
--

CREATE SEQUENCE healthnet.patient_med_patient_med_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE healthnet.patient_med_patient_med_id_seq OWNER TO postgres;

--
-- TOC entry 4955 (class 0 OID 0)
-- Dependencies: 225
-- Name: patient_med_patient_med_id_seq; Type: SEQUENCE OWNED BY; Schema: healthnet; Owner: postgres
--

ALTER SEQUENCE healthnet.patient_med_patient_med_id_seq OWNED BY healthnet.patient_med.patient_med_id;


--
-- TOC entry 226 (class 1259 OID 16870)
-- Name: staff_supervisor; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.staff_supervisor (
    employee character varying(50),
    supervisor character varying(50)
);


ALTER TABLE healthnet.staff_supervisor OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16873)
-- Name: triple; Type: TABLE; Schema: healthnet; Owner: postgres
--

CREATE TABLE healthnet.triple (
    s character varying(100),
    p character varying(50),
    o character varying(100)
);


ALTER TABLE healthnet.triple OWNER TO postgres;

--
-- TOC entry 4769 (class 2604 OID 16876)
-- Name: bill id; Type: DEFAULT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.bill ALTER COLUMN id SET DEFAULT nextval('healthnet.bill_id_seq'::regclass);


--
-- TOC entry 4773 (class 2604 OID 16877)
-- Name: clinic id; Type: DEFAULT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.clinic ALTER COLUMN id SET DEFAULT nextval('healthnet.clinic_id_seq'::regclass);


--
-- TOC entry 4774 (class 2604 OID 16878)
-- Name: patient id; Type: DEFAULT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.patient ALTER COLUMN id SET DEFAULT nextval('healthnet.patient_id_seq'::regclass);


--
-- TOC entry 4775 (class 2604 OID 16879)
-- Name: patient_med patient_med_id; Type: DEFAULT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.patient_med ALTER COLUMN patient_med_id SET DEFAULT nextval('healthnet.patient_med_patient_med_id_seq'::regclass);


--
-- TOC entry 4935 (class 0 OID 16843)
-- Dependencies: 216
-- Data for Name: bill; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.bill (id, total) FROM stdin;
1	300.00
2	0.00
\.


--
-- TOC entry 4936 (class 0 OID 16847)
-- Dependencies: 217
-- Data for Name: bill_audit; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.bill_audit (bill_id, old_total, new_total, changed_at) FROM stdin;
1	\N	300.00	2025-12-12 12:20:08.276642
\.


--
-- TOC entry 4938 (class 0 OID 16852)
-- Dependencies: 219
-- Data for Name: bill_item; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.bill_item (bill_id, amount, updated_at) FROM stdin;
1	150.00	2025-11-01 13:51:02.727589
1	150.00	2025-11-01 13:51:02.727589
\.


--
-- TOC entry 4939 (class 0 OID 16856)
-- Dependencies: 220
-- Data for Name: clinic; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.clinic (id, name, lon, lat) FROM stdin;
1	Kigali Central	30.061	-1.9565
2	Remera Clinic	30.065	-1.96
3	Nyamirambo Health	30.05	-1.965
4	Gikondo Medical	30.08	-1.94
5	CHUK Hospital	30.059	-1.9585
\.


--
-- TOC entry 4941 (class 0 OID 16860)
-- Dependencies: 222
-- Data for Name: patient; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.patient (id, name) FROM stdin;
1	Alice
2	Bob
\.


--
-- TOC entry 4943 (class 0 OID 16864)
-- Dependencies: 224
-- Data for Name: patient_med; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.patient_med (patient_med_id, patient_id, med_name, dose_mg, start_dt, end_dt) FROM stdin;
1	1	Paracetamol	500.00	2025-01-01	2025-01-07
2	2	Amoxicillin	250.00	2025-02-01	2025-02-10
\.


--
-- TOC entry 4945 (class 0 OID 16870)
-- Dependencies: 226
-- Data for Name: staff_supervisor; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.staff_supervisor (employee, supervisor) FROM stdin;
Alice	Bob
Bob	Carol
Carol	Dana
Eve	Carol
Frank	Eve
\.


--
-- TOC entry 4946 (class 0 OID 16873)
-- Dependencies: 227
-- Data for Name: triple; Type: TABLE DATA; Schema: healthnet; Owner: postgres
--

COPY healthnet.triple (s, p, o) FROM stdin;
Patient1	hasDiagnosis	Influenza
Patient2	hasDiagnosis	Diabetes
Influenza	isA	ViralDisease
ViralDisease	isA	InfectiousDisease
COVID19	isA	ViralDisease
Patient3	hasDiagnosis	COVID19
Patient4	hasDiagnosis	Cold
Cold	isA	InfectiousDisease
\.


--
-- TOC entry 4956 (class 0 OID 0)
-- Dependencies: 218
-- Name: bill_id_seq; Type: SEQUENCE SET; Schema: healthnet; Owner: postgres
--

SELECT pg_catalog.setval('healthnet.bill_id_seq', 1, false);


--
-- TOC entry 4957 (class 0 OID 0)
-- Dependencies: 221
-- Name: clinic_id_seq; Type: SEQUENCE SET; Schema: healthnet; Owner: postgres
--

SELECT pg_catalog.setval('healthnet.clinic_id_seq', 5, true);


--
-- TOC entry 4958 (class 0 OID 0)
-- Dependencies: 223
-- Name: patient_id_seq; Type: SEQUENCE SET; Schema: healthnet; Owner: postgres
--

SELECT pg_catalog.setval('healthnet.patient_id_seq', 2, true);


--
-- TOC entry 4959 (class 0 OID 0)
-- Dependencies: 225
-- Name: patient_med_patient_med_id_seq; Type: SEQUENCE SET; Schema: healthnet; Owner: postgres
--

SELECT pg_catalog.setval('healthnet.patient_med_patient_med_id_seq', 4, true);


--
-- TOC entry 4779 (class 2606 OID 16881)
-- Name: bill bill_pkey; Type: CONSTRAINT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.bill
    ADD CONSTRAINT bill_pkey PRIMARY KEY (id);


--
-- TOC entry 4781 (class 2606 OID 16883)
-- Name: clinic clinic_pkey; Type: CONSTRAINT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.clinic
    ADD CONSTRAINT clinic_pkey PRIMARY KEY (id);


--
-- TOC entry 4785 (class 2606 OID 16885)
-- Name: patient_med patient_med_pkey; Type: CONSTRAINT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.patient_med
    ADD CONSTRAINT patient_med_pkey PRIMARY KEY (patient_med_id);


--
-- TOC entry 4783 (class 2606 OID 16887)
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id);


--
-- TOC entry 4788 (class 2620 OID 16888)
-- Name: bill_item trg_update_bill_totals_delete; Type: TRIGGER; Schema: healthnet; Owner: postgres
--

CREATE TRIGGER trg_update_bill_totals_delete AFTER DELETE ON healthnet.bill_item REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION healthnet.update_bill_totals();


--
-- TOC entry 4789 (class 2620 OID 16889)
-- Name: bill_item trg_update_bill_totals_insert; Type: TRIGGER; Schema: healthnet; Owner: postgres
--

CREATE TRIGGER trg_update_bill_totals_insert AFTER INSERT ON healthnet.bill_item REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION healthnet.update_bill_totals();


--
-- TOC entry 4790 (class 2620 OID 16890)
-- Name: bill_item trg_update_bill_totals_row; Type: TRIGGER; Schema: healthnet; Owner: postgres
--

CREATE TRIGGER trg_update_bill_totals_row AFTER INSERT OR DELETE OR UPDATE ON healthnet.bill_item FOR EACH ROW EXECUTE FUNCTION healthnet.update_bill_totals_row();


--
-- TOC entry 4791 (class 2620 OID 16891)
-- Name: bill_item trg_update_bill_totals_update; Type: TRIGGER; Schema: healthnet; Owner: postgres
--

CREATE TRIGGER trg_update_bill_totals_update AFTER UPDATE ON healthnet.bill_item REFERENCING OLD TABLE AS deleted NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION healthnet.update_bill_totals();


--
-- TOC entry 4786 (class 2606 OID 16892)
-- Name: bill_item bill_item_bill_id_fkey; Type: FK CONSTRAINT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.bill_item
    ADD CONSTRAINT bill_item_bill_id_fkey FOREIGN KEY (bill_id) REFERENCES healthnet.bill(id);


--
-- TOC entry 4787 (class 2606 OID 16897)
-- Name: patient_med patient_med_patient_id_fkey; Type: FK CONSTRAINT; Schema: healthnet; Owner: postgres
--

ALTER TABLE ONLY healthnet.patient_med
    ADD CONSTRAINT patient_med_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES healthnet.patient(id);


-- Completed on 2025-12-12 12:40:57

--
-- PostgreSQL database dump complete
--

\unrestrict yztgJ1gIuhQ0cgJdnpFxW9C6qrZEHrK23wMgyO1DgrmXOQLDlXsA3bidgXn6wvh

