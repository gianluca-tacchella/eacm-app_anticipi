@EndUserText.label: 'MFXN attribution parametes'
define abstract entity /EACM/A_MFXN_ASSIGN
{
  @EndUserText.label: 'Riga riepilogo'
  SummaryUuid          : sysuuid_x16;

  @EndUserText.label: 'Conferma differenza org./IVA'
  ForceDifferentOrgTax : abap_boolean;
}
