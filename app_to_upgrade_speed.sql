---------- Apps

select distinct
  year, date, current_date_sameday,
  country,
  vertical,
  app_type,
  app_no,
  time_hours_till_app as hours_till_app  
from
  (select distinct 
    dd.year, dd.date, dc.current_date_sameday,
    upper(jp.country_code) as country, initcap(jp.vertical_id) as vertical,
    jp.id as job, 
    rank() over(partition by jp.id order by ja.date_created asc) as app_no,
    case when ja.was_sent_automatically = 'true' then 'AutoApp' else 'ManualApp' end as app_type,
    datediff(hour, jp.date_created, ja.date_created) as time_hours_till_app
  from intl.job jp
  join reporting.DW_D_DATE dd         on date(jp.date_created) = dd.date
  join analytics.DW_D_DATE_CURRENT dc on dd.date = dc.date and dd.year >= year(now())-1 and dd.date < date(current_date)
  join intl.job_application ja        on jp.id = ja.job_id and jp.country_code = ja.country_code
  where jp.search_status = 'Approved') app_job
where app_no between 1 and 10
group by 1,2,3,4,5,6,7,8

union

---------- New Premiums

select 
  year, date, current_date_sameday,
  country,
  vertical,
  upgrade_type,
  0 as app_no,
  time_hours_till_upgrade as hours_till_upgrade  
from
  (select
    dd.year, dd.date, dc.current_date_sameday,
    upper(mm.countrycode) as country,
    case when lower(mm.vertical) = 'housekeeping' then 'Homecare' 
         when (mm.vertical is null or mm.vertical = '') then 'Childcare' 
      else initcap(mm.vertical) end as vertical,
    case when date(sp.subscriptionDateCreated) = date(mm.dateMemberSignup) then 'Day1s'
         when ( date(mm.dateFirstPremiumSignup) = date(sp.subscriptionDateCreated) and date(sp.subscriptionDateCreated) != date(mm.dateMemberSignup) ) then 'Nths'
      end as upgrade_type,
    datediff(hour, mm.dateMemberSignup, sp.subscriptionDateCreated) as time_hours_till_upgrade,  
    sp.subscriptionId as upgrades
              
  from intl.transaction tt
    join intl.hive_member mm            on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false' and lower(mm.role) = 'seeker'
    join intl.hive_subscription_plan sp on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code
    join reporting.DW_D_DATE dd         on date(sp.subscriptionDateCreated) = dd.date and dd.year >= year(now())-1 and dd.date < date(current_date)
    join analytics.DW_D_DATE_CURRENT dc on dd.date = dc.date 
    
  where tt.type in ('PriorAuthCapture','AuthAndCapture')
    and tt.status = 'SUCCESS' 
    and tt.amount > 0 
    and date(mm.dateFirstPremiumSignup) = date(sp.subscriptionDateCreated)
  group by 1,2,3,4,5,6,7,8  order by 1 asc) up
group by 1,2,3,4,5,6,7,8
