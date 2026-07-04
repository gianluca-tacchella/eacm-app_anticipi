@EndUserText.label: 'MFXN direct advances ZPRDP'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/I_MFXN_DSUM
  as select from /eacm/zprdp as z
{
  key z.bukrs as Bukrs,
  key z.zcdaz as Zcdaz,
  key z.zamco as Zamco,
  key z.waerk as Waerk,
  key z.vkorg as Vkorg,
  key z.vtweg as Vtweg,
  key z.zclpr as Zclpr,

      count( * ) as LineCount,

      @Semantics.amount.currencyCode: 'Waerk'
      sum( z.ziman ) as TotalAdvance,

      @Semantics.amount.currencyCode: 'Waerk'
      sum( z.zirec ) as TotalRecovered,

      @Semantics.amount.currencyCode: 'Waerk'
      sum( z.ziprv ) as TotalCommission
}
group by
  z.bukrs,
  z.zcdaz,
  z.zamco,
  z.waerk,
  z.vkorg,
  z.vtweg,
  z.zclpr
