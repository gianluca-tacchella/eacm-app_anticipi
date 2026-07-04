@EndUserText.label: 'MFXN extract parameters'
define abstract entity /EACM/A_MFXN_START
{
  @EndUserText.label: 'Societa'
  Bukrs     : bukrs;

  @EndUserText.label: 'AAAAMM Competenza'
  Zamcf     : /eacm/zamco;

  @EndUserText.label: 'Codice agente'
  Zcdaz     : /eacm/zcdaz;

  @EndUserText.label: 'Org. commerciale da'
  VkorgLow  : vkorg;

  @EndUserText.label: 'Org. commerciale a'
  VkorgHigh : vkorg;

  @EndUserText.label: 'Canale distribuzione da'
  VtwegLow  : vtweg;

  @EndUserText.label: 'Canale distribuzione a'
  VtwegHigh : vtweg;
}

