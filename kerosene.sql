--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1)
-- Dumped by pg_dump version 17.5 (Debian 17.5-1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: users_credentials; Type: TABLE; Schema: public; Owner: astrofer
--

CREATE TABLE public.users_credentials (
    id integer NOT NULL,
    username character varying(50),
    passphrase character varying(64),
    creation_date timestamp with time zone DEFAULT now()
);


ALTER TABLE public.users_credentials OWNER TO astrofer;

--
-- Name: users_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: astrofer
--

CREATE SEQUENCE public.users_credentials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_credentials_id_seq OWNER TO astrofer;

--
-- Name: users_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astrofer
--

ALTER SEQUENCE public.users_credentials_id_seq OWNED BY public.users_credentials.id;


--
-- Name: users_credentials id; Type: DEFAULT; Schema: public; Owner: astrofer
--

ALTER TABLE ONLY public.users_credentials ALTER COLUMN id SET DEFAULT nextval('public.users_credentials_id_seq'::regclass);


--
-- Data for Name: users_credentials; Type: TABLE DATA; Schema: public; Owner: astrofer
--

COPY public.users_credentials (id, username, passphrase, creation_date) FROM stdin;
3	omega	d3-dd3dd3d-3e3d-d3d-d	2025-08-26 14:45:38.665027-05
4	xablau	7ge73ge-d-3d3e3e3	2025-08-29 13:17:49.619858-05
\.


--
-- Name: users_credentials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: astrofer
--

SELECT pg_catalog.setval('public.users_credentials_id_seq', 4, true);


--
-- Name: users_credentials users_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: astrofer
--

ALTER TABLE ONLY public.users_credentials
    ADD CONSTRAINT users_credentials_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

