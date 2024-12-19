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

# Build & Push


1. terraform apply -var-file=inputs.dev.tfvars.json
2. aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 762868722203.dkr.ecr.us-east-1.amazonaws.com
3. docker buildx build --platform=linux/amd64 -t 762868722203.dkr.ecr.us-east-1.amazonaws.com/tbkb-ncbi-sync:latest .
4. docker push 762868722203.dkr.ecr.us-east-1.amazonaws.com/tbkb-ncbi-sync:latest