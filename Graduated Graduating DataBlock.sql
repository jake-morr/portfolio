select distinct slot.graduated_ind
, slot.id
, slot.name
, slot.student_level
, slot.academic_period_graduated
, slot.academic_period_graduated_desc
, slot.college_desc
, slot.department_desc
, slot.campus_desc
, slot.degree_desc
, slot.type
, slot.discipline
, slot.CONCENTRATION_DESC
, slot.program
, slot.program_desc
, FILL.CATALOG_ACADEMIC_PERIOD_DESC catalog
, fill.year_graduated
, fill.year_graduated_desc
, fill.outcome_application_date
, fill.outcome_graduation_date
, fill.transfer_work_exists_ind
, fill.award_category
, fill.award_status
, fill.award_status_desc
--, fill.program maybe grab this in slot
--, fill.program_desc slot
, fill.graduation_status
, fill.graduation_status_desc
, fill.academic_period_grad_req_comp
, fill.acad_per_grad_req_comp_desc
/*, fill.cumalative_credits_attempted
, fill.cumalative_credits_earned
, fill.cumalative_credits_passed
, fill.cumalative_gpa_credits
, fill.cumalative_quality_points
, fill.cumalative_gpa
, fill.CUMALATIVE__level_GPA
, fill.cum_inst_credits_attempted
, fill.cum_inst_credits_earned
, fill.cum_inst_credits_passed
, fill.cum_inst_quality_points
, fill.cumalative_institution_gpa
, fill.cum_transfer_credits_attempted
, fill.cum_transfer_credits_earned
, fill.cum_transfer_credits_passed
, fill.cum_transfer_quality_points
, fill.cumalative_transfer_gpa*/
, FILL.INSTITUTION_GPA
, FILL.INSTITUTION_GPA_CREDITS
, FILL.INSTITUTION_CREDITS_ATTEMPTED
, FILL.INSTITUTION_CREDITS_EARNED
, FILL.INSTITUTION_CREDITS_PASSED
, FILL.INSTITUTION_QUALITY_POINTS
, FILL.OVERALL_GPA
, FILL.OVERALL_GPA_CREDITS
, FILL.OVERALL_CREDITS_ATTEMPTED
, FILL.OVERALL_CREDITS_EARNED
, FILL.OVERALL_CREDITS_PASSED
, FILL.OVERALL_QUALITY_POINTS
, FILL.TRANSFER_GPA
, FILL.TRANSFER_GPA_CREDITS
, FILL.TRANSFER_CREDITS_ATTEMPTED
, FILL.TRANSFER_CREDITS_EARNED
, FILL.TRANSFER_CREDITS_PASSED
, FILL.TRANSFER_QUALITY_POINTS
, fill.HONORS_COUNT
, FILL.MAILING_NAME_PREFERRED PREFERRED_NAME
, FILL.CONFIDENTIALITY_IND
, fill.LAST_NAME
, fill.FIRST_NAME
, fill.MIDDLE_NAME
, fill.MIDDLE_INITIAL
, fill.FULL_NAME_FMIL
, fill.FULL_NAME_LFMI
, fill.LEGAL_NAME
, fill.CURRENT_AGE
, fill.Birth_date
, fill.sex
, fill.sex_desc
, fill.user_name
, fill.age_admitted
, fill.year_admitted
, fill.year_admitted_desc
, fill.admissions_population
, fill.admissions_population_desc
, fill.primary_advisor_type
, fill.primary_advisor_type_desc
, fill.primary_advisor_name_fmil
, fill.CREDITS_ENROLLED_GRAD_PERIOD
, FILL.EMAIL_ADDRESS STUDENT_EMAIL
, FILL.HOLD

from
(select GRADUATED_IND GRADUATED_ind
        , ID
		, NAME
        , student_level
        , academic_period_graduation academic_period_graduated
		, academic_period_grad_desc academic_period_graduated_desc
        --, college_code
        , case when field_of_study_type = 'Minor' then null else college_desc end as college_desc
        --, department_code
        , case when field_of_study_type = 'Minor' then null else department_desc end as department_desc
        --, campus_code
        , campus_desc
        --, degree_code
        ,  case when field_of_study_type = 'Minor' then null else degree_desc end as degree_desc
        --, catalog_academic_period
        ----, catalog_academic_period_grad_desc
        , case when field_of_study_type = 'Major' then program else null end as program
        , case when field_of_study_type = 'Major' then program_desc else null end as program_desc
        , field_of_study_type TYPE
       --, field_of_study_desc
       --, field_of_study_code
        , field_of_study_desc DISCIPLINE
        , concentration_desc CONCENTRATION_DESC
        --, concentration_code
        , person_uid

from (

        /* first major, first concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(major, 1, 1) = '0' then major_desc
                        when substr(major, 1, 1) = 'U' then major_desc --|| ' (undeclared)'
                        when substr(major, 1, 1) = 'Q' then major_desc --|| ' (pre-major)'
                        else major_desc end
                     else major_desc end as field_of_study_desc
                , first_concentration_desc as concentration_desc
                , person_uid
                --, first_concentration as concentration_code
                from academic_outcome
                ----where primary_program_ind = 'Y'
                where major is not null

        union

        /* first major, second concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(major, 1, 1) = '0' then major_desc
                        when substr(major, 1, 1) = 'U' then major_desc --|| ' (undeclared)'
                        when substr(major, 1, 1) = 'Q' then major_desc --|| ' (pre-major)'
                        else major_desc end
                     else major_desc end as field_of_study_desc
                , second_concentration_desc as concentration_desc
                , person_uid
                --, second_concentration as concentration_code
                from academic_outcome
                ----where primary_program_ind = 'Y'
                where major is not null
                and second_concentration is not null

        union

        /* first major, third concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(major, 1, 1) = '0' then major_desc
                        when substr(major, 1, 1) = 'U' then major_desc --|| ' (undeclared)'
                        when substr(major, 1, 1) = 'Q' then major_desc --|| ' (pre-major)'
                        else major_desc end
                     else major_desc end as field_of_study_desc
                , third_concentration_desc as concentration_desc
                --, third_concentration as concentration_code
                , person_uid
                from academic_outcome
                ----where primary_program_ind = 'Y'
                where major is not null
                and third_concentration is not null

        union

        /* second major, first concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , second_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , second_program_classification progam
                , second_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(second_major, 1, 1) = '0' then second_major_desc
                        when substr(second_major, 1, 1) = 'U' then second_major_desc --|| ' (undeclared)'
                        when substr(second_major, 1, 1) = 'Q' then second_major_desc --|| ' (pre-major)'
                        else second_major_desc end
                     else second_major_desc end as field_of_study_desc
                , second_major_conc_1_desc as concentration_desc
                --, second_major_conc_1 as concentration_code
                , person_uid
                from academic_outcome
                ----where primary_program_ind = 'Y'
                where second_major is not null

        union

        /* second major, second concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , second_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , second_program_classification progam
                , second_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(second_major, 1, 1) = '0' then second_major_desc
                        when substr(second_major, 1, 1) = 'U' then second_major_desc --|| ' (undeclared)'
                        when substr(second_major, 1, 1) = 'Q' then second_major_desc --|| ' (pre-major)'
                        else second_major_desc end
                     else second_major_desc end as field_of_study_desc
                , second_major_conc_2_desc as concentration_desc
                --, second_major_conc_2 as concentration_code
                , person_uid
                from academic_outcome
                ----where primary_program_ind = 'Y'
                where second_major is not null
                and second_major_conc_2 is not null

        union

        /* second major, third concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , second_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , second_program_classification progam
                , second_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(second_major, 1, 1) = '0' then second_major_desc
                        when substr(second_major, 1, 1) = 'U' then second_major_desc --|| ' (undeclared)'
                        when substr(second_major, 1, 1) = 'Q' then second_major_desc --|| ' (pre-major)'
                        else second_major_desc end
                     else second_major_desc end as field_of_study_desc
                , second_major_conc_3_desc as concentration_desc
                --, second_major_conc_3 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where second_major is not null
                and second_major_conc_3 is not null

        union

        /* third major, first concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , third_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , third_program_classification progam
                , third_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(third_major, 1, 1) = '0' then third_major_desc
                        when substr(third_major, 1, 1) = 'U' then third_major_desc --|| ' (undeclared)'
                        when substr(third_major, 1, 1) = 'Q' then third_major_desc --|| ' (pre-major)'
                        else third_major_desc end
                     else third_major_desc end as field_of_study_desc
                , third_major_conc_1_desc as concentration_desc
                --, third_major_conc_1 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where third_major is not null

        union

        /* third major, second concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , third_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , third_program_classification progam
                , third_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(third_major, 1, 1) = '0' then third_major_desc
                        when substr(third_major, 1, 1) = 'U' then third_major_desc --|| ' (undeclared)'
                        when substr(third_major, 1, 1) = 'Q' then third_major_desc --|| ' (pre-major)'
                        else third_major_desc end
                     else third_major_desc end as field_of_study_desc
                , third_major_conc_2_desc as concentration_desc
                --, third_major_conc_2 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where third_major is not null
                and third_major_conc_2 is not null

        union

        /* third major, third concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , third_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , third_program_classification progam
                , third_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(third_major, 1, 1) = '0' then third_major_desc
                        when substr(third_major, 1, 1) = 'U' then third_major_desc --|| ' (undeclared)'
                        when substr(third_major, 1, 1) = 'Q' then third_major_desc --|| ' (pre-major)'
                        else third_major_desc end
                     else third_major_desc end as field_of_study_desc
                , third_major_conc_3_desc as concentration_desc
                --, third_major_conc_3 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where third_major is not null
                and third_major_conc_3 is not null

        union

        /* fourth major, first concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , fourth_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , fourth_program_classification progam
                , fourth_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(fourth_major, 1, 1) = '0' then fourth_major_desc
                        when substr(fourth_major, 1, 1) = 'U' then fourth_major_desc --|| ' (undeclared)'
                        when substr(fourth_major, 1, 1) = 'Q' then fourth_major_desc --|| ' (pre-major)'
                        else fourth_major_desc end
                     else fourth_major_desc end as field_of_study_desc
                , fourth_major_conc_1_desc as concentration_desc
                --, fourth_major_conc_1 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where fourth_major is not null

        union

        /* fourth major, second concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , fourth_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , fourth_program_classification progam
                , fourth_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(fourth_major, 1, 1) = '0' then fourth_major_desc
                        when substr(fourth_major, 1, 1) = 'U' then fourth_major_desc --|| ' (undeclared)'
                        when substr(fourth_major, 1, 1) = 'Q' then fourth_major_desc --|| ' (pre-major)'
                        else fourth_major_desc end
                     else fourth_major_desc end as field_of_study_desc
                , fourth_major_conc_2_desc as concentration_desc
                --, fourth_major_conc_2 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where fourth_major is not null
                and fourth_major_conc_2 is not null

        union

        /* fourth major, third concentration */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , fourth_department_desc as department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , fourth_program_classification progam
                , fourth_program_classif_desc program_desc
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP')
                    then 'Major'
                    else 'Certificate' end as field_of_study_type
               --, major_desc as field_of_study_desc
               --, major as field_of_study_code
                , case
                    when degree in ('000000','BA','BAB','BAE','BCS','BDES','BFA','BM,','BME','BS','BSN','DPT','MA','MBA','MCR','MED','MFQ','MM','MOT','MPA','MPAC','MPH','MS','MSW','MURP') then
                    case
                        when substr(fourth_major, 1, 1) = '0' then fourth_major_desc
                        when substr(fourth_major, 1, 1) = 'U' then fourth_major_desc --|| ' (undeclared)'
                        when substr(fourth_major, 1, 1) = 'Q' then fourth_major_desc --|| ' (pre-major)'
                        else fourth_major_desc end
                     else fourth_major_desc end as field_of_study_desc
                , fourth_major_conc_3_desc as concentration_desc
                --, fourth_major_conc_3 as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where fourth_major is not null
                and fourth_major_conc_3 is not null

        union

        /* first minor */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , 'Minor' as field_of_study_type
                , first_minor_desc as field_of_study_desc
                --, first_minor as field_of_study_code
                , '' as concentration_desc
                --, '' as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where first_minor is not null

        union

        /* second minor */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , 'Minor' as field_of_study_type
                , second_minor_desc as field_of_study_desc
                --, second_minor as field_of_study_code
                , '' as concentration_desc
                --, '' as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where second_minor is not null

        union

        /* third minor */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , 'Minor' as field_of_study_type
                , third_minor_desc as field_of_study_desc
                --, third_minor as field_of_study_code
                , '' as concentration_desc
                --, '' as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where third_minor is not null

        union

        /* fourth minor */
        select GRADUATED_IND
                , ID
				, NAME
                , student_level
                , academic_period_graduation
                , academic_period_grad_desc
                --, college as college_code
                , college_desc
                --, department as department_code
                , department_desc
                --, campus as campus_code
                , campus_desc
                --, degree as degree_code
                , degree_desc
                --, catalog_academic_period
                ----, catalog_academic_period_grad_desc
                , program
                , program_desc
                , 'Minor' as field_of_study_type
                , fourth_minor_desc as field_of_study_desc
                --, fourth_minor as field_of_study_code
                , '' as concentration_desc
                --, '' as concentration_code
                , person_uid
                from academic_outcome
                --where primary_program_ind = 'Y'
                where fourth_minor is not null
    )
) slot



inner join
    (SELECT *
FROM
(Select distinct
 ao.person_uid person_uid
, AO.ACADEMIC_YEAR_GRADUATION year_graduated
, AO.academic_period_graduation academic_period_graduated
, AO.ACADEMIC_YEAR_GRADUATION_DESC year_graduated_desc
, AO.APPLIED_FOR_OUTCOME_IND
, AO.OUTCOME_APPLICATION_DATE
, AO.OUTCOME_GRADUATION_DATE
, AO.TRANSFER_WORK_EXISTS_IND
, AO.AWARD_CATEGORY
, AO.DEGREE
, AO.Degree_Desc
, AO.STATUS award_status
, AO.STATUS_DESC award_status_desc
, AO.COLLEGE first_program_college
, AO.CAMPUS_DESC first_major_campus_desc
, AO.PROGRAM
, AO.PROGRAM_DESC
, AO.PROGRAM_CLASSIFICATION first_program_classification
, AO.PROGRAM_CLASSIFICATION_DESC first_program_class_desc
, AO.MAJOR first_major
, AO.Major_desc
, AO.DEPARTMENT first_program_department
, AO.FIRST_CONCENTRATION first_major_first_conc
, AO.SECOND_CONCENTRATION first_major_second_conc
, AO.SECOND_CONCENTRATION_DESC first_major_second_conc_desc
, AO.THIRD_CONCENTRATION first_major_third_conc
, AO.THIRD_CONCENTRATION_DESC first_major_third_conc_desc
, AO.SECOND_PROGRAM_CLASSIFICATION second_program_classification
, AO.SECOND_PROGRAM_CLASSIF_DESC second_program_class_desc
, AO.SECOND_MAJOR second__major
, AO.SECOND_MAJOR_DESC  second_major_desc
, AO.SECOND_DEPARTMENT second__program_department
, AO.SECOND_DEPARTMENT_DESC second__program_dept_desc
, AO.SECOND_MAJOR_CONC_1
, AO.SECOND_MAJOR_CONC_1_DESC
, AO.SECOND_MAJOR_CONC_2
, AO.SECOND_MAJOR_CONC_2_DESC
, AO.SECOND_MAJOR_CONC_3
, AO.SECOND_MAJOR_CONC_3_DESC
, AO.THIRD_PROGRAM_CLASSIFICATION third_program_classification
, AO.THIRD_PROGRAM_CLASSIF_DESC third_program_class_desc
, AO.THIRD_MAJOR third_major
, AO.THIRD_MAJOR_DESC third_major_desc
, AO.THIRD_DEPARTMENT third_program_department
, AO.THIRD_DEPARTMENT_DESC third_program_department_desc
, AO.THIRD_MAJOR_CONC_1
, AO.THIRD_MAJOR_CONC_1_DESC
, AO.THIRD_MAJOR_CONC_2
, AO.THIRD_MAJOR_CONC_2_DESC
, AO.THIRD_MAJOR_CONC_3
, AO.THIRD_MAJOR_CONC_3_DESC
, AO.FOURTH_PROGRAM_CLASSIFICATION fourth_program_classification
, AO.FOURTH_PROGRAM_CLASSIF_DESC fourth_program_class_desc
, AO.FOURTH_MAJOR fourth_major
, AO.FOURTH_MAJOR_DESC fourth_major_desc
, AO.FOURTH_DEPARTMENT fourth_program_department
, AO.FOURTH_DEPARTMENT_DESC fourth_program_department_desc
, AO.FOURTH_MAJOR_CONC_1
, AO.FOURTH_MAJOR_CONC_1_DESC
, AO.FOURTH_MAJOR_CONC_2
, AO.FOURTH_MAJOR_CONC_2_DESC
, AO.FOURTH_MAJOR_CONC_3
, AO.FOURTH_MAJOR_CONC_3_DESC
, AO.FIRST_MINOR first_minor
, AO.FIRST_MINOR_DESC first_minor_desc
, AO.SECOND_MINOR second_minor
, AO.SECOND_MINOR_DESC second_minor_desc
, AO.THIRD_MINOR third_minor
, AO.THIRD_MINOR_DESC third_minor_desc
, AO.FOURTH_MINOR fourth_minor
, AO.FOURTH_MINOR_DESC fourth_minor_desc
, AO.GRADUATION_STATUS
, AO.GRADUATION_STATUS_DESC
, AO.GRAD_REQ_COMPLETED_ACAD_PER academic_period_grad_req_comp
, AO.GRAD_REQ_COMP_ACAD_PER_DESC acad_per_grad_req_comp_desc
, AO.CREDITS_ATTEMPTED cumalative_credits_attempted
, AO.CREDITS_EARNED cumalative_credits_earned
, AO.CREDITS_PASSED cumalative_credits_passed
, AO.GPA_CREDITS cumalative_gpa_credits
, AO.QUALITY_POINTS cumalative_quality_points
, GPA.GPA cumalative_gpa
/*, ROUND(GPAL.GPA,2) as CUMALATIVE__level_GPA
, AO.INSTITUTION_CREDITS_ATTEMPTED cum_inst_credits_attempted
, AO.INSTITUTION_CREDITS_EARNED cum_inst_credits_earned
, AO.INSTITUTION_CREDITS_PASSED cum_inst_credits_passed
, AO.INSTITUTION_QUALITY_POINTS cum_inst_quality_points
, AO.INSTITUTION_GPA cumalative_institution_gpa
, AO.TRANSFER_CREDITS_ATTEMPTED cum_transfer_credits_attempted
, AO.TRANSFER_CREDITS_EARNED cum_transfer_credits_earned
, AO.TRANSFER_CREDITS_PASSED cum_transfer_credits_passed
, AO.TRANSFER_QUALITY_POINTS cum_transfer_quality_points
, AO.TRANSFER_GPA cumalative_transfer_gpa*/
, ROUND(GPA_I.GPA,2) INSTITUTION_GPA
, GPA_I.GPA_CREDITS INSTITUTION_GPA_CREDITS
, GPA_I.CREDITS_ATTEMPTED INSTITUTION_CREDITS_ATTEMPTED
, GPA_I.CREDITS_EARNED INSTITUTION_CREDITS_EARNED
, GPA_I.CREDITS_PASSED INSTITUTION_CREDITS_PASSED
, GPA_I.QUALITY_POINTS INSTITUTION_QUALITY_POINTS
, ROUND(GPA_O.GPA,2) OVERALL_GPA
, GPA_O.GPA_CREDITS OVERALL_GPA_CREDITS
, GPA_O.CREDITS_ATTEMPTED OVERALL_CREDITS_ATTEMPTED
, GPA_O.CREDITS_EARNED OVERALL_CREDITS_EARNED
, GPA_O.CREDITS_PASSED OVERALL_CREDITS_PASSED
, GPA_O.QUALITY_POINTS OVERALL_QUALITY_POINTS
, ROUND(GPA_T.GPA,2) TRANSFER_GPA
, GPA_T.GPA_CREDITS TRANSFER_GPA_CREDITS
, GPA_T.CREDITS_ATTEMPTED TRANSFER_CREDITS_ATTEMPTED
, GPA_T.CREDITS_EARNED TRANSFER_CREDITS_EARNED
, GPA_T.CREDITS_PASSED TRANSFER_CREDITS_PASSED
, GPA_T.QUALITY_POINTS TRANSFER_QUALITY_POINTS
, AO.HONORS_COUNT
, PDT.LAST_NAME
, PDT.FIRST_NAME
, PDT.MIDDLE_NAME
, PDT.MIDDLE_INITIAL
, PDT.FULL_NAME_FMIL
, PDT.FULL_NAME_LFMI
, PDT.LEGAL_NAME
, PDT.CURRENT_AGE
, PDT.BIRTH_DATE
, PDT.GENDER sex
, PDT.GENDER_DESC sex_desc
, PDTEWU.USER_NAME
, ACST.AGE_ADMITTED
, ACST.YEAR_ADMITTED
, ACST.YEAR_ADMITTED_DESC
, ACST.ACADEMIC_PERIOD_ADMITTED
, ACST.ACADEMIC_PERIOD_ADMITTED_DESC
, ACST.ADMISSIONS_POPULATION
, ACST.ADMISSIONS_POPULATION_DESC
, ACST.PRIMARY_ADVISOR_TYPE
, ACST.PRIMARY_ADVISOR_TYPE_DESC
, ACST.PRIMARY_ADVISOR_NAME_FMIL
, ENR.TOTAL_CREDITS CREDITS_ENROLLED_GRAD_PERIOD
, PERS.EMAIL_ADDRESS
, PDT.CONFIDENTIALITY_IND
, PDT.MAILING_NAME_PREFERRED
, HOLD.HOLD
, ACST.CATALOG_ACADEMIC_PERIOD_DESC


FROM ACADEMIC_OUTCOME AO

LEFT JOIN GPA
ON GPA.PERSON_UID = AO.PERSON_UID
AND GPA.ACADEMIC_PERIOD = AO.ACADEMIC_PERIOD

LEFT JOIN PERSON_DETAIL PDT
on PDT.PERSON_UID = AO.PERSON_UID

LEFT JOIN PERSON_DETAIL_SUPP_EWU PDTEWU
ON PDTEWU.PERSON_UID = AO.PERSON_UID

INNER JOIN ACADEMIC_STUDY_extended ACST
ON ACST.PERSON_UID = AO.PERSON_UID
AND ACST.ACADEMIC_PERIOD = AO.ACADEMIC_PERIOD_graduation
and( (acst.major_desc = AO.major_desc) or (acst.major_desc = AO.second_major_desc) or (acst.major_desc = AO.third_major_desc))

INNER JOIN GPA GPA_I
ON GPA_I.PERSON_UID = AO.PERSON_UID
AND GPA_I.ACADEMIC_STUDY_VALUE = AO.STUDENT_LEVEL
AND GPA_I.GPA_GROUPING = 'C'
AND GPA_I.GPA_TYPE = 'I'

LEFT JOIN GPA GPA_O
ON GPA_O.PERSON_UID = AO.PERSON_UID
AND GPA_O.ACADEMIC_STUDY_VALUE = AO.STUDENT_LEVEL
AND GPA_O.GPA_GROUPING = 'C'
AND GPA_O.GPA_TYPE = 'O'

LEFT JOIN GPA GPA_T
ON GPA_T.PERSON_UID = AO.PERSON_UID
AND GPA_T.ACADEMIC_STUDY_VALUE = AO.STUDENT_LEVEL
AND GPA_T.GPA_GROUPING = 'C'
AND GPA_T.GPA_TYPE = 'T'

LEFT JOIN ENROLLMENT ENR
ON ENR.PERSON_UID = AO.PERSON_UID
AND ENR.ACADEMIC_PERIOD = AO.ACADEMIC_PERIOD_graduation

LEFT JOIN PERSON PERS
ON PERS.PERSON_UID = AO.PERSON_UID
AND PERS.EMAIL_TYPE = 'STU'

LEFT JOIN
    (SELECT PERSON_UID
         , LISTAGG(HOLD_DESC, ' , ') WITHIN GROUP (ORDER BY HOLD_DESC) HOLD
        , ACTIVE_HOLD_IND
        FROM HOLD group by PERSON_UID, ACTIVE_HOLD_IND) HOLD
ON HOLD.PERSON_UID = AO.PERSON_UID
AND ACTIVE_HOLD_IND = 'Y'



)
) fill
on fill.person_uid = slot.person_uid
and fill.academic_period_graduated = slot.academic_period_graduated
and ((fill.major_desc = slot.discipline) or (fill.second_major_desc = slot.discipline) or (fill.first_minor_desc = slot.discipline) or (fill.second_minor_desc = slot.discipline) or (fill.third_minor_desc = slot.discipline) or (fill.fourth_minor_desc = slot.discipline))




where :main_BT_RunDashbd1 is not null

and (
(:term_cbx = 'N' and
slot.academic_period_graduated = :parm_LB_academicPeriod1.VALUE
and :Parm_DD_start_term = 'blank'
and :Parm_DD_end_term = 'blank' )
or (:term_cbx = 'Y' and
slot.academic_period_graduated between :Parm_DD_start_term and :Parm_DD_end_term)
or
(:cbx = 'Y' and
'-ALL-' = :parm_LB_academicPeriod1.VALUE
and :Parm_DD_start_term = 'blank'
and :Parm_DD_end_term = 'blank' )
)

and (
('-ALL-' = :parm_DD_dept1.value_description
or ('-ALL-' <> :parm_DD_dept1.value_description
and department_desc = :parm_DD_dept1.value_description))
)
and (
('-ALL-' = :parm_DD_college1.value_description
or ('-ALL-' <> :parm_DD_college1.value_description
and college_desc = :parm_DD_college1.value_description))
)
and(
(:grad_status1 = 'Graduated' and graduated_ind = 'Y')
or (:grad_status1 = 'Applied to Graduate' and graduated_ind = 'N')
or (:grad_status1 = 'All' and graduated_ind in ('Y','N'))
)
and(
(:level1 = 'Graduate' and STUDENT_LEVEL in ('GR','GS'))
or (:level1 = 'Undergraduate' and STUDENT_LEVEL in ('UG','US'))
or (:level1 = 'All' and STUDENT_LEVEL in ('GR','GS','US','UG'))
)
and(
('-ALL-' = :parm_LB_type1
or ('-ALL-' <> :parm_LB_type1
and type = :parm_LB_type1))
)
and(
:cbx = 'N'
or :cbx = 'Y'
and ID = :Parm_Memo_ListIDs
)



order by 2

--$addfilter
