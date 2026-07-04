//@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'MFXN range sales organization'
@Metadata.allowExtensions: true
define view entity /EACM/I_MFXN_VKORG
  as select from /eacm/mfxn_rngvk as r
  association to parent /EACM/I_MFXN_HDR as _Recovery
    on $projection.Uuid = _Recovery.Uuid
{
  key r.uuid       as Uuid,
  key r.range_uuid as RangeUuid,
      r.sort_order as SortOrder,
      r.sel_sign   as SelSign,
      r.sel_option as SelOption,
      r.low        as Low,
      r.high       as High,

      _Recovery
}
