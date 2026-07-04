@EndUserText.label: 'MFXN range sales organization - projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/C_MFXN_VKORG
  as projection on /EACM/I_MFXN_VKORG
{
  key Uuid,
  key RangeUuid,
      SortOrder,
      SelSign,
      SelOption,
      Low,
      High,

      _Recovery : redirected to parent /EACM/C_MFXN_HDR
}
