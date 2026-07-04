//@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'MFXN movment staged'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/I_MFXN_POST
  as select from /eacm/mfxn_post as p
  association to parent /EACM/I_MFXN_HDR as _Recovery
    on $projection.Uuid = _Recovery.Uuid
{
  key p.uuid         as Uuid,
  key p.post_uuid    as PostUuid,
      p.advance_uuid as AdvanceUuid,
      p.summary_uuid as SummaryUuid,
      p.post_type    as PostType,
      p.vkorg        as Vkorg,
      p.vtweg        as Vtweg,
      p.zclpr        as Zclpr,
      p.zcdaz        as Zcdaz,
      p.zwaer        as Zwaer,
      p.zamco        as Zamco,
      p.zprec        as Zprec,
      @Semantics.amount.currencyCode: 'Zwaer'
      p.zirec        as Zirec,
      p.bukrs        as Bukrs,
      p.gjahr        as Gjahr,
      @Semantics.amount.currencyCode: 'Zwaer'
      p.ziman        as Ziman,
      p.belnr        as Belnr,
      p.ztpan        as Ztpan,
      p.zamca        as Zamca,
      p.zesfa        as Zesfa,
      p.znrfa        as Znrfa,
      p.mwskz        as Mwskz,
      p.fkdat        as Fkdat,
      p.created_by   as CreatedBy,
      p.created_at   as CreatedAt,

      _Recovery
}
