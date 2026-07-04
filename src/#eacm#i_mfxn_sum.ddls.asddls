//@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'MFXN summary of advances'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/I_MFXN_SUM
  as select from /eacm/mfxn_sum as s
  association to parent /EACM/I_MFXN_HDR as _Recovery
    on $projection.Uuid = _Recovery.Uuid
{
  key s.uuid          as Uuid,
  key s.line_uuid     as LineUuid,
      s.vkorg         as Vkorg,
      s.vtweg         as Vtweg,
      s.zclpr         as Zclpr,
      s.waerk         as Waerk,
      s.mwskz         as Mwskz,
      @Semantics.amount.currencyCode: 'Waerk'
      s.ziprv         as Ziprv,
      @Semantics.amount.currencyCode: 'Waerk'
      s.zirec         as Zirec,
      @Semantics.amount.currencyCode: 'Waerk'
      s.available_rec as AvailableRec,
      @Semantics.amount.currencyCode: 'Waerk'
      s.ziprvlc       as ZiprvLc,
      @Semantics.amount.currencyCode: 'Waerk'
      s.zireclc       as ZirecLc,

      _Recovery
}
