@EndUserText.label: 'MFXN parametro azione ZPRDP'
define abstract entity /EACM/A_MFXN_ZPRDP
{
  @EndUserText.label: 'Importo recupero'
  @Semantics.amount.currencyCode: 'RecoveryCurrency'
  RecoveryAmount   : abap.curr(15,2);

  @EndUserText.label: 'Valuta recupero'
  RecoveryCurrency : waerk;

  @EndUserText.label: 'Classe recupero'
  RecoveryClass    : /eacm/zclpr;

  @EndUserText.label: 'Competenza documento recupero'
  RecoveryPeriod   : /eacm/zamco;

  @EndUserText.label: 'Codice IVA'
  TaxCode          : mwskz;
}
