//@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'MFXN recoverable advances'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/I_MFXN_ADV
  as select from /eacm/mfxn_adv as a
  association to parent /EACM/I_MFXN_HDR as _Recovery
    on $projection.Uuid = _Recovery.Uuid
{
  key a.uuid          as Uuid,
  key a.line_uuid     as LineUuid,
      a.vkorg         as Vkorg,
      a.vtweg         as Vtweg,
      a.zclpr         as Zclpr,
      a.vbeln         as Vbeln,
      a.posnr         as Posnr,
      a.zcdaz         as Zcdaz,
      a.zidag         as Zidag,
      a.zidrg         as Zidrg,
      a.bukrs         as Bukrs,
      a.gjahr         as Gjahr,
      a.belnr         as Belnr,
      a.kunrg         as Kunrg,
      a.fkdat         as Fkdat,
      a.zamco         as Zamco,
      a.zamcos        as Zamcos,
      a.source_waerk  as SourceWaerk,
      a.display_waerk as DisplayWaerk,
      a.mwskz         as Mwskz,

      @Semantics.amount.currencyCode: 'SourceWaerk'
      a.source_ziman  as SourceZiman,
      @Semantics.amount.currencyCode: 'SourceWaerk'
      a.source_zirec  as SourceZirec,
      @Semantics.amount.currencyCode: 'DisplayWaerk'
      a.ziman         as Ziman,
      @Semantics.amount.currencyCode: 'DisplayWaerk'
      a.zirec         as Zirec,
      @Semantics.amount.currencyCode: 'DisplayWaerk'
      a.rec           as Rec,
      @Semantics.amount.currencyCode: 'DisplayWaerk'
      a.max_rec       as MaxRec,
      @Semantics.amount.currencyCode: 'DisplayWaerk'
      a.zimanlc       as ZimanLc,
      @Semantics.amount.currencyCode: 'DisplayWaerk'
      a.zireclc       as ZirecLc,
      a.changed_by    as ChangedBy,
      a.changed_at    as ChangedAt,

      _Recovery
}
