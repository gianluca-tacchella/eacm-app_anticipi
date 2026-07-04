@EndUserText.label: 'MFXN range distribution channel - projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/C_MFXN_VTWEG
  as projection on /EACM/I_MFXN_VTWEG
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
