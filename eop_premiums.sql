with premium_balance as (
    select distinct
      dd.month_end,
      count(distinct case when date(sp.nextpaymentdate) > dd.month_end then sp.subscriptionId end) as premiums,
      count(distinct case when date(sp.nextpaymentdate) > dd.month_end and mm.memberstatus = 'PendingActive' then sp.memberid end) as pending_premiums
    from intl.transaction tt
      join intl.hive_subscription_plan sp on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code 
      join intl.hive_member mm            on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false' and lower(mm.role) = 'seeker' 
      join (select distinct date(fiscal_month_end_date) as month_end from reporting.dw_d_date where year >= year(now())-2 and date(fiscal_month_end_date) <= date(current_date)) dd on date(subscriptiondatecreated) <= dd.month_end
    where tt.type in ('PriorAuthCapture','AuthAndCapture')
      and tt.status = 'SUCCESS'
      and tt.amount > 0
    group by 1),
    
churn as (
   select
    date(fiscal_month_end_date) as month_end,
    count(distinct sp.subscriptionId) as churn,
    count(distinct case when cd.member_id is null then sp.subscriptionId end) as voluntary_churn,
    count(distinct case when cd.member_id is not null then sp.subscriptionId end) as involuntary_churn
  from intl.transaction tt
    join intl.hive_subscription_plan sp       on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code and sp.subscriptionEndDate is not null
    join intl.hive_member mm                  on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false' and lower(mm.role) = 'seeker' 
    join reporting.dw_d_date dd               on dd.date = date(sp.subscriptionenddate) and year >= year(now())-2 and last_day(sp.subscriptionenddate) <= date(fiscal_month_end_date)
    left join intl.CLOSE_DOWNGRADE_DETAIL cd  on cd.member_id = sp.memberid and cd.country_code = sp.countrycode and cd.subscription_plan_id = sp.subscriptionId 
                                              and cd.action_performed = 'Downgrade' and cd.user_type in ('CSR', 'Backoffice') and cd.action_reason in ('AutoRenewal', 'ChargebackReceived', 'SafetyBlacklist', 'SafetyFraud') 
  where tt.type in ('AuthAndCapture')
    and tt.status = 'SUCCESS'
    and tt.amount > 0
  group by 1)
  
select 
  coalesce(p.month_end, c.month_end) as month_end,
  p.premiums,
  p.pending_premiums,
  sum(c.churn) as churn,
  sum(c.voluntary_churn) as voluntary_churn,
  sum(c.involuntary_churn) as involuntary_churn
from premium_balance p
full outer join churn c on p.month_end = c.month_end 
where coalesce(p.month_end, c.month_end) < date(current_date)
group by 1,2,3 order by 1
