//@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'MFXN range distribution channel'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity /EACM/I_MFXN_VTWEG
  as select from /eacm/mfxn_rngvt as r
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
