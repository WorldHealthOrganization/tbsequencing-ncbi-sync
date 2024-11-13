from itertools import groupby

from toolz import unique

from src.common import logs
from src.common.stats import Stats
from src.db.database import Connection
from src.sync_sequencing_data import sql
from src.sync_sequencing_data.models import NewSampleAlias, SRARunResultFile

log = logs.create_logger(__name__)

def save_sra_data(db: Connection, tmp_package_id: int, items: list[SRARunResultFile]) -> Stats:
    sanity_check(items)

    totals = Stats()

    # Case 1: Fresh MD5, existing Biosample Accession
    # First: Find duplication by MD5
    # Second: Assign the sample ID by looking for alias:
    #         Biosample Accession
    #         SRS Accession
    # Third: Save the sequencing data

    # Case 2: Existing MD5, existing Biosample Accession
    # First: Find duplication by MD5
    # Second: Assign the sample ID by looking for alias:
    #         Biosample Accession
    #         SRS Accession
    # Third: Nothing

    # [TODO] Case 3: Existing MD5, fresh Biosample Accession
    # First: Find duplication by MD5
    # Reuse the sample
    # Add new aliases
    # If SRR (file name == SRA File accession key) is different
    #   Add the the sequencing data, mark as a duplicate (add another DB column)
    # Sample metadata sync: take the earliest biosample accession id, sync this data only

    # Case 4: Fresh MD5, fresh Biosample Accession
    # Sequencing file match: -
    # Sample: -
    #   Biosample Accession
    #   SRS Accession
    # Save:
    #   Create the dummy sample
    #   Attach the SRS & Biosample accession keys to it as Aliases
    #   Save the sequencing data & hash

    # [POSTPONED] Case 5: TBKB had the data uploaded, but NCBI has the new sequencing files
    # Expectation: We should remove the TBKB sequencing data, replace it with NCBI sequencing files
    # Now: add the new aliases to the sample, mark as a duplicate to ignore

    # [TODO] Case 6: Some MD5 exists, some are not; Biosample - doesn't matter
    # It is real? Could it be possible?
    # TODO: Set an assertion for it!

    # [TODO] DB
    # [TODO] Sample Alias Index: Unique Origin+Name+package_id
    # [TODO] Sequencing Hashes Index: Unique sequencing_data_id+value
    # TODO: we should check for a pair or biosample_accession+md5+filename(SRR)

    # Ensure the correct order to get advantage of the groupby in various functions
    items.sort(key=lambda x: x.biosample_accession)

    items, stats = filter_out_matched_by_library_name(db, items)
    log.debug(stats)
    totals.merge(stats)

    items, stats = match_sample_ids_by_accession_keys(db, items)
    log.debug(stats)
    totals.merge(stats)

    items, stats = match_sample_ids_by_hashes(db, items)
    log.debug(stats)
    totals.merge(stats)

    items, stats = create_missing_samples(db, tmp_package_id, items)
    log.debug(stats)
    totals.merge(stats)

    items, stats = create_missing_sample_aliases(db, tmp_package_id, items)
    log.debug(stats)
    totals.merge(stats)

    items, stats = insert_sequencing_data(db, items)
    log.debug(stats)
    totals.merge(stats)
    return totals


def sanity_check(items: list[SRARunResultFile]):
    # just to keep the sanity okay...
    for group, matches in groupby(items, lambda x: x.biosample_accession):
        if len({m.srs_accession for m in matches}) > 1:
            raise Exception(f"The same biosample name has multiple different sra names?! {group}", group, items)


def filter_out_matched_by_library_name(db, items):
    totals = Stats()

    # Exclude the duplications withing the dataset, just in case
    original_len = len(items)
    items = list(unique(items, key=lambda item: item.library_name))
    if len(items) != original_len:
        totals.increment("skipped_found_by_library_name_in_payload", original_len - len(items))

    found_srs = sql.get_sequencingdata_by_library_name(db, [item.library_name for item in items])

    result = [item for item in items if item.library_name not in found_srs]
    totals.increment("skipped_found_by_library_name_in_db", len(items) - len(result))
    return result, totals



def match_sample_ids_by_accession_keys(db: Connection, items: list[SRARunResultFile]) -> tuple[list[SRARunResultFile], Stats]:
    totals = Stats()

    alias_to_sample_id = {
        sample_alias.name: sample_alias.sample_id
        for sample_alias in sql.get_samples_by_sample_aliases(
            db, list(set([item.biosample_accession for item in items] + [item.srs_accession for item in items]))
        )
    }

    for item in items:
        if item.biosample_accession in alias_to_sample_id:
            item.db_sample_id = alias_to_sample_id[item.biosample_accession]
            item.db_aliases_created = True
            totals.increment("sample_matched_by_biosample_name")

        elif item.srs_accession in alias_to_sample_id:
            item.db_sample_id = alias_to_sample_id[item.srs_accession]
            item.db_aliases_created = True
            totals.increment("sample_matched_by_sra_name")
    return items, totals


def match_sample_ids_by_hashes(db: Connection, items: list[SRARunResultFile]) -> tuple[list[SRARunResultFile], Stats]:
    totals = Stats()

    found_hashes = sql.get_sequencingdata_by_hashes(db, set(hash for item in items for hash in item.md5_hashes))

    to_remove = []
    for item in items:
        sample_id_candidates = list(set(found_hashes.get(h, None) for h in item.md5_hashes))

        if any(sample_id_candidates):
            # TODO: Should we?
            # if not all(sample_id_candidates):
            #     to_remove.append(item)
            #     log.warning(f"not all hashes are found: {sample_id_candidates}")
            #     totals.increment("sample_matched_by_md5_error_not_all_hashes_are_found", 1)
            #     continue
            if len(set(sample_id_candidates)) > 1:
                to_remove.append(item)
                log.warning(f"more than one match for {item.biosample_accession}")
                log.warning(f"sample ids matched are {sample_id_candidates}")
                totals.increment("sample_matched_by_md5_error_more_than_one_match", 1)
                continue

            item.db_sample_id = sample_id_candidates[0]

            # It means the biosample is there, we have an ID
            # So now we need to associate the rest of the files with this sample ID
            for same_sample_item in items:
                if same_sample_item.biosample_accession == item.biosample_accession:
                    same_sample_item.db_sample_id = item.db_sample_id

            totals.increment("sample_matched_by_md5", 1)
    for r in to_remove:
        items.remove(r)
    return items, totals


def create_missing_samples(
    db: Connection, tmp_package_id: int, items: list[SRARunResultFile]
) -> tuple[list[SRARunResultFile], Stats]:
    totals = Stats()

    to_be_created = [item for item in items if item.db_sample_id is None]
    if not to_be_created:
        return items, totals

    groups: dict[str, list[SRARunResultFile]] = {
        g: list(matches) for g, matches in groupby(to_be_created, lambda x: x.biosample_accession)
    }

    # create the new sample ids and spread it across
    sample_ids = sql.create_dummy_samples(db, tmp_package_id, len(groups))
    for i, (alias, matches) in enumerate(groups.items()):
        for item in matches:
            item.db_sample_id = sample_ids[i]
        totals.increment("new_sample_added")
    return items, totals


def create_missing_sample_aliases(
    db: Connection, tmp_package_id: int, items: list[SRARunResultFile]
) -> tuple[list[SRARunResultFile], Stats]:
    totals = Stats()

    # populate the aliases, but only once per sample
    new_aliases = []
    for key, matches in groupby(items, lambda x: x.db_sample_id):
        item = next(matches)
        if item.db_aliases_created:
            continue

        new_aliases.append(
            NewSampleAlias(
                tmp_package_id, item.db_sample_id, item.biosample_accession, "BioSample", "Sample name"
            )
        )
        new_aliases.append(
            NewSampleAlias(tmp_package_id, item.db_sample_id, item.srs_accession, "SRS", "Sample name")
        )
        totals.increment("new_sample_alias_added")

    if new_aliases:
        sql.insert_sample_aliases(db, new_aliases)
    return items, totals


def insert_sequencing_data(db: Connection, items: list[SRARunResultFile]) -> tuple[list[SRARunResultFile], Stats]:
    totals = Stats()
    if items:
        sql.insert_sequencingdata(db, items)
    totals.increment("sequencing_data_inserted", len(items))
    return items, totals
