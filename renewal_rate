with prior_period as (
    select
        payment_date, 
        countrycode,
        subscriptionid,    
        priceplandurationinmonths,
        case when ranking = 0 then 'first_upgrade' 
             when ranking = 1 then 'initial_renewal' 
           else 'subsquent_renewal' end as status         
      from (
        select
          date(t.when_processed) as payment_date,
          sp.countrycode, 
          sp.subscriptionid,
          date(sp.subscriptiondatecreated) as subscriptiondatecreated, 
          sp.priceplandurationinmonths,
          ceiling(trunc(datediff(month,sp.subscriptiondatecreated, t.when_processed)/sp.pricePlanDurationInMonths)) as ranking   
        from intl.hive_subscription_plan sp
          join intl.hive_member m on sp.countrycode = m.countrycode and sp.memberid = m.memberid and m.IsInternalAccount = 'false' and m.role is not null
          join intl.transaction t on t.country_code = sp.countrycode and t.member_id = sp.memberid and t.subscription_plan_id = sp.subscriptionid 
            and t.type in ('PriorAuthCapture','AuthAndCapture') and t.status = 'SUCCESS' and t.amount > 0
        where date(sp.subscriptiondatecreated) < date(current_date)
          and year(t.when_processed) = 2024) a ), 
          
current_period as (
   select
        payment_date, 
        countrycode,
        subscriptionid,    
        priceplandurationinmonths,
        case when ranking = 0 then 'first_upgrade' 
             when ranking = 1 then 'initial_renewal' 
           else 'subsquent_renewal' end as status         
      from (
        select
          date(t.when_processed) as payment_date,
          sp.countrycode, 
          sp.subscriptionid,
          date(sp.subscriptiondatecreated) as subscriptiondatecreated, 
          sp.priceplandurationinmonths,
          ceiling(trunc(datediff(month,sp.subscriptiondatecreated, t.when_processed)/sp.pricePlanDurationInMonths)) as ranking   
        from intl.hive_subscription_plan sp
          join intl.hive_member m on sp.countrycode = m.countrycode and sp.memberid = m.memberid and m.IsInternalAccount = 'false' and m.role is not null
          join intl.transaction t on t.country_code = sp.countrycode and t.member_id = sp.memberid and t.subscription_plan_id = sp.subscriptionid 
            and t.type in ('PriorAuthCapture','AuthAndCapture') and t.status = 'SUCCESS' and t.amount > 0
        where date(sp.subscriptiondatecreated) < date(current_date)
          and year(t.when_processed) = 2024) b )
          
select 
  coalesce(a.payment_date, b.payment_date) as payment_date,
  coalesce(a.countrycode, b.countrycode) as countrycode,
  coalesce(a.priceplandurationinmonths, b.priceplandurationinmonths) as priceplandurationinmonths,
  coalesce(a.status, b.status) as status,
  count(distinct a.subscriptionid) as prior_period,
  count(distinct b.subscriptionid) as current_period,
  ceiling(((count(distinct b.subscriptionid)/count(distinct a.subscriptionid))*100)) as renewal_rate
  
from prior_period a
left join current_period b on a.countrycode = b.countrycode and a.subscriptionid = b.subscriptionid and b.payment_date > a.payment_date

group by 1,2,3,4

limit 100
