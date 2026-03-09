select 
  countrycode, memberid, subscriptionid, sub_start_date, sub_end_date, days_between,
  case when action_performed is null then 'Not in Closed Downgrade Table' else action_performed end as close_downgrade_action, 
  concat( concat(who_why, ' /'), concat(' ', date(action_date)) ) as 'user / reason / date',    
  case when refund is null then 'No Refund' else refund end refund 
from ( 
select distinct 
  sp.countrycode, sp.memberid, sp.subscriptionid, date(sp.subscriptiondatecreated) as sub_start_date, date(sp.subscriptionenddate) as sub_end_date, datediff('day', sp.subscriptiondatecreated, sp.subscriptionenddate) as days_between,
  cd.action_performed, cd.user_type as user, cd.action_date, cd.action_reason, concat(concat(cd.user_type, ' / '), cd.action_reason) as who_why,
  concat( concat(rc.type, ' on '), date(rc.date_created)) as refund 
from intl.transaction tt
  join intl.hive_subscription_plan sp       on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code
  join intl.hive_member m                   on tt.member_id = m.memberid and tt.country_code = m.countrycode
  left join intl.CLOSE_DOWNGRADE_DETAIL cd  on cd.member_id = sp.memberid and cd.country_code = sp.countrycode and cd.subscription_plan_id = sp.subscriptionid 
  left join intl.transaction rc             on rc.subscription_plan_id = tt.subscription_plan_id and rc.country_code = tt.country_code
                                            and rc.type in ('Credit','Chargeback') and rc.status = 'SUCCESS' and rc.amount > 0                                         
where tt.type in ('PriorAuthCapture','AuthAndCapture')
  and tt.status = 'SUCCESS'
  and tt.amount > 0
  and m.IsInternalAccount = 'false'
  and year(sp.subscriptionDateCreated) >= 2021
  and datediff('month', sp.subscriptiondatecreated, sp.subscriptionenddate) = 0
  and sp.subscriptionenddate is not null
  and m.closedforfraud = 'false'
) abc
