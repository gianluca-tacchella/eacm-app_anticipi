@EndUserText.label: 'MFXN direct advances ZPRDP'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity /EACM/I_MFXN_RECOVERY
  as select from /eacm/zprdp as z
  association [0..*] to /EACM/I_MFXN_DSUM as _Summaries
    on  _Summaries.Bukrs = $projection.Bukrs
    and _Summaries.Zcdaz = $projection.Zcdaz
    and _Summaries.Zamco = $projection.Zamco
    and _Summaries.Waerk = $projection.Waerk
  association [0..*] to /EACM/I_MFXN_ZPRDP as _Advances
    on  _Advances.Bukrs = $projection.Bukrs
    and _Advances.Zcdaz = $projection.Zcdaz
    and _Advances.Zamco = $projection.Zamco
    and _Advances.Waerk = $projection.Waerk
{
  key z.bukrs as Bukrs,
  key z.zcdaz as Zcdaz,
  key z.zamco as Zamco,
  key z.waerk as Waerk,

      count( * )   as AdvanceCount,
      min( z.fkdat ) as FirstBillingDate,
      max( z.fkdat ) as LastBillingDate,

      @Semantics.amount.currencyCode: 'Waerk'
      sum( z.ziman ) as TotalAdvance,

      @Semantics.amount.currencyCode: 'Waerk'
      sum( z.zirec ) as TotalRecovered,

      @Semantics.amount.currencyCode: 'Waerk'
      sum( z.ziprv ) as TotalCommission,

      _Summaries,
      _Advances
}
group by
  z.bukrs,
  z.zcdaz,
  z.zamco,
  z.waerk
