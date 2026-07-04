CLASS lcl_zprdp_action DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS process
      IMPORTING is_key       TYPE /EACM/I_MFXN_ZPRDP
                is_parameter TYPE /EACM/A_MFXN_ZPRDP
                iv_mode      TYPE /eacm/mfxn_char1
      EXPORTING ev_ok        TYPE abap_boolean
                ev_text      TYPE string.
ENDCLASS.

CLASS lcl_zprdp_action IMPLEMENTATION.
  METHOD process.
    ev_ok = abap_false.
    CLEAR ev_text.

    SELECT SINGLE *
      FROM /eacm/zprdp
      WHERE vkorg = @is_key-Vkorg
        AND vtweg = @is_key-Vtweg
        AND zclpr = @is_key-Zclpr
        AND vbeln = @is_key-Vbeln
        AND posnr = @is_key-Posnr
        AND zcdaz = @is_key-Zcdaz
        AND zidag = @is_key-Zidag
        AND zidrg = @is_key-Zidrg
      INTO @DATA(ls_zprdp).

    IF sy-subrc <> 0.
      ev_text = 'Riga /EACM/ZPRDP non trovata.'.
      RETURN.
    ENDIF.

    DATA(lv_amount) = is_parameter-RecoveryAmount.
    DATA(lv_open_amount) = CONV /eacm/zprdp-zirec( ls_zprdp-ziman - ls_zprdp-zirec ).

    IF iv_mode = 'R' AND lv_amount IS INITIAL.
      lv_amount = lv_open_amount.
    ENDIF.

    IF lv_amount IS INITIAL OR lv_amount <= 0.
      ev_text = 'Inserire un importo recupero maggiore di zero.'.
      RETURN.
    ENDIF.

    IF lv_amount > lv_open_amount.
      ev_text = |Importo massimo recuperabile: { lv_open_amount } { ls_zprdp-waerk }.|.
      RETURN.
    ENDIF.

    DATA(lv_recovery_class) = COND /eacm/zclpr(
      WHEN is_parameter-RecoveryClass IS NOT INITIAL THEN is_parameter-RecoveryClass
      ELSE ls_zprdp-zclpr ).

    DATA(lv_recovery_period) = COND /eacm/zamco(
      WHEN is_parameter-RecoveryPeriod IS NOT INITIAL THEN is_parameter-RecoveryPeriod
      ELSE ls_zprdp-zamco ).

    DATA(lv_currency) = COND waerk(
      WHEN is_parameter-RecoveryCurrency IS NOT INITIAL THEN is_parameter-RecoveryCurrency
      ELSE ls_zprdp-waerk ).

    IF lv_currency <> ls_zprdp-waerk.
      ev_text = |Valuta azione { lv_currency } diversa da valuta documento { ls_zprdp-waerk }.|.
      RETURN.
    ENDIF.

    DATA(lv_new_zirec) = CONV /eacm/zprdp-zirec( ls_zprdp-zirec + lv_amount ).

    UPDATE /eacm/zprdp
      SET zirec = @lv_new_zirec,
          zcamd = @sy-uname,
          zdtmd = @sy-datum,
          zormd = @sy-uzeit,
          tcode = 'RAP'
      WHERE vkorg = @ls_zprdp-vkorg
        AND vtweg = @ls_zprdp-vtweg
        AND zclpr = @ls_zprdp-zclpr
        AND vbeln = @ls_zprdp-vbeln
        AND posnr = @ls_zprdp-posnr
        AND zcdaz = @ls_zprdp-zcdaz
        AND zidag = @ls_zprdp-zidag
        AND zidrg = @ls_zprdp-zidrg.

    IF sy-subrc <> 0.
      ev_text = 'Aggiornamento /EACM/ZPRDP non riuscito.'.
      RETURN.
    ENDIF.

    SELECT MAX( zprec )
      FROM /eacm/zprar
      WHERE vkorg = @ls_zprdp-vkorg
        AND vtweg = @ls_zprdp-vtweg
        AND zclpr = @lv_recovery_class
        AND zcdaz = @ls_zprdp-zcdaz
        AND zwaer = @ls_zprdp-waerk
        AND zamco = @lv_recovery_period
      INTO @DATA(lv_zprec).

    lv_zprec = lv_zprec + 1.

    MODIFY /eacm/zprar FROM @( VALUE /eacm/zprar(
      client = sy-mandt
      vkorg = ls_zprdp-vkorg
      vtweg = ls_zprdp-vtweg
      zclpr = lv_recovery_class
      zcdaz = ls_zprdp-zcdaz
      zwaer = ls_zprdp-waerk
      zamco = lv_recovery_period
      zprec = lv_zprec
      zirec = lv_amount
      bukrs = ls_zprdp-bukrs
      gjahr = lv_recovery_period(4)
      ziman = 0
      belnr = ls_zprdp-belnr
      ztpan = space
      zamca = ls_zprdp-zamco
      zesfa = ls_zprdp-gjahr
      znrfa = ls_zprdp-vbeln
      mwskz = is_parameter-TaxCode
      fkdat = ls_zprdp-fkdat ) ).

    IF sy-subrc <> 0.
      ev_text = 'Scrittura /EACM/ZPRAR non riuscita.'.
      RETURN.
    ENDIF.

    ev_ok = abap_true.
    ev_text = |Recupero salvato: { lv_amount } { ls_zprdp-waerk } su documento { ls_zprdp-vbeln }.|.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_RecoveryLine DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR RecoveryLine RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK RecoveryLine.

    METHODS Recover FOR MODIFY
      IMPORTING keys FOR ACTION RecoveryLine~Recover RESULT result.

    METHODS Attribute FOR MODIFY
      IMPORTING keys FOR ACTION RecoveryLine~Attribute RESULT result.

    METHODS SaveToSap FOR MODIFY
      IMPORTING keys FOR ACTION RecoveryLine~SaveToSap RESULT result.
ENDCLASS.

CLASS lhc_RecoveryLine IMPLEMENTATION.
  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys
      ( %tky = key-%tky
        %action-Recover = if_abap_behv=>auth-allowed
        %action-Attribute = if_abap_behv=>auth-allowed
        %action-SaveToSap = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD lock.
*    LOOP AT keys INTO DATA(key).
*      CALL FUNCTION 'ENQUEUE_/EACM/EZPRDP'
*        EXPORTING
*          mandt          = sy-mandt
*          vkorg          = key-Vkorg
*          vtweg          = key-Vtweg
*          zclpr          = key-Zclpr
*          vbeln          = key-Vbeln
*          posnr          = key-Posnr
*          zcdaz          = key-Zcdaz
*          zidag          = key-Zidag
*          zidrg          = key-Zidrg
*          _scope         = '2'
*          _wait          = ' '
*        EXCEPTIONS
*          foreign_lock   = 1
*          system_failure = 2
*          OTHERS         = 3.
*
*      IF sy-subrc <> 0.
*        APPEND VALUE #( %tky = key-%tky ) TO failed-recoveryline.
*        APPEND VALUE #( %tky = key-%tky
*                        %msg = new_message_with_text(
*                          severity = if_abap_behv_message=>severity-error
*                          text     = 'Record /EACM/ZPRDP bloccato da altro utente.' ) ) TO reported-recoveryline.
*      ENDIF.
*    ENDLOOP.
  ENDMETHOD.

  METHOD Recover.
    LOOP AT keys INTO DATA(key).
      lcl_zprdp_action=>process(
        EXPORTING
          is_key       = CORRESPONDING #( key )
          is_parameter = key-%param
          iv_mode      = 'R'
        IMPORTING
          ev_ok        = DATA(lv_ok)
          ev_text      = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-recoveryline.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-recoveryline.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-recoveryline.
      ENDIF.
    ENDLOOP.

    LOOP AT keys INTO key.
      SELECT SINGLE *
        FROM /EACM/I_MFXN_ZPRDP
        WHERE Vkorg = @key-Vkorg
          AND Vtweg = @key-Vtweg
          AND Zclpr = @key-Zclpr
          AND Vbeln = @key-Vbeln
          AND Posnr = @key-Posnr
          AND Zcdaz = @key-Zcdaz
          AND Zidag = @key-Zidag
          AND Zidrg = @key-Zidrg
        INTO @DATA(line).
      IF sy-subrc = 0.
*        APPEND VALUE #( %tky = key-%tky %param = line ) TO result.
APPEND VALUE #( %tky = key-%tky %param = CORRESPONDING #( line ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD Attribute.
    LOOP AT keys INTO DATA(key).
      lcl_zprdp_action=>process(
        EXPORTING
          is_key       = CORRESPONDING #( key )
          is_parameter = key-%param
          iv_mode      = 'A'
        IMPORTING
          ev_ok        = DATA(lv_ok)
          ev_text      = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-recoveryline.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-recoveryline.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-recoveryline.
      ENDIF.
    ENDLOOP.

    LOOP AT keys INTO key.
      SELECT SINGLE *
        FROM /EACM/I_MFXN_ZPRDP
        WHERE Vkorg = @key-Vkorg
          AND Vtweg = @key-Vtweg
          AND Zclpr = @key-Zclpr
          AND Vbeln = @key-Vbeln
          AND Posnr = @key-Posnr
          AND Zcdaz = @key-Zcdaz
          AND Zidag = @key-Zidag
          AND Zidrg = @key-Zidrg
        INTO @DATA(line).
      IF sy-subrc = 0.
*        APPEND VALUE #( %tky = key-%tky %param = line ) TO result.
        APPEND VALUE #( %tky = key-%tky %param = CORRESPONDING #( line ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD SaveToSap.
    LOOP AT keys INTO DATA(key).
      lcl_zprdp_action=>process(
        EXPORTING
          is_key       = CORRESPONDING #( key )
          is_parameter = key-%param
          iv_mode      = 'S'
        IMPORTING
          ev_ok        = DATA(lv_ok)
          ev_text      = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-recoveryline.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-recoveryline.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-recoveryline.
      ENDIF.
    ENDLOOP.

    LOOP AT keys INTO key.
      SELECT SINGLE *
        FROM /EACM/I_MFXN_ZPRDP
        WHERE Vkorg = @key-Vkorg
          AND Vtweg = @key-Vtweg
          AND Zclpr = @key-Zclpr
          AND Vbeln = @key-Vbeln
          AND Posnr = @key-Posnr
          AND Zcdaz = @key-Zcdaz
          AND Zidag = @key-Zidag
          AND Zidrg = @key-Zidrg
        INTO @DATA(line).
      IF sy-subrc = 0.
*        APPEND VALUE #( %tky = key-%tky %param = line ) TO result.
APPEND VALUE #( %tky = key-%tky %param = CORRESPONDING #( line ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
