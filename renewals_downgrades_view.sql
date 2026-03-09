drop view if exists analytics.vw_INTL_Daily_Renewals_Downgrades; 

grant select on analytics.vw_INTL_Daily_Renewals_Downgrades to reporting_ro, analytics_team;

create view analytics.vw_INTL_Daily_Renewals_Downgrades as

with renewals as (
  select
    date, week_start_date, current_date_sameday, 
    countrycode, member_type, user_device, vertical, subscription_length, payment_type,
    case when ranking = 1 then 'First Period Renewal' else 'Non-First Period Renewal' end as renewal_period,
    count(distinct subscriptionid) as renewals 
  from (
    select
      ddd.date, ddd.week_start_date, dc.current_date_sameday, 
      sp.countrycode, sp.subscriptionid, case when lower(m.device) = 'smartphone' then 'Mobile' when (m.device = '' or m.device is null) then 'Mobile' else initcap(lower(m.device)) end as user_device,
      initcap(m.role) as  member_type, case when lower(m.vertical) = 'homecare' then 'Housekeeping' when (m.vertical is null or m.vertical = '') then 'Childcare' else initcap(m.vertical) end as vertical,    
      sp.priceplandurationinmonths as subscription_length, cc.payment_type,  
      ceiling(trunc(datediff(month,sp.subscriptiondatecreated, t.when_processed)/sp.pricePlanDurationInMonths)) as ranking   
    from intl.hive_subscription_plan sp
      join intl.hive_member m on sp.countrycode = m.countrycode and sp.memberid = m.memberid and m.IsInternalAccount = 'false' and m.role is not null
      join intl.transaction t on t.country_code = sp.countrycode and t.member_id = sp.memberid and t.subscription_plan_id = sp.subscriptionid 
        and t.type in ('PriorAuthCapture','AuthAndCapture') and t.status = 'SUCCESS' and t.amount > 0
      join intl.credit_card cc on cc.id = t.credit_card_id and t.member_id = cc.member_id and t.country_code = cc.country_code
      join reporting.dw_d_date ddd on date(t.when_processed) = ddd.date and ddd.year >= 2019 and ddd.date < date(current_date)
      join analytics.dw_d_date_current dc on dc.date = ddd.date
    where date(sp.subscriptiondatecreated) < date(current_date)
    group by 1,2,3,4,5,6,7,8,9,10,11) a
  where ranking > 0
  group by 1,2,3,4,5,6,7,8,9,10),

downgrades as (
    select
      date, week_start_date, current_date_sameday, 
      countrycode, member_type, user_device, vertical, subscription_length, payment_type,
      case when ranking in (0,1) then 'First Period Renewal' else 'Non-First Period Renewal' end as renewal_period,
      count(distinct subscriptionid) as downgrades
    from (
        select
          ddd.date, ddd.week_start_date, dc.current_date_sameday, 
          sp.countrycode, sp.subscriptionid, case when lower(m.device) = 'smartphone' then 'Mobile' when (m.device = '' or m.device is null) then 'Mobile' else initcap(lower(m.device)) end as user_device,
          initcap(m.role) as  member_type, case when lower(m.vertical) = 'homecare' then 'Housekeeping' when (m.vertical is null or m.vertical = '') then 'Childcare' else initcap(m.vertical) end as vertical,    
          sp.priceplandurationinmonths as subscription_length, cc.payment_type,  
          ceiling(trunc(datediff(month,sp.subscriptiondatecreated, sp.subscriptionenddate)/sp.pricePlanDurationInMonths)) as ranking 
        from intl.hive_subscription_plan sp
          join intl.hive_member m on sp.countrycode = m.countrycode and sp.memberid = m.memberid and m.IsInternalAccount = 'false' and m.role is not null
          join intl.transaction t on t.country_code = sp.countrycode and t.member_id = sp.memberid and t.subscription_plan_id = sp.subscriptionid 
            and t.type in ('PriorAuthCapture','AuthAndCapture') and t.status = 'SUCCESS' and t.amount > 0
          join intl.credit_card cc on cc.id = t.credit_card_id and t.member_id = cc.member_id and t.country_code = cc.country_code
          join reporting.dw_d_date ddd on ddd.date = date(sp.subscriptionenddate) and ddd.date < date(current_date) and ddd.year >= 2019
          join analytics.dw_d_date_current dc on dc.date = ddd.date
          where date(sp.subscriptiondatecreated) < date(current_date)
          group by 1,2,3,4,5,6,7,8,9,10,11
      ) a
    group by 1,2,3,4,5,6,7,8,9,10)
    
select
  coalesce(r.date, d.date) as date,
  coalesce(r.week_start_date, d.week_start_date) as week_start_date,
  coalesce(r.current_date_sameday, d.current_date_sameday) as current_date_sameday,
  coalesce(r.countrycode, d.countrycode) as countrycode,
  coalesce(r.member_type, d.member_type) as member_type,
  coalesce(r.user_device, d.user_device) as user_device,
  coalesce(r.vertical, d.vertical) as vertical,
  coalesce(r.subscription_length, d.subscription_length) as subscription_length,
  coalesce(r.payment_type, d.payment_type) as payment_type,
  coalesce(r.renewal_period, d.renewal_period) as renewal_period,

  ifnull(sum(renewals),0) as renewals,
  ifnull(sum(downgrades),0) as downgrades,
  (ifnull(sum(renewals),0) + ifnull(sum(downgrades),0)) as potential_renewals
  
from renewals r
full outer join downgrades d on r.date = d.date and r.week_start_date = d.week_start_date and r.current_date_sameday = d.current_date_sameday 
                             and r.countrycode = d.countrycode and r.member_type = d.member_type and r.user_device = d.user_device and r.vertical = d.vertical
                             and r.subscription_length = d.subscription_length and r.payment_type = d.payment_type and r.renewal_period = d.renewal_period
                             
group by 1,2,3,4,5,6,7,8,9,10 
order by 1,2 asc
