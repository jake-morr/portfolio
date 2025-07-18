-- ============================================
-- STUDENT RETENTION TRACKING QUERY
-- Pulls FTIC, registration persistence, and college info
-- for undergraduate students across Fall 2020–2024
-- ============================================

SELECT DISTINCT 
    person_uid,
    academic_period, 
    class, 
    registered, 
    ftic,
    college
FROM (
    SELECT DISTINCT 
        acst.person_uid, 
        
        -- Normalize academic period (convert 'xx15' to 'xx20')
        CASE 
            WHEN SUBSTR(acst.academic_period, 5, 2) = '15' 
                THEN SUBSTR(acst.academic_period, 1, 4) || '20'
            ELSE acst.academic_period
        END AS academic_period,

        -- Normalize student classification
        CASE 
            WHEN acst.student_classification = 'EF' THEN 'FR' 
            ELSE acst.student_classification 
        END AS class,

        -- Registration flag based on presence in Winter terms
        CASE 
            WHEN acst.academic_period IN (202520,202515) AND reg23.person_uid IS NOT NULL THEN 1 
            WHEN acst.academic_period IN (202420,202415) AND reg22.person_uid IS NOT NULL THEN 1
            WHEN acst.academic_period IN (202320,202315) AND reg21.person_uid IS NOT NULL THEN 1
        END AS registered,

        -- FTIC Flag (from prior term with 12+ credits and valid populations)
        CASE 
            WHEN ftic.person_uid IS NOT NULL THEN 1 
            ELSE 0 
        END AS ftic,

        -- Filtered college description for declared majors in selected colleges
        CASE 
            WHEN acst.major NOT LIKE 'Q%' 
                 AND acst.academic_period IN (202520,202515) 
                 AND acst.college IN ('HS', 'PS', 'US', 'ST') 
                 THEN acst.college_desc 
            ELSE NULL 
        END AS college

    FROM census_academic_study acst

    -- Join to enrollment table to ensure active records
    INNER JOIN census_enrollment enr
        ON enr.person_uid = acst.person_uid
        AND enr.academic_period = acst.academic_period

    -- ==============================
    -- Identify First-Time-In-College
    -- ==============================
    LEFT JOIN (
        SELECT acst.person_uid,
               SUBSTR(acst.academic_period, 1, 4) || '40' AS academic_period
        FROM census_academic_study acst
        INNER JOIN census_enrollment enr
            ON enr.academic_period = acst.academic_period
            AND enr.person_uid = acst.person_uid
            AND enr.total_credits >= 12
        WHERE SUBSTR(acst.academic_period, 5, 2) IN ('35','40')
          AND acst.student_population IN ('B', 'F', 'I', 'P')
          AND acst.admissions_population IN ('AI', 'AL', 'CA', 'CR', 'FB', 'FC', 'FI', 'FO', 'FR', 'GD', 'IE', 'IN')
          AND acst.academic_period >= 202135
    ) ftic
    ON ftic.person_uid = acst.person_uid
    AND (ftic.academic_period + 100) = acst.academic_period

    -- ==============================
    -- Flag Re-Registration: Winter 2023
    -- ==============================
    LEFT JOIN (
        SELECT DISTINCT person_uid 
        FROM academic_study 
        WHERE registered_ind = 'Y'
          AND academic_period IN (202540, 202435)
    ) reg23
    ON acst.person_uid = reg23.person_uid

    -- ==============================
    -- Flag Re-Registration: Winter 2022
    -- ==============================
    LEFT JOIN (
        SELECT DISTINCT enr.person_uid,
                        '202420' AS academic_period_for,
                        '202415' AS academic_period_for2
        FROM daily_enrollment_summ_ewu enr
        INNER JOIN (
            SELECT DISTINCT ewu_quarter_start_date, ewu_quarter_code AS term
            FROM dim_date
            WHERE ewu_quarter_code = 202440
        ) d
        ON enr.academic_period IN (d.term, d.term - 5)
        WHERE enr.academic_period IN (202440, 202435)
          AND enr.freeze_event = 'DAILY'
          AND TRUNC(enr.freeze_date) = (
              SELECT DISTINCT ewu_quarter_start_date - TRUNC(SYSDATE)
              FROM dim_date 
              WHERE ewu_quarter_code = 202540
          )
    ) reg22
    ON acst.person_uid = reg22.person_uid
    AND acst.academic_period IN (reg22.academic_period_for, reg22.academic_period_for2)

    -- ==============================
    -- Flag Re-Registration: Winter 2021
    -- ==============================
    LEFT JOIN (
        SELECT DISTINCT enr.person_uid,
                        '202320' AS academic_period_for,
                        '202315' AS academic_period_for2
        FROM daily_enrollment_summ_ewu enr
        INNER JOIN (
            SELECT DISTINCT ewu_quarter_start_date, ewu_quarter_code AS term
            FROM dim_date
            WHERE ewu_quarter_code = 202340
        ) d
        ON enr.academic_period IN (d.term, d.term - 5)
        WHERE enr.academic_period IN (202340, 202335)
          AND enr.freeze_event = 'DAILY'
          AND TRUNC(enr.freeze_date) = (
              SELECT DISTINCT ewu_quarter_start_date - TRUNC(SYSDATE)
              FROM dim_date 
              WHERE ewu_quarter_code = 202540
          )
    ) reg21
    ON acst.person_uid = reg21.person_uid
    AND acst.academic_period IN (reg21.academic_period_for, reg21.academic_period_for2)

    -- ==============================
    -- EXCLUSIONS
    -- ==============================

    WHERE NOT EXISTS (
        -- Exclude students who graduated in the current or immediate next term
        SELECT 1 
        FROM academic_outcome ao 
        WHERE ao.academic_period_graduation IN (acst.academic_period, acst.academic_period + 10)
          AND ao.person_uid = acst.person_uid
    )
    AND acst.student_level IN ('UG', 'US')           -- Undergraduate students only
    AND acst.student_population != 'M'               -- Exclude special admit students
    AND acst.academic_period IN (
        202520, 202420, 202320, 
        202515, 202415, 202315
    )
)

ORDER BY person_uid, academic_period;
