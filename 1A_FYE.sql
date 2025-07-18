-- ========================================
-- STUDENT RETENTION & ATTRIBUTES QUERY
-- Builds a dataset for a specific cohort term
-- Author: Jake Morrison
-- ========================================

SELECT DISTINCT 
    acst.person_uid,

    -- Retention Outcomes
    CASE WHEN ret.person_uid IS NOT NULL THEN 1 ELSE 0 END AS year_1_retained,
    CASE WHEN ret1.person_uid IS NOT NULL THEN 1 ELSE 0 END AS retained_1q,
    CASE WHEN ret2.person_uid IS NOT NULL THEN 1 ELSE 0 END AS retained_2q,
    CASE WHEN ao.person_uid IS NOT NULL THEN 1 ELSE 0 END AS graduated,
    CASE WHEN cont.person_uid IS NOT NULL THEN 1 ELSE 0 END AS persisting,

    -- Pre-College Metrics
    CASE WHEN ent.person_uid IS NOT NULL THEN credits ELSE 0 END AS credits,  -- transfer-in credits
    CASE WHEN fye.person_uid IS NOT NULL THEN 1 ELSE 0 END AS fye,            -- enrolled in FYE
    fyeg.grade,                                                               -- highest FYE grade
    CASE 
        WHEN fyeg.person_uid IS NOT NULL AND fyeg.grade < 20 THEN 1 
        WHEN fyeg.person_uid IS NOT NULL AND fyeg.grade >= 20 THEN 0 
        ELSE NULL 
    END AS failed_fye,

    -- Special Populations
    CASE WHEN eop.person_uid IS NOT NULL THEN 1 ELSE 0 END AS eop,  -- EOP program
    odsmgr.ZSKO_TRANSCRIPTS.f_get_EWU_cum_gpa_term(acst.person_uid, (acst.academic_period + 90), acst.student_level) AS cum_gpa,

    -- Demographics
    pdt.gender,
    odsmgr.ZGKI_COMMON.f_get_race_federal(acst.person_uid, acst.academic_period) AS race,
    CASE 
        WHEN acst.student_population = 'P' THEN 1            -- Running Start by population
        WHEN rs.person_uid IS NOT NULL THEN 1                -- Running Start by enrollment
        ELSE 0 
    END AS running_start,
    CASE WHEN FirstGen.person_uid IS NOT NULL THEN 'Y' ELSE 'N' END AS first_gen,
    CASE WHEN hg.entity_uid IS NOT NULL THEN '1' ELSE '0' END AS dorm, -- on-campus housing

    -- Academic Preparation
    acst.major,
    CASE 
        WHEN alek.test_score >= 41 THEN 1                    -- ALEKS math placement
        WHEN mathi.person_uid IS NOT NULL THEN 1             -- passed math at EWU
        WHEN mathtn.person_uid IS NOT NULL THEN 1            -- passed transfer math
        ELSE 0 
    END AS math_ready,

    CASE  -- English readiness via standardized tests or coursework
        WHEN sat11.person_uid IS NOT NULL AND sat11.test_score >= 480 THEN 1
        WHEN sat01.person_uid IS NOT NULL AND sat01.test_score >= 450 THEN 1
        WHEN act01_1.person_uid IS NOT NULL AND act01_1.test_score >= 15 THEN 1
        WHEN act01_2.person_uid IS NOT NULL AND act01_2.test_score >= 18 THEN 1
        WHEN awpi.person_uid IS NOT NULL THEN 1
        WHEN awptn.person_uid IS NOT NULL THEN 1
        ELSE 0 
    END AS english_ready,

    -- Transfer-out flag
    CASE WHEN nsc.person_uid IS NOT NULL THEN 1 ELSE 0 END AS transferred

FROM census_academic_study acst

-- Required Enrollment and Demographics
INNER JOIN census_enrollment enr ON enr.person_uid = acst.person_uid AND enr.academic_period = acst.academic_period
INNER JOIN person_detail pdt ON pdt.person_uid = acst.person_uid

-- ---- Left Joins for Attributes ----

-- EOP program participation
LEFT JOIN (
    SELECT person_uid FROM student_cohort WHERE cohort = 'EOP'
) eop ON eop.person_uid = acst.person_uid

-- Enrolled in FYE course
LEFT JOIN (
    SELECT DISTINCT stc.person_uid
    FROM student_course stc
    WHERE EXISTS (
        SELECT 1 FROM student_course stc1
        WHERE stc1.course_identification IN ('ITGS110', 'ITGS120', 'ITGS130')
          AND stc1.academic_period BETWEEN :term AND (:term + 90)
          AND stc1.final_grade IS NOT NULL
          AND stc1.person_uid = stc.person_uid
    )
) fye ON fye.person_uid = acst.person_uid

-- Running Start: alternative catch-all
LEFT JOIN (
    SELECT acst2.person_uid
    FROM census_academic_study acst2
    WHERE EXISTS (
        SELECT 1 FROM census_academic_study acst3
        WHERE acst3.student_population = 'M'
          AND acst3.person_uid = acst2.person_uid
    )
) rs ON rs.person_uid = acst.person_uid

-- Prior transfer-in credits
LEFT JOIN (
    SELECT person_uid, ROUND(SUM(credits_earned), 0) AS credits
    FROM gpa
    WHERE academic_period < :term AND academic_period != 000000
    GROUP BY person_uid
) ent ON ent.person_uid = acst.person_uid

-- First-generation status (OFIR cohort)
LEFT JOIN (
    SELECT person_uid FROM student_cohort WHERE cohort = 'OFIR'
    GROUP BY person_uid
) FirstGen ON acst.person_uid = FirstGen.person_uid

-- Passed math at EWU
LEFT JOIN (
    SELECT DISTINCT person_uid, academic_period
    FROM student_course
    WHERE (subject = 'MATH' OR course_identification = 'UNIVMTH')
      AND grade_value >= 20
) mathi ON mathi.person_uid = acst.person_uid AND mathi.academic_period < acst.academic_period

-- Passed math elsewhere (transfer)
LEFT JOIN (
    SELECT DISTINCT person_uid, academic_period
    FROM student_course
    WHERE (subject = 'MATH' OR course_identification = 'UNIVMTH')
      AND transfer_course_ind = 'Y'
      AND (
            SUBSTR(final_grade, 3, 3) >= '2.0'
            OR SUBSTR(final_grade, 3, 2) NOT IN ('C-', 'D', 'D+', 'D-', 'F', 'W', 'NC')
          )
) mathtn ON mathtn.person_uid = acst.person_uid AND mathtn.academic_period < acst.academic_period

-- Highest ALEKS score
LEFT JOIN (
    SELECT person_uid, MAX(test_score) AS test_score
    FROM test WHERE test = 'ALEK' GROUP BY person_uid
) alek ON alek.person_uid = acst.person_uid

-- Highest SAT/ACT scores (split by pre/post 2018 date)
LEFT JOIN (
    SELECT person_uid, MAX(test_score) AS test_score
    FROM test WHERE test = 'S11' AND test_date >= '19-SEP-2018' GROUP BY person_uid
) sat11 ON sat11.person_uid = acst.person_uid

LEFT JOIN (
    SELECT person_uid, MAX(test_score) AS test_score
    FROM test WHERE test = 'S01' AND test_date < '19-SEP-2018' GROUP BY person_uid
) sat01 ON sat01.person_uid = acst.person_uid

LEFT JOIN (
    SELECT person_uid, MAX(test_score) AS test_score
    FROM test WHERE test = 'A01' AND test_date >= '19-SEP-2018' GROUP BY person_uid
) act01_1 ON act01_1.person_uid = acst.person_uid

LEFT JOIN (
    SELECT person_uid, MAX(test_score) AS test_score
    FROM test WHERE test = 'A01' AND test_date < '19-SEP-2018' GROUP BY person_uid
) act01_2 ON act01_2.person_uid = acst.person_uid

-- Passed English at EWU or transfer
LEFT JOIN (
    SELECT DISTINCT person_uid, academic_period
    FROM student_course
    WHERE course_identification IN ('ENGL101','ENGL113','ENGL201','UNIVEW1','UNIVEW2')
      AND grade_value >= 20
) awpi ON awpi.person_uid = acst.person_uid AND awpi.academic_period < acst.academic_period

LEFT JOIN (
    SELECT DISTINCT person_uid, academic_period
    FROM student_course
    WHERE course_identification IN ('ENGL101','ENGL113','ENGL201','UNIVEW1','UNIVEW2')
      AND transfer_course_ind = 'Y'
      AND (
            SUBSTR(final_grade, 3, 3) >= '2.0'
            OR SUBSTR(final_grade, 3, 2) NOT IN ('C-', 'D', 'D+', 'D-', 'F', 'W', 'NC')
          )
) awptn ON awptn.person_uid = acst.person_uid AND awptn.academic_period < acst.academic_period

-- Max FYE course grade
LEFT JOIN (
    SELECT person_uid, MAX(grade_value) AS grade
    FROM student_course
    WHERE course_identification IN ('ITGS110','ITGS120','ITGS130') AND final_grade IS NOT NULL
    GROUP BY person_uid
) fyeg ON fyeg.person_uid = acst.person_uid

-- Graduation status (award category 24 = bachelor's)
LEFT JOIN (
    SELECT DISTINCT person_uid
    FROM academic_outcome
    WHERE graduated_ind = 'Y'
      AND academic_period_graduation > :term
      AND award_category = '24'
) ao ON ao.person_uid = acst.person_uid

-- Persistence (enrolled after cohort year)
LEFT JOIN (
    SELECT DISTINCT person_uid
    FROM census_academic_study
    WHERE academic_period > 202030 AND student_level IN ('US','UG')
) cont ON cont.person_uid = acst.person_uid

-- NSC match = transferred elsewhere
LEFT JOIN (
    SELECT DISTINCT person_uid
    FROM nsc_st_data
    WHERE enrollment_begin > '01-JAN-18'
      AND college_code_branch != '003775-00'
) nsc ON nsc.person_uid = acst.person_uid

-- On-campus housing indicator
LEFT JOIN (
    SELECT entity_uid
    FROM address
    WHERE address_type = 'HG'
      AND SUBSTR(address_start_date, 8, 2) IN (17, 18)
) hg ON hg.entity_uid = acst.person_uid

-- Retention Checks: Year 1, 1Q, 2Q
LEFT JOIN (
    SELECT person_uid
    FROM census_academic_study
    WHERE academic_period IN (201840, 201835) -- cohort + 1 year
) ret ON ret.person_uid = acst.person_uid

LEFT JOIN (
    SELECT person_uid
    FROM census_academic_study
    WHERE academic_period IN (201810, 201815) -- cohort + winter
) ret1 ON ret1.person_uid = acst.person_uid

LEFT JOIN (
    SELECT person_uid
    FROM census_academic_study
    WHERE academic_period IN (201820, 201815) -- cohort + spring
) ret2 ON ret2.person_uid = acst.person_uid

-- ---- Filter: Cohort Definition ----
WHERE 
    acst.academic_period = :term
    AND acst.student_population IN ('F', 'B', 'I', 'P')  -- degree-seeking UG
    AND acst.student_level IN ('UG', 'US')
    AND enr.total_credits >= 12                         -- full-time status
