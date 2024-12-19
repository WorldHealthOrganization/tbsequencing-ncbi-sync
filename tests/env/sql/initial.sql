--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3
-- Dumped by pg_dump version 14.6 (Homebrew)

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
-- Name: biosql; Type: SCHEMA; Schema: -; Owner: fdxuser
--

CREATE SCHEMA biosql;



--
-- Name: genphensql; Type: SCHEMA; Schema: -; Owner: fdxuser
--

CREATE SCHEMA genphensql;



--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- Name: constrain_taxon(); Type: FUNCTION; Schema: biosql; Owner: fdxuser
--

CREATE FUNCTION biosql.constrain_taxon() RETURNS integer
    LANGUAGE sql STRICT SECURITY DEFINER
    AS $$
CREATE RULE rule_taxon_i
       AS ON INSERT TO taxon
       WHERE (
             SELECT taxon_id FROM taxon
             WHERE ncbi_taxon_id = new.ncbi_taxon_id
             )
             IS NOT NULL
       DO INSTEAD NOTHING
;
SELECT 1;
$$;



--
-- Name: unconstrain_taxon(); Type: FUNCTION; Schema: biosql; Owner: fdxuser
--

CREATE FUNCTION biosql.unconstrain_taxon() RETURNS integer
    LANGUAGE sql STRICT SECURITY DEFINER
    AS $$
DROP RULE rule_taxon_i ON taxon;
SELECT 1;
$$;



--
-- Name: drop_indexes(); Type: FUNCTION; Schema: genphensql; Owner: fdxuser
--

CREATE FUNCTION genphensql.drop_indexes() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    i RECORD;
BEGIN
    FOR i IN
        (SELECT schemaname, indexname
         FROM pg_indexes
         WHERE schemaname IN ('public', 'genphensql'))
        LOOP
            EXECUTE 'DROP INDEX "' || i.schemaname || '"."' || i.indexname || '"';
        END LOOP;
    RETURN 1;
END;
$$;



--
-- Name: drop_materialized_views(); Type: FUNCTION; Schema: genphensql; Owner: fdxuser
--

CREATE FUNCTION genphensql.drop_materialized_views() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    i RECORD;
BEGIN
    FOR i IN
        (SELECT schemaname, matviewname
         FROM pg_matviews
         WHERE schemaname IN ('public', 'genphensql'))
        LOOP
            EXECUTE 'DROP MATERIALIZED VIEW IF EXISTS "' || i.schemaname || '"."' ||
                    i.matviewname || '" CASCADE';
        END LOOP;
    RETURN 1;
END;
$$;



--
-- Name: drop_primary_uniq_foreign_constraints(); Type: FUNCTION; Schema: genphensql; Owner: fdxuser
--

CREATE FUNCTION genphensql.drop_primary_uniq_foreign_constraints() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    i RECORD;
BEGIN
    FOR i IN
        (SELECT table_schema, table_name, constraint_name
         FROM information_schema.table_constraints
         WHERE table_schema IN ('public', 'genphensql')
           and constraint_type IN ('PRIMARY KEY', 'UNIQUE', 'FOREIGN KEY')
         ORDER BY array_position(array ['UNIQUE', 'FOREIGN KEY', 'PRIMARY KEY'],
                                 constraint_type::text))
        LOOP
            EXECUTE 'ALTER TABLE "' || i.table_schema || '"."' || i.table_name ||
                    '" DROP CONSTRAINT "' || i.constraint_name || '" CASCADE';
        END LOOP;
    RETURN 1;
END;
$$;



--
-- Name: drop_views(); Type: FUNCTION; Schema: genphensql; Owner: fdxuser
--

CREATE FUNCTION genphensql.drop_views() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    i RECORD;
BEGIN
    FOR i IN
        (SELECT table_schema, table_name
         FROM information_schema.views
         WHERE table_schema IN ('public', 'genphensql')
           and table_name !~ '^pg_')
        LOOP
            EXECUTE 'DROP VIEW IF EXISTS "' || i.table_schema || '"."' || i.table_name ||
                    '" CASCADE';
        END LOOP;
    RETURN 1;
END;
$$;



--
-- Name: biodatabase_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.biodatabase_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: biodatabase; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.biodatabase (
    biodatabase_id integer DEFAULT nextval('biosql.biodatabase_pk_seq'::regclass) NOT NULL,
    name character varying(128) NOT NULL,
    authority character varying(128),
    description text
);



--
-- Name: bioentry_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.bioentry_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: bioentry; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.bioentry (
    bioentry_id integer DEFAULT nextval('biosql.bioentry_pk_seq'::regclass) NOT NULL,
    biodatabase_id integer NOT NULL,
    taxon_id integer,
    name character varying(40) NOT NULL,
    accession character varying(128) NOT NULL,
    identifier character varying(40),
    division character varying(6),
    description text,
    version integer NOT NULL
);



--
-- Name: bioentry_dbxref; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.bioentry_dbxref (
    bioentry_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    rank integer
);



--
-- Name: bioentry_path; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.bioentry_path (
    object_bioentry_id integer NOT NULL,
    subject_bioentry_id integer NOT NULL,
    term_id integer NOT NULL,
    distance integer
);



--
-- Name: bioentry_qualifier_value; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.bioentry_qualifier_value (
    bioentry_id integer NOT NULL,
    term_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);



--
-- Name: bioentry_reference; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.bioentry_reference (
    bioentry_id integer NOT NULL,
    reference_id integer NOT NULL,
    start_pos integer,
    end_pos integer,
    rank integer DEFAULT 0 NOT NULL
);



--
-- Name: bioentry_relationship_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.bioentry_relationship_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: bioentry_relationship; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.bioentry_relationship (
    bioentry_relationship_id integer DEFAULT nextval('biosql.bioentry_relationship_pk_seq'::regclass) NOT NULL,
    object_bioentry_id integer NOT NULL,
    subject_bioentry_id integer NOT NULL,
    term_id integer NOT NULL,
    rank integer
);



--
-- Name: biosequence; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.biosequence (
    bioentry_id integer NOT NULL,
    version integer,
    length integer,
    alphabet character varying(10),
    seq text
);



--
-- Name: comment_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.comment_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: comment; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.comment (
    comment_id integer DEFAULT nextval('biosql.comment_pk_seq'::regclass) NOT NULL,
    bioentry_id integer NOT NULL,
    comment_text text NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);



--
-- Name: dbxref_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.dbxref_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: dbxref; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.dbxref (
    dbxref_id integer DEFAULT nextval('biosql.dbxref_pk_seq'::regclass) NOT NULL,
    dbname character varying(40) NOT NULL,
    accession character varying(128) NOT NULL,
    version integer NOT NULL
);



--
-- Name: dbxref_qualifier_value; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.dbxref_qualifier_value (
    dbxref_id integer NOT NULL,
    term_id integer NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    value text
);



--
-- Name: django_ses_sesstat; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.django_ses_sesstat (
    id integer NOT NULL,
    date date NOT NULL,
    delivery_attempts integer NOT NULL,
    bounces integer NOT NULL,
    complaints integer NOT NULL,
    rejects integer NOT NULL,
    CONSTRAINT django_ses_sesstat_bounces_check CHECK ((bounces >= 0)),
    CONSTRAINT django_ses_sesstat_complaints_check CHECK ((complaints >= 0)),
    CONSTRAINT django_ses_sesstat_delivery_attempts_check CHECK ((delivery_attempts >= 0)),
    CONSTRAINT django_ses_sesstat_rejects_check CHECK ((rejects >= 0))
);



--
-- Name: django_ses_sesstat_id_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

ALTER TABLE biosql.django_ses_sesstat ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME biosql.django_ses_sesstat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: location_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.location_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: location; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.location (
    location_id integer DEFAULT nextval('biosql.location_pk_seq'::regclass) NOT NULL,
    seqfeature_id integer NOT NULL,
    dbxref_id integer,
    term_id integer,
    start_pos integer,
    end_pos integer,
    strand integer DEFAULT 0 NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);



--
-- Name: location_qualifier_value; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.location_qualifier_value (
    location_id integer NOT NULL,
    term_id integer NOT NULL,
    value character varying(255) NOT NULL,
    int_value integer
);



--
-- Name: ontology_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.ontology_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: ontology; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.ontology (
    ontology_id integer DEFAULT nextval('biosql.ontology_pk_seq'::regclass) NOT NULL,
    name character varying(32) NOT NULL,
    definition text
);



--
-- Name: reference_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.reference_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: reference; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.reference (
    reference_id integer DEFAULT nextval('biosql.reference_pk_seq'::regclass) NOT NULL,
    dbxref_id integer,
    location text NOT NULL,
    title text,
    authors text,
    crc character varying(32)
);



--
-- Name: seqfeature_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.seqfeature_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: seqfeature; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.seqfeature (
    seqfeature_id integer DEFAULT nextval('biosql.seqfeature_pk_seq'::regclass) NOT NULL,
    bioentry_id integer NOT NULL,
    type_term_id integer NOT NULL,
    source_term_id integer NOT NULL,
    display_name character varying(64),
    rank integer DEFAULT 0 NOT NULL
);



--
-- Name: seqfeature_dbxref; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.seqfeature_dbxref (
    seqfeature_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    rank integer
);



--
-- Name: seqfeature_path; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.seqfeature_path (
    object_seqfeature_id integer NOT NULL,
    subject_seqfeature_id integer NOT NULL,
    term_id integer NOT NULL,
    distance integer
);



--
-- Name: seqfeature_qualifier_value; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.seqfeature_qualifier_value (
    seqfeature_id integer NOT NULL,
    term_id integer NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    value text NOT NULL
);



--
-- Name: seqfeature_relationship_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.seqfeature_relationship_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: seqfeature_relationship; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.seqfeature_relationship (
    seqfeature_relationship_id integer DEFAULT nextval('biosql.seqfeature_relationship_pk_seq'::regclass) NOT NULL,
    object_seqfeature_id integer NOT NULL,
    subject_seqfeature_id integer NOT NULL,
    term_id integer NOT NULL,
    rank integer
);



--
-- Name: taxon_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.taxon_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: taxon; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.taxon (
    taxon_id integer DEFAULT nextval('biosql.taxon_pk_seq'::regclass) NOT NULL,
    ncbi_taxon_id integer,
    parent_taxon_id integer,
    node_rank character varying(32),
    genetic_code smallint,
    mito_genetic_code smallint,
    left_value integer,
    right_value integer
);



--
-- Name: taxon_name; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.taxon_name (
    taxon_id integer NOT NULL,
    name character varying(255) NOT NULL,
    name_class character varying(32) NOT NULL
);



--
-- Name: term_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.term_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: term; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.term (
    term_id integer DEFAULT nextval('biosql.term_pk_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    definition text,
    identifier character varying(40),
    is_obsolete character(1),
    ontology_id integer NOT NULL
);



--
-- Name: term_dbxref; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.term_dbxref (
    term_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    rank integer
);



--
-- Name: term_path_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.term_path_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: term_path; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.term_path (
    term_path_id integer DEFAULT nextval('biosql.term_path_pk_seq'::regclass) NOT NULL,
    subject_term_id integer NOT NULL,
    predicate_term_id integer NOT NULL,
    object_term_id integer NOT NULL,
    ontology_id integer NOT NULL,
    distance integer
);



--
-- Name: term_relationship_pk_seq; Type: SEQUENCE; Schema: biosql; Owner: fdxuser
--

CREATE SEQUENCE biosql.term_relationship_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: term_relationship; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.term_relationship (
    term_relationship_id integer DEFAULT nextval('biosql.term_relationship_pk_seq'::regclass) NOT NULL,
    subject_term_id integer NOT NULL,
    predicate_term_id integer NOT NULL,
    object_term_id integer NOT NULL,
    ontology_id integer NOT NULL
);



--
-- Name: term_relationship_term; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.term_relationship_term (
    term_relationship_id integer NOT NULL,
    term_id integer NOT NULL
);



--
-- Name: term_synonym; Type: TABLE; Schema: biosql; Owner: fdxuser
--

CREATE TABLE biosql.term_synonym (
    synonym character varying(255) NOT NULL,
    term_id integer NOT NULL
);



--
-- Name: additional_sample_name; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.additional_sample_name (
    sample_id integer NOT NULL,
    db character varying NOT NULL,
    db_label character varying NOT NULL,
    sample_name_synonym character varying NOT NULL
);



--
-- Name: amplicon_target; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.amplicon_target (
    amplicon_target_id integer NOT NULL,
    amplicon_assay_name character varying,
    chromosome character varying NOT NULL,
    start integer NOT NULL,
    "end" integer NOT NULL,
    gene_db_crossref_id integer NOT NULL
);



--
-- Name: amplicon_target_amplicon_target_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.amplicon_target_amplicon_target_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: amplicon_target_amplicon_target_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.amplicon_target_amplicon_target_id_seq OWNED BY genphensql.amplicon_target.amplicon_target_id;


--
-- Name: annotation; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.annotation (
    annotation_id bigint NOT NULL,
    reference_db_crossref_id integer NOT NULL,
    hgvs_value character varying NOT NULL,
    predicted_effect character varying NOT NULL,
    distance_to_reference integer
);



--
-- Name: annotation_annotation_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.annotation_annotation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: annotation_annotation_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.annotation_annotation_id_seq OWNED BY genphensql.annotation.annotation_id;


--
-- Name: bioproject; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.bioproject (
    bioproject_id bigint,
    ncbi_xml_value xml
);



--
-- Name: epidemiological_cut_off_value; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.epidemiological_cut_off_value (
    drug_id integer NOT NULL,
    medium_name character varying NOT NULL,
    value double precision NOT NULL
);



--
-- Name: minimum_inhibitory_concentration_test; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.minimum_inhibitory_concentration_test (
    test_id bigint NOT NULL,
    sample_id integer NOT NULL,
    drug_id integer NOT NULL,
    plate character varying,
    mic_value numrange NOT NULL,
    submission_date date
);



--
-- Name: categorized_mic; Type: VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE VIEW genphensql.categorized_mic AS
 SELECT mic.test_id,
    mic.sample_id,
    mic.drug_id,
        CASE
            WHEN ((upper(mic.mic_value))::double precision <= ecoff.value) THEN 'S'::text
            WHEN ((lower(mic.mic_value))::double precision > ecoff.value) THEN 'R'::text
            ELSE NULL::text
        END AS category
   FROM (genphensql.minimum_inhibitory_concentration_test mic
     LEFT JOIN genphensql.epidemiological_cut_off_value ecoff ON (((mic.drug_id = ecoff.drug_id) AND ((mic.plate)::text = (ecoff.medium_name)::text))));



--
-- Name: drug; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.drug (
    drug_id integer NOT NULL,
    drug_name character varying NOT NULL,
    drug_code character varying NOT NULL
);



--
-- Name: drug_drug_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.drug_drug_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: drug_drug_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.drug_drug_id_seq OWNED BY genphensql.drug.drug_id;


--
-- Name: drug_synonym; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.drug_synonym (
    drug_id bigint,
    code character varying,
    drug_name_synonym character varying NOT NULL
);



--
-- Name: protein_id; Type: VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE VIEW genphensql.protein_id AS
 SELECT dbxref.dbxref_id AS protein_db_crossref_id,
    sdb.dbxref_id AS gene_db_crossref_id
   FROM ((biosql.dbxref
     JOIN biosql.seqfeature_qualifier_value sqv ON ((sqv.value = (dbxref.accession)::text)))
     JOIN biosql.seqfeature_dbxref sdb ON ((sdb.seqfeature_id = sqv.seqfeature_id)))
  WHERE ((dbxref.dbname)::text = 'Protein'::text);



--
-- Name: variant_to_annotation; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.variant_to_annotation (
    variant_id integer NOT NULL,
    annotation_id integer NOT NULL
);



--
-- Name: formatted_annotation_per_gene; Type: MATERIALIZED VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE MATERIALIZED VIEW genphensql.formatted_annotation_per_gene AS
 SELECT vartoannot1.variant_id,
    annot1.reference_db_crossref_id AS gene_id,
    annot1.predicted_effect,
    annot1.hgvs_value AS nucleotidic_annotation,
    protein_annotation.hgvs_value AS proteic_annotation,
    annot1.distance_to_reference
   FROM (((genphensql.variant_to_annotation vartoannot1
     JOIN genphensql.annotation annot1 ON ((annot1.annotation_id = vartoannot1.annotation_id)))
     JOIN biosql.dbxref ON ((dbxref.dbxref_id = annot1.reference_db_crossref_id)))
     LEFT JOIN ( SELECT vartoannot2.variant_id,
            protein_id.gene_db_crossref_id,
            annot2.reference_db_crossref_id,
            annot2.hgvs_value
           FROM ((genphensql.variant_to_annotation vartoannot2
             JOIN genphensql.annotation annot2 ON ((annot2.annotation_id = vartoannot2.annotation_id)))
             JOIN genphensql.protein_id ON ((protein_id.protein_db_crossref_id = annot2.reference_db_crossref_id)))) protein_annotation ON (((protein_annotation.variant_id = vartoannot1.variant_id) AND (protein_annotation.gene_db_crossref_id = annot1.reference_db_crossref_id))))
  WHERE ((protein_annotation.reference_db_crossref_id IS NOT NULL) OR ((((annot1.predicted_effect)::text = 'upstream_gene_variant'::text) AND (annot1.distance_to_reference < 408)) OR ((annot1.predicted_effect)::text = 'non_coding_transcript_exon_variant'::text)))
  WITH NO DATA;



--
-- Name: gene_drug_resistance_association; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.gene_drug_resistance_association (
    gene_db_crossref_id integer NOT NULL,
    drug_id integer NOT NULL,
    tier integer NOT NULL,
    id integer NOT NULL
);



--
-- Name: gene_drug_resistance_association_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.gene_drug_resistance_association_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: gene_drug_resistance_association_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.gene_drug_resistance_association_id_seq OWNED BY genphensql.gene_drug_resistance_association.id;


--
-- Name: gene_name; Type: VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE VIEW genphensql.gene_name AS
 SELECT sdb.dbxref_id AS gene_db_crossref_id,
    sqv.value AS gene_name
   FROM ((((biosql.seqfeature_dbxref sdb
     JOIN biosql.seqfeature_qualifier_value sqv ON ((sqv.seqfeature_id = sdb.seqfeature_id)))
     JOIN biosql.seqfeature ON ((sqv.seqfeature_id = seqfeature.seqfeature_id)))
     JOIN biosql.term ON (((term.term_id = sqv.term_id) AND ((term.name)::text = 'gene'::text))))
     JOIN biosql.term t2 ON (((t2.term_id = seqfeature.type_term_id) AND ((t2.name)::text = 'gene'::text))));



--
-- Name: genotype; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.genotype (
    genotype_id bigint NOT NULL,
    sample_id integer NOT NULL,
    variant_id integer NOT NULL,
    genotyper character varying NOT NULL,
    quality double precision NOT NULL,
    reference_ad integer NOT NULL,
    alternative_ad integer NOT NULL,
    total_dp integer NOT NULL,
    genotype_value character varying NOT NULL
);



--
-- Name: genotype_genotype_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.genotype_genotype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: genotype_genotype_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.genotype_genotype_id_seq OWNED BY genphensql.genotype.genotype_id;


--
-- Name: growth_medium; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.growth_medium (
    medium_id integer NOT NULL,
    medium_name character varying NOT NULL
);



--
-- Name: growth_medium_medium_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.growth_medium_medium_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: growth_medium_medium_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.growth_medium_medium_id_seq OWNED BY genphensql.growth_medium.medium_id;


--
-- Name: locus_sequencing_stats; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.locus_sequencing_stats (
    sample_id integer NOT NULL,
    gene_db_crossref_id integer NOT NULL,
    mean_depth double precision NOT NULL,
    coverage_10x double precision NOT NULL,
    coverage_15x double precision NOT NULL,
    coverage_20x double precision NOT NULL,
    coverage_30x double precision NOT NULL
);



--
-- Name: locus_tag; Type: VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE VIEW genphensql.locus_tag AS
 SELECT sdb.dbxref_id AS gene_db_crossref_id,
    sqv.value AS locus_tag_name
   FROM ((((biosql.seqfeature_dbxref sdb
     JOIN biosql.seqfeature_qualifier_value sqv ON ((sqv.seqfeature_id = sdb.seqfeature_id)))
     JOIN biosql.seqfeature ON ((sqv.seqfeature_id = seqfeature.seqfeature_id)))
     JOIN biosql.term ON (((term.term_id = sqv.term_id) AND ((term.name)::text = 'locus_tag'::text))))
     JOIN biosql.term t2 ON (((t2.term_id = seqfeature.type_term_id) AND ((t2.name)::text = 'gene'::text))));



--
-- Name: phenotypic_drug_susceptibility_test; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.phenotypic_drug_susceptibility_test (
    test_id bigint NOT NULL,
    sample_id integer NOT NULL,
    drug_id integer NOT NULL,
    medium_id integer,
    method_id integer,
    concentration double precision,
    test_result character(1) NOT NULL,
    submission_date date
);



--
-- Name: merged_mic_and_pdst; Type: VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE VIEW genphensql.merged_mic_and_pdst AS
 SELECT ('pDST'::text || ((phenotypic_drug_susceptibility_test.test_id)::character varying)::text) AS test_id,
    phenotypic_drug_susceptibility_test.sample_id,
    phenotypic_drug_susceptibility_test.drug_id,
    phenotypic_drug_susceptibility_test.test_result
   FROM genphensql.phenotypic_drug_susceptibility_test
UNION
 SELECT ('MIC'::text || ((categorized_mic.test_id)::character varying)::text) AS test_id,
    categorized_mic.sample_id,
    categorized_mic.drug_id,
    categorized_mic.category AS test_result
   FROM genphensql.categorized_mic;



--
-- Name: microdilution_plate_concentration; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.microdilution_plate_concentration (
    plate character varying NOT NULL,
    drug_id integer NOT NULL,
    concentration double precision NOT NULL
);



--
-- Name: minimum_inhibitory_concentration_test_test_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.minimum_inhibitory_concentration_test_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: minimum_inhibitory_concentration_test_test_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.minimum_inhibitory_concentration_test_test_id_seq OWNED BY genphensql.minimum_inhibitory_concentration_test.test_id;


--
-- Name: molecular_drug_resistance_test; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.molecular_drug_resistance_test (
    test_id bigint NOT NULL,
    sample_id bigint NOT NULL,
    test_name character varying NOT NULL,
    drug_id integer NOT NULL,
    test_result character(1) NOT NULL
);



--
-- Name: molecular_drug_resistance_test_test_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.molecular_drug_resistance_test_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: molecular_drug_resistance_test_test_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.molecular_drug_resistance_test_test_id_seq OWNED BY genphensql.molecular_drug_resistance_test.test_id;


--
-- Name: variant; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.variant (
    variant_id bigint NOT NULL,
    chromosome character varying NOT NULL,
    "position" integer NOT NULL,
    reference_nucleotide character varying NOT NULL,
    alternative_nucleotide character varying NOT NULL
);



--
-- Name: multiple_variant_decomposition; Type: MATERIALIZED VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE MATERIALIZED VIEW genphensql.multiple_variant_decomposition AS
 SELECT z.variant_id AS mnv_variant_id,
    v2.variant_id AS single_variant_id
   FROM (( SELECT variant.variant_id,
            variant."position",
            regexp_split_to_table((variant.reference_nucleotide)::text, '(?=([ATCG])+)'::text) AS ref,
            regexp_split_to_table((variant.alternative_nucleotide)::text, '(?=([ATCG])+)'::text) AS alt,
            generate_series(0, (length((variant.reference_nucleotide)::text) - 1)) AS shift
           FROM genphensql.variant
          WHERE ((length((variant.reference_nucleotide)::text) > 1) AND (length((variant.reference_nucleotide)::text) = length((variant.alternative_nucleotide)::text)))) z
     LEFT JOIN genphensql.variant v2 ON ((((v2.reference_nucleotide)::text = z.ref) AND ((v2.alternative_nucleotide)::text = z.alt) AND (v2."position" = (z."position" + z.shift)))))
  WHERE (z.ref <> z.alt)
  WITH NO DATA;



--
-- Name: patient; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.patient (
    patient_id bigint NOT NULL,
    gender character(1),
    age_at_sampling integer,
    disease character varying,
    new_tuberculosis_case boolean,
    previous_treatment_category character varying,
    treatment_regimen character varying,
    treatment_duration integer,
    treatment_outcome character varying,
    hiv_positive boolean
);



--
-- Name: patient_patient_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.patient_patient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: patient_patient_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.patient_patient_id_seq OWNED BY genphensql.patient.patient_id;


--
-- Name: phenotypic_drug_susceptibility_assessment_method; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.phenotypic_drug_susceptibility_assessment_method (
    method_id integer NOT NULL,
    method_name character varying NOT NULL
);



--
-- Name: phenotypic_drug_susceptibility_assessment_method_method_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.phenotypic_drug_susceptibility_assessment_method_method_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: phenotypic_drug_susceptibility_assessment_method_method_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.phenotypic_drug_susceptibility_assessment_method_method_id_seq OWNED BY genphensql.phenotypic_drug_susceptibility_assessment_method.method_id;


--
-- Name: phenotypic_drug_susceptibility_test_test_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.phenotypic_drug_susceptibility_test_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: phenotypic_drug_susceptibility_test_test_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.phenotypic_drug_susceptibility_test_test_id_seq OWNED BY genphensql.phenotypic_drug_susceptibility_test.test_id;


--
-- Name: phenotypic_drug_susceptiblity_test_who_category; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.phenotypic_drug_susceptiblity_test_who_category (
    drug_id integer NOT NULL,
    medium_id integer NOT NULL,
    concentration double precision NOT NULL,
    category character varying NOT NULL
);



--
-- Name: ranked_annotation; Type: MATERIALIZED VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE MATERIALIZED VIEW genphensql.ranked_annotation AS
 SELECT variant_to_annotation.variant_id,
    annotation.annotation_id,
    x.gene_name,
    annotation.predicted_effect,
    annotation.hgvs_value,
    annotation.distance_to_reference,
    rank() OVER (PARTITION BY variant_to_annotation.variant_id ORDER BY
        CASE
            WHEN ((((annotation.predicted_effect)::text <> 'synonymous_variant'::text) AND (protein_id.protein_db_crossref_id IS NOT NULL)) OR ((annotation.predicted_effect)::text = 'non_coding_transcript_exon_variant'::text)) THEN 1
            WHEN (((annotation.predicted_effect)::text = 'synonymous_variant'::text) AND (locustag1.locus_tag_name IS NOT NULL)) THEN 2
            WHEN ((annotation.predicted_effect)::text = ANY ((ARRAY['upstream_gene_variant'::character varying, 'downstream_gene_variant'::character varying])::text[])) THEN (annotation.distance_to_reference + 2)
            ELSE NULL::integer
        END) AS rank
   FROM ((((genphensql.variant_to_annotation
     JOIN genphensql.annotation USING (annotation_id))
     LEFT JOIN genphensql.locus_tag locustag1 ON ((locustag1.gene_db_crossref_id = annotation.reference_db_crossref_id)))
     LEFT JOIN genphensql.protein_id ON ((protein_id.protein_db_crossref_id = annotation.reference_db_crossref_id)))
     JOIN ( SELECT locustag2.gene_db_crossref_id,
            COALESCE(gene_name.gene_name, locustag2.locus_tag_name) AS gene_name
           FROM (genphensql.locus_tag locustag2
             LEFT JOIN genphensql.gene_name ON ((gene_name.gene_db_crossref_id = locustag2.gene_db_crossref_id)))) x ON ((x.gene_db_crossref_id = COALESCE(protein_id.gene_db_crossref_id, locustag1.gene_db_crossref_id))))
  WITH NO DATA;



--
-- Name: preferred_annotation; Type: MATERIALIZED VIEW; Schema: genphensql; Owner: fdxuser
--

CREATE MATERIALIZED VIEW genphensql.preferred_annotation AS
 SELECT ranked_annotation.variant_id,
    ranked_annotation.gene_name,
    ranked_annotation.predicted_effect,
    ranked_annotation.hgvs_value,
    ranked_annotation.distance_to_reference AS mii
   FROM genphensql.ranked_annotation
  WHERE (ranked_annotation.rank = 1)
  WITH NO DATA;



--
-- Name: promoter_distance; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.promoter_distance (
    gene_db_crossref_id integer NOT NULL,
    region_start integer NOT NULL,
    region_end integer NOT NULL
);



--
-- Name: sample; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.sample (
    sample_id bigint NOT NULL,
    biosample_id integer,
    sample_name character varying NOT NULL,
    sra_name character varying,
    ncbi_taxon_id integer NOT NULL,
    submission_date date,
    sampling_date daterange,
    country_id integer,
    additional_geographical_information character varying,
    latitude character varying,
    longitude character varying,
    isolation_source character varying,
    status character varying,
    last_status_change timestamp without time zone,
    patiend_id bigint
);



--
-- Name: sample_sample_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.sample_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: sample_sample_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.sample_sample_id_seq OWNED BY genphensql.sample.sample_id;


--
-- Name: smear_microscopy_results; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.smear_microscopy_results (
    test_id bigint NOT NULL,
    sample_id bigint NOT NULL,
    smear_result character varying
);



--
-- Name: smear_microscopy_results_test_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.smear_microscopy_results_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: smear_microscopy_results_test_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.smear_microscopy_results_test_id_seq OWNED BY genphensql.smear_microscopy_results.test_id;


--
-- Name: staged_genotype; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.staged_genotype (
    sample_id integer NOT NULL,
    chromosome character varying NOT NULL,
    "position" integer NOT NULL,
    variant_id integer,
    reference_nucleotide character varying NOT NULL,
    alternative_nucleotide character varying NOT NULL,
    genotyper character varying NOT NULL,
    quality double precision NOT NULL,
    reference_ad integer NOT NULL,
    alternative_ad integer NOT NULL,
    total_dp integer NOT NULL,
    genotype_value character varying NOT NULL
);



--
-- Name: staged_minimum_inhibitory_concentration_test; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.staged_minimum_inhibitory_concentration_test (
    sample_id integer NOT NULL,
    drug_id integer NOT NULL,
    plate character varying,
    mic_value character varying NOT NULL
);



--
-- Name: staged_variant_to_annotation; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.staged_variant_to_annotation (
    variant_id integer NOT NULL,
    locus_tag_name character varying NOT NULL,
    hgvs_value character varying NOT NULL,
    predicted_effect character varying NOT NULL,
    type character varying NOT NULL,
    distance_to_reference integer
);



--
-- Name: summary_sequencing_stats; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.summary_sequencing_stats (
    sample_id integer NOT NULL,
    median_depth double precision NOT NULL,
    coverage_10x double precision NOT NULL,
    coverage_15x double precision NOT NULL,
    coverage_20x double precision NOT NULL,
    coverage_30x double precision NOT NULL,
    raw_total_sequences bigint NOT NULL,
    filtered_sequences bigint NOT NULL,
    sequences bigint NOT NULL,
    is_sorted bigint NOT NULL,
    first_fragments bigint NOT NULL,
    last_fragments bigint NOT NULL,
    reads_mapped bigint NOT NULL,
    reads_mapped_and_paired bigint NOT NULL,
    reads_unmapped bigint NOT NULL,
    reads_properly_paired bigint NOT NULL,
    reads_paired bigint NOT NULL,
    reads_duplicated bigint NOT NULL,
    reads_mq_0 bigint NOT NULL,
    reads_qc_failed bigint NOT NULL,
    non_primary_alignments bigint NOT NULL,
    total_length bigint NOT NULL,
    total_first_fragment_length bigint NOT NULL,
    total_last_fragment_length bigint NOT NULL,
    bases_mapped bigint NOT NULL,
    bases_mapped_cigar bigint NOT NULL,
    bases_trimmed bigint NOT NULL,
    bases_duplicated bigint NOT NULL,
    mismatches bigint NOT NULL,
    error_rate double precision NOT NULL,
    average_length integer NOT NULL,
    average_first_fragment_length integer NOT NULL,
    average_last_fragment_length integer NOT NULL,
    maximum_length integer NOT NULL,
    maximum_first_fragment_length integer NOT NULL,
    maximum_last_fragment_length integer NOT NULL,
    average_quality double precision NOT NULL,
    insert_size_average double precision NOT NULL,
    insert_size_standard_deviation double precision NOT NULL,
    inward_oriented_pairs integer NOT NULL,
    outward_oriented_pairs integer NOT NULL,
    pairs_with_other_orientation integer NOT NULL,
    pairs_on_different_chromosomes integer NOT NULL,
    percentage_of_properly_paired_reads double precision NOT NULL
);



--
-- Name: taxonomy_stats; Type: TABLE; Schema: genphensql; Owner: fdxuser
--

CREATE TABLE genphensql.taxonomy_stats (
    sample_id integer NOT NULL,
    ncbi_taxon_id integer NOT NULL,
    value double precision NOT NULL
);



--
-- Name: variant_variant_id_seq; Type: SEQUENCE; Schema: genphensql; Owner: fdxuser
--

CREATE SEQUENCE genphensql.variant_variant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: variant_variant_id_seq; Type: SEQUENCE OWNED BY; Schema: genphensql; Owner: fdxuser
--

ALTER SEQUENCE genphensql.variant_variant_id_seq OWNED BY genphensql.variant.variant_id;


--
-- Name: account_emailaddress; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.account_emailaddress (
    id integer NOT NULL,
    email character varying(254) NOT NULL,
    verified boolean NOT NULL,
    "primary" boolean NOT NULL,
    user_id integer NOT NULL
);



--
-- Name: account_emailaddress_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.account_emailaddress ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.account_emailaddress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: account_emailconfirmation; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.account_emailconfirmation (
    id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    sent timestamp with time zone,
    key character varying(64) NOT NULL,
    email_address_id integer NOT NULL
);



--
-- Name: account_emailconfirmation_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.account_emailconfirmation ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.account_emailconfirmation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);



--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);



--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);



--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);



--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);



--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.auth_user_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.auth_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);



--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.auth_user_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: authtoken_token; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.authtoken_token (
    key character varying(40) NOT NULL,
    created timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);



--
-- Name: country; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.country (
    three_letters_code character(3) NOT NULL,
    two_letters_code character(2),
    country_id integer NOT NULL,
    country_usual_name character varying,
    country_official_name character varying
);



--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);



--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);



--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);



--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);



--
-- Name: django_site; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.django_site (
    id integer NOT NULL,
    domain character varying(100) NOT NULL,
    name character varying(50) NOT NULL
);



--
-- Name: django_site_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.django_site ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: genphen_formattedannotationpergene; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.genphen_formattedannotationpergene (
    id bigint NOT NULL,
    variant_id bigint NOT NULL,
    gene_db_crossref_id integer NOT NULL,
    predicted_effect character varying(1024) NOT NULL,
    nucleotidic_annotation character varying(1024) NOT NULL,
    proteic_annotation character varying(1024),
    distance_to_reference integer
);



--
-- Name: genphen_formattedannotationpergene_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.genphen_formattedannotationpergene ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.genphen_formattedannotationpergene_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: genphen_genotyperesistance; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.genphen_genotyperesistance (
    id bigint NOT NULL,
    resistance_flag character varying(10) NOT NULL,
    variant character varying(32768) NOT NULL,
    drug_id integer NOT NULL,
    sample_id bigint NOT NULL
);



--
-- Name: genphen_genotyperesistance_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.genphen_genotyperesistance ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.genphen_genotyperesistance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: identity_profile; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.identity_profile (
    user_id integer NOT NULL,
    institution_name character varying(1024) NOT NULL,
    institution_phone character varying(128) NOT NULL,
    institution_head_name character varying(1024) NOT NULL,
    institution_head_email character varying(254) NOT NULL,
    verification_state character varying(50) NOT NULL,
    institution_country_id character varying(3)
);



--
-- Name: overview_druggene; Type: MATERIALIZED VIEW; Schema: public; Owner: fdxuser
--

CREATE MATERIALIZED VIEW public.overview_druggene AS
 SELECT gdra.gene_db_crossref_id AS gene_db_crossref,
    gdra.drug_id AS drug,
    gn.gene_name,
    d.drug_name
   FROM ((genphensql.gene_drug_resistance_association gdra
     JOIN genphensql.gene_name gn ON ((gdra.gene_db_crossref_id = gn.gene_db_crossref_id)))
     JOIN genphensql.drug d ON ((gdra.drug_id = d.drug_id)))
  WITH NO DATA;



--
-- Name: overview_druggeneinfo; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.overview_druggeneinfo (
    id bigint NOT NULL,
    gene_name character varying(100) NOT NULL,
    gene_db_crossref integer,
    variant_name character varying(100) NOT NULL,
    start_pos integer,
    end_pos integer,
    nucleodic_ann_name character varying(100) NOT NULL,
    proteic_ann_name character varying(100) NOT NULL,
    consequence character varying(50) NOT NULL,
    resistant_count double precision NOT NULL,
    susceptble_count double precision NOT NULL,
    intermediate_count double precision NOT NULL,
    drug_id integer NOT NULL
);



--
-- Name: overview_druggeneinfo_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.overview_druggeneinfo ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.overview_druggeneinfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: overview_gene; Type: MATERIALIZED VIEW; Schema: public; Owner: fdxuser
--

CREATE MATERIALIZED VIEW public.overview_gene AS
 WITH terms_ranked AS (
         SELECT sd.dbxref_id,
            term.name,
            sqv.value,
            row_number() OVER (PARTITION BY sqv.value ORDER BY sqv.seqfeature_id DESC) AS rank
           FROM ((biosql.seqfeature_qualifier_value sqv
             JOIN biosql.seqfeature_dbxref sd ON ((sd.seqfeature_id = sqv.seqfeature_id)))
             JOIN biosql.term ON ((sqv.term_id = term.term_id)))
        ), terms AS (
         SELECT terms_ranked.dbxref_id,
            terms_ranked.name,
            terms_ranked.value
           FROM terms_ranked
          WHERE (terms_ranked.rank = 1)
        ), ranked_locations AS (
         SELECT sd.dbxref_id,
            l_1.start_pos,
            l_1.end_pos,
            l_1.strand,
            row_number() OVER (PARTITION BY sd.dbxref_id ORDER BY sd.seqfeature_id DESC) AS rank
           FROM (biosql.seqfeature_dbxref sd
             JOIN biosql.location l_1 ON ((sd.seqfeature_id = l_1.seqfeature_id)))
        ), locations AS (
         SELECT ranked_locations.dbxref_id,
            ranked_locations.start_pos,
            ranked_locations.end_pos,
            ranked_locations.strand
           FROM ranked_locations
          WHERE (ranked_locations.rank = 1)
        )
 SELECT d.accession AS ncbi_id,
    d.dbxref_id AS gene_db_crossref,
    l.start_pos,
    l.end_pos,
    l.strand,
    gene_name.value AS gene_name,
    locus_tag.value AS locus_tag,
    gene_description.value AS gene_description,
    gene_type.value AS gene_type,
    length(protein_sequence.value) AS protein_length
   FROM ((((((biosql.dbxref d
     JOIN locations l ON ((d.dbxref_id = l.dbxref_id)))
     LEFT JOIN terms gene_name ON (((gene_name.dbxref_id = d.dbxref_id) AND ((gene_name.name)::text = 'gene'::text))))
     LEFT JOIN terms locus_tag ON (((locus_tag.dbxref_id = d.dbxref_id) AND ((locus_tag.name)::text = 'locus_tag'::text))))
     LEFT JOIN terms gene_description ON (((gene_description.dbxref_id = d.dbxref_id) AND ((gene_description.name)::text = 'product'::text))))
     LEFT JOIN terms gene_type ON (((gene_type.dbxref_id = d.dbxref_id) AND ((gene_type.name)::text = 'protein_id'::text))))
     LEFT JOIN terms protein_sequence ON (((protein_sequence.dbxref_id = d.dbxref_id) AND ((protein_sequence.name)::text = 'translation'::text))))
  WHERE ((d.dbname)::text = 'GeneID'::text)
  WITH NO DATA;



--
-- Name: submission_pdstest; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_pdstest (
    id bigint NOT NULL,
    concentration double precision,
    test_result character varying(1),
    staging boolean NOT NULL,
    drug_id integer,
    medium_id integer,
    method_id integer,
    package_id bigint NOT NULL,
    sample_id bigint,
    sample_alias_id bigint NOT NULL
);



--
-- Name: submission_sample; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_sample (
    id bigint NOT NULL,
    biosample_id integer,
    submission_date date,
    sampling_date daterange,
    additional_geographical_information character varying(8192),
    latitude character varying(8192),
    longitude character varying(8192),
    isolation_source character varying(8192),
    bioanalysis_status character varying(50) NOT NULL,
    bioanalysis_status_changed_at date,
    origin character varying(128) NOT NULL,
    country_id character varying(3),
    ncbi_taxon_id integer NOT NULL,
    package_id bigint
);



--
-- Name: overview_sample_drug_result; Type: MATERIALIZED VIEW; Schema: public; Owner: fdxuser
--

CREATE MATERIALIZED VIEW public.overview_sample_drug_result AS
 WITH sample_drug_result_contradictory AS (
         SELECT DISTINCT sp.drug_id,
            sp.sample_id,
            sp.test_result
           FROM public.submission_pdstest sp
          WHERE ((sp.staging IS FALSE) AND (sp.sample_id IS NOT NULL))
        ), sample_drug AS (
         SELECT sdr_1.drug_id,
            sdr_1.sample_id
           FROM sample_drug_result_contradictory sdr_1
          GROUP BY sdr_1.drug_id, sdr_1.sample_id
         HAVING (count(sdr_1.test_result) = 1)
        )
 SELECT sdr.sample_id,
    ss.sampling_date,
    ss.country_id,
    sdr.drug_id,
    sdr.test_result
   FROM ((sample_drug_result_contradictory sdr
     JOIN sample_drug sd ON (((sd.drug_id = sdr.drug_id) AND (sd.sample_id = sdr.sample_id))))
     JOIN public.submission_sample ss ON ((ss.id = sdr.sample_id)))
  WITH NO DATA;



--
-- Name: overview_genedrugstats; Type: MATERIALIZED VIEW; Schema: public; Owner: fdxuser
--

CREATE MATERIALIZED VIEW public.overview_genedrugstats AS
 WITH overall_samples AS (
         SELECT count(DISTINCT genotype.sample_id) AS count
           FROM genphensql.genotype
        ), global_frequencies AS (
         SELECT genotype.variant_id,
            count(DISTINCT genotype.sample_id) AS total_samples,
            ((((count(DISTINCT genotype.sample_id))::numeric * 100.0) / (( SELECT overall_samples.count
                   FROM overall_samples))::numeric))::double precision AS global_frequency
           FROM genphensql.genotype
          GROUP BY genotype.variant_id
        )
 SELECT overview_gene.gene_name,
    overview_gene.gene_db_crossref,
    (overview_gene.start_pos + fapg.distance_to_reference) AS start_pos,
    (overview_gene.end_pos + fapg.distance_to_reference) AS end_pos,
    fapg.variant_id,
    ((((var."position" || '-'::text) || (var.reference_nucleotide)::text) || '-'::text) || (var.alternative_nucleotide)::text) AS variant_name,
    fapg.nucleotidic_annotation AS nucleodic_ann_name,
    fapg.proteic_annotation AS proteic_ann_name,
    fapg.predicted_effect AS consequence,
    gf.total_samples AS total_counts,
    gf.global_frequency,
    sdr.drug_id,
    sum(
        CASE
            WHEN ((sdr.test_result)::text = 'S'::text) THEN 1
            ELSE 0
        END) AS susceptible_count,
    sum(
        CASE
            WHEN ((sdr.test_result)::text = 'R'::text) THEN 1
            ELSE 0
        END) AS resistant_count,
    sum(
        CASE
            WHEN ((sdr.test_result)::text = 'I'::text) THEN 1
            ELSE 0
        END) AS intermediate_count
   FROM ((((((public.overview_gene
     JOIN public.genphen_formattedannotationpergene fapg ON ((fapg.gene_db_crossref_id = overview_gene.gene_db_crossref)))
     JOIN genphensql.variant var ON ((var.variant_id = fapg.variant_id)))
     JOIN genphensql.genotype g ON ((g.variant_id = fapg.variant_id)))
     JOIN global_frequencies gf ON ((gf.variant_id = g.variant_id)))
     JOIN public.overview_sample_drug_result sdr ON ((sdr.sample_id = g.sample_id)))
     JOIN genphensql.gene_drug_resistance_association gdra ON (((gdra.gene_db_crossref_id = overview_gene.gene_db_crossref) AND (gdra.drug_id = sdr.drug_id))))
  GROUP BY overview_gene.gene_name, overview_gene.gene_db_crossref, (overview_gene.start_pos + fapg.distance_to_reference), (overview_gene.end_pos + fapg.distance_to_reference), fapg.variant_id, fapg.nucleotidic_annotation, fapg.proteic_annotation, fapg.predicted_effect, var."position", var.reference_nucleotide, var.alternative_nucleotide, gf.global_frequency, gf.total_samples, sdr.drug_id
  WITH NO DATA;



--
-- Name: overview_genesearchhistory; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.overview_genesearchhistory (
    date timestamp with time zone NOT NULL,
    id bigint NOT NULL,
    gene_db_crossref_id integer,
    counter integer
);



--
-- Name: overview_genesearchhistory_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.overview_genesearchhistory ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.overview_genesearchhistory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: overview_sample_drug_result_stats; Type: MATERIALIZED VIEW; Schema: public; Owner: fdxuser
--

CREATE MATERIALIZED VIEW public.overview_sample_drug_result_stats AS
 SELECT overview_sample_drug_result.drug_id,
    overview_sample_drug_result.country_id,
    overview_sample_drug_result.sampling_date,
    sum(
        CASE
            WHEN ((overview_sample_drug_result.test_result)::text = 'S'::text) THEN 1
            ELSE 0
        END) AS susceptible,
    sum(
        CASE
            WHEN ((overview_sample_drug_result.test_result)::text = 'R'::text) THEN 1
            ELSE 0
        END) AS resistant,
    sum(
        CASE
            WHEN ((overview_sample_drug_result.test_result)::text = 'I'::text) THEN 1
            ELSE 0
        END) AS intermediate,
    'Pheno'::text AS resistance_type
   FROM public.overview_sample_drug_result
  GROUP BY overview_sample_drug_result.drug_id, overview_sample_drug_result.country_id, overview_sample_drug_result.sampling_date, 'Pheno'::text
UNION
 SELECT gr.drug_id,
    ss.country_id,
    ss.sampling_date,
    sum(
        CASE
            WHEN ((gr.resistance_flag)::text = 'S'::text) THEN 1
            ELSE 0
        END) AS susceptible,
    sum(
        CASE
            WHEN ((gr.resistance_flag)::text = 'R'::text) THEN 1
            ELSE 0
        END) AS resistant,
    sum(
        CASE
            WHEN ((gr.resistance_flag)::text = 'I'::text) THEN 1
            ELSE 0
        END) AS intermediate,
    'Geno'::text AS resistance_type
   FROM (public.genphen_genotyperesistance gr
     JOIN public.submission_sample ss ON ((ss.id = gr.sample_id)))
  GROUP BY gr.drug_id, ss.country_id, ss.sampling_date, 'Geno'::text
  WITH NO DATA;



--
-- Name: overview_global_resistance_stats; Type: MATERIALIZED VIEW; Schema: public; Owner: fdxuser
--

CREATE MATERIALIZED VIEW public.overview_global_resistance_stats AS
 WITH resistant AS (
         SELECT r.sample_id,
            array_agg(d.drug_name) AS drug_arr
           FROM (public.overview_sample_drug_result r
             JOIN genphensql.drug d ON ((d.drug_id = r.drug_id)))
          WHERE ((r.test_result)::text = 'R'::text)
          GROUP BY r.sample_id
        ), mono_resistant AS (
         SELECT resistant.sample_id,
            resistant.drug_arr
           FROM resistant
          WHERE (((((resistant.drug_arr)::text[] = ARRAY['Ethambutol'::text]) OR ((resistant.drug_arr)::text[] = ARRAY['Isoniazid'::text])) OR ((resistant.drug_arr)::text[] = ARRAY['Pyrazinamide'::text])) OR ((resistant.drug_arr)::text[] = ARRAY['Rifampicin'::text]))
        ), poly_resistant AS (
         SELECT resistant.sample_id,
            resistant.drug_arr
           FROM resistant
          WHERE ((( SELECT count(*) AS count
                   FROM ( SELECT unnest(resistant.drug_arr) AS unnest
                        INTERSECT
                         SELECT unnest(ARRAY['Ethambutol'::text, 'Isoniazid'::text, 'Pyrazinamide'::text, 'Rifampicin'::text]) AS unnest) intersection) > 1) AND ((resistant.drug_arr)::text[] <> ARRAY['Isoniazid'::text, 'Rifampicin'::text]))
        ), multidrug_resistant AS (
         SELECT resistant.sample_id,
            resistant.drug_arr
           FROM resistant
          WHERE (ARRAY['Isoniazid'::text, 'Rifampicin'::text] <@ (resistant.drug_arr)::text[])
        ), extensive_drug_resistant AS (
         SELECT multidrug_resistant.sample_id,
            multidrug_resistant.drug_arr
           FROM multidrug_resistant
          WHERE ((ARRAY['Fluoroquinolones'::text] <@ (multidrug_resistant.drug_arr)::text[]) AND (ARRAY['Capreomycin'::text, 'Kanamycin'::text, 'Amikacin'::text] && (multidrug_resistant.drug_arr)::text[]))
        ), rifampicin_resistant AS (
         SELECT count(osdrs.resistant) AS count
           FROM (public.overview_sample_drug_result_stats osdrs
             JOIN genphensql.drug d ON ((d.drug_id = osdrs.drug_id)))
          WHERE ((d.drug_name)::text = 'Rifampicin'::text)
        )
 SELECT ( SELECT count(*) AS count
           FROM public.submission_sample) AS total_samples,
    ( SELECT count(*) AS count
           FROM mono_resistant) AS mono_resistant,
    ( SELECT count(*) AS count
           FROM poly_resistant) AS poly_resistant,
    ( SELECT count(*) AS count
           FROM multidrug_resistant) AS multidrug_resistant,
    ( SELECT count(*) AS count
           FROM extensive_drug_resistant) AS extensive_drug_resistant,
    ( SELECT rifampicin_resistant.count
           FROM rifampicin_resistant) AS rifampicin_resistant
  WITH NO DATA;



--
-- Name: overview_globalsample; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.overview_globalsample (
    id bigint NOT NULL,
    resistance_type character varying(50) NOT NULL,
    date date NOT NULL,
    mono_res double precision,
    poly_res double precision,
    multi_drug_res double precision,
    ext_drug_res double precision,
    rif_res double precision,
    country_id_id character varying(3) NOT NULL
);



--
-- Name: overview_globalsample_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.overview_globalsample ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.overview_globalsample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: socialaccount_socialaccount; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.socialaccount_socialaccount (
    id integer NOT NULL,
    provider character varying(30) NOT NULL,
    uid character varying(191) NOT NULL,
    last_login timestamp with time zone NOT NULL,
    date_joined timestamp with time zone NOT NULL,
    extra_data text NOT NULL,
    user_id integer NOT NULL
);



--
-- Name: socialaccount_socialaccount_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.socialaccount_socialaccount ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.socialaccount_socialaccount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: socialaccount_socialapp; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.socialaccount_socialapp (
    id integer NOT NULL,
    provider character varying(30) NOT NULL,
    name character varying(40) NOT NULL,
    client_id character varying(191) NOT NULL,
    secret character varying(191) NOT NULL,
    key character varying(191) NOT NULL
);



--
-- Name: socialaccount_socialapp_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.socialaccount_socialapp ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.socialaccount_socialapp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: socialaccount_socialapp_sites; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.socialaccount_socialapp_sites (
    id bigint NOT NULL,
    socialapp_id integer NOT NULL,
    site_id integer NOT NULL
);



--
-- Name: socialaccount_socialapp_sites_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.socialaccount_socialapp_sites ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.socialaccount_socialapp_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: socialaccount_socialtoken; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.socialaccount_socialtoken (
    id integer NOT NULL,
    token text NOT NULL,
    token_secret text NOT NULL,
    expires_at timestamp with time zone,
    account_id integer NOT NULL,
    app_id integer NOT NULL
);



--
-- Name: socialaccount_socialtoken_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.socialaccount_socialtoken ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.socialaccount_socialtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_attachment; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_attachment (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    type character varying(32) NOT NULL,
    file character varying(100) NOT NULL,
    size bigint,
    original_filename character varying(1024),
    package_id bigint NOT NULL
);



--
-- Name: submission_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_attachment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_contributor; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_contributor (
    id bigint NOT NULL,
    first_name character varying(1024) NOT NULL,
    last_name character varying(1024) NOT NULL,
    role character varying(1024) NOT NULL,
    package_id bigint NOT NULL
);



--
-- Name: submission_contributor_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_contributor ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_message; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_message (
    id bigint NOT NULL,
    content text,
    "timestamp" timestamp with time zone NOT NULL,
    package_id bigint NOT NULL,
    sender_id integer NOT NULL
);



--
-- Name: submission_message_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_message ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_mictest; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_mictest (
    id bigint NOT NULL,
    plate character varying(8192) NOT NULL,
    range numrange,
    staging boolean NOT NULL,
    drug_id integer NOT NULL,
    package_id bigint NOT NULL,
    sample_id bigint,
    sample_alias_id bigint NOT NULL
);



--
-- Name: submission_mictest_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_mictest ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_mictest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_package; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_package (
    id bigint NOT NULL,
    submitted_on timestamp with time zone NOT NULL,
    state_changed_on timestamp with time zone NOT NULL,
    name character varying(1024) NOT NULL,
    description character varying(8192),
    state character varying(50) NOT NULL,
    origin character varying(1024) NOT NULL,
    bioproject_id integer,
    matching_state character varying(32) NOT NULL,
    rejection_reason text NOT NULL,
    owner_id integer
);



--
-- Name: submission_package_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_package ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_package_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_packagesequencingdata; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_packagesequencingdata (
    id bigint NOT NULL,
    verdicts jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL,
    filename character varying(1024) NOT NULL,
    package_id bigint NOT NULL,
    sequencing_data_id bigint NOT NULL,
    sequencing_data_hash_id bigint NOT NULL
);



--
-- Name: submission_packagesequencingdata_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_packagesequencingdata ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_packagesequencingdata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_packagestats; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_packagestats (
    id bigint NOT NULL,
    cnt_mic_tests integer NOT NULL,
    cnt_pds_tests integer NOT NULL,
    cnt_pds_drug_concentration integer NOT NULL,
    list_mic_drugs jsonb NOT NULL,
    list_pds_drugs jsonb NOT NULL,
    cnt_messages integer NOT NULL,
    cnt_sample_aliases integer NOT NULL,
    cnt_samples_matched integer NOT NULL,
    cnt_samples_created integer NOT NULL,
    cnt_sequencing_data integer NOT NULL,
    package_id bigint NOT NULL
);



--
-- Name: submission_packagestats_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_packagestats ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_packagestats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_pdstest_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_pdstest ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_pdstest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_sample ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_samplealias; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_samplealias (
    id bigint NOT NULL,
    verdicts jsonb NOT NULL,
    name character varying(2048) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    fastq_prefix character varying(2048),
    match_source character varying(64),
    sampling_date daterange,
    origin character varying(128) NOT NULL,
    origin_label character varying(1024) NOT NULL,
    country_id character varying(3),
    package_id bigint NOT NULL,
    sample_id bigint
);



--
-- Name: submission_samplealias_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_samplealias ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_samplealias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_sequencingdata; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_sequencingdata (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    filename character varying(100),
    file_size bigint,
    library_name character varying(8192) NOT NULL,
    file_path character varying(8192),
    data_location character varying(8192) NOT NULL,
    library_preparation_strategy character varying(8192),
    dna_source character varying(8192),
    dna_selection character varying(8192),
    sequencing_platform character varying(8192),
    sequencing_machine character varying(8192),
    library_layout character varying(8192),
    assay character varying(8192),
    sample_id bigint
);



--
-- Name: submission_sequencingdata_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_sequencingdata ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_sequencingdata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_sequencingdatahash; Type: TABLE; Schema: public; Owner: fdxuser
--

CREATE TABLE public.submission_sequencingdatahash (
    id bigint NOT NULL,
    algorithm character varying(8192) NOT NULL,
    value character varying(8192) NOT NULL,
    sequencing_data_id bigint NOT NULL
);



--
-- Name: submission_sequencingdatahash_id_seq; Type: SEQUENCE; Schema: public; Owner: fdxuser
--

ALTER TABLE public.submission_sequencingdatahash ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.submission_sequencingdatahash_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: amplicon_target amplicon_target_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.amplicon_target ALTER COLUMN amplicon_target_id SET DEFAULT nextval('genphensql.amplicon_target_amplicon_target_id_seq'::regclass);


--
-- Name: annotation annotation_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.annotation ALTER COLUMN annotation_id SET DEFAULT nextval('genphensql.annotation_annotation_id_seq'::regclass);


--
-- Name: drug drug_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.drug ALTER COLUMN drug_id SET DEFAULT nextval('genphensql.drug_drug_id_seq'::regclass);


--
-- Name: gene_drug_resistance_association id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.gene_drug_resistance_association ALTER COLUMN id SET DEFAULT nextval('genphensql.gene_drug_resistance_association_id_seq'::regclass);


--
-- Name: genotype genotype_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.genotype ALTER COLUMN genotype_id SET DEFAULT nextval('genphensql.genotype_genotype_id_seq'::regclass);


--
-- Name: growth_medium medium_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.growth_medium ALTER COLUMN medium_id SET DEFAULT nextval('genphensql.growth_medium_medium_id_seq'::regclass);


--
-- Name: minimum_inhibitory_concentration_test test_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.minimum_inhibitory_concentration_test ALTER COLUMN test_id SET DEFAULT nextval('genphensql.minimum_inhibitory_concentration_test_test_id_seq'::regclass);


--
-- Name: molecular_drug_resistance_test test_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.molecular_drug_resistance_test ALTER COLUMN test_id SET DEFAULT nextval('genphensql.molecular_drug_resistance_test_test_id_seq'::regclass);


--
-- Name: patient patient_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.patient ALTER COLUMN patient_id SET DEFAULT nextval('genphensql.patient_patient_id_seq'::regclass);


--
-- Name: phenotypic_drug_susceptibility_assessment_method method_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.phenotypic_drug_susceptibility_assessment_method ALTER COLUMN method_id SET DEFAULT nextval('genphensql.phenotypic_drug_susceptibility_assessment_method_method_id_seq'::regclass);


--
-- Name: phenotypic_drug_susceptibility_test test_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.phenotypic_drug_susceptibility_test ALTER COLUMN test_id SET DEFAULT nextval('genphensql.phenotypic_drug_susceptibility_test_test_id_seq'::regclass);


--
-- Name: sample sample_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.sample ALTER COLUMN sample_id SET DEFAULT nextval('genphensql.sample_sample_id_seq'::regclass);


--
-- Name: smear_microscopy_results test_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.smear_microscopy_results ALTER COLUMN test_id SET DEFAULT nextval('genphensql.smear_microscopy_results_test_id_seq'::regclass);


--
-- Name: variant variant_id; Type: DEFAULT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.variant ALTER COLUMN variant_id SET DEFAULT nextval('genphensql.variant_variant_id_seq'::regclass);


--
-- Name: biodatabase biodatabase_name_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.biodatabase
    ADD CONSTRAINT biodatabase_name_key UNIQUE (name);


--
-- Name: biodatabase biodatabase_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.biodatabase
    ADD CONSTRAINT biodatabase_pkey PRIMARY KEY (biodatabase_id);


--
-- Name: bioentry bioentry_accession_biodatabase_id_version_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry
    ADD CONSTRAINT bioentry_accession_biodatabase_id_version_key UNIQUE (accession, biodatabase_id, version);


--
-- Name: bioentry_dbxref bioentry_dbxref_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_dbxref
    ADD CONSTRAINT bioentry_dbxref_pkey PRIMARY KEY (bioentry_id, dbxref_id);


--
-- Name: bioentry bioentry_identifier_biodatabase_id_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry
    ADD CONSTRAINT bioentry_identifier_biodatabase_id_key UNIQUE (identifier, biodatabase_id);


--
-- Name: bioentry_path bioentry_path_object_bioentry_id_subject_bioentry_id_term_i_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_path
    ADD CONSTRAINT bioentry_path_object_bioentry_id_subject_bioentry_id_term_i_key UNIQUE (object_bioentry_id, subject_bioentry_id, term_id, distance);


--
-- Name: bioentry bioentry_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry
    ADD CONSTRAINT bioentry_pkey PRIMARY KEY (bioentry_id);


--
-- Name: bioentry_qualifier_value bioentry_qualifier_value_bioentry_id_term_id_rank_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_qualifier_value
    ADD CONSTRAINT bioentry_qualifier_value_bioentry_id_term_id_rank_key UNIQUE (bioentry_id, term_id, rank);


--
-- Name: bioentry_reference bioentry_reference_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_reference
    ADD CONSTRAINT bioentry_reference_pkey PRIMARY KEY (bioentry_id, reference_id, rank);


--
-- Name: bioentry_relationship bioentry_relationship_object_bioentry_id_subject_bioentry_i_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_relationship
    ADD CONSTRAINT bioentry_relationship_object_bioentry_id_subject_bioentry_i_key UNIQUE (object_bioentry_id, subject_bioentry_id, term_id);


--
-- Name: bioentry_relationship bioentry_relationship_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_relationship
    ADD CONSTRAINT bioentry_relationship_pkey PRIMARY KEY (bioentry_relationship_id);


--
-- Name: biosequence biosequence_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.biosequence
    ADD CONSTRAINT biosequence_pkey PRIMARY KEY (bioentry_id);


--
-- Name: comment comment_bioentry_id_rank_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.comment
    ADD CONSTRAINT comment_bioentry_id_rank_key UNIQUE (bioentry_id, rank);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (comment_id);


--
-- Name: dbxref dbxref_accession_dbname_version_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.dbxref
    ADD CONSTRAINT dbxref_accession_dbname_version_key UNIQUE (accession, dbname, version);


--
-- Name: dbxref dbxref_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.dbxref
    ADD CONSTRAINT dbxref_pkey PRIMARY KEY (dbxref_id);


--
-- Name: dbxref_qualifier_value dbxref_qualifier_value_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.dbxref_qualifier_value
    ADD CONSTRAINT dbxref_qualifier_value_pkey PRIMARY KEY (dbxref_id, term_id, rank);


--
-- Name: django_ses_sesstat django_ses_sesstat_date_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.django_ses_sesstat
    ADD CONSTRAINT django_ses_sesstat_date_key UNIQUE (date);


--
-- Name: django_ses_sesstat django_ses_sesstat_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.django_ses_sesstat
    ADD CONSTRAINT django_ses_sesstat_pkey PRIMARY KEY (id);


--
-- Name: location location_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (location_id);


--
-- Name: location_qualifier_value location_qualifier_value_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location_qualifier_value
    ADD CONSTRAINT location_qualifier_value_pkey PRIMARY KEY (location_id, term_id);


--
-- Name: location location_seqfeature_id_rank_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location
    ADD CONSTRAINT location_seqfeature_id_rank_key UNIQUE (seqfeature_id, rank);


--
-- Name: ontology ontology_name_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.ontology
    ADD CONSTRAINT ontology_name_key UNIQUE (name);


--
-- Name: ontology ontology_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.ontology
    ADD CONSTRAINT ontology_pkey PRIMARY KEY (ontology_id);


--
-- Name: reference reference_crc_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.reference
    ADD CONSTRAINT reference_crc_key UNIQUE (crc);


--
-- Name: reference reference_dbxref_id_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.reference
    ADD CONSTRAINT reference_dbxref_id_key UNIQUE (dbxref_id);


--
-- Name: reference reference_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (reference_id);


--
-- Name: seqfeature seqfeature_bioentry_id_type_term_id_source_term_id_rank_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature
    ADD CONSTRAINT seqfeature_bioentry_id_type_term_id_source_term_id_rank_key UNIQUE (bioentry_id, type_term_id, source_term_id, rank);


--
-- Name: seqfeature_dbxref seqfeature_dbxref_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_dbxref
    ADD CONSTRAINT seqfeature_dbxref_pkey PRIMARY KEY (seqfeature_id, dbxref_id);


--
-- Name: seqfeature_path seqfeature_path_object_seqfeature_id_subject_seqfeature_id__key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_path
    ADD CONSTRAINT seqfeature_path_object_seqfeature_id_subject_seqfeature_id__key UNIQUE (object_seqfeature_id, subject_seqfeature_id, term_id, distance);


--
-- Name: seqfeature seqfeature_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature
    ADD CONSTRAINT seqfeature_pkey PRIMARY KEY (seqfeature_id);


--
-- Name: seqfeature_qualifier_value seqfeature_qualifier_value_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_qualifier_value
    ADD CONSTRAINT seqfeature_qualifier_value_pkey PRIMARY KEY (seqfeature_id, term_id, rank);


--
-- Name: seqfeature_relationship seqfeature_relationship_object_seqfeature_id_subject_seqfea_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_relationship
    ADD CONSTRAINT seqfeature_relationship_object_seqfeature_id_subject_seqfea_key UNIQUE (object_seqfeature_id, subject_seqfeature_id, term_id);


--
-- Name: seqfeature_relationship seqfeature_relationship_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_relationship
    ADD CONSTRAINT seqfeature_relationship_pkey PRIMARY KEY (seqfeature_relationship_id);


--
-- Name: taxon_name taxon_name_name_name_class_taxon_id_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.taxon_name
    ADD CONSTRAINT taxon_name_name_name_class_taxon_id_key UNIQUE (name, name_class, taxon_id);


--
-- Name: taxon taxon_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.taxon
    ADD CONSTRAINT taxon_pkey PRIMARY KEY (taxon_id);


--
-- Name: term_dbxref term_dbxref_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_dbxref
    ADD CONSTRAINT term_dbxref_pkey PRIMARY KEY (term_id, dbxref_id);


--
-- Name: term term_identifier_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term
    ADD CONSTRAINT term_identifier_key UNIQUE (identifier);


--
-- Name: term term_name_ontology_id_is_obsolete_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term
    ADD CONSTRAINT term_name_ontology_id_is_obsolete_key UNIQUE (name, ontology_id, is_obsolete);


--
-- Name: term_path term_path_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_path
    ADD CONSTRAINT term_path_pkey PRIMARY KEY (term_path_id);


--
-- Name: term_path term_path_subject_term_id_predicate_term_id_object_term_id__key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_path
    ADD CONSTRAINT term_path_subject_term_id_predicate_term_id_object_term_id__key UNIQUE (subject_term_id, predicate_term_id, object_term_id, ontology_id, distance);


--
-- Name: term term_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term
    ADD CONSTRAINT term_pkey PRIMARY KEY (term_id);


--
-- Name: term_relationship term_relationship_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship
    ADD CONSTRAINT term_relationship_pkey PRIMARY KEY (term_relationship_id);


--
-- Name: term_relationship term_relationship_subject_term_id_predicate_term_id_object__key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship
    ADD CONSTRAINT term_relationship_subject_term_id_predicate_term_id_object__key UNIQUE (subject_term_id, predicate_term_id, object_term_id, ontology_id);


--
-- Name: term_relationship_term term_relationship_term_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship_term
    ADD CONSTRAINT term_relationship_term_pkey PRIMARY KEY (term_relationship_id);


--
-- Name: term_relationship_term term_relationship_term_term_id_key; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship_term
    ADD CONSTRAINT term_relationship_term_term_id_key UNIQUE (term_id);


--
-- Name: term_synonym term_synonym_pkey; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_synonym
    ADD CONSTRAINT term_synonym_pkey PRIMARY KEY (term_id, synonym);


--
-- Name: taxon xaktaxon_left_value; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.taxon
    ADD CONSTRAINT xaktaxon_left_value UNIQUE (left_value);


--
-- Name: taxon xaktaxon_ncbi_taxon_id; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.taxon
    ADD CONSTRAINT xaktaxon_ncbi_taxon_id UNIQUE (ncbi_taxon_id);


--
-- Name: taxon xaktaxon_right_value; Type: CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.taxon
    ADD CONSTRAINT xaktaxon_right_value UNIQUE (right_value);


--
-- Name: amplicon_target amplicon_target_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.amplicon_target
    ADD CONSTRAINT amplicon_target_pkey PRIMARY KEY (amplicon_target_id);


--
-- Name: annotation annotation_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.annotation
    ADD CONSTRAINT annotation_pkey PRIMARY KEY (annotation_id);


--
-- Name: drug drug_drug_code_key; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.drug
    ADD CONSTRAINT drug_drug_code_key UNIQUE (drug_code);


--
-- Name: drug drug_drug_name_key; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.drug
    ADD CONSTRAINT drug_drug_name_key UNIQUE (drug_name);


--
-- Name: drug drug_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.drug
    ADD CONSTRAINT drug_pkey PRIMARY KEY (drug_id);


--
-- Name: drug_synonym drug_synonym_drug_name_synonym_key; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.drug_synonym
    ADD CONSTRAINT drug_synonym_drug_name_synonym_key UNIQUE (drug_name_synonym);


--
-- Name: gene_drug_resistance_association gene_drug_resistance_association_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.gene_drug_resistance_association
    ADD CONSTRAINT gene_drug_resistance_association_pkey PRIMARY KEY (id);


--
-- Name: growth_medium growth_medium_medium_name_key; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.growth_medium
    ADD CONSTRAINT growth_medium_medium_name_key UNIQUE (medium_name);


--
-- Name: growth_medium growth_medium_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.growth_medium
    ADD CONSTRAINT growth_medium_pkey PRIMARY KEY (medium_id);


--
-- Name: phenotypic_drug_susceptibility_assessment_method phenotypic_drug_susceptibility_assessment_metho_method_name_key; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.phenotypic_drug_susceptibility_assessment_method
    ADD CONSTRAINT phenotypic_drug_susceptibility_assessment_metho_method_name_key UNIQUE (method_name);


--
-- Name: phenotypic_drug_susceptibility_assessment_method phenotypic_drug_susceptibility_assessment_method_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.phenotypic_drug_susceptibility_assessment_method
    ADD CONSTRAINT phenotypic_drug_susceptibility_assessment_method_pkey PRIMARY KEY (method_id);


--
-- Name: variant variant_pkey; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.variant
    ADD CONSTRAINT variant_pkey PRIMARY KEY (variant_id);


--
-- Name: variant_to_annotation variant_to_annotation_variant_id_annotation_id_key; Type: CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.variant_to_annotation
    ADD CONSTRAINT variant_to_annotation_variant_id_annotation_id_key UNIQUE (variant_id, annotation_id);


--
-- Name: account_emailaddress account_emailaddress_email_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.account_emailaddress
    ADD CONSTRAINT account_emailaddress_email_key UNIQUE (email);


--
-- Name: account_emailaddress account_emailaddress_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.account_emailaddress
    ADD CONSTRAINT account_emailaddress_pkey PRIMARY KEY (id);


--
-- Name: account_emailconfirmation account_emailconfirmation_key_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.account_emailconfirmation
    ADD CONSTRAINT account_emailconfirmation_key_key UNIQUE (key);


--
-- Name: account_emailconfirmation account_emailconfirmation_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.account_emailconfirmation
    ADD CONSTRAINT account_emailconfirmation_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- Name: authtoken_token authtoken_token_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_pkey PRIMARY KEY (key);


--
-- Name: authtoken_token authtoken_token_user_id_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_key UNIQUE (user_id);


--
-- Name: country country_country_id_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_country_id_key UNIQUE (country_id);


--
-- Name: country country_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (three_letters_code);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: django_site django_site_domain_a2e37b91_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_site
    ADD CONSTRAINT django_site_domain_a2e37b91_uniq UNIQUE (domain);


--
-- Name: django_site django_site_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_site
    ADD CONSTRAINT django_site_pkey PRIMARY KEY (id);


--
-- Name: genphen_formattedannotationpergene genphen_formattedannotationpergene_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.genphen_formattedannotationpergene
    ADD CONSTRAINT genphen_formattedannotationpergene_pkey PRIMARY KEY (id);


--
-- Name: genphen_genotyperesistance genphen_genotyperesistance_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.genphen_genotyperesistance
    ADD CONSTRAINT genphen_genotyperesistance_pkey PRIMARY KEY (id);


--
-- Name: identity_profile identity_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.identity_profile
    ADD CONSTRAINT identity_profile_pkey PRIMARY KEY (user_id);


--
-- Name: overview_druggeneinfo overview_druggeneinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.overview_druggeneinfo
    ADD CONSTRAINT overview_druggeneinfo_pkey PRIMARY KEY (id);


--
-- Name: overview_genesearchhistory overview_genesearchhistory_gene_db_crossref_id_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.overview_genesearchhistory
    ADD CONSTRAINT overview_genesearchhistory_gene_db_crossref_id_key UNIQUE (gene_db_crossref_id);


--
-- Name: overview_genesearchhistory overview_genesearchhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.overview_genesearchhistory
    ADD CONSTRAINT overview_genesearchhistory_pkey PRIMARY KEY (id);


--
-- Name: overview_globalsample overview_globalsample_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.overview_globalsample
    ADD CONSTRAINT overview_globalsample_pkey PRIMARY KEY (id);


--
-- Name: socialaccount_socialaccount socialaccount_socialaccount_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialaccount
    ADD CONSTRAINT socialaccount_socialaccount_pkey PRIMARY KEY (id);


--
-- Name: socialaccount_socialaccount socialaccount_socialaccount_provider_uid_fc810c6e_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialaccount
    ADD CONSTRAINT socialaccount_socialaccount_provider_uid_fc810c6e_uniq UNIQUE (provider, uid);


--
-- Name: socialaccount_socialapp_sites socialaccount_socialapp__socialapp_id_site_id_71a9a768_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialapp_sites
    ADD CONSTRAINT socialaccount_socialapp__socialapp_id_site_id_71a9a768_uniq UNIQUE (socialapp_id, site_id);


--
-- Name: socialaccount_socialapp socialaccount_socialapp_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialapp
    ADD CONSTRAINT socialaccount_socialapp_pkey PRIMARY KEY (id);


--
-- Name: socialaccount_socialapp_sites socialaccount_socialapp_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialapp_sites
    ADD CONSTRAINT socialaccount_socialapp_sites_pkey PRIMARY KEY (id);


--
-- Name: socialaccount_socialtoken socialaccount_socialtoken_app_id_account_id_fca4e0ac_uniq; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialtoken
    ADD CONSTRAINT socialaccount_socialtoken_app_id_account_id_fca4e0ac_uniq UNIQUE (app_id, account_id);


--
-- Name: socialaccount_socialtoken socialaccount_socialtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialtoken
    ADD CONSTRAINT socialaccount_socialtoken_pkey PRIMARY KEY (id);


--
-- Name: submission_attachment submission_attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_attachment
    ADD CONSTRAINT submission_attachment_pkey PRIMARY KEY (id);


--
-- Name: submission_contributor submission_contributor_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_contributor
    ADD CONSTRAINT submission_contributor_pkey PRIMARY KEY (id);


--
-- Name: submission_message submission_message_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_message
    ADD CONSTRAINT submission_message_pkey PRIMARY KEY (id);


--
-- Name: submission_mictest submission_mictest_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_mictest
    ADD CONSTRAINT submission_mictest_pkey PRIMARY KEY (id);


--
-- Name: submission_package submission_package_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_package
    ADD CONSTRAINT submission_package_pkey PRIMARY KEY (id);


--
-- Name: submission_packagesequencingdata submission_packagesequencingdata_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagesequencingdata
    ADD CONSTRAINT submission_packagesequencingdata_pkey PRIMARY KEY (id);


--
-- Name: submission_packagestats submission_packagestats_package_id_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagestats
    ADD CONSTRAINT submission_packagestats_package_id_key UNIQUE (package_id);


--
-- Name: submission_packagestats submission_packagestats_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagestats
    ADD CONSTRAINT submission_packagestats_pkey PRIMARY KEY (id);


--
-- Name: submission_pdstest submission_pdstest_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_pkey PRIMARY KEY (id);


--
-- Name: submission_sample submission_sample_biosample_id_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sample
    ADD CONSTRAINT submission_sample_biosample_id_key UNIQUE (biosample_id);


--
-- Name: submission_sample submission_sample_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sample
    ADD CONSTRAINT submission_sample_pkey PRIMARY KEY (id);


--
-- Name: submission_samplealias submission_samplealias_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_samplealias
    ADD CONSTRAINT submission_samplealias_pkey PRIMARY KEY (id);


--
-- Name: submission_sequencingdata submission_sequencingdata_file_path_key; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sequencingdata
    ADD CONSTRAINT submission_sequencingdata_file_path_key UNIQUE (file_path);


--
-- Name: submission_sequencingdata submission_sequencingdata_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sequencingdata
    ADD CONSTRAINT submission_sequencingdata_pkey PRIMARY KEY (id);


--
-- Name: submission_sequencingdatahash submission_sequencingdatahash_pkey; Type: CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sequencingdatahash
    ADD CONSTRAINT submission_sequencingdatahash_pkey PRIMARY KEY (id);


--
-- Name: bioentry_db; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentry_db ON biosql.bioentry USING btree (biodatabase_id);


--
-- Name: bioentry_name; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentry_name ON biosql.bioentry USING btree (name);


--
-- Name: bioentry_tax; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentry_tax ON biosql.bioentry USING btree (taxon_id);


--
-- Name: bioentrypath_child; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentrypath_child ON biosql.bioentry_path USING btree (subject_bioentry_id);


--
-- Name: bioentrypath_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentrypath_trm ON biosql.bioentry_path USING btree (term_id);


--
-- Name: bioentryqual_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentryqual_trm ON biosql.bioentry_qualifier_value USING btree (term_id);


--
-- Name: bioentryref_ref; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentryref_ref ON biosql.bioentry_reference USING btree (reference_id);


--
-- Name: bioentryrel_child; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentryrel_child ON biosql.bioentry_relationship USING btree (subject_bioentry_id);


--
-- Name: bioentryrel_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX bioentryrel_trm ON biosql.bioentry_relationship USING btree (term_id);


--
-- Name: db_auth; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX db_auth ON biosql.biodatabase USING btree (authority);


--
-- Name: dblink_dbx; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX dblink_dbx ON biosql.bioentry_dbxref USING btree (dbxref_id);


--
-- Name: dbxref_db; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX dbxref_db ON biosql.dbxref USING btree (dbname);


--
-- Name: dbxrefqual_dbx; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX dbxrefqual_dbx ON biosql.dbxref_qualifier_value USING btree (dbxref_id);


--
-- Name: dbxrefqual_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX dbxrefqual_trm ON biosql.dbxref_qualifier_value USING btree (term_id);


--
-- Name: feadblink_dbx; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX feadblink_dbx ON biosql.seqfeature_dbxref USING btree (dbxref_id);


--
-- Name: locationqual_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX locationqual_trm ON biosql.location_qualifier_value USING btree (term_id);


--
-- Name: seqfeature_fsrc; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeature_fsrc ON biosql.seqfeature USING btree (source_term_id);


--
-- Name: seqfeature_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeature_trm ON biosql.seqfeature USING btree (type_term_id);


--
-- Name: seqfeatureloc_dbx; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeatureloc_dbx ON biosql.location USING btree (dbxref_id);


--
-- Name: seqfeatureloc_start; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeatureloc_start ON biosql.location USING btree (start_pos, end_pos);


--
-- Name: seqfeatureloc_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeatureloc_trm ON biosql.location USING btree (term_id);


--
-- Name: seqfeaturepath_child; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeaturepath_child ON biosql.seqfeature_path USING btree (subject_seqfeature_id);


--
-- Name: seqfeaturepath_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeaturepath_trm ON biosql.seqfeature_path USING btree (term_id);


--
-- Name: seqfeaturequal_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeaturequal_trm ON biosql.seqfeature_qualifier_value USING btree (term_id);


--
-- Name: seqfeaturerel_child; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeaturerel_child ON biosql.seqfeature_relationship USING btree (subject_seqfeature_id);


--
-- Name: seqfeaturerel_trm; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX seqfeaturerel_trm ON biosql.seqfeature_relationship USING btree (term_id);


--
-- Name: taxnamename; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX taxnamename ON biosql.taxon_name USING btree (name);


--
-- Name: taxnametaxonid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX taxnametaxonid ON biosql.taxon_name USING btree (taxon_id);


--
-- Name: taxparent; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX taxparent ON biosql.taxon USING btree (parent_taxon_id);


--
-- Name: term_ont; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX term_ont ON biosql.term USING btree (ontology_id);


--
-- Name: trmdbxref_dbxrefid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmdbxref_dbxrefid ON biosql.term_dbxref USING btree (dbxref_id);


--
-- Name: trmpath_objectid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmpath_objectid ON biosql.term_path USING btree (object_term_id);


--
-- Name: trmpath_ontid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmpath_ontid ON biosql.term_path USING btree (ontology_id);


--
-- Name: trmpath_predicateid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmpath_predicateid ON biosql.term_path USING btree (predicate_term_id);


--
-- Name: trmrel_objectid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmrel_objectid ON biosql.term_relationship USING btree (object_term_id);


--
-- Name: trmrel_ontid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmrel_ontid ON biosql.term_relationship USING btree (ontology_id);


--
-- Name: trmrel_predicateid; Type: INDEX; Schema: biosql; Owner: fdxuser
--

CREATE INDEX trmrel_predicateid ON biosql.term_relationship USING btree (predicate_term_id);


--
-- Name: preferred_annotation_variant_id_idx; Type: INDEX; Schema: genphensql; Owner: fdxuser
--

CREATE INDEX preferred_annotation_variant_id_idx ON genphensql.preferred_annotation USING btree (variant_id);


--
-- Name: ranked_annotation_annotation_id_idx; Type: INDEX; Schema: genphensql; Owner: fdxuser
--

CREATE INDEX ranked_annotation_annotation_id_idx ON genphensql.ranked_annotation USING btree (annotation_id);


--
-- Name: ranked_annotation_variant_id_idx; Type: INDEX; Schema: genphensql; Owner: fdxuser
--

CREATE INDEX ranked_annotation_variant_id_idx ON genphensql.ranked_annotation USING btree (variant_id);


--
-- Name: account_emailaddress_email_03be32b2_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX account_emailaddress_email_03be32b2_like ON public.account_emailaddress USING btree (email varchar_pattern_ops);


--
-- Name: account_emailaddress_user_id_2c513194; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX account_emailaddress_user_id_2c513194 ON public.account_emailaddress USING btree (user_id);


--
-- Name: account_emailconfirmation_email_address_id_5b7f8c58; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX account_emailconfirmation_email_address_id_5b7f8c58 ON public.account_emailconfirmation USING btree (email_address_id);


--
-- Name: account_emailconfirmation_key_f43612bd_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX account_emailconfirmation_key_f43612bd_like ON public.account_emailconfirmation USING btree (key varchar_pattern_ops);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- Name: authtoken_token_key_10f0b77e_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX authtoken_token_key_10f0b77e_like ON public.authtoken_token USING btree (key varchar_pattern_ops);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: django_site_domain_a2e37b91_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX django_site_domain_a2e37b91_like ON public.django_site USING btree (domain varchar_pattern_ops);


--
-- Name: genphen_genotyperesistance_drug_id_8c22559e; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX genphen_genotyperesistance_drug_id_8c22559e ON public.genphen_genotyperesistance USING btree (drug_id);


--
-- Name: genphen_genotyperesistance_sample_id_b73c867b; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX genphen_genotyperesistance_sample_id_b73c867b ON public.genphen_genotyperesistance USING btree (sample_id);


--
-- Name: identity_profile_institution_country_id_52b93890; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX identity_profile_institution_country_id_52b93890 ON public.identity_profile USING btree (institution_country_id);


--
-- Name: identity_profile_institution_country_id_52b93890_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX identity_profile_institution_country_id_52b93890_like ON public.identity_profile USING btree (institution_country_id varchar_pattern_ops);


--
-- Name: overview_druggeneinfo_drug_id_2af1d659; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_drug_id_2af1d659 ON public.overview_druggeneinfo USING btree (drug_id);


--
-- Name: overview_druggeneinfo_nucleodic_ann_name_9908af51; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_nucleodic_ann_name_9908af51 ON public.overview_druggeneinfo USING btree (nucleodic_ann_name);


--
-- Name: overview_druggeneinfo_nucleodic_ann_name_9908af51_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_nucleodic_ann_name_9908af51_like ON public.overview_druggeneinfo USING btree (nucleodic_ann_name varchar_pattern_ops);


--
-- Name: overview_druggeneinfo_proteic_ann_name_da613225; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_proteic_ann_name_da613225 ON public.overview_druggeneinfo USING btree (proteic_ann_name);


--
-- Name: overview_druggeneinfo_proteic_ann_name_da613225_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_proteic_ann_name_da613225_like ON public.overview_druggeneinfo USING btree (proteic_ann_name varchar_pattern_ops);


--
-- Name: overview_druggeneinfo_variant_name_0499b323; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_variant_name_0499b323 ON public.overview_druggeneinfo USING btree (variant_name);


--
-- Name: overview_druggeneinfo_variant_name_0499b323_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_druggeneinfo_variant_name_0499b323_like ON public.overview_druggeneinfo USING btree (variant_name varchar_pattern_ops);


--
-- Name: overview_globalsample_country_id_id_8d89d748; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_globalsample_country_id_id_8d89d748 ON public.overview_globalsample USING btree (country_id_id);


--
-- Name: overview_globalsample_country_id_id_8d89d748_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX overview_globalsample_country_id_id_8d89d748_like ON public.overview_globalsample USING btree (country_id_id varchar_pattern_ops);


--
-- Name: package__origin__upper__idx; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX package__origin__upper__idx ON public.submission_package USING btree (upper((origin)::text));


--
-- Name: samplealias__name__upper__idx; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX samplealias__name__upper__idx ON public.submission_samplealias USING btree (upper((name)::text));


--
-- Name: sd__library_name__upper__idx; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX sd__library_name__upper__idx ON public.submission_sequencingdata USING btree (upper((library_name)::text));


--
-- Name: socialaccount_socialaccount_user_id_8146e70c; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX socialaccount_socialaccount_user_id_8146e70c ON public.socialaccount_socialaccount USING btree (user_id);


--
-- Name: socialaccount_socialapp_sites_site_id_2579dee5; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX socialaccount_socialapp_sites_site_id_2579dee5 ON public.socialaccount_socialapp_sites USING btree (site_id);


--
-- Name: socialaccount_socialapp_sites_socialapp_id_97fb6e7d; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX socialaccount_socialapp_sites_socialapp_id_97fb6e7d ON public.socialaccount_socialapp_sites USING btree (socialapp_id);


--
-- Name: socialaccount_socialtoken_account_id_951f210e; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX socialaccount_socialtoken_account_id_951f210e ON public.socialaccount_socialtoken USING btree (account_id);


--
-- Name: socialaccount_socialtoken_app_id_636a42d7; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX socialaccount_socialtoken_app_id_636a42d7 ON public.socialaccount_socialtoken USING btree (app_id);


--
-- Name: submission_attachment_package_id_7ece98cd; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_attachment_package_id_7ece98cd ON public.submission_attachment USING btree (package_id);


--
-- Name: submission_contributor_package_id_dedaa8ed; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_contributor_package_id_dedaa8ed ON public.submission_contributor USING btree (package_id);


--
-- Name: submission_message_package_id_1903a366; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_message_package_id_1903a366 ON public.submission_message USING btree (package_id);


--
-- Name: submission_message_sender_id_889ad7f4; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_message_sender_id_889ad7f4 ON public.submission_message USING btree (sender_id);


--
-- Name: submission_mictest_drug_id_91fed812; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_mictest_drug_id_91fed812 ON public.submission_mictest USING btree (drug_id);


--
-- Name: submission_mictest_package_id_6c55213d; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_mictest_package_id_6c55213d ON public.submission_mictest USING btree (package_id);


--
-- Name: submission_mictest_sample_alias_id_1d54b8ea; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_mictest_sample_alias_id_1d54b8ea ON public.submission_mictest USING btree (sample_alias_id);


--
-- Name: submission_mictest_sample_id_e3a39bc3; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_mictest_sample_id_e3a39bc3 ON public.submission_mictest USING btree (sample_id);


--
-- Name: submission_package_owner_id_2ebc52e7; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_package_owner_id_2ebc52e7 ON public.submission_package USING btree (owner_id);


--
-- Name: submission_packagesequenci_sequencing_data_hash_id_1f49f016; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_packagesequenci_sequencing_data_hash_id_1f49f016 ON public.submission_packagesequencingdata USING btree (sequencing_data_hash_id);


--
-- Name: submission_packagesequencingdata_package_id_100b06f4; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_packagesequencingdata_package_id_100b06f4 ON public.submission_packagesequencingdata USING btree (package_id);


--
-- Name: submission_packagesequencingdata_sequencing_data_id_0f995c7b; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_packagesequencingdata_sequencing_data_id_0f995c7b ON public.submission_packagesequencingdata USING btree (sequencing_data_id);


--
-- Name: submission_pdstest_drug_id_30f598d1; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_pdstest_drug_id_30f598d1 ON public.submission_pdstest USING btree (drug_id);


--
-- Name: submission_pdstest_medium_id_14c4f20a; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_pdstest_medium_id_14c4f20a ON public.submission_pdstest USING btree (medium_id);


--
-- Name: submission_pdstest_method_id_d5fd1e1b; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_pdstest_method_id_d5fd1e1b ON public.submission_pdstest USING btree (method_id);


--
-- Name: submission_pdstest_package_id_d5a3159d; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_pdstest_package_id_d5a3159d ON public.submission_pdstest USING btree (package_id);


--
-- Name: submission_pdstest_sample_alias_id_52a34dad; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_pdstest_sample_alias_id_52a34dad ON public.submission_pdstest USING btree (sample_alias_id);


--
-- Name: submission_pdstest_sample_id_997bda98; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_pdstest_sample_id_997bda98 ON public.submission_pdstest USING btree (sample_id);


--
-- Name: submission_sample_country_id_73948463; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sample_country_id_73948463 ON public.submission_sample USING btree (country_id);


--
-- Name: submission_sample_country_id_73948463_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sample_country_id_73948463_like ON public.submission_sample USING btree (country_id varchar_pattern_ops);


--
-- Name: submission_sample_ncbi_taxon_id_40a8a411; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sample_ncbi_taxon_id_40a8a411 ON public.submission_sample USING btree (ncbi_taxon_id);


--
-- Name: submission_sample_package_id_f5d6c797; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sample_package_id_f5d6c797 ON public.submission_sample USING btree (package_id);


--
-- Name: submission_samplealias_country_id_fd913c9d; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_samplealias_country_id_fd913c9d ON public.submission_samplealias USING btree (country_id);


--
-- Name: submission_samplealias_country_id_fd913c9d_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_samplealias_country_id_fd913c9d_like ON public.submission_samplealias USING btree (country_id varchar_pattern_ops);


--
-- Name: submission_samplealias_package_id_69ab4b64; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_samplealias_package_id_69ab4b64 ON public.submission_samplealias USING btree (package_id);


--
-- Name: submission_samplealias_sample_id_21086250; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_samplealias_sample_id_21086250 ON public.submission_samplealias USING btree (sample_id);


--
-- Name: submission_sequencingdata_file_path_a125c41c_like; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sequencingdata_file_path_a125c41c_like ON public.submission_sequencingdata USING btree (file_path varchar_pattern_ops);


--
-- Name: submission_sequencingdata_sample_id_cb824ad0; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sequencingdata_sample_id_cb824ad0 ON public.submission_sequencingdata USING btree (sample_id);


--
-- Name: submission_sequencingdatahash_sequencing_data_id_6b44ffac; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE INDEX submission_sequencingdatahash_sequencing_data_id_6b44ffac ON public.submission_sequencingdatahash USING btree (sequencing_data_id);


--
-- Name: uc__packagesequencingdata__package__sequencing_data__sequencing; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE UNIQUE INDEX uc__packagesequencingdata__package__sequencing_data__sequencing ON public.submission_packagesequencingdata USING btree (package_id, sequencing_data_id, sequencing_data_hash_id);


--
-- Name: uc__samplealias__package__fastq_prefix; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE UNIQUE INDEX uc__samplealias__package__fastq_prefix ON public.submission_samplealias USING btree (package_id, fastq_prefix);


--
-- Name: uc__samplealias__package__name; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE UNIQUE INDEX uc__samplealias__package__name ON public.submission_samplealias USING btree (package_id, name);


--
-- Name: uc__sequencing_data__library_name__file_path; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE UNIQUE INDEX uc__sequencing_data__library_name__file_path ON public.submission_sequencingdata USING btree (library_name, file_path);


--
-- Name: uc__sequencing_data_hash__sequencing_data__algorithm__value; Type: INDEX; Schema: public; Owner: fdxuser
--

CREATE UNIQUE INDEX uc__sequencing_data_hash__sequencing_data__algorithm__value ON public.submission_sequencingdatahash USING btree (sequencing_data_id, algorithm, value);


--
-- Name: biodatabase rule_biodatabase_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_biodatabase_i AS
    ON INSERT TO biosql.biodatabase
   WHERE (( SELECT biodatabase.biodatabase_id
           FROM biosql.biodatabase
          WHERE ((biodatabase.name)::text = (new.name)::text)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: bioentry_dbxref rule_bioentry_dbxref_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_bioentry_dbxref_i AS
    ON INSERT TO biosql.bioentry_dbxref
   WHERE (( SELECT bioentry_dbxref.dbxref_id
           FROM biosql.bioentry_dbxref
          WHERE ((bioentry_dbxref.bioentry_id = new.bioentry_id) AND (bioentry_dbxref.dbxref_id = new.dbxref_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: bioentry_path rule_bioentry_path_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_bioentry_path_i AS
    ON INSERT TO biosql.bioentry_path
   WHERE (( SELECT bioentry_relationship.bioentry_relationship_id
           FROM biosql.bioentry_relationship
          WHERE ((bioentry_relationship.object_bioentry_id = new.object_bioentry_id) AND (bioentry_relationship.subject_bioentry_id = new.subject_bioentry_id) AND (bioentry_relationship.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: bioentry_qualifier_value rule_bioentry_qualifier_value_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_bioentry_qualifier_value_i AS
    ON INSERT TO biosql.bioentry_qualifier_value
   WHERE (( SELECT bioentry_qualifier_value.bioentry_id
           FROM biosql.bioentry_qualifier_value
          WHERE ((bioentry_qualifier_value.bioentry_id = new.bioentry_id) AND (bioentry_qualifier_value.term_id = new.term_id) AND (bioentry_qualifier_value.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: bioentry_reference rule_bioentry_reference_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_bioentry_reference_i AS
    ON INSERT TO biosql.bioentry_reference
   WHERE (( SELECT bioentry_reference.bioentry_id
           FROM biosql.bioentry_reference
          WHERE ((bioentry_reference.bioentry_id = new.bioentry_id) AND (bioentry_reference.reference_id = new.reference_id) AND (bioentry_reference.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: bioentry_relationship rule_bioentry_relationship_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_bioentry_relationship_i AS
    ON INSERT TO biosql.bioentry_relationship
   WHERE (( SELECT bioentry_relationship.bioentry_relationship_id
           FROM biosql.bioentry_relationship
          WHERE ((bioentry_relationship.object_bioentry_id = new.object_bioentry_id) AND (bioentry_relationship.subject_bioentry_id = new.subject_bioentry_id) AND (bioentry_relationship.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: biosequence rule_biosequence_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_biosequence_i AS
    ON INSERT TO biosql.biosequence
   WHERE (( SELECT biosequence.bioentry_id
           FROM biosql.biosequence
          WHERE (biosequence.bioentry_id = new.bioentry_id)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: comment rule_comment_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_comment_i AS
    ON INSERT TO biosql.comment
   WHERE (( SELECT comment.comment_id
           FROM biosql.comment
          WHERE ((comment.bioentry_id = new.bioentry_id) AND (comment.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: dbxref rule_dbxref_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_dbxref_i AS
    ON INSERT TO biosql.dbxref
   WHERE (( SELECT dbxref.dbxref_id
           FROM biosql.dbxref
          WHERE (((dbxref.accession)::text = (new.accession)::text) AND ((dbxref.dbname)::text = (new.dbname)::text) AND (dbxref.version = new.version))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: dbxref_qualifier_value rule_dbxref_qualifier_value_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_dbxref_qualifier_value_i AS
    ON INSERT TO biosql.dbxref_qualifier_value
   WHERE (( SELECT dbxref_qualifier_value.dbxref_id
           FROM biosql.dbxref_qualifier_value
          WHERE ((dbxref_qualifier_value.dbxref_id = new.dbxref_id) AND (dbxref_qualifier_value.term_id = new.term_id) AND (dbxref_qualifier_value.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: location rule_location_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_location_i AS
    ON INSERT TO biosql.location
   WHERE (( SELECT location.location_id
           FROM biosql.location
          WHERE ((location.seqfeature_id = new.seqfeature_id) AND (location.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: location_qualifier_value rule_location_qualifier_value_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_location_qualifier_value_i AS
    ON INSERT TO biosql.location_qualifier_value
   WHERE (( SELECT location_qualifier_value.location_id
           FROM biosql.location_qualifier_value
          WHERE ((location_qualifier_value.location_id = new.location_id) AND (location_qualifier_value.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: ontology rule_ontology_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_ontology_i AS
    ON INSERT TO biosql.ontology
   WHERE (( SELECT ontology.ontology_id
           FROM biosql.ontology
          WHERE ((ontology.name)::text = (new.name)::text)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: reference rule_reference_i1; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_reference_i1 AS
    ON INSERT TO biosql.reference
   WHERE (( SELECT reference.reference_id
           FROM biosql.reference
          WHERE ((reference.crc)::text = (new.crc)::text)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: reference rule_reference_i2; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_reference_i2 AS
    ON INSERT TO biosql.reference
   WHERE (( SELECT reference.reference_id
           FROM biosql.reference
          WHERE (reference.dbxref_id = new.dbxref_id)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: seqfeature_dbxref rule_seqfeature_dbxref_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_seqfeature_dbxref_i AS
    ON INSERT TO biosql.seqfeature_dbxref
   WHERE (( SELECT seqfeature_dbxref.seqfeature_id
           FROM biosql.seqfeature_dbxref
          WHERE ((seqfeature_dbxref.seqfeature_id = new.seqfeature_id) AND (seqfeature_dbxref.dbxref_id = new.dbxref_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: seqfeature rule_seqfeature_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_seqfeature_i AS
    ON INSERT TO biosql.seqfeature
   WHERE (( SELECT seqfeature.seqfeature_id
           FROM biosql.seqfeature
          WHERE ((seqfeature.bioentry_id = new.bioentry_id) AND (seqfeature.type_term_id = new.type_term_id) AND (seqfeature.source_term_id = new.source_term_id) AND (seqfeature.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: seqfeature_path rule_seqfeature_path_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_seqfeature_path_i AS
    ON INSERT TO biosql.seqfeature_path
   WHERE (( SELECT seqfeature_path.subject_seqfeature_id
           FROM biosql.seqfeature_path
          WHERE ((seqfeature_path.object_seqfeature_id = new.object_seqfeature_id) AND (seqfeature_path.subject_seqfeature_id = new.subject_seqfeature_id) AND (seqfeature_path.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: seqfeature_qualifier_value rule_seqfeature_qualifier_value_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_seqfeature_qualifier_value_i AS
    ON INSERT TO biosql.seqfeature_qualifier_value
   WHERE (( SELECT seqfeature_qualifier_value.seqfeature_id
           FROM biosql.seqfeature_qualifier_value
          WHERE ((seqfeature_qualifier_value.seqfeature_id = new.seqfeature_id) AND (seqfeature_qualifier_value.term_id = new.term_id) AND (seqfeature_qualifier_value.rank = new.rank))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: seqfeature_relationship rule_seqfeature_relationship_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_seqfeature_relationship_i AS
    ON INSERT TO biosql.seqfeature_relationship
   WHERE (( SELECT seqfeature_relationship.subject_seqfeature_id
           FROM biosql.seqfeature_relationship
          WHERE ((seqfeature_relationship.object_seqfeature_id = new.object_seqfeature_id) AND (seqfeature_relationship.subject_seqfeature_id = new.subject_seqfeature_id) AND (seqfeature_relationship.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: taxon rule_taxon_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_taxon_i AS
    ON INSERT TO biosql.taxon
   WHERE (( SELECT taxon.taxon_id
           FROM biosql.taxon
          WHERE (taxon.ncbi_taxon_id = new.ncbi_taxon_id)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: taxon_name rule_taxon_name_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_taxon_name_i AS
    ON INSERT TO biosql.taxon_name
   WHERE (( SELECT taxon_name.taxon_id
           FROM biosql.taxon_name
          WHERE ((taxon_name.taxon_id = new.taxon_id) AND ((taxon_name.name)::text = (new.name)::text) AND ((taxon_name.name_class)::text = (new.name_class)::text))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term_dbxref rule_term_dbxref_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_dbxref_i AS
    ON INSERT TO biosql.term_dbxref
   WHERE (( SELECT term_dbxref.dbxref_id
           FROM biosql.term_dbxref
          WHERE ((term_dbxref.dbxref_id = new.dbxref_id) AND (term_dbxref.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term rule_term_i1; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_i1 AS
    ON INSERT TO biosql.term
   WHERE (( SELECT term.term_id
           FROM biosql.term
          WHERE ((term.identifier)::text = (new.identifier)::text)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term rule_term_i2; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_i2 AS
    ON INSERT TO biosql.term
   WHERE (( SELECT term.term_id
           FROM biosql.term
          WHERE (((term.name)::text = (new.name)::text) AND (term.ontology_id = new.ontology_id) AND (term.is_obsolete = new.is_obsolete))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term_path rule_term_path_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_path_i AS
    ON INSERT TO biosql.term_path
   WHERE (( SELECT term_path.subject_term_id
           FROM biosql.term_path
          WHERE ((term_path.subject_term_id = new.subject_term_id) AND (term_path.predicate_term_id = new.predicate_term_id) AND (term_path.object_term_id = new.object_term_id) AND (term_path.ontology_id = new.ontology_id) AND (term_path.distance = new.distance))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term_relationship rule_term_relationship_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_relationship_i AS
    ON INSERT TO biosql.term_relationship
   WHERE (( SELECT term_relationship.term_relationship_id
           FROM biosql.term_relationship
          WHERE ((term_relationship.subject_term_id = new.subject_term_id) AND (term_relationship.predicate_term_id = new.predicate_term_id) AND (term_relationship.object_term_id = new.object_term_id) AND (term_relationship.ontology_id = new.ontology_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term_relationship_term rule_term_relationship_term_i1; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_relationship_term_i1 AS
    ON INSERT TO biosql.term_relationship_term
   WHERE (( SELECT term_relationship_term.term_relationship_id
           FROM biosql.term_relationship_term
          WHERE (term_relationship_term.term_relationship_id = new.term_relationship_id)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term_relationship_term rule_term_relationship_term_i2; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_relationship_term_i2 AS
    ON INSERT TO biosql.term_relationship_term
   WHERE (( SELECT term_relationship_term.term_id
           FROM biosql.term_relationship_term
          WHERE (term_relationship_term.term_id = new.term_id)) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: term_synonym rule_term_synonym_i; Type: RULE; Schema: biosql; Owner: fdxuser
--

CREATE RULE rule_term_synonym_i AS
    ON INSERT TO biosql.term_synonym
   WHERE (( SELECT term_synonym.term_id
           FROM biosql.term_synonym
          WHERE (((term_synonym.synonym)::text = (new.synonym)::text) AND (term_synonym.term_id = new.term_id))) IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: bioentry fkbiodatabase_bioentry; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry
    ADD CONSTRAINT fkbiodatabase_bioentry FOREIGN KEY (biodatabase_id) REFERENCES biosql.biodatabase(biodatabase_id);


--
-- Name: biosequence fkbioentry_bioseq; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.biosequence
    ADD CONSTRAINT fkbioentry_bioseq FOREIGN KEY (bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: comment fkbioentry_comment; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.comment
    ADD CONSTRAINT fkbioentry_comment FOREIGN KEY (bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: bioentry_dbxref fkbioentry_dblink; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_dbxref
    ADD CONSTRAINT fkbioentry_dblink FOREIGN KEY (bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: bioentry_qualifier_value fkbioentry_entqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_qualifier_value
    ADD CONSTRAINT fkbioentry_entqual FOREIGN KEY (bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: bioentry_reference fkbioentry_entryref; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_reference
    ADD CONSTRAINT fkbioentry_entryref FOREIGN KEY (bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: seqfeature fkbioentry_seqfeature; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature
    ADD CONSTRAINT fkbioentry_seqfeature FOREIGN KEY (bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: bioentry_path fkchildent_bioentrypath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_path
    ADD CONSTRAINT fkchildent_bioentrypath FOREIGN KEY (subject_bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: bioentry_relationship fkchildent_bioentryrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_relationship
    ADD CONSTRAINT fkchildent_bioentryrel FOREIGN KEY (subject_bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: seqfeature_path fkchildfeat_seqfeatpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_path
    ADD CONSTRAINT fkchildfeat_seqfeatpath FOREIGN KEY (subject_seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: seqfeature_relationship fkchildfeat_seqfeatrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_relationship
    ADD CONSTRAINT fkchildfeat_seqfeatrel FOREIGN KEY (subject_seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: bioentry_dbxref fkdbxref_dblink; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_dbxref
    ADD CONSTRAINT fkdbxref_dblink FOREIGN KEY (dbxref_id) REFERENCES biosql.dbxref(dbxref_id) ON DELETE CASCADE;


--
-- Name: dbxref_qualifier_value fkdbxref_dbxrefqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.dbxref_qualifier_value
    ADD CONSTRAINT fkdbxref_dbxrefqual FOREIGN KEY (dbxref_id) REFERENCES biosql.dbxref(dbxref_id) ON DELETE CASCADE;


--
-- Name: seqfeature_dbxref fkdbxref_feadblink; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_dbxref
    ADD CONSTRAINT fkdbxref_feadblink FOREIGN KEY (dbxref_id) REFERENCES biosql.dbxref(dbxref_id) ON DELETE CASCADE;


--
-- Name: location fkdbxref_location; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location
    ADD CONSTRAINT fkdbxref_location FOREIGN KEY (dbxref_id) REFERENCES biosql.dbxref(dbxref_id);


--
-- Name: reference fkdbxref_reference; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.reference
    ADD CONSTRAINT fkdbxref_reference FOREIGN KEY (dbxref_id) REFERENCES biosql.dbxref(dbxref_id);


--
-- Name: term_dbxref fkdbxref_trmdbxref; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_dbxref
    ADD CONSTRAINT fkdbxref_trmdbxref FOREIGN KEY (dbxref_id) REFERENCES biosql.dbxref(dbxref_id) ON DELETE CASCADE;


--
-- Name: location_qualifier_value fkfeatloc_locqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location_qualifier_value
    ADD CONSTRAINT fkfeatloc_locqual FOREIGN KEY (location_id) REFERENCES biosql.location(location_id) ON DELETE CASCADE;


--
-- Name: term fkont_term; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term
    ADD CONSTRAINT fkont_term FOREIGN KEY (ontology_id) REFERENCES biosql.ontology(ontology_id) ON DELETE CASCADE;


--
-- Name: term_path fkontology_trmpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_path
    ADD CONSTRAINT fkontology_trmpath FOREIGN KEY (ontology_id) REFERENCES biosql.ontology(ontology_id) ON DELETE CASCADE;


--
-- Name: term_relationship fkontology_trmrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship
    ADD CONSTRAINT fkontology_trmrel FOREIGN KEY (ontology_id) REFERENCES biosql.ontology(ontology_id) ON DELETE CASCADE;


--
-- Name: bioentry_path fkparentent_bioentrypath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_path
    ADD CONSTRAINT fkparentent_bioentrypath FOREIGN KEY (object_bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: bioentry_relationship fkparentent_bioentryrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_relationship
    ADD CONSTRAINT fkparentent_bioentryrel FOREIGN KEY (object_bioentry_id) REFERENCES biosql.bioentry(bioentry_id) ON DELETE CASCADE;


--
-- Name: seqfeature_path fkparentfeat_seqfeatpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_path
    ADD CONSTRAINT fkparentfeat_seqfeatpath FOREIGN KEY (object_seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: seqfeature_relationship fkparentfeat_seqfeatrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_relationship
    ADD CONSTRAINT fkparentfeat_seqfeatrel FOREIGN KEY (object_seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: bioentry_reference fkreference_entryref; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_reference
    ADD CONSTRAINT fkreference_entryref FOREIGN KEY (reference_id) REFERENCES biosql.reference(reference_id) ON DELETE CASCADE;


--
-- Name: seqfeature_dbxref fkseqfeature_feadblink; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_dbxref
    ADD CONSTRAINT fkseqfeature_feadblink FOREIGN KEY (seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: seqfeature_qualifier_value fkseqfeature_featqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_qualifier_value
    ADD CONSTRAINT fkseqfeature_featqual FOREIGN KEY (seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: location fkseqfeature_location; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location
    ADD CONSTRAINT fkseqfeature_location FOREIGN KEY (seqfeature_id) REFERENCES biosql.seqfeature(seqfeature_id) ON DELETE CASCADE;


--
-- Name: seqfeature fksourceterm_seqfeature; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature
    ADD CONSTRAINT fksourceterm_seqfeature FOREIGN KEY (source_term_id) REFERENCES biosql.term(term_id);


--
-- Name: bioentry fktaxon_bioentry; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry
    ADD CONSTRAINT fktaxon_bioentry FOREIGN KEY (taxon_id) REFERENCES biosql.taxon(taxon_id);


--
-- Name: taxon_name fktaxon_taxonname; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.taxon_name
    ADD CONSTRAINT fktaxon_taxonname FOREIGN KEY (taxon_id) REFERENCES biosql.taxon(taxon_id) ON DELETE CASCADE;


--
-- Name: bioentry_path fkterm_bioentrypath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_path
    ADD CONSTRAINT fkterm_bioentrypath FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: bioentry_relationship fkterm_bioentryrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_relationship
    ADD CONSTRAINT fkterm_bioentryrel FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: bioentry_qualifier_value fkterm_entqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.bioentry_qualifier_value
    ADD CONSTRAINT fkterm_entqual FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: location fkterm_featloc; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location
    ADD CONSTRAINT fkterm_featloc FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: seqfeature_qualifier_value fkterm_featqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_qualifier_value
    ADD CONSTRAINT fkterm_featqual FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: location_qualifier_value fkterm_locqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.location_qualifier_value
    ADD CONSTRAINT fkterm_locqual FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: seqfeature_path fkterm_seqfeatpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_path
    ADD CONSTRAINT fkterm_seqfeatpath FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: seqfeature_relationship fkterm_seqfeatrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature_relationship
    ADD CONSTRAINT fkterm_seqfeatrel FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: seqfeature fkterm_seqfeature; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.seqfeature
    ADD CONSTRAINT fkterm_seqfeature FOREIGN KEY (type_term_id) REFERENCES biosql.term(term_id);


--
-- Name: term_synonym fkterm_syn; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_synonym
    ADD CONSTRAINT fkterm_syn FOREIGN KEY (term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_dbxref fkterm_trmdbxref; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_dbxref
    ADD CONSTRAINT fkterm_trmdbxref FOREIGN KEY (term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: dbxref_qualifier_value fktrm_dbxrefqual; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.dbxref_qualifier_value
    ADD CONSTRAINT fktrm_dbxrefqual FOREIGN KEY (term_id) REFERENCES biosql.term(term_id);


--
-- Name: term_relationship_term fktrm_trmreltrm; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship_term
    ADD CONSTRAINT fktrm_trmreltrm FOREIGN KEY (term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_path fktrmobject_trmpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_path
    ADD CONSTRAINT fktrmobject_trmpath FOREIGN KEY (object_term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_relationship fktrmobject_trmrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship
    ADD CONSTRAINT fktrmobject_trmrel FOREIGN KEY (object_term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_path fktrmpredicate_trmpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_path
    ADD CONSTRAINT fktrmpredicate_trmpath FOREIGN KEY (predicate_term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_relationship fktrmpredicate_trmrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship
    ADD CONSTRAINT fktrmpredicate_trmrel FOREIGN KEY (predicate_term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_relationship_term fktrmrel_trmreltrm; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship_term
    ADD CONSTRAINT fktrmrel_trmreltrm FOREIGN KEY (term_relationship_id) REFERENCES biosql.term_relationship(term_relationship_id) ON DELETE CASCADE;


--
-- Name: term_path fktrmsubject_trmpath; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_path
    ADD CONSTRAINT fktrmsubject_trmpath FOREIGN KEY (subject_term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: term_relationship fktrmsubject_trmrel; Type: FK CONSTRAINT; Schema: biosql; Owner: fdxuser
--

ALTER TABLE ONLY biosql.term_relationship
    ADD CONSTRAINT fktrmsubject_trmrel FOREIGN KEY (subject_term_id) REFERENCES biosql.term(term_id) ON DELETE CASCADE;


--
-- Name: variant_to_annotation fk_annotation_id__annotation__annotation_id; Type: FK CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.variant_to_annotation
    ADD CONSTRAINT fk_annotation_id__annotation__annotation_id FOREIGN KEY (annotation_id) REFERENCES genphensql.annotation(annotation_id);


--
-- Name: variant_to_annotation fk_variant_id__variant__variant_id; Type: FK CONSTRAINT; Schema: genphensql; Owner: fdxuser
--

ALTER TABLE ONLY genphensql.variant_to_annotation
    ADD CONSTRAINT fk_variant_id__variant__variant_id FOREIGN KEY (variant_id) REFERENCES genphensql.variant(variant_id);


--
-- Name: account_emailaddress account_emailaddress_user_id_2c513194_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.account_emailaddress
    ADD CONSTRAINT account_emailaddress_user_id_2c513194_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: account_emailconfirmation account_emailconfirm_email_address_id_5b7f8c58_fk_account_e; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.account_emailconfirmation
    ADD CONSTRAINT account_emailconfirm_email_address_id_5b7f8c58_fk_account_e FOREIGN KEY (email_address_id) REFERENCES public.account_emailaddress(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: authtoken_token authtoken_token_user_id_35299eff_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_35299eff_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: genphen_genotyperesistance genphen_genotyperesi_sample_id_b73c867b_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.genphen_genotyperesistance
    ADD CONSTRAINT genphen_genotyperesi_sample_id_b73c867b_fk_submissio FOREIGN KEY (sample_id) REFERENCES public.submission_sample(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: genphen_genotyperesistance genphen_genotyperesistance_drug_id_8c22559e_fk_drug_drug_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.genphen_genotyperesistance
    ADD CONSTRAINT genphen_genotyperesistance_drug_id_8c22559e_fk_drug_drug_id FOREIGN KEY (drug_id) REFERENCES genphensql.drug(drug_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: identity_profile identity_profile_institution_country__52b93890_fk_country_t; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.identity_profile
    ADD CONSTRAINT identity_profile_institution_country__52b93890_fk_country_t FOREIGN KEY (institution_country_id) REFERENCES public.country(three_letters_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: identity_profile identity_profile_user_id_a346fd60_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.identity_profile
    ADD CONSTRAINT identity_profile_user_id_a346fd60_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: overview_druggeneinfo overview_druggeneinfo_drug_id_2af1d659_fk_drug_drug_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.overview_druggeneinfo
    ADD CONSTRAINT overview_druggeneinfo_drug_id_2af1d659_fk_drug_drug_id FOREIGN KEY (drug_id) REFERENCES genphensql.drug(drug_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: overview_globalsample overview_globalsampl_country_id_id_8d89d748_fk_country_t; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.overview_globalsample
    ADD CONSTRAINT overview_globalsampl_country_id_id_8d89d748_fk_country_t FOREIGN KEY (country_id_id) REFERENCES public.country(three_letters_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: socialaccount_socialtoken socialaccount_social_account_id_951f210e_fk_socialacc; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialtoken
    ADD CONSTRAINT socialaccount_social_account_id_951f210e_fk_socialacc FOREIGN KEY (account_id) REFERENCES public.socialaccount_socialaccount(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: socialaccount_socialtoken socialaccount_social_app_id_636a42d7_fk_socialacc; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialtoken
    ADD CONSTRAINT socialaccount_social_app_id_636a42d7_fk_socialacc FOREIGN KEY (app_id) REFERENCES public.socialaccount_socialapp(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: socialaccount_socialapp_sites socialaccount_social_site_id_2579dee5_fk_django_si; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialapp_sites
    ADD CONSTRAINT socialaccount_social_site_id_2579dee5_fk_django_si FOREIGN KEY (site_id) REFERENCES public.django_site(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: socialaccount_socialapp_sites socialaccount_social_socialapp_id_97fb6e7d_fk_socialacc; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialapp_sites
    ADD CONSTRAINT socialaccount_social_socialapp_id_97fb6e7d_fk_socialacc FOREIGN KEY (socialapp_id) REFERENCES public.socialaccount_socialapp(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: socialaccount_socialaccount socialaccount_socialaccount_user_id_8146e70c_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.socialaccount_socialaccount
    ADD CONSTRAINT socialaccount_socialaccount_user_id_8146e70c_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_attachment submission_attachmen_package_id_7ece98cd_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_attachment
    ADD CONSTRAINT submission_attachmen_package_id_7ece98cd_fk_submissio FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_contributor submission_contribut_package_id_dedaa8ed_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_contributor
    ADD CONSTRAINT submission_contribut_package_id_dedaa8ed_fk_submissio FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_message submission_message_package_id_1903a366_fk_submission_package_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_message
    ADD CONSTRAINT submission_message_package_id_1903a366_fk_submission_package_id FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_message submission_message_sender_id_889ad7f4_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_message
    ADD CONSTRAINT submission_message_sender_id_889ad7f4_fk_auth_user_id FOREIGN KEY (sender_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_mictest submission_mictest_drug_id_91fed812_fk_drug_drug_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_mictest
    ADD CONSTRAINT submission_mictest_drug_id_91fed812_fk_drug_drug_id FOREIGN KEY (drug_id) REFERENCES genphensql.drug(drug_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_mictest submission_mictest_package_id_6c55213d_fk_submission_package_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_mictest
    ADD CONSTRAINT submission_mictest_package_id_6c55213d_fk_submission_package_id FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_mictest submission_mictest_sample_alias_id_1d54b8ea_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_mictest
    ADD CONSTRAINT submission_mictest_sample_alias_id_1d54b8ea_fk_submissio FOREIGN KEY (sample_alias_id) REFERENCES public.submission_samplealias(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_mictest submission_mictest_sample_id_e3a39bc3_fk_submission_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_mictest
    ADD CONSTRAINT submission_mictest_sample_id_e3a39bc3_fk_submission_sample_id FOREIGN KEY (sample_id) REFERENCES public.submission_sample(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_package submission_package_owner_id_2ebc52e7_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_package
    ADD CONSTRAINT submission_package_owner_id_2ebc52e7_fk_auth_user_id FOREIGN KEY (owner_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_packagesequencingdata submission_packagese_package_id_100b06f4_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagesequencingdata
    ADD CONSTRAINT submission_packagese_package_id_100b06f4_fk_submissio FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_packagesequencingdata submission_packagese_sequencing_data_hash_1f49f016_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagesequencingdata
    ADD CONSTRAINT submission_packagese_sequencing_data_hash_1f49f016_fk_submissio FOREIGN KEY (sequencing_data_hash_id) REFERENCES public.submission_sequencingdatahash(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_packagesequencingdata submission_packagese_sequencing_data_id_0f995c7b_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagesequencingdata
    ADD CONSTRAINT submission_packagese_sequencing_data_id_0f995c7b_fk_submissio FOREIGN KEY (sequencing_data_id) REFERENCES public.submission_sequencingdata(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_packagestats submission_packagest_package_id_f48a0d40_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_packagestats
    ADD CONSTRAINT submission_packagest_package_id_f48a0d40_fk_submissio FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_pdstest submission_pdstest_drug_id_30f598d1_fk_drug_drug_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_drug_id_30f598d1_fk_drug_drug_id FOREIGN KEY (drug_id) REFERENCES genphensql.drug(drug_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_pdstest submission_pdstest_medium_id_14c4f20a_fk_growth_me; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_medium_id_14c4f20a_fk_growth_me FOREIGN KEY (medium_id) REFERENCES genphensql.growth_medium(medium_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_pdstest submission_pdstest_method_id_d5fd1e1b_fk_phenotypi; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_method_id_d5fd1e1b_fk_phenotypi FOREIGN KEY (method_id) REFERENCES genphensql.phenotypic_drug_susceptibility_assessment_method(method_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_pdstest submission_pdstest_package_id_d5a3159d_fk_submission_package_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_package_id_d5a3159d_fk_submission_package_id FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_pdstest submission_pdstest_sample_alias_id_52a34dad_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_sample_alias_id_52a34dad_fk_submissio FOREIGN KEY (sample_alias_id) REFERENCES public.submission_samplealias(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_pdstest submission_pdstest_sample_id_997bda98_fk_submission_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_pdstest
    ADD CONSTRAINT submission_pdstest_sample_id_997bda98_fk_submission_sample_id FOREIGN KEY (sample_id) REFERENCES public.submission_sample(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_sample submission_sample_country_id_73948463_fk_country_t; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sample
    ADD CONSTRAINT submission_sample_country_id_73948463_fk_country_t FOREIGN KEY (country_id) REFERENCES public.country(three_letters_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_sample submission_sample_ncbi_taxon_id_40a8a411_fk_taxon_ncbi_taxon_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sample
    ADD CONSTRAINT submission_sample_ncbi_taxon_id_40a8a411_fk_taxon_ncbi_taxon_id FOREIGN KEY (ncbi_taxon_id) REFERENCES biosql.taxon(ncbi_taxon_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_sample submission_sample_package_id_f5d6c797_fk_submission_package_id; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sample
    ADD CONSTRAINT submission_sample_package_id_f5d6c797_fk_submission_package_id FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_samplealias submission_sampleali_country_id_fd913c9d_fk_country_t; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_samplealias
    ADD CONSTRAINT submission_sampleali_country_id_fd913c9d_fk_country_t FOREIGN KEY (country_id) REFERENCES public.country(three_letters_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_samplealias submission_sampleali_package_id_69ab4b64_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_samplealias
    ADD CONSTRAINT submission_sampleali_package_id_69ab4b64_fk_submissio FOREIGN KEY (package_id) REFERENCES public.submission_package(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_samplealias submission_sampleali_sample_id_21086250_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_samplealias
    ADD CONSTRAINT submission_sampleali_sample_id_21086250_fk_submissio FOREIGN KEY (sample_id) REFERENCES public.submission_sample(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_sequencingdata submission_sequencin_sample_id_cb824ad0_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sequencingdata
    ADD CONSTRAINT submission_sequencin_sample_id_cb824ad0_fk_submissio FOREIGN KEY (sample_id) REFERENCES public.submission_sample(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: submission_sequencingdatahash submission_sequencin_sequencing_data_id_6b44ffac_fk_submissio; Type: FK CONSTRAINT; Schema: public; Owner: fdxuser
--

ALTER TABLE ONLY public.submission_sequencingdatahash
    ADD CONSTRAINT submission_sequencin_sequencing_data_id_6b44ffac_fk_submissio FOREIGN KEY (sequencing_data_id) REFERENCES public.submission_sequencingdata(id) DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--

