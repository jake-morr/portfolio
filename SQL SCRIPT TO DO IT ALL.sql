select distinct
   AcSt.person_uid
,  AcSt.name
, AcSt.ID
, ZSKO_TRANSCRIPTS.F_GET_OVRL_CUM_CR_TERM(AcSt.person_uid,AcSt.academic_period) AS credits
, GPA.gpa --not sure if this is correct. Might be a function for term
, ZSKO_TRANSCRIPTS.f_get_EWU_cum_gpa_term(AcSt.person_uid,AcSt.academic_period) AS cum_gpa
, AcSt.student_classification
, AcSt.major_desc -- dont forget primary program indicator
, AcSt.college_desc
-- academic_standing
, AcSt.academic_standing_desc
, AcSt.primary_advisor_name_FMIL
, AcSt.primary_advisor_type_desc
, hold.hold_desc
, hold.active_hold_ind
, hold.registration_hold_ind
, case when
    (AcSt.registered_ind = 'Y' and AcSt.academic_period = '202030') then 'Y' else null end summer
-- figure out if enrolled in summer
, AO.last_status
, AO.graduated_ind
, AO.outcome_graduation_date
, AcSt.admissions_population_desc
, AcSt.student_population_desc
, AcSt.student_population

from ACADEMIC_STUDY AcSt

inner join GPA_BY_TERM GPA
on GPA.person_uid = AcSt.person_uid
and GPA.academic_period = AcSt.academic_period

left join 
    (select hold.person_uid
    , hold.hold_desc
    , hold.active_hold_ind
    , hold.registration_hold_ind
    from HOLD
    where active_hold_ind = 'Y')
    hold
on hold.person_uid = AcSt.person_uid
--may not be what we want

left join
    (select person_uid
    , MAX(STATUS_DESC) OVER (PARTITION BY PERSON_UID) last_status
    , MAX(graduated_ind) over (partition by PERSON_UID) graduated_ind
    , MAX(OUTCOME_GRADUATION_DATE) OVER (PARTITION BY PERSON_UID) outcome_graduation_date

from academic_outcome) AO
on AO.person_uid = AcSt.person_uid

--not exists for fall 2020 enrollment

where AcSt.academic_period in ('202020','202015')
and AcSt.primary_program_ind = 'Y'
and AcSt.registered_ind = 'Y'
and AcSt.student_level in ('US','UG')
and (AO.graduated_ind = 'N' or AO.graduated_ind is null)
and AcSt.student_population not in ('M','Q')
and (not exists(select 'X'
    from academic_study AcSt2
    where registered_ind = 'Y'
    and academic_period in ('202040','202035')
    and AcSt.person_uid = AcSt2.person_uid))
order by AcSt.person_uid
