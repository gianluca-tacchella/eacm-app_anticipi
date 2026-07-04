@EndUserText.label: 'MFXN summary of advances - projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/C_MFXN_SUM
  as projection on /EACM/I_MFXN_SUM
{
  key Uuid,
  key LineUuid,
      Vkorg,
      Vtweg,
      Zclpr,
      Waerk,
      Mwskz,
      Ziprv,
      Zirec,
      AvailableRec,
      ZiprvLc,
      ZirecLc,

      _Recovery : redirected to parent /EACM/C_MFXN_HDR
}
