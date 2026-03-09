select distinct
  date(datecreated) as date,
  upper(countrycode) as Country,
  'Vetting' as Content_Moderation,
  case when entityType = 'JobApplicationTemplate' then 'Job Application'
       when entityType = 'ReviewResponse' then 'Review Response'
       when entityType = 'VerticalProfile' then 'Profile'
    else entityType end as Content_Type, 
  case when rejectReason is null then 'No Reason' else 
    trim(regexp_replace(regexp_replace(split_part(rejectReason, ',', 1),'(Rejected|SecurityBreach|TOU)',''),'([a-z])([A-Z])', '\1 \2')) end as Violation,
  count(distinct objectId) as No_Items
from intl.hive_event 
where name = 'CSRApproval'
  and date(datecreated) >= '2024-01-01'
  and approvalAction = 'Rejected'
group by 1,2,3,4,5

union

select distinct 
  date(date_created) as date,
  upper(country_code) as Country,
  'Block List' as Content_Moderation,
  'Member' as Content_Type,
  case when rule_description = 'firstName,phoneNumber,countryCode+' then 'Name, Phone Number and Country'
       when rule_description = 'lastName,phoneNumber,countryCode+' then 'Name, Phone Number and Country'
       when rule_description = 'emailAddress+' then 'Email'
       when rule_description = 'csrBlacklist' then 'Member Care Block List'
       when rule_description = 'csrBlacklistAuto' then 'Auto Block List: Profanity'
    else initcap(cast(rule_description as varchar (100))) end as Violation,
  count(distinct blacklisted_person_id) as No_Items
from intl.blacklist_reason 
where date(date_created) >= '2024-01-01'
group by 1,2,3,4,5

union

select distinct 
  date(cd.action_date) as date,
  upper(cd.country_code) as Country,
  'Account Closure' as Content_Moderation,
  'Member' as Content_Type,
  case when cd.action_reason = 'RT_OPEN_INACTIVE' then 'Closed Inactive Account' else 
    regexp_replace(cd.action_reason, '([a-z])([A-Z])', '\1 \2') end as Violation,
  count(distinct case when vt.memberid is null then cd.member_id end) as No_Items
from intl.close_downgrade_detail  cd
left join intl.hive_event         vt on cd.member_id = vt.memberid and cd.country_code = vt.countrycode and vt.name = 'CSRApproval' 
                                  and vt.approvalAction = 'Rejected' and date(vt.datecreated) >= '2024-01-01'
where cd.action_performed = 'Close'
and cd.user_type in ('CSR', 'Backoffice')
and date(cd.action_date) >= '2024-01-01' 
and cd.action_reason not in ('RT_CLOSED_ACCT','AutoRenewal','ChangeOfPlans','DissatisfiedService','FoundCare','FoundElsewhere','NoneProvided','Revocation','TooManyEmails','WrongSubscription') 
group by 1,2,3,4,5
