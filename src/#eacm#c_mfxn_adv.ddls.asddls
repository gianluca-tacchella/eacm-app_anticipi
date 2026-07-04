@EndUserText.label: 'MFXN recoverable advances - projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/C_MFXN_ADV
  as projection on /EACM/I_MFXN_ADV
{
  key Uuid,
  key LineUuid,
      Vkorg,
      Vtweg,
      Zclpr,
      Vbeln,
      Posnr,
      Zcdaz,
      Zidag,
      Zidrg,
      Bukrs,
      Gjahr,
      Belnr,
      Kunrg,
      Fkdat,
      Zamco,
      Zamcos,
      SourceWaerk,
      DisplayWaerk,
      Mwskz,
      SourceZiman,
      SourceZirec,
      Ziman,
      Zirec,
      Rec,
      MaxRec,
      ZimanLc,
      ZirecLc,

      _Recovery : redirected to parent /EACM/C_MFXN_HDR
}
