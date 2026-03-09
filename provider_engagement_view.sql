drop view if exists analytics.vw_INTL_Provider_Engagement;
create view analytics.vw_INTL_Provider_Engagement as 

select 
  date, Current_Date_SameDay, vertical, channel, membership_status, activity_date, isStale, country_code,
  sum(signups) as signups,
  sum(active_accounts) as active_accounts,
  sum(active_accounts) over (partition by vertical, channel, membership_status, activity_date, isStale, country_code order by date range between interval '14' day preceding and current row) as 'active_accounts_14days',
  sum(active_accounts) over (partition by vertical, channel, membership_status, activity_date, isStale, country_code order by date range between interval '30' day preceding and current row) as 'active_accounts_30days'
  
from
(
  select 
    dd.date,
    cd.Current_Date_SameDay,
    case when mm.vertical = 'homeCare' then 'Housekeeping' 
         when (mm.vertical is null or mm.vertical = '') then 'Childcare' 
       else initcap(lower(mm.vertical)) end as vertical,
    mm.channel,   
    case when up.memberid is not null then 'Premium' else 'Basic' end as membership_status,
    case when date(mm.dateMemberSignup) = aa.date then 'Same_Day_Signup' else 'After_Signup' end as activity_date,
    mm.isStale,
    upper(mm.countrycode) as country_code,   
    count(distinct mm.memberid) as signups,
    count(distinct aa.memberid) as active_accounts
  from intl.hive_member mm
  cross join ( select distinct date from reporting.DW_D_DATE where year >= year(now())-1) dd
  join analytics.DW_D_DATE_CURRENT cd       on dd.date = cd.date 
  left join intl.hive_event up              on mm.memberid = up.memberid and mm.countrycode = up.countrycode and up.name = 'Upgrade'
  left join 
            (
              select distinct
                  coalesce(date(ev.datecreated), date(fb.requested_date)) as date, coalesce(ev.countrycode, fb.country_code) as countrycode, coalesce(ev.memberid, fb.requesting_member_id) as memberid  
                from intl.hive_event ev
                full outer join intl.feedback_request fb   on fb.requesting_member_id = ev.memberid and fb.country_code = ev.countrycode and year(fb.requested_date) >= year(now())-1                        
                where ev.year >= year(now())-1 
                    and name in ('Search', 'Edit', 'JobApplication', 'Message', 'Photo')
                    and 
                      (
                      (name = 'Search' and searchType = 'Job') or
                      (name = 'Edit' and itemType = 'VerticalProfile' and memberSearchStatus = 'Approved') or
                      (name = 'JobApplication' and action is null and memberSearchStatus = 'Approved') or
                      (name = 'Message' and memberSearchStatus = 'Approved') or
                      (name = 'Photo' and photoAction = 'Upload' and memberSearchStatus = 'Approved' )
                      ) 
                group by 1,2,3 order by 1 asc
               ) aa on mm.memberid = aa.memberid and mm.countrycode = aa.countrycode and dd.date = aa.date  

  where lower(mm.role) = 'provider'
    and mm.isinternalaccount = 'false'
    and mm.closedforfraud = 'false' 
    and mm.searchStatus = 'Approved'
    and date(mm.dateMemberSignup) <= dd.date
    and dd.date < date(current_date)
    and mm.loginCount > 0
    and date(mm.lastLoginDate) > date(mm.dateMemberSignup)
  group by 1,2,3,4,5,6,7,8
) ab

group by 1,2,3,4,5,6,7,8,active_accounts

---
;
grant select on analytics.vw_INTL_Provider_Engagement to reporting_ro, analytics_team;
;
select * from analytics.vw_INTL_Active_Providers where year(date) = 2023 limit 100
