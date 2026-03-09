/* 
NOTES
+ A seeker can have more than one job, how do we deal with that when measuring upgrade conversion metrics?
+ Limiting to only new premiums for simplicity - though need to think through logic, see example of reupgrade below.
* Hypothesis: The longer it takes to send manual app the lower the B2P
*/

select 
  jobs_apps.country,
  jobs_apps.vertical,
  --jobs_apps.seeker,
  jobs_apps.job,
  jobs_apps.job_post_date,
  jobs_apps.job_post_method,
  jobs_apps.app_provider,
  jobs_apps.app,
  jobs_apps.app_sent_date,
  jobs_apps.app_type,
  datediff(hh,jobs_apps.job_post_date,jobs_apps.app_sent_date) as hours_job_post_app,
  upgrades.subscription_id,
  upgrades.upgrade_start_date,
  upgrades.upgrade_end_date
  
from
  (select 
      upper(jb.country_code) as country,
      initcap(jb.vertical_id) as vertical,
      jb.member_id as seeker,
      jb.id as job,
      jb.date_created as job_post_date,
      jb.posting_method as job_post_method,
      ja.member_id as app_provider,
      ja.id as app,
      ja.date_created as app_sent_date,
      case when ja.was_sent_automatically = 'false' then 'Manual' else 'Auto' end as app_type
    from intl.job jb
    left join intl.job_application ja on jb.id = ja.job_id and jb.country_code = ja.country_code 
          and jb.date_created < ja.date_created 
    where jb.search_status = 'Approved'
      and year(jb.date_created) >= 2021
      and date(jb.date_created) < date(current_date)) jobs_apps
    
left join 
(select
    upper(mm.countrycode) as country,
    mm.memberid as seeker,
    sp.subscriptionid as subscription_id,
    mm.dateFirstPremiumSignup,
    sp.subscriptionDateCreated as upgrade_start_date,
    sp.subscriptionEndDate as upgrade_end_date
  from intl.transaction tt
  join intl.hive_subscription_plan sp on sp.subscriptionId = tt.subscription_plan_id 
            and sp.countrycode = tt.country_code and year(sp.subscriptionDateCreated) >= 2021 
            and date(sp.subscriptionDateCreated) < date(current_date)
  join intl.hive_member mm on tt.member_id = mm.memberid and tt.country_code = mm.countrycode
            and mm.IsInternalAccount = 'false' and lower(mm.role) = 'seeker'  
            and year(dateFirstPremiumSignup) >= 2021  
  where tt.type in ('PriorAuthCapture','AuthAndCapture')
    and tt.status = 'SUCCESS'
    and date(mm.dateFirstPremiumSignup) = date(sp.subscriptionDateCreated)
    and tt.amount > 0) upgrades on jobs_apps.seeker = upgrades.seeker and jobs_apps.country = upgrades.country 
                                      and dateFirstPremiumSignup > jobs_apps.job_post_date
                                  
where jobs_apps.seeker in ('1234459')
