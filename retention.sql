with premium_balance as (
  select distinct
    dd.date as premium_balance_date,
    upper(mm.countrycode) as country, initcap(mm.role) as role,
    case when lower(mm.device) = 'smartphone' then 'Mobile' when (mm.device = '' or mm.device is null) then 'Mobile' else initcap(mm.device) end as device,
    case when lower(mm.vertical) = 'homecare' then 'Housekeeping' when (mm.vertical is null or mm.vertical = '') then 'Childcare' else initcap(mm.vertical) end as vertical,
    sp.priceplandurationinmonths as subscription_length,
    cc.payment_type, 
    count(distinct sp.subscriptionId) as premium_balance
  from intl.transaction tt
    join intl.hive_subscription_plan sp on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code 
    join intl.credit_card cc            on cc.id = tt.credit_card_id and tt.member_id = cc.member_id and tt.country_code = cc.country_code
    join intl.hive_member mm            on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false'
    join (select distinct date from reporting.dw_d_date where year >= year(now())-2 and date < date(current_date)) dd on date(sp.subscriptionDateCreated) <= dd.date and date(nextPaymentdate) > dd.date 
  where tt.type in ('PriorAuthCapture','AuthAndCapture')
    and tt.status = 'SUCCESS'
    and tt.amount > 0
  group by 1,2,3,4,5,6,7 
),

churn as (
  select
    date(sp.subscriptionDateCreated) as start_date, date(sp.subscriptionenddate) as end_date,
    upper(mm.countrycode) as country, initcap(mm.role) as role,
    case when lower(mm.device) = 'smartphone' then 'Mobile' when (mm.device = '' or mm.device is null) then 'Mobile' else initcap(mm.device) end as device,
    case when lower(mm.vertical) = 'homecare' then 'Housekeeping' when (mm.vertical is null or mm.vertical = '') then 'Childcare' else initcap(mm.vertical) end as vertical,
    sp.priceplandurationinmonths as subscription_length,
    cc.payment_type, 
    count(distinct sp.subscriptionId) as churn
  from intl.transaction tt
    join intl.hive_subscription_plan sp       on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code and sp.subscriptionEndDate is not null
    join intl.credit_card cc                  on cc.id = tt.credit_card_id and tt.member_id = cc.member_id and tt.country_code = cc.country_code
    join intl.hive_member mm                  on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false' 
  where tt.type in ('PriorAuthCapture','AuthAndCapture')
    and tt.status = 'SUCCESS'
    and tt.amount > 0
  group by 1,2,3,4,5,6,7,8  
)

select 
  p.premium_balance_date,
  c.start_date,
  c.end_date,
  coalesce(p.country, c.country) as country,
  coalesce(p.role, c.role) as role,
  coalesce(p.device, c.device) as device,
  coalesce(p.vertical, c.vertical) as vertical,
  coalesce(p.subscription_length, c.subscription_length) as subscription_length,
  coalesce(p.payment_type, c.payment_type) as payment_type,
  ifnull(sum(p.premium_balance),0) as premium_balance,
  ifnull(sum(c.churn),0) as churn
  
from premium_balance p
full outer join churn c on p.country = c.country and p.role = c.role and p.device = c.device and p.vertical = c.vertical and p.subscription_length = c.subscription_length and p.payment_type = c.payment_type
      
group by 1,2,3,4,5,6,7,8,9
