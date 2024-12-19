from src.common.logs import create_logger
from src.db.database import Connection

log = create_logger(__name__)

def get_object_without_project_imported_count(db: Connection, tmp_project_id: int, obj:str) -> int:
   
    valid_objects = {"sample", "samplealias"}
    if obj not in valid_objects:
        log.error(
            "Function get_object_without_project_imported_count was provided incorrect object value %",
            object
        )
        raise

    curr = db.cursor()
    target = f"SELECT COUNT(id) FROM public.submission_{obj} s "
    conditions = f"WHERE s.package_id = {tmp_project_id} "

    if obj == "sample":
        additional_conditions = " AND s.biosample_id IS NOT NULL"
    elif obj == "samplealias":
        additional_conditions = " AND s.origin='BioSample' AND s.origin_label='Sample name'"

    curr.execute(
        target + conditions + additional_conditions
    )
    count = curr.fetchone()
    assert count
    return count[0]

def get_objects_without_project_imported(
    db: Connection, tmp_project_id: int, per_page: int, last_id: int, obj: str
) -> list[tuple[int, int]]:

    valid_objects = {"sample", "samplealias"}
    if obj not in valid_objects:
        log.error(
            "Function get_objects_without_project_imported was provided incorrect object value %",
            obj
        )
        raise Exception

    if obj == "sample":
        target_conditions = """
        SELECT s.id, s.biosample_id FROM public.submission_sample s
        WHERE s.biosample_id IS NOT NULL 
        """
    elif obj == "samplealias":
        target_conditions = """
        SELECT s.id, s.name FROM public.submission_samplealias s
        WHERE s.origin='BioSample' and s.origin_label='Sample name' 
        """ 

    additional_conditions =  f"AND s.id > {last_id} AND s.package_id = {tmp_project_id} "
    order = f"ORDER BY s.id LIMIT {per_page}"

    curr = db.cursor()
    curr.execute(
        target_conditions + additional_conditions + order 
    )
    objects = curr.fetchall()
    return objects  # type: ignore



def get_or_create_data_package_by_ncbi_id(db: Connection, bioproject_id: int, bioproject_name: str) -> int:
    curr = db.cursor()

    curr.execute("SELECT id FROM public.submission_package WHERE bioproject_id = %s;", (bioproject_id,))
    existing = curr.fetchone()
    if existing:
        return existing[0]

    curr.execute(
        """
        INSERT INTO public.submission_package(
            "origin", "bioproject_id", "name", "submitted_on",
            "state_changed_on", "state", "matching_state", "rejection_reason")
        VALUES ('NCBI', %s, %s, NOW(), NOW(), '', '', '')
        RETURNING id;
    """,
        (bioproject_id, bioproject_name),
    )

    new_package = curr.fetchone()
    assert new_package
    return new_package[0]


def move_sample_data_to_new_package(
    db: Connection, new_package_id: int, biosample_ids: list[int]
) -> tuple[int, int, int]:
    curr = db.cursor()

    curr.execute(
        """
UPDATE public.submission_sample
SET package_id=%s
WHERE biosample_id = ANY(%s)
""",
        (new_package_id, biosample_ids),
    )
    samples_updated = curr.rowcount

    curr.execute(
        """
UPDATE public.submission_pdstest
SET package_id=%s
WHERE sample_id IN (
    SELECT id
    FROM public.submission_sample
    WHERE biosample_id = ANY(%s)
) AND sample_alias_id in (
    SELECT public.submission_samplealias.id
    FROM public.submission_samplealias
    INNER JOIN public.submission_sample pss on pss.id= sample_id
    WHERE public.submission_samplealias.origin='BioSample' 
        AND public.submission_samplealias.origin_label='Sample name'
        AND biosample_id=ANY(%s)
);
""",
        (new_package_id, biosample_ids, biosample_ids),
    )

    pdst_updated = curr.rowcount

    return samples_updated, pdst_updated

def move_alias_data_to_package(
    db: Connection, new_package_id: int, aliases_to_update: list[str]
) -> tuple[int, int, int]:
    curr = db.cursor()

    curr.execute(
        """
UPDATE public.submission_samplealias
SET package_id=%s
WHERE name like ANY(%s) and origin in ('BioSample', 'SRS');
""",
        (new_package_id, aliases_to_update),
    )
    aliases_updated = curr.rowcount

    return aliases_updated
