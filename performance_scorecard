select
  base_dates.date,
  base_dates.year,
  base_dates.month_start_date,
  base_dates.date_current,
  base_dates.monthToDate,
  base_dates.YearToDate,
  base_dates.run_date,
  sum(spend_usd) as spend_usd,
  sum(visits) as visits, 
  sum(basics) as basics,
  sum(total_premiums) as total_premiums,
  sum(day1_premiums) as day1_premiums,
  sum(day30_premiums) as day30_premiums,
  sum(nth_premiums) as nth_premiums, 
  sum(reupgrades) as reupgrades,   
  sum(jobs) as jobs,
  sum(apps) as apps,
  sum(auto_apps) as auto_apps,
  sum(manual_apps) as manual_apps,
  sum(jobs_no_apps) as jobs_no_apps,
  sum(premium_balance) as premium_balance,
  sum(churn) as churn, 
  sum(renewals) as renewals,
  sum(potential_renewals) as potential_renewals,
  sum(first_period_renewals) as first_period_renewals,
  sum(potential_first_period_renewals) as potential_first_period_renewals,
  sum(one_month_renewals) as one_month_renewals,
  sum(one_month_potential_renewals) as one_month_potential_renewals
  
from (
--1. Base dates
  select distinct
    dd.date,
    dd.year,
    dd.month_start_date,
    dc.current_date_sameday as 'date_current',
    dc.MonthToDate,
    dc.YearToDate,
    current_date() as 'run_date',
    countrycode.countrycode,
	  vertical.vertical
  from reporting.DW_D_DATE dd
    join analytics.dw_d_date_current dc on dd.date = dc.date
  cross join (
    select distinct -- 17 rows
      m.countrycode as 'countrycode'
    from intl.hive_member m
    where date(dateProfileComplete) = '2024-05-20'
    ) countrycode
  cross join (
    select distinct-- 7 rows       
      case 
        when vertical = 'homeCare' then 'Housekeeping'
        when lower(vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
        else initcap(lower(vertical))
      end as vertical
    from intl.hive_member
    where date(dateProfileComplete) = '2024-05-20'
    ) vertical
  where
    year(dd.date) >= year(now())
    and dd.date < current_date()
) base_dates

left join (
    select distinct 
      date, countrycode, vertical, 
      sum(case when currency = 'EUR' then spend * fx.currency_rate 
               when currency = 'AUD' then spend * fx.currency_rate
               when currency = 'CAD' then spend * fx.currency_rate
               when currency = 'GBP' then spend * fx.currency_rate end) as spend_usd
    from (
        select distinct --- Google
             dd.date,  
             lower(country) as countrycode,
             case when vertical = 'HomeCare' then 'Housekeeping'
                  when (vertical not in ('ChildCare', 'HomeCare', 'PetCare') or vertical is null) then 'OV'
                else initcap(vertical) end as vertical,
             sem.currency,
             ifnull(sum(sem.cost),0) as spend
          from intl.dw_f_campaign_spend_intl sem
            join reporting.DW_D_DATE dd on date(sem.date) = dd.date and dd.date < date(current_date) and dd.year >= year(now())
          where sem.country is not null
            and lower(sem.campaign_type) = 'seeker'
          group by 1,2,3,4 
  
        union

          --- Bing 
          select distinct dd.date, 'at' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(AT_Seeker_Microsoft) as spend
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'au' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(AU_Seeker_Microsoft) as spend  
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'be' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(BE_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'ca' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(CA_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4  
          union
          select distinct dd.date, 'ch' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(CH_Seeker_Microsoft) as spend
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'de' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(DE_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4  
          union
          select distinct dd.date, 'dk' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(DK_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'fi' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(FI_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'ie' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(IE_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'nl' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(NL_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'no' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(NO_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4  
          union
          select distinct dd.date, 'nz' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(NZ_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
          union
          select distinct dd.date, 'se' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(SE_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4  
          union
          select distinct dd.date, 'uk' as countrycode, 'OV' as vertical, 'EUR' as currency, sum(UK_Seeker_Microsoft) as spend 
          from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 

        union

        select distinct --- FACEBOOK 
          dd.date,
          case when lower(country) = 'en' then 'ca' 
               when lower(country) = '_'  then 'au' 
               when lower(country) in ('ve', 'po')  then 'de' 
            else lower(country) end as countrycode, 
           case when vertical = 'Child Care' then 'Childcare'
                when vertical = 'PetCare' then 'Petcare'
                when vertical = 'HouseKeeping' then 'Housekeeping'
            else 'OV' end as vertical,     
          fb.currency,
          ifnull(sum(spend),0) as spend 
        from intl.DW_F_FACEBOOK_SPEND_INTL fb
          join reporting.DW_D_DATE dd on date(date_start) = dd.date and dd.date < date(current_date) and dd.year >= year(now())
        where lower(campaign_type) = 'seeker' 
        group by 1,2,3,4 
  
        union


        select distinct -- Quality Click
          date, countrycode, vertical, currency, ifnull(sum(spend),0) as spend
        from 
            (select distinct
              dd.date,
              case when program in ('DE', 'AT', 'CH') then lower(program)
                    when product like '%FR%' then 'fr'
                    when product like '%BE_nl%' then 'be'  
                    when product like '%BE_fr%' then 'fb'  
                    when product like '%DK%' then 'dk'  
                    when product like '%FI%' then 'fi'  
                    when product like '%NL%' then 'nl'  
                    when product like '%SE%' then 'se'  
                    when product like '%IE%' then 'ie'  
                    when product like '%ES%' then 'es'  
                    when product like '%AU%' then 'au'  
                    when product like '%NO%' then 'no'
                    when product like '%NZ%' then 'nz'
                    when product like '%UK%' then 'uk'
                    when product like '%CA%' then 'ca'
               end as countrycode, 
               case when partnerid = '372' then 'Childcare'
                    when partnerid = '468' then 'Housekeeping'
                    when partnerid = '472' then 'Housekeeping'
                    when partnerid = '17' then 'Petcare'
                    when partnerid = '480' then 'Petcare'
                  else 'OV' end as vertical,
              'EUR' as currency,
               sum(qc.commission) as spend
            from intl.quality_click_spend qc
              join reporting.DW_D_DATE dd on date(day) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
            where partnerid not in ('435', '469')
              and (lower(product) not like '%alltagshelfer%' or lower(product) not like '%provider%')     
            group by 1,2,3,4) qc
        group by 1,2,3,4 
  
        union

        select distinct --- Putzfrau Agentur
          date, countrycode, vertical, currency, ifnull(sum(spend),0) as spend 
        from 
            (select distinct
               dd.date,   
               case when program in ('DE', 'AT', 'CH') then lower(program)
                    when product like '%FR%' then 'fr'
                    when product like '%BE_nl%' then 'be'  
                    when product like '%BE_fr%' then 'fb'  
                    when product like '%DK%' then 'dk'  
                    when product like '%FI%' then 'fi'  
                    when product like '%NL%' then 'nl'  
                    when product like '%SE%' then 'se'  
                    when product like '%IE%' then 'ie'  
                    when product like '%ES%' then 'es'  
                    when product like '%AU%' then 'au'  
                    when product like '%NO%' then 'no'
                    when product like '%NZ%' then 'nz'
                    when product like '%UK%' then 'uk'
                    when product like '%CA%' then 'ca'
                end as countrycode, 
               'Housekeeping' as vertical,
              'EUR' as currency,
               sum(qc.commission) as spend
            from intl.quality_click_spend qc
              join reporting.DW_D_DATE dd on date(day) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
            where partnerid = '469'
              and (lower(product) not like '%alltagshelfer%' or lower(product) not like '%provider%') -- Assigned default to seekers as discussed with Fabian
            group by 1,2,3,4) qc
        group by 1,2,3,4 

        union

        select distinct --- Putzchecker
           dd.date, 'de' as countrycode, 'Housekeeping' as vertical, 'EUR' as currency, ifnull((sum(clicks)*1.5),0) as spend 
        from intl.quality_click_cpc
          join reporting.DW_D_DATE dd on date(day) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
        group by 1,2,3,4 
  
        union

        --- TikTok 
        select dd.date, 'de' as countrycode, 'Childcare' as vertical, 'EUR' as currency, ifnull(sum(DE_Seeker_Mibaby),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4

        union

        --- Awin
        select distinct
          dd.date,
          case when advertiser_id = '10557' then 'de'
               when advertiser_id = '10709' then 'at'   
               when advertiser_id = '45671' then 'uk' 
            end as countrycode,  
          'OV' as vertical,  
        	case when advertiser_id in ('10557', '10709') then 'EUR' else 'GBP' end as currency,	   
          ifnull((sum(aw.commission_amount)*1.3),0) as spend 
        from intl.awin_spend aw
          join reporting.DW_D_DATE dd on date(aw.transaction_Date) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
        where lower(aw.commissionStatus) in ('approved', 'pending')
          and aw.commission_group_code not in ('REG_P','REGP')
        group by 1,2,3,4 
	
        union

        select distinct --- Meinestadt
           dd.date, 'de' as countrycode, vertical, 'EUR' as currency,
           ifnull(sum(case when spend.year = spend.current_year and spend.month = spend.current_month then ((spend)/current_days) else ((spend)/days_in_month) end),0) as spend_domestic_currency
        from (
          select distinct
            year(sp.subscriptionDateCreated) as year,
            month(sp.subscriptionDateCreated) as month,
            date_part('day', last_day(sp.subscriptionDateCreated)) as days_in_month,
            date_part('day', current_date()-1) as current_days,
            month(current_date()-1) as current_month,
            year(current_date()-1) as current_year,
            case when m.vertical = 'homeCare' then 'Housekeeping'
                 when lower(m.vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
                 when m.vertical is null then 'OV'
              else initcap(lower(m.vertical)) end as vertical,
            count(distinct sp.subscriptionId) as premiums,
            case when count(distinct sp.subscriptionId)<=150 then (count(distinct sp.subscriptionId)*80) 
              when count(distinct sp.subscriptionId)>150 then (150*80)+((count(distinct sp.subscriptionId)-150)*120) end as 'Spend' 
          from intl.transaction t
            join intl.hive_subscription_plan sp on sp.subscriptionId = t.subscription_plan_id and sp.countrycode = t.country_code
              and year(sp.subscriptionDateCreated) >= year(now())-1 and date(sp.subscriptionDateCreated) < date(current_date)
            join intl.hive_member m on t.member_id = m.memberid and t.country_code = sp.countrycode and date(m.dateFirstPremiumSignup) = date(sp.subscriptionDateCreated)
              and m.IsInternalAccount is not true
              and lower(m.role) = 'seeker' and lower(m.audience) = 'seeker'
              and lower(m.campaign) = 'online' and lower(m.site) = 'meinestadt.de' 
          where t.type in ('PriorAuthCapture','AuthAndCapture') and t.status = 'SUCCESS' and t.amount > 0
            and t.country_code = 'de'      
            and year(t.date_created) >= year(now()) and date(t.date_created) < date(current_date)
          group by 1,2,3,4,5,6,7
        ) spend
          join reporting.DW_D_DATE dd on spend.year = dd.year and spend.month = dd.month and dd.year >= year(now()) and dd.date < date(current_date)
          group by 1,2,3,4 
      
        union   

        -- Pinterest 
        select distinct dd.date, 'de' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(DE_Seeker_Pinterest),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
        union
        select distinct dd.date, 'uk' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(UK_Seeker_Pinterest),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
        union
        select distinct dd.date, 'ca' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(CA_Seeker_Pinterest),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 
        union
        select distinct dd.date, 'au' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(AU_Seeker_Pinterest),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 

        union

        select distinct --- TV 
           dd.date, 'de' as countrycode, 'Housekeeping' as vertical, 'EUR' as currency, ifnull(sum(DE_TV),0) as spend
        from intl.DW_MARKETING_SPEND_INTL
          join reporting.DW_D_DATE dd on date(spend_date) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
        group by 1,2,3,4
  
        union

        select distinct --- Spotify
          dd.date, 'de' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(spend),0) as spend
        from intl.spotify_spend sy
        join reporting.DW_D_DATE dd on date(sy.start_date) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
        group by 1,2,3,4 

        union

        -- Impact
        select distinct dd.date, 'ca' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(CA_OTHER_ONLINE),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4  
        union
        select distinct dd.date, 'au' as countrycode, 'OV' as vertical, 'EUR' as currency, ifnull(sum(AU_OTHER_ONLINE),0) as spend 
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4   
  
        union

        --- Kleinanzeigen
        select distinct dd.date, 'de' as country, 'OV' as vertical, 'EUR' as currency, ifnull(sum(DE_Seeker_Nebenan),0) as spend
        from intl.DW_MARKETING_SPEND_INTL join reporting.DW_D_DATE dd on spend_date = dd.date where dd.year >= year(now()) and dd.date < date(current_date) group by 1,2,3,4 

    ) comb
      join reporting.DW_CARE_FX_RATES fx  on fx.source_currency = comb.currency and source_currency in ('EUR','GBP','CAD','AUD') and fx.target_currency = 'USD' and fx.currency_rate_type = 'Current'
      group by 1,2,3
) spend on base_dates.date = spend.date and base_dates.countrycode = spend.countrycode and base_dates.vertical = spend.vertical      

left join (
    select 
      dd.date, v.countrycode, 
      case when lower(rxservice) in ('childcare', 'cc', 'c') or lower(rxservice) like '%child%' then 'Childcare'
           when ( lower(rxservice) in ('housekeeping', 'homecare', 'hk', 'ho') or lower(rxservice) like '%homecare%' ) then 'Housekeeping'
           when ( lower(rxservice) in ('petcare', 'pc', 'hk', 'ho') or lower(rxservice) like '%petcare%' ) then 'Petcare'
           when ( lower(rxservice) not in ('childcare', 'cc', 'c', 'housekeeping', 'homecare', 'hk', 'ho', 'petcare', 'pc', 'hk', 'ho') or regexp_not_ilike(rxservice, 'child | homecare | petcare') ) then 'OV'
           when lower(rxsite) in ('msn', 'awin', 'pinterest', 'kleinanzeigen', 'spotify', 'impact') then 'OV'
           when lower(rxsite) = 'qualityclick' and rxcreativeversion = '372' then 'Childcare' 
           when lower(rxsite) = 'qualityclick' and rxcreativeversion in ('468', '469', '472') then 'Housekeeping'  
           when lower(rxsite) = 'qualityclick' and rxcreativeversion in ('17', '480') then 'Petcare'  
           when lower(rxsite) = 'qualityclick' and rxcreativeversion not in ('372', '468', '472', '17', '480') then 'OV' 
           when lower(rxsite) = 'putzchecker' then 'Housekeeping' 
           when lower(rxsite) = 'tiktok' then 'Childcare'       
        else concat(lower(rxsite), lower(rxservice)) end as vertical,
      count(distinct visitorid) as visits                                                         
    from intl.hive_visit v 
    join reporting.DW_D_DATE dd on date(startDate) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
    where lower(v.rxcampaign) in ('sem', 'online', 'affiliate', 'influencer', 'seo') 
      and lower(v.rxsite) not like 'careus%'
      and (v.memberid is null or v.signup = true)
      and lower(v.rxaudience) in ('seeker', 'all', 'general') 
    group by 1,2,3
) visits on base_dates.date = visits.date and base_dates.countrycode = visits.countrycode and base_dates.vertical = visits.vertical

left join (
      select
        dd.date, mm.countrycode,
        case when mm.vertical = 'homeCare' then 'Housekeeping'
             when lower(mm.vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
             when mm.vertical is null then 'OV'
          else initcap(lower(mm.vertical)) end as vertical,
        count(distinct mm.memberid) as basics  
      from intl.hive_member mm   
      join reporting.DW_D_DATE dd on date(mm.dateMemberSignup) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
      where lower(mm.campaign) in ('sem', 'online', 'affiliate', 'influencer', 'seo') 
        and lower(mm.site) not like 'careus%' 
        and mm.IsInternalAccount = 'false'
        and lower(mm.role) = 'seeker'
      group by 1,2,3) basics on base_dates.date = basics.date and base_dates.countrycode = basics.countrycode and base_dates.vertical = basics.vertical 
      
left join (
      select
        d.date,
        case when mm.vertical = 'homeCare' then 'Housekeeping'
           when lower(mm.vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
           when mm.vertical is null then 'OV'
          else initcap(lower(mm.vertical)) end as vertical,
        mm.countrycode,
        count(distinct sp.subscriptionId) as total_premiums,
        count(distinct case when date(sp.subscriptionDateCreated) = date(mm.dateMemberSignup) then sp.subscriptionId end) as day1_premiums,
        count(distinct case when date(mm.dateFirstPremiumSignup) = date(sp.subscriptionDateCreated) and datediff('day', mm.dateMemberSignup, sp.subscriptionDateCreated)<=30 then sp.subscriptionId end) as day30_premiums,
        count(distinct case when date(mm.dateFirstPremiumSignup) = date(sp.subscriptionDateCreated) and date(sp.subscriptionDateCreated) != date(mm.dateMemberSignup) then sp.subscriptionId end) as nth_premiums, 
        count(distinct case when date(mm.dateFirstPremiumSignup) != date(sp.subscriptionDateCreated) then sp.subscriptionId end) as reupgrades     
      from intl.transaction tt
        join intl.hive_subscription_plan sp on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code
        join reporting.DW_D_DATE d          on date(sp.subscriptionDateCreated) = d.date and d.year >= year(now()) and d.date < date(current_date)
        join intl.hive_member mm            on sp.memberid = mm.memberid and sp.countrycode = mm.countrycode
      where tt.type in ('PriorAuthCapture','AuthAndCapture')
        and tt.status = 'SUCCESS'
        and tt.amount > 0
        and mm.IsInternalAccount = 'false'
        and lower(mm.campaign) in ('sem', 'online', 'affiliate', 'influencer', 'seo') 
        and lower(mm.site) not like 'careus%'  
        and lower(mm.role) = 'seeker'
      group by 1,2,3) premiums on base_dates.date = premiums.date and base_dates.countrycode = premiums.countrycode and base_dates.vertical = premiums.vertical

left join (
      select
        dd.date,
        jp.country_code as countrycode,
        case when mm.vertical = 'homeCare' then 'Housekeeping'
             when lower(mm.vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
             when mm.vertical is null then 'OV'
         else initcap(lower(mm.vertical)) end as vertical,
        count(distinct jp.id) as jobs,
        count(distinct ja.id) as apps,
        count(distinct case when ja.was_sent_automatically = 'true' then ja.id end) as auto_apps,
        count(distinct case when ja.was_sent_automatically = 'false' then ja.id end) as manual_apps,
        count(distinct case when ja.id is null then jp.id end) as jobs_no_apps   
      from intl.job jp
        join intl.hive_member mm            on mm.memberid = jp.member_id and mm.countrycode = jp.country_code and mm.IsInternalAccount = 'false'
        left join intl.job_application ja   on jp.id = ja.job_id and jp.country_code = ja.country_code
        join reporting.DW_D_DATE dd         on date(jp.date_created) = dd.date and dd.year >= year(now()) and dd.date < date(current_date)
      where jp.search_status = 'Approved'
      group by 1,2,3) jobs_apps on base_dates.date = jobs_apps.date and base_dates.countrycode = jobs_apps.countrycode and base_dates.vertical = jobs_apps.vertical
      
left join (
      with premium_balance as (
          select distinct
            dd.date, mm.countrycode,
            case when mm.vertical = 'homeCare' then 'Housekeeping'
                 when lower(mm.vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
                 when mm.vertical is null then 'OV'
              else initcap(lower(mm.vertical)) end as vertical,
            count(distinct case when date(sp.nextpaymentdate) > dd.date then sp.subscriptionId end) as premiums
          from intl.transaction tt
            join intl.hive_subscription_plan sp on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code 
            join intl.hive_member mm            on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false' and mm.closedforfraud = 'false' and lower(mm.role) = 'seeker' 
            join (select distinct date from reporting.dw_d_date where year >= year(now()) and date < date(current_date)) dd on date(subscriptiondatecreated) < dd.date
          where tt.type in ('PriorAuthCapture','AuthAndCapture')
            and tt.status = 'SUCCESS'
            and tt.amount > 0
          group by 1,2,3),
    
      churn as (
         select
          dd.date, mm.countrycode,
          case when mm.vertical = 'homeCare' then 'Housekeeping'
               when lower(mm.vertical) not in ('childcare','homecare','petcare','housekeeping') then 'OV'
               when mm.vertical is null then 'OV'
            else initcap(lower(mm.vertical)) end as vertical,
          count(distinct sp.subscriptionId) as churn
        from intl.transaction tt
          join intl.hive_subscription_plan sp       on sp.subscriptionId = tt.subscription_plan_id and sp.countrycode = tt.country_code and sp.subscriptionEndDate is not null
          join intl.hive_member mm                  on tt.member_id = mm.memberid and tt.country_code = mm.countrycode and mm.IsInternalAccount = 'false' and mm.closedforfraud = 'false' and lower(mm.role) = 'seeker' 
          join reporting.dw_d_date dd               on dd.date = date(sp.subscriptionenddate) and year >= year(now()) and dd.date < date(current_date) 
        where tt.type in ('AuthAndCapture')
          and tt.status = 'SUCCESS'
          and tt.amount > 0
        group by 1,2,3)
  
      select 
        coalesce(p.date, c.date) as date,
        coalesce(p.countrycode, c.countrycode) as countrycode,
        coalesce(p.vertical, c.vertical) as vertical,
        ifnull(sum(p.premiums),0) as premium_balance,
        ifnull(sum(c.churn),0) as churn
      from premium_balance p
      full outer join churn c on p.date = c.date and p.countrycode = c.countrycode and p.vertical = c.vertical
      group by 1,2,3 order by 1      
) retention on base_dates.date = retention.date and base_dates.countrycode = retention.countrycode and base_dates.vertical = retention.vertical

left join (
    select
      date, countrycode, 
      case when vertical not in ('Childcare', 'Housekeeping', 'Petcare') then 'OV' else vertical end as vertical,
      ifnull(sum(renewals),0) as renewals,
      ifnull(sum(potential_renewals),0) as potential_renewals,
      sum(case when renewal_period = 'First Period Renewal' then renewals else 0 end) as first_period_renewals,
      sum(case when renewal_period = 'First Period Renewal' then potential_renewals else 0 end) as potential_first_period_renewals,
      sum(case when subscription_length = 1 then renewals else 0 end) as one_month_renewals,
      sum(case when subscription_length = 1 then potential_renewals else 0 end) as one_month_potential_renewals
    from analytics_prod.INTL_DAILY_RENEWALS_DOWNGRADES
    where year(date) >= year(now())
      and member_type = 'Seeker'
    group by 1,2,3) renewal on base_dates.date = renewal.date and base_dates.countrycode = renewal.countrycode and base_dates.vertical = renewal.vertical

group by 1,2,3,4,5,6,7
