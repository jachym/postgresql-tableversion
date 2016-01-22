/**
* Get all tables that are modified by a revision.
*
* @param p_revision       The revision
* @return                 A tableset of modified table records
* @throws RAISE_EXCEPTION If the provided revision does not exist
*/
CREATE OR REPLACE FUNCTION ver_get_modified_tables(
    p_revision  INTEGER
)
RETURNS TABLE(
    schema_name NAME,
    table_name  NAME
) 
AS $$
BEGIN
    IF NOT EXISTS(SELECT * FROM table_version.revision WHERE id = p_revision) THEN
        RAISE EXCEPTION 'Revision % does not exist', p_revision;
    END IF;
            
    RETURN QUERY
        SELECT
            VTB.schema_name,
            VTB.table_name
        FROM
            table_version.versioned_tables VTB,
            table_version.tables_changed TBC
        WHERE
            VTB.id = TBC.table_id AND
            TBC.revision = p_revision
        ORDER BY
            VTB.schema_name,
            VTB.table_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/**
* Get tables that are modified for a given revision range.
*
* @param p_revision1      The start revision for the range
* @param p_revision2      The end revision for the range
* @return                 A tableset of records modified tables and revision when the change occured.
*/
CREATE OR REPLACE FUNCTION ver_get_modified_tables(
    p_revision1 INTEGER,
    p_revision2 INTEGER
) 
RETURNS TABLE(
    revision    INTEGER,
    schema_name NAME,
    table_name  NAME
) AS
$$
DECLARE
    v_revision1 INTEGER;
    v_revision2 INTEGER;
    v_temp      INTEGER;
BEGIN
    v_revision1 := p_revision1;
    v_revision2 := p_revision2;

    IF v_revision1 > v_revision2 THEN
        v_temp      := v_revision1;
        v_revision1 := v_revision2;
        v_revision2 := v_temp;
    END IF;
    
    RETURN QUERY
        SELECT
            TBC.revision,
            VTB.schema_name,
            VTB.table_name
        FROM
            table_version.versioned_tables VTB,
            table_version.tables_changed TBC
        WHERE
            VTB.id = TBC.table_id AND
            TBC.revision > v_revision1 AND
            TBC.revision <= v_revision2
        ORDER BY
            TBC.revision,
            VTB.schema_name,
            VTB.table_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

