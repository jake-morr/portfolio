select distinct acst.person_uid
, case when ret.person_uid is not null then 1 else 0 end as year_1_retained
, case when ret1.person_uid is not null then 1 else 0 end as retained_1q
, case when ret2.person_uid is not null then 1 else 0 end as retained_2q
, case when ao.person_uid is not null then 1 else 0 end as graduated
, case when cont.person_uid is not null then 1 else 0 end as persisting
, case when ent.person_uid is not null then credits else 0 end as credits
, case when fye.person_uid is not null then 1 else 0 end fye
, fyeg.grade
, case when fyeg.person_uid is not null and fyeg.grade < 20 then 1 
        when fyeg.person_uid is not null and fyeg.grade >= 20 then 0
        else null
        end failed_fye
, case when eop.person_uid is not null then 1 else 0 end eop
, odsmgr.ZSKO_TRANSCRIPTS.f_get_EWU_cum_gpa_term(acst.person_uid,(acst.academic_period + 90),acst.student_level) cum_gpa
, pdt.gender
, odsmgr.ZGKI_COMMON.f_get_race_federal(AcSt.person_uid,AcSt.academic_period) race
-- lived on campus
, case when AcSt.student_population = 'P' then 1 -- this is previous running start and should catch all running start, not just EWU running start
    when rs.person_uid is not null then 1 -- this catches EWU running start. Should be caught with the above, but this is extra
    else 0 end as running_start
, case when FirstGen.person_uid is not null then 'Y' else 'N' end first_gen
, case when hg.entity_uid is not null then '1' else '0' end as dorm
, acst.major
, case when alek.test_score >= 41 then 1 
        when mathi.person_uid is not null then 1
        when mathtn.person_uid is not null then 1
        else 0 end math_ready
, case --auto-enroll awp
    when (sat11.person_uid is not null and sat11.test_score >= 480) then 1
    when (sat01.person_uid is not null and sat01.test_score >= 450) then 1
    when (act01_1.person_uid is not null and act01_1.test_score >= 15) then 1
    when (act01_2.person_uid is not null and act01_2.test_score >= 18) then 1
    when awpi.person_uid is not null then 1
    when awptn.person_uid is not null then 1
    else 0
     end
     english_ready
, case when nsc.person_uid is not null then 1 else 0 end transferred

from census_academic_study acst

inner join census_enrollment enr
on enr.person_uid = acst.person_uid
and enr.academic_period = acst.academic_period

inner join person_detail pdt
on pdt.person_uid = acst.person_uid

left join
        (select person_uid
        from student_cohort
        where cohort = 'EOP') eop
on eop.person_uid = acst.person_uid

left join
    (select distinct stc.person_uid
    from student_course stc
    where (exists(select 'X'
                    from student_course stc1
                    where stc1.course_identification in ('ITGS110','ITGS120','ITGS130')
                    and stc1.academic_period between :term and (:term + 90) -- cohort term to summer after cohort term
                    and stc1.final_grade is not null
                    and stc1.person_uid = stc.person_uid))) fye
on fye.person_uid = acst.person_uid

left join (select acst2.person_uid
            from census_academic_study acst2
            where (exists(select 'X'
                        from census_academic_study acst3
                        where acst3.student_population = 'M'
                        and acst2.person_uid = acst3.person_uid))) rs
on rs.person_uid = acst.person_uid

left join (select person_uid
            , round(sum(credits_earned),0) credits
            from gpa
            where academic_period < :term -- cohort term
            and academic_period != 000000
            group by person_uid) ent
on ent.person_uid = acst.person_uid

left join (select person_uid, min(academic_period) as SC_TERM, COHORT
     from student_cohort
     where cohort = 'OFIR'
     group by person_uid, COHORT
) FirstGen
on acst.person_uid = FirstGen.person_uid
            
/* look for passed math at ewu */
left join
    (select distinct person_uid
    , academic_period
    from student_course
    where (subject = 'MATH' or course_identification = 'UNIVMTH')
    --and transfer_course_ind = 'N'
    and grade_value >= 20)
mathi
on mathi.person_uid = acst.person_uid
and mathi.academic_period < acst.academic_period

/* look for passed math elsewhere */
left join
    (select distinct person_uid
    , academic_period
    from student_course
    where (subject = 'MATH' or course_identification = 'UNIVMTH')
    and transfer_course_ind = 'Y'
    and ((substr(final_grade,3,3) >= '2.0')
        or (substr(final_grade,3,2) not in ('C-', 'D', 'D+', 'D-', 'F', 'W', 'NC'))))
mathtn
on mathtn.person_uid = acst.person_uid
and mathtn.academic_period < acst.academic_period

/* look for max aleks score */
left join
    (select distinct person_uid
    , test
    , max(test_score) test_score
    from test
    where test = 'ALEK' group by person_uid,test) alek
on alek.person_uid = acst.person_uid

/* look for max s11 score */
left join
    (select distinct person_uid
    , test
    , max(test_score) test_score
    from test
    where test = 'S11' and test_date >= '19-SEP-2018' group by person_uid,test)
sat11
on sat11.person_uid = acst.person_uid

/* look for max s01 score */
left join
    (select distinct person_uid
    , test
    , max(test_score) test_score
    from test
    where test = 'S01' and test_date < '19-SEP-2018' group by person_uid,test)
sat01
on sat01.person_uid = acst.person_uid

/* look for max a01 score */
left join
    (select distinct person_uid
    , test
    , max(test_score) test_score
    from test
    where test = 'A01' and test_date >= '19-SEP-2018' group by person_uid,test)
act01_1
on act01_1.person_uid = acst.person_uid

/* look for max a01 score */
left join
    (select distinct person_uid
    , test
    , max(test_score) test_score
    from test
    where test = 'A01' and test_date < '19-SEP-2018' group by person_uid,test)
act01_2
on act01_2.person_uid = acst.person_uid

/* look for passed engl at ewu */
left join
    (select distinct person_uid
    , academic_period
    from student_course
    where course_identification in ('ENGL101', 'ENGL113', 'ENGL201', 'UNIVEW1', 'UNIVEW2')
    --and transfer_course_ind = 'N'
    and grade_value >= 20)
awpi
on awpi.person_uid = acst.person_uid
and awpi.academic_period < acst.academic_period

/* look for passed engl elsewhere */
left join
    (select distinct person_uid
    , academic_period
    from student_course
    where course_identification in ('ENGL101', 'ENGL113', 'ENGL201', 'UNIVEW1', 'UNIVEW2')
    and transfer_course_ind = 'Y'
    and ((substr(final_grade,3,3) >= '2.0')
        or (substr(final_grade,3,2) not in ('C-', 'D', 'D+', 'D-', 'F', 'W', 'NC'))))
awptn
on awptn.person_uid = acst.person_uid
and awptn.academic_period < acst.academic_period

/* high grade in FYE */
left join
    (select distinct person_uid
    , max(grade_value) grade
    from student_course
    where course_identification in ('ITGS110','ITGS120','ITGS130')
    and final_grade is not null
    group by person_uid) fyeg
on fyeg.person_uid = acst.person_uid

/* did the student_graduate */

left join
    (select distinct person_uid
    from academic_outcome
    where graduated_ind = 'Y'
    and academic_period_graduation > :term
    and award_category = '24') ao
on ao.person_uid = acst.person_uid

/* is the student still at the university */

left join
    (select distinct person_uid
    from census_academic_study
    where academic_period > 202030
    and student_level in ('US','UG')) cont
on cont.person_uid = acst.person_uid

            /* NSC data */
            left join
                (select distinct person_uid
                from nsc_st_data
                where enrollment_begin > '01-JAN-18'
                and college_code_branch != '003775-00') nsc
            on nsc.person_uid = acst.person_uid


            left join
                (select entity_uid
                from address 
                where address_type = 'HG'
                and substr(address_start_date,8,2) in (17,18)) hg
            on hg.entity_uid = acst.person_uid

            left join (select acst4.person_uid
                        from census_academic_study acst4
                        where (exists(select 'X'
                                    from census_academic_study acst5
                                    where academic_period in (201840,201835) -- cohort term + 1
                                    and acst4.person_uid = acst5.person_uid))
                        and acst4.academic_period = :term
                        and acst4.student_level in ('UG','US')
                        and acst4.student_population in ('F','B','I','P')
                        ) ret
            on ret.person_uid = acst.person_uid
            
            left join (select acst6.person_uid
                        from census_academic_study acst6
                        where (exists(select 'X'
                                    from census_academic_study acst7
                                    where academic_period in (201820,201815) -- spring after cohort term
                                    and acst6.person_uid = acst7.person_uid))
                        and acst6.academic_period = :term
                        and acst6.student_level in ('UG','US')
                        and acst6.student_population in ('F','B','I','P')) ret2
            on ret2.person_uid = acst.person_uid
            
            left join (select acst8.person_uid
                        from census_academic_study acst8
                        where (exists(select 'X'
                                    from census_academic_study acst9
                                    where academic_period in (201810,201815) -- winter after cohort term
                                    and acst8.person_uid = acst9.person_uid))
                        and acst8.academic_period = :term
                        and acst8.student_level in ('UG','US')
                        and acst8.student_population in ('F','B','I','P')) ret1
            on ret1.person_uid = acst.person_uid

where AcSt.academic_period in (:term) -- cohort year
and AcSt.student_population in ('F','B','I','P') 
and AcSt.student_level in ('UG','US')
and enr.total_credits >= 12
