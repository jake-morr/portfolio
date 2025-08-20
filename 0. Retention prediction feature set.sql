/* ================================
   Retention/registration feature set
   Term: Spring 2025 (202520)
   Excludes: non-UG pops M/Q, students registered in 202540/202535, and Spring 2025 grads
   Notes:
     - Uses institution GPA ("I") and cumulative GPA grouping ("C")
     - Completion ratio = credits_earned / credits_attempted (0 when attempted is 0 or NULL)
     - Academic standing is coded to small integers per rules below
   ================================= */

WITH params AS (
  SELECT 
    202520 AS p_acad_period_base,      -- Spring 2025 census/standing/etc.
    202540 AS p_reg_term_primary,      -- Next primary term to check registration
    202535 AS p_reg_term_alt,          -- Alt term (e.g., summer/session) to check registration
    'UG'     AS p_student_level,
    'I'      AS p_gpa_type_institution,
    'C'      AS p_gpa_grouping_cum,
    'G100'   AS p_pell_fund_code,      -- Pell fund
    '2425'   AS p_pell_aid_year_paid,  -- Aid year for Pell paid amounts
    '2526'   AS p_fa_app_aid_year,     -- Aid year for FAFSA/FA application status
    'OFIR'   AS p_first_gen_cohort     -- First-gen cohort code
  FROM dual
)

SELECT DISTINCT
    acst.id,
    acst.person_uid,

    /* Cumulative GPA as of the term using custom function (UG level) */
    odsmgr.zsko_transcripts.f_get_ewu_cum_gpa_term(
      acst.person_uid, 
      acst.academic_period, 
      'UG'
    )                                       AS cum_gpa,

    /* Term (spring) GPA from GPA-by-term table for the same period */
    gpt.gpa                                 AS spring_gpa,

    /* Academic standing coding:
       AD=1 (Academic Dismissal);
       P1/P2=2 (Probation 1/2); 
       AR=3 (Academic Recovery/Restriction);
       GS/00 or NULL=0 (Good Standing / Not coded) */
    CASE
      WHEN stand.academic_standing_end = 'AD'                             THEN 1
      WHEN stand.academic_standing IN ('P1', 'P2')                        THEN 2
      WHEN stand.academic_standing_end = 'AR'                             THEN 3
      WHEN stand.academic_standing_end IN ('GS', '00') 
        OR stand.academic_standing IS NULL                                THEN 0
    END                                          AS academic_standing,

    /* Class coding: FR=1, SO=2, JR=3, SR=4 */
    CASE acst.student_classification
      WHEN 'FR' THEN 1
      WHEN 'SO' THEN 2
      WHEN 'JR' THEN 3
      WHEN 'SR' THEN 4
    END                                          AS class,

    /* Completion ratio (credit-earned / credit-attempted), 0 if null or 0-attempted */
    ROUND(
      CASE 
        WHEN gpa.credits_attempted IS NULL OR gpa.credits_attempted = 0 
          THEN 0
        ELSE NVL(gpa.credits_earned, 0) / gpa.credits_attempted
      END
    , 3)                                         AS completion_ratio,

    /* Active registration hold (financial or otherwise) flag */
    CASE WHEN f1.person_uid IS NOT NULL THEN 1 ELSE 0 END  AS financial_hold,

    /* Full-time load (>=12 credits in the term) */
    CASE WHEN enr.total_credits >= 12 THEN 1 ELSE 0 END     AS full_time,

    /* Any D/F/W this term in institution courses (grade_value < 20 threshold) */
    CASE WHEN stc.person_uid IS NOT NULL THEN 1 ELSE 0 END  AS dfw,

    /* Pell paid in 24-25 (aid_year '2425') */
    CASE WHEN a.person_uid IS NOT NULL THEN 1 ELSE 0 END    AS pell,

    /* Receivables account balance */
    ra.account_balance,

    /* Financial aid applicant (FAFSA/FM) for aid year '2526' */
    CASE WHEN fa.person_uid IS NOT NULL THEN 1 ELSE 0 END   AS finaid_applicant,

    /* First-generation (cohort OFIR) */
    CASE WHEN fgen.person_uid IS NOT NULL THEN 1 ELSE 0 END AS fgen

FROM
    params p
    /* Spring 2025 census academic study population (primary driver) */
    JOIN census_academic_study acst
      ON acst.academic_period = p.p_acad_period_base
     AND acst.student_level   = p.p_student_level
     AND acst.student_population NOT IN ('M','Q')

    /* GPA by term (term GPA for the same period) */
    LEFT JOIN gpa_by_term gpt
      ON gpt.person_uid       = acst.person_uid
     AND gpt.academic_period  = acst.academic_period
     AND gpt.gpa_type         = p.p_gpa_type_institution

    /* First-gen cohort membership */
    LEFT JOIN student_cohort fgen
      ON fgen.person_uid = acst.person_uid
     AND fgen.cohort     = p.p_first_gen_cohort

    /* Student receivable balance */
    LEFT JOIN receivable_account ra
      ON ra.account_uid = acst.person_uid

    /* Pell paid (aid year 24-25, fund G100) */
    LEFT JOIN award_by_aid_year a
      ON a.person_uid         = acst.person_uid
     AND a.fund               = p.p_pell_fund_code
     AND a.total_paid_amount  > 0
     AND a.aid_year           = p.p_pell_aid_year_paid

    /* Course outcomes with D/F/W flag: institution courses w/ numeric grade < 20 */
    LEFT JOIN student_course stc
      ON stc.person_uid            = acst.person_uid
     AND stc.academic_period       = acst.academic_period
     AND stc.institution_course_ind = 'Y'
     AND stc.grade_value           < 20

    /* Institutional cumulative GPA record (for credits attempted/earned) */
    LEFT JOIN gpa
      ON gpa.person_uid    = acst.person_uid
     AND gpa.gpa_type      = p.p_gpa_type_institution
     AND gpa.gpa_grouping  = p.p_gpa_grouping_cum

    /* Enrollment for credits (used to define full-time) */
    INNER JOIN enrollment enr
      ON enr.person_uid      = acst.person_uid
     AND enr.academic_period = acst.academic_period

    /* Academic standing for the same term (primary program only) */
    LEFT JOIN academic_study stand
      ON stand.person_uid          = acst.person_uid
     AND stand.academic_period     = acst.academic_period
     AND stand.primary_program_ind = 'Y'

    /* Active registration holds (any active+registration hold) */
    LEFT JOIN hold f1
      ON f1.person_uid           = acst.person_uid
     AND f1.active_hold_ind      = 'Y'
     AND f1.registration_hold_ind = 'Y'

    /* Financial-aid applicant status (FAFSA/FM) for 25-26 */
    LEFT JOIN finaid_applicant_status fa
      ON fa.person_uid      = acst.person_uid
     AND fa.aid_year        = p.p_fa_app_aid_year
     AND fa.fm_application_ind = 'Y'

/* Exclude students already registered for upcoming terms (202540 or 202535) */
WHERE NOT EXISTS (
        SELECT 1
        FROM enrollment ret
        WHERE ret.person_uid = acst.person_uid
          AND ret.academic_period IN (p.p_reg_term_primary, p.p_reg_term_alt)
          AND ret.registered_ind = 'Y'
      )
/* Exclude students who already graduated in 202530 or have graduated flag */
  AND NOT EXISTS (
        SELECT 1
        FROM academic_outcome ao
        WHERE ao.person_uid = acst.person_uid
          AND (ao.graduated_ind = 'Y' OR ao.academic_period_graduation = 202530)
      )
;
