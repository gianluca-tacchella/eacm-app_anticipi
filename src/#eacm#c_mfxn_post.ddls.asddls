@EndUserText.label: 'MFXN movment staged - projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/C_MFXN_POST
  as projection on /EACM/I_MFXN_POST
{
  key Uuid,
  key PostUuid,
      AdvanceUuid,
      SummaryUuid,
      PostType,
      Vkorg,
      Vtweg,
      Zclpr,
      Zcdaz,
      Zwaer,
      Zamco,
      Zprec,
      Zirec,
      Bukrs,
      Gjahr,
      Ziman,
      Belnr,
      Ztpan,
      Zamca,
      Zesfa,
      Znrfa,
      Mwskz,
      Fkdat,
      CreatedBy,
      CreatedAt,

      _Recovery : redirected to parent /EACM/C_MFXN_HDR
}
