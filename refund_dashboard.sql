select 
  upper(m.countrycode) as Country,
  sp.memberid as MemberID,
  t.transaction_id,
  date(sp.subscriptionDateCreated) as 'Upgrade Date',
  date(dg.datecreated) as 'Downgrade Requested Date',
  date(sp.nextPaymentdate) as 'Next Payment Date',
  sp.pricePlanDurationInMonths as 'Subscription in Months',
  sp.pricePlanFee as 'Subscription Amount',

  datediff(day,date(sp.firstPaymentDate),date(sp.nextPaymentDate)) as 'Total Days Premium',  --- Covers the entire time user was premium
  datediff(day,date(t.billed_service_start_date),date(sp.nextPaymentdate)) as 'Days in Period',  --- Covers the time user was premium on current subscription plan 
  datediff(day,date(current_date),date(sp.nextPaymentdate)) as 'Days till Basic', --- How many days of premium are left
  
  datediff(day,date(dg.dateCreated),date(sp.nextPaymentdate))-30 as 'Days to Refund', --- Law allows for a max 30 days cancellation notice
  sp.pricePlanFee/datediff(day,date(t.billed_service_start_date),date(sp.nextPaymentdate)) as 'Daily Rate', --- Subscription fee by day
  
  (cast(sp.pricePlanFee as numeric)/cast(datediff(day,date(t.billed_service_start_date),date(sp.nextPaymentdate)) as numeric))*
  (cast(datediff(day,date(dg.dateCreated),date(sp.nextPaymentdate))-30 as numeric)) as 'Refund Amount', --- Mulitples 'Days to Refund' by 'Daily Rate' for the sum to be refunded
  
  case when r.member_id = '4031125' and t.transaction_id = '8886953' then 'Yes' 
       when r.member_id is not null and r.status = 'SUCCESS' then 'Yes' --- Identifies members who have been refunded
       when r.member_id is not null and r.status = 'FAILURE' then 'Failed'  
  else 'No' end as 'Refunded'  
  
    
from  (select distinct date_created, billed_service_start_date, subscription_plan_id, transaction_id, country_code, member_id
      from
        (select distinct date_created, billed_service_start_date, subscription_plan_id, id as transaction_id, country_code, member_id,
          rank() over (partition by member_id order by date_created desc) as ranked
        from intl.transaction
        where type = 'AuthAndCapture'
          and status = 'SUCCESS'
          and amount > 0 
          group by 1,2,3,4,5,6) req
            where ranked=1
            group by 1,2,3,4,5,6) t
                                            
  join intl.hive_subscription_plan sp       on sp.subscriptionId = t.subscription_plan_id 
                                            and sp.countrycode = t.country_code                                      

  join intl.hive_member m                   on t.member_id = m.memberid 
                                            and t.country_code = m.countrycode 
                                            and m.IsInternalAccount = 'false' 
                                            and m.ClosedForFraud = 'false'
                                            and m.countrycode not in ('uk','ca','au','nz','ch') --- These countries are not legally registered in Germany 
                                            and m.memberStatus = 'Premium' --- Only looking at current premiums 
                                            
  join intl.hive_event dg                   on dg.memberid = m.memberid
                                            and dg.countrycode = m.countrycode
                                            and dg.name = 'AccountActionRequest' --- When the downgrade was requested
                                            and dg.accountaction = 'Downgrade'
                                            and dg.actionOccursOn <> 'Now'  --- Only downgrades schedulled to occur at the end of premium period and did not happen immediately
                                            and dg.datecreated >= sp.subscriptionDateCreated
                                            and dg.objectid = sp.subscriptionId
                                            
 left join (select date_created, country_code, member_id, subscription_plan_id, status
                from
                (select 
                  date_created,
                  country_code,
                  member_id,
                  subscription_plan_id,
                  status,
                  rank() over (partition by member_id, subscription_plan_id order by date_created desc) as ranked
                from intl.transaction 
                where type = 'Credit' 
                  and amount > 0 ) ab
                where ranked = 1) r           on r.member_id = t.member_id and r.country_code = t.country_code
                                              and r.date_created > t.date_created and r.subscription_plan_id = t.subscription_plan_id
                                             
  left join intl.transaction cb              on cb.member_id = t.member_id
                                            and cb.country_code = t.country_code
                                            and cb.date_created > t.date_created
                                            and cb.type = 'Chargeback' 
                                            and cb.amount > 0 
                                            and cb.status = 'SUCCESS'
                                            and cb.subscription_plan_id = t.subscription_plan_id
                                            
where date(sp.subscriptionDateCreated) >= '2022-03-01'  --- Legal changes to German law covers those upgrading after this date
  and sp.nextPaymentDateAction = 'Downgrade'  --- Only including those who've requested a downgrade
  and sp.pricePlanDurationInMonths <> 1 --- Legal changes only impact users with subscriptions that are longer than a month
  and datediff(day,date(dg.dateCreated),date(sp.nextPaymentdate)) > 30  --- Must be more than 30 days left from requesting downgrade until the next payment date be eligiable for refund
  and datediff(day,date(sp.firstPaymentDate),date(sp.nextPaymentDate)) > datediff(day,date(t.billed_service_start_date),date(sp.nextPaymentdate)) --- Excludes the first transaction if multiple auto-renews have occurred (difference in days would be the same on the first transaction)
  and cb.member_id is null -- Added 15.08.2022 to exclude those with ChargeBack
  and sp.subscriptionid not in 
      (select distinct dn.subscriptionid
      from intl.transaction tt
      join intl.hive_subscription_plan sp on tt.member_id = sp.memberid and tt.country_code = sp.countrycode and tt.subscription_plan_id = sp.subscriptionid
      join (select billed_service_start_date, memberid, subscriptionid, countrycode, subscriptionDateCreated, nextPaymentDate, pricePlanDurationInMonths, pricePlanFee, discounted_fee
                  from
                    (select billed_service_start_date, memberid, subscriptionid, countrycode, subscriptionDateCreated, nextPaymentDate, 
                            pricePlanDurationInMonths, pricePlanFee, discounted_fee,
                            rank() over (partition by memberid order by billed_service_start_date desc) as ranked_bill_date
                      from (select distinct   
                              tt.billed_service_start_date, 
                              sp.memberid, 
                              sp.subscriptionid, 
                              sp.countrycode, 
                              sp.subscriptionDateCreated, 
                              sp.nextPaymentDate, 
                              sp.pricePlanDurationInMonths,
                              sp.pricePlanFee,
                              (sp.pricePlanFee*0.7) as discounted_fee
                            from intl.transaction tt
                              join intl.hive_subscription_plan sp on tt.member_id = sp.memberid and tt.country_code = sp.countrycode and tt.subscription_plan_id = sp.subscriptionid
                            where tt.type in ('PriorAuthCapture','AuthAndCapture')
                              and tt.status = 'SUCCESS'
                              and tt.amount > 0
                              and sp.promotionCode = 'canceldowngrade30'
                              and sp.nextPaymentDateAction = 'Downgrade'
                              and date(sp.subscriptionDateCreated) >= '2022-03-01'
                              and date(sp.subscriptionDateCreated) < date(current_date)
                              and sp.countrycode not in ('uk','ca','au','nz','ch')
                              and sp.pricePlanDurationInMonths <> 1) ab
                      ) cd where ranked_bill_date = 1) dn on dn.memberid = sp.memberid and dn.countrycode = sp.countrycode and dn.subscriptionDateCreated > sp.subscriptionDateCreated
      where tt.type in ('PriorAuthCapture','AuthAndCapture') 
        and tt.status = 'SUCCESS'
        and tt.amount > 0
        and date(sp.subscriptionDateCreated) >= '2022-03-01'
        and date(sp.subscriptionDateCreated) < date(current_date)
        and sp.countrycode not in ('uk','ca','au','nz','ch')
        and sp.pricePlanDurationInMonths <> 1
        and sp.nextPaymentDateAction = 'ApplyPromotion'
      group by 1) 
            
union

select 
  upper(comb.countrycode) as Country,
  comb.memberid as MemberID,
  comb.transaction_id,
  date(comb.subscriptionDateCreated) as 'Upgrade Date',
  date(dg.datecreated) as 'Downgrade Requested Date',
  date(comb.nextPaymentdate) as 'Next Payment Date',
  comb.pricePlanDurationInMonths as 'Subscription in Months',
  comb.discounted_fee as 'Subscription Amount',

  datediff(day,date(comb.firstPaymentDate),date(comb.nextPaymentDate)) as 'Total Days Premium',  --- Covers the entire time user was premium
  datediff(day,date(comb.billed_service_start_date),date(comb.nextPaymentdate)) as 'Days in Period',  --- Covers the time user was premium on current subscription plan 
  datediff(day,date(current_date),date(comb.nextPaymentdate)) as 'Days till Basic', --- How many days of premium are left
  
  datediff(day,date(dg.dateCreated),date(comb.nextPaymentdate))-30 as 'Days to Refund', --- Law allows for a max 30 days cancellation notice
  comb.discounted_fee/datediff(day,date(comb.billed_service_start_date),date(comb.nextPaymentdate)) as 'Daily Rate', --- Subscription fee by day
  
  (cast(comb.discounted_fee as numeric)/cast(datediff(day,date(comb.billed_service_start_date),date(comb.nextPaymentdate)) as numeric))*
  (cast(datediff(day,date(dg.dateCreated),date(comb.nextPaymentdate))-30 as numeric)) as 'Refund Amount', --- Mulitples 'Days to Refund' by 'Daily Rate' for the sum to be refunded
  
  case when r.member_id is not null and r.status = 'SUCCESS' then 'Yes' --- Identifies members who have been refunded
       when r.member_id is not null and r.status = 'FAILURE' then 'Failed'
       when m.memberid = '7867010' and comb.transaction_id = '9430561' then 'Yes' 
       when m.memberid = '14263862' and comb.transaction_id = '8462052' then 'Yes'
       when m.memberid = '10673369' and comb.transaction_id = '9262461' then 'Yes'
       when m.memberid = '13013147' and comb.transaction_id = '9616421' then 'Yes'
       when m.memberid = '15186687' and comb.transaction_id = '9267301' then 'Yes'
       when m.memberid = '13946771' and comb.transaction_id = '8859322' then 'Yes'
  else 'No' end as 'Refunded'  
  
from (
select memberid, countrycode, discounted_fee, pricePlanDurationInMonths, billed_service_start_date, subscriptionid, transaction_id, subscriptionDateCreated, transaction_date, firstPaymentDate, nextPaymentDate
from
(select 
  sp.memberid,
  sp.countrycode, 
  dn.discounted_fee,
  dn.pricePlanDurationInMonths,
  dn.billed_service_start_date,    
  dn.subscriptionid, 
  dn.transaction_id,
  tt.date_created as transaction_date,
  sp.subscriptionDateCreated,   
  sp.firstPaymentDate, 
  dn.nextPaymentDate,
  rank () over (partition by sp.memberid order by tt.date_created asc) as ranked_transaction_date 
from intl.transaction tt
join intl.hive_subscription_plan sp on tt.member_id = sp.memberid and tt.country_code = sp.countrycode and tt.subscription_plan_id = sp.subscriptionid
join (select billed_service_start_date, memberid, subscriptionid, transaction_id, countrycode, subscriptionDateCreated, nextPaymentDate, pricePlanDurationInMonths, discounted_fee
            from
              (select billed_service_start_date, memberid, subscriptionid, countrycode, subscriptionDateCreated, transaction_id, nextPaymentDate, 
                      pricePlanDurationInMonths, discounted_fee, rank() over (partition by memberid order by billed_service_start_date desc) as ranked_bill_date
                from (select distinct   
                        tt.billed_service_start_date, 
                        sp.memberid, 
                        sp.subscriptionid, 
                        tt.id as transaction_id,
                        sp.countrycode, 
                        sp.subscriptionDateCreated, 
                        sp.nextPaymentDate, 
                        sp.pricePlanDurationInMonths,
                        (sp.pricePlanFee*0.7) as discounted_fee
                      from intl.transaction tt
                        join intl.hive_subscription_plan sp on tt.member_id = sp.memberid and tt.country_code = sp.countrycode and tt.subscription_plan_id = sp.subscriptionid
                      where tt.type in ('PriorAuthCapture','AuthAndCapture')
                        and tt.status = 'SUCCESS'
                        and tt.amount > 0
                        and sp.promotionCode = 'canceldowngrade30'
                        and sp.nextPaymentDateAction = 'Downgrade'
                        and date(sp.subscriptionDateCreated) >= '2022-03-01'
                        and date(sp.subscriptionDateCreated) < date(current_date)
                        and sp.countrycode not in ('uk','ca','au','nz','ch')
                        and sp.pricePlanDurationInMonths <> 1) ab
                ) cd
            where ranked_bill_date = 1
          ) dn on dn.memberid = sp.memberid and dn.countrycode = sp.countrycode and dn.subscriptionDateCreated > sp.subscriptionDateCreated
where tt.type in ('PriorAuthCapture','AuthAndCapture') 
  and tt.status = 'SUCCESS'
  and tt.amount > 0
  and date(sp.subscriptionDateCreated) >= '2022-03-01'
  and date(sp.subscriptionDateCreated) < date(current_date)
  and sp.countrycode not in ('uk','ca','au','nz','ch')
  and sp.pricePlanDurationInMonths <> 1
  and sp.nextPaymentDateAction = 'ApplyPromotion'
group by 1,2,3,4,5,6,7,8,9,10,11
) comb
where ranked_transaction_date = 1) comb

 join intl.hive_member m                     on comb.memberid = m.memberid 
                                            and comb.countrycode = m.countrycode 
                                            and m.IsInternalAccount = 'false' 
                                            and m.ClosedForFraud = 'false'
                                            and m.countrycode not in ('uk','ca','au','nz','ch') --- These countries are not legally registered in Germany 
                                            and m.memberStatus = 'Premium' --- Only looking at current premiums 
                                            
  join intl.hive_event dg                    on dg.memberid = comb.memberid
                                            and dg.countrycode = comb.countrycode
                                            and dg.name = 'AccountActionRequest' --- When the downgrade was requested
                                            and dg.accountaction = 'Downgrade'
                                            and dg.actionOccursOn <> 'Now'  --- Only downgrades schedulled to occur at the end of premium period and did not happen immediately
                                            and dg.datecreated >= comb.subscriptionDateCreated
                                            and dg.objectid = comb.subscriptionId
                                            
  left join (select date_created, country_code, member_id, subscription_plan_id, status
                  from
                  (select 
                    date_created,
                    country_code,
                    member_id,
                    subscription_plan_id,
                    status,
                    rank() over (partition by member_id, subscription_plan_id order by date_created desc) as ranked
                  from intl.transaction 
                  where type = 'Credit' 
                    and amount > 0 ) ab
                  where ranked = 1) r           on r.member_id = comb.memberid and r.country_code = comb.countrycode
                                                and r.date_created > comb.transaction_date and r.subscription_plan_id = comb.subscriptionid                         

  left join intl.transaction cb              on cb.member_id = comb.memberid
                                            and cb.country_code = comb.countrycode
                                            and cb.date_created > comb.transaction_date
                                            and cb.type = 'Chargeback' 
                                            and cb.amount > 0 
                                            and cb.status = 'SUCCESS'
                                            and cb.subscription_plan_id = comb.subscriptionid 
                                            
where 1
  and datediff(day,date(dg.dateCreated),date(comb.nextPaymentdate)) > 30  --- Must be more than 30 days left from requesting downgrade until the next payment date be eligiable for refund
  and datediff(day,date(comb.firstPaymentDate),date(comb.nextPaymentDate)) > datediff(day,date(comb.billed_service_start_date),date(comb.nextPaymentdate)) --- Excludes the first transaction if multiple auto-renews have occurred (difference in days would be the same on the first transaction)
  and cb.member_id is null -- Added 15.08.2022 to exclude those with ChargeBack
