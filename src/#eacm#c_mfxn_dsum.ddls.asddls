@EndUserText.label: 'MFXN riepilogo diretto ZPRDP'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/C_MFXN_DSUM
  as select from /EACM/I_MFXN_DSUM as s
{
  key s.Bukrs as Bukrs,
  key s.Zcdaz as Zcdaz,
  key s.Zamco as Zamco,
  key s.Waerk as Waerk,
  key s.Vkorg as Vkorg,
  key s.Vtweg as Vtweg,
  key s.Zclpr as Zclpr,

      s.LineCount as LineCount,
      s.TotalAdvance as TotalAdvance,
      s.TotalRecovered as TotalRecovered,
      s.TotalCommission as TotalCommission
}
