# WHO Owner
Owned by the Global Tuberculosis Programme, GTB, Geneva Switzerland. References: Carl-Michael Nathanson.

# Overview
This repository holds both terraform configuration files and python application code for handling the synchronization between the local database and the INSDC. 

This repository must be deployed after the main infrastructure [repository](https://github.com/finddx/tbsequencing-infrastructure).

# Terraform 
You can use a local backend for deploying, or the same S3 and DynamoDB backend you might have set up for the main infrastructure [repository](https://github.com/finddx/tbsequencing-infrastructure). Be careful to set a new key for the terraform state object. Refer to our [GitHub composite action](https://github.com/finddx/configure-terraform-backend/blob/main/action.yml) for reference for setting up the backend file.

The repository will deploy the following:
- AWS Batch resources for handling jobs
- Eventbridge rules to schedule synchronization (disabled by default)
- Step Function workflow for orchestrating the jobs

For deployment, there are no other dependancies than having the main infrastructure repository deployed.

There are only three terraform variable to set up:
- project_name
- environment
- aws_region

They must be equal to the values used in the main repository.

## INSDC synchronization
One of the step workflow will run daily (if enabled) and will synchronize our database with new sample data available at the INSDC. All synchronization is performed by using the different tools of the [NCBI Entrez API](https://www.ncbi.nlm.nih.gov/books/NBK25501/) (esearch, efetch, elink). The logic is the following: 

1. Search newly submitted sequencing data with the term “MYCOBACTERIUM” in the organism attribute value.
2. Insert the new records into the sequencingdata table
3. Using elink, search for all BioSamples associated with these newly inserted sequencing data and insert the new records into our sample and samplealias tables
4. Using elink, search for all BioProject associated with these newly inserted samples and insert the new records into our package table


## NCBI Taxonomy synchronization

Our database is also synchronized with the NCBI taxonomy, via the tables that we imported from the bioSQL schema. We use scripts (in perl) provided by the [bioSQL](https://github.com/biosql/biosql) community to synchronize our taxonomy. We synchronize the taxonomy every 3 months.

# Application Code

You will need to build and deploy a Docker image containing the python application code handling synchronization. An AWS ECR has been deployed by the main repository and will receive the Docker image. Refer to our [action file](.github/workflows/push.yml) and reusable [workflow](https://github.com/finddx/seq-treat-tbkb-github-workflows/blob/main/.github/workflows/build_push.yml) for building and pushing the image.

For the synchronization logic to be successful, you will need to:

1. Deploy the [backend](https://github.com/finddx/tbsequencing-backend) repository
2. Have the migration run in ECS
3. Fill up the NCBI authentication secrets that were created in AWS Secrets Manager
4. Run first the taxonomy synchronization and then the INSDC 

# Entrez

# IDs

All entries in Entrez have an ID, which is called an "accession" - like an accession key.
It is a numeric ID with a prefix which identifies the object it provides access to:

- experiment_accession (SRX),
- study_accession (SRP),
- run_alias (GSM_r),
- sample_alias (GSM_),
- experiment_alias (GSM),
- study_alias (GSE)

- STUDY with accessions in the form of SRP#, ERP#, or DRP#
- SAMPLE with accessions in the form of SRS#, ERS#, or DRS#
- EXPERIMENT with accessions in the form of SRX#, ERX#, or DRX#
- RUN with accessions in the form of SRR#, ERR#, or DRR#
- The first letter in the accession makes a notation of the source database - SRA, EBI, or DDBJ correspondingly.
