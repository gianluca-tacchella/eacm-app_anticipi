@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'MFXN recovery of advanced'
@Metadata.allowExtensions: true
define root view entity /EACM/I_MFXN_HDR
  as select from /eacm/mfxn_h as h
  composition [0..*] of /EACM/I_MFXN_VKORG as _VkorgRanges
  composition [0..*] of /EACM/I_MFXN_VTWEG as _VtwegRanges
  composition [0..*] of /EACM/I_MFXN_ADV   as _Advances
  composition [0..*] of /EACM/I_MFXN_SUM   as _Summaries
  composition [0..*] of /EACM/I_MFXN_POST  as _Postings
{
  key h.uuid                  as Uuid,
      h.bukrs                 as Bukrs,
      h.zamcf                 as Zamcf,
      h.zcdaz                 as Zcdaz,
      h.agent_name            as AgentName,
      h.loccur                as LocalCurrency,
      h.euro_mode             as EuroMode,
      h.status                as Status,
      h.message_text          as MessageText,
      h.created_by            as CreatedBy,
      h.created_at            as CreatedAt,
      h.changed_by            as ChangedBy,
      h.changed_at            as ChangedAt,
      h.local_last_changed_at as LocalLastChangedAt,

      _VkorgRanges,
      _VtwegRanges,
      _Advances,
      _Summaries,
      _Postings
}
