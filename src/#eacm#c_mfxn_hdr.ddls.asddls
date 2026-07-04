@EndUserText.label: 'MFXN recupero anticipi'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity /EACM/C_MFXN_HDR
  provider contract transactional_query
  as projection on /EACM/I_MFXN_HDR
{
  key Uuid,
      Bukrs,
      Zamcf,
      Zcdaz,
      AgentName,
      LocalCurrency,
      EuroMode,
      Status,
      MessageText,
      LocalLastChangedAt,

      _VkorgRanges : redirected to composition child /EACM/C_MFXN_VKORG,
      _VtwegRanges : redirected to composition child /EACM/C_MFXN_VTWEG,
      _Advances    : redirected to composition child /EACM/C_MFXN_ADV,
      _Summaries   : redirected to composition child /EACM/C_MFXN_SUM,
            _Postings    : redirected to composition child /EACM/C_MFXN_POST
}
