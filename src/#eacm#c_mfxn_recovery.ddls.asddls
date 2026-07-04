@EndUserText.label: 'MFXN recuperi diretti ZPRDP'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity /EACM/C_MFXN_RECOVERY
  as select from /EACM/I_MFXN_RECOVERY as r
  association [0..*] to /EACM/C_MFXN_DSUM as _Summaries
    on  _Summaries.Bukrs = $projection.Bukrs
    and _Summaries.Zcdaz = $projection.Zcdaz
    and _Summaries.Zamco = $projection.Zamco
    and _Summaries.Waerk = $projection.Waerk
  association [0..*] to /EACM/C_MFXN_ZPRDP as _Advances
    on  _Advances.Bukrs = $projection.Bukrs
    and _Advances.Zcdaz = $projection.Zcdaz
    and _Advances.Zamco = $projection.Zamco
    and _Advances.Waerk = $projection.Waerk
{
  key r.Bukrs as Bukrs,
  key r.Zcdaz as Zcdaz,
  key r.Zamco as Zamco,
  key r.Waerk as Waerk,

      r.AdvanceCount as AdvanceCount,
      r.FirstBillingDate as FirstBillingDate,
      r.LastBillingDate as LastBillingDate,
      r.TotalAdvance as TotalAdvance,
      r.TotalRecovered as TotalRecovered,
      r.TotalCommission as TotalCommission,

      _Summaries,
      _Advances
}
