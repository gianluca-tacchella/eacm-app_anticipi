//@EndUserText.label: 'MFXN - /EACM/ZPRDP - projection'
//@AccessControl.authorizationCheck: #NOT_REQUIRED
//@Metadata.allowExtensions: true
//@Search.searchable: true
//define root view entity /EACM/C_MFXN_ZPRDP
//  as projection on /EACM/I_MFXN_ZPRDP
//{
//  key Vkorg,
//  key Vtweg,
//  key Zclpr,
//  key Vbeln,
//  key Posnr,
//  key Zcdaz,
//  key Zidag,
//  key Zidrg,
//
//      Bukrs,
//      Gjahr,
//      Belnr,
//      Kunrg,
//      Fkdat,
//      Zamco,
//      Waerk,
//      Ztpcd,
//      Zstre,
//      Zdtsf,
//      Ziman,
//      Zirec,
//      Ziprv,
//      HasOpenAmount
//}

@EndUserText.label: 'MFXN - /EACM/ZPRDP - projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity /EACM/C_MFXN_ZPRDP
  provider contract transactional_query
  as projection on /EACM/I_MFXN_ZPRDP
{
  key Vkorg,
  key Vtweg,
  key Zclpr,
  key Vbeln,
  key Posnr,
  key Zcdaz,
  key Zidag,
  key Zidrg,

      Bukrs,
      Gjahr,
      Belnr,
      Kunrg,
      Fkdat,
      Zamco,
      Waerk,
      Ztpcd,
      Zstre,
      Zdtsf,
      Ziman,
      Zirec,
      Ziprv,
      HasOpenAmount
}
