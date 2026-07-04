@EndUserText.label: 'MFXN - /eacm/ZPRDP'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity /EACM/I_MFXN_ZPRDP
  as select from /eacm/zprdp as z
{
  key z.vkorg as Vkorg,
  key z.vtweg as Vtweg,
  key z.zclpr as Zclpr,
  key z.vbeln as Vbeln,
  key z.posnr as Posnr,
  key z.zcdaz as Zcdaz,
  key z.zidag as Zidag,
  key z.zidrg as Zidrg,

      z.bukrs as Bukrs,
      z.gjahr as Gjahr,
      z.belnr as Belnr,
      z.kunrg as Kunrg,
      z.fkdat as Fkdat,
      z.zamco as Zamco,
      z.waerk as Waerk,
      z.ztpcd as Ztpcd,
      z.zstre as Zstre,
      z.zdtsf as Zdtsf,

      @Semantics.amount.currencyCode: 'Waerk'
      z.ziman as Ziman,

      @Semantics.amount.currencyCode: 'Waerk'
      z.zirec as Zirec,

      @Semantics.amount.currencyCode: 'Waerk'
      z.ziprv as Ziprv,

      case
        when z.ziman > z.zirec then cast( 'X' as abap_boolean )
        else cast( ' ' as abap_boolean )
      end as HasOpenAmount
}
