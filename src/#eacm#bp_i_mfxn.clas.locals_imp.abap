CLASS lcl_mfxn_logic DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS extract
      IMPORTING iv_uuid TYPE sysuuid_x16
      EXPORTING ev_ok   TYPE abap_boolean
                ev_text TYPE string.

    CLASS-METHODS start_extraction
      IMPORTING is_parameter TYPE /EACM/A_MFXN_START
      EXPORTING ev_uuid      TYPE sysuuid_x16
                ev_ok        TYPE abap_boolean
                ev_text      TYPE string.

    CLASS-METHODS apply_amount
      IMPORTING iv_uuid      TYPE sysuuid_x16
                iv_line_uuid TYPE sysuuid_x16
                iv_reverse   TYPE abap_boolean
                is_parameter TYPE /EACM/A_MFXN_ASSIGN
      EXPORTING ev_ok        TYPE abap_boolean
                ev_text      TYPE string.

    CLASS-METHODS save_to_sap
      IMPORTING iv_uuid TYPE sysuuid_x16
      EXPORTING ev_ok   TYPE abap_boolean
                ev_text TYPE string.

  PRIVATE SECTION.
    TYPES tt_vkorg_range TYPE RANGE OF vkorg.
    TYPES tt_vtweg_range TYPE RANGE OF vtweg.
    TYPES tt_zclpr_range TYPE RANGE OF /eacm/zclpr.

    CLASS-METHODS build_vkorg_range
      IMPORTING is_header       TYPE /eacm/mfxn_h
      RETURNING VALUE(rt_range) TYPE tt_vkorg_range.

    CLASS-METHODS build_vtweg_range
      IMPORTING iv_uuid         TYPE sysuuid_x16
      RETURNING VALUE(rt_range) TYPE tt_vtweg_range.

    CLASS-METHODS build_doc_type_range
      IMPORTING iv_advance      TYPE abap_boolean
      RETURNING VALUE(rt_range) TYPE tt_zclpr_range.

    CLASS-METHODS conversion_period
      IMPORTING iv_zamco       TYPE /eacm/zamco
      RETURNING VALUE(rv_text) TYPE /EACM/MFNX_CHAR6.

    CLASS-METHODS convert_to_local
      IMPORTING iv_date           TYPE sy-datum
                iv_local_currency TYPE waerk
      CHANGING  cv_amount         TYPE /eacm/mfxn_adv-ziman
                cv_currency       TYPE waerk.

    CLASS-METHODS convert_from_local
      IMPORTING iv_date           TYPE sy-datum
                iv_local_currency TYPE waerk
      CHANGING  cv_amount         TYPE /eacm/mfxn_adv-ziman
                cv_currency       TYPE waerk.

    CLASS-METHODS get_tax_code
      IMPORTING iv_vkorg       TYPE vkorg
                iv_vtweg       TYPE vtweg
                iv_zclpr       TYPE /eacm/zclpr
                iv_vbeln       TYPE vbeln
                iv_posnr       TYPE posnr
                iv_zidag       TYPE /eacm/zidag
                iv_zcdaz       TYPE /eacm/zcdaz
                iv_bukrs       TYPE bukrs
                iv_kunrg       TYPE kunrg
                iv_fkdat       TYPE fkdat
      RETURNING VALUE(rv_mwskz) TYPE mwskz.

    CLASS-METHODS country_group
      IMPORTING iv_land1        TYPE land1
                iv_date         TYPE sy-datum
      RETURNING VALUE(rv_group) TYPE /eacm/zzage.


TYPES ty_sum TYPE /eacm/mfxn_sum.
TYPES tt_sum TYPE STANDARD TABLE OF ty_sum WITH EMPTY KEY.

    CLASS-METHODS append_summary
      IMPORTING is_header TYPE /eacm/mfxn_h
                is_line   TYPE /eacm/mfxn_sum
      CHANGING  ct_sum     TYPE tt_sum. ""TYPE STANDARD TABLE OF /eacm/mfxn_sum .

    "!
    "! @parameter iv_uuid |
    "! @parameter iv_status |
    "! @parameter iv_text |
    CLASS-METHODS set_header_message
      IMPORTING iv_uuid   TYPE sysuuid_x16
                iv_status TYPE /EACM/MFXN_CHAR1
                iv_text   TYPE string.
ENDCLASS.

CLASS lcl_mfxn_logic IMPLEMENTATION.
  METHOD start_extraction.
    ev_ok = abap_false.
    CLEAR: ev_uuid, ev_text.

    IF is_parameter-Bukrs IS INITIAL OR is_parameter-Zamcf IS INITIAL OR is_parameter-Zcdaz IS INITIAL.
      ev_text = 'Inserire societa, competenza e agente.'.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Recovery
        CREATE FIELDS ( Bukrs Zamcf Zcdaz Status MessageText )
        WITH VALUE #( (
          %cid        = 'RECOVERY'
          Bukrs       = is_parameter-Bukrs
          Zamcf       = is_parameter-Zamcf
          Zcdaz       = is_parameter-Zcdaz
          Status      = 'N'
          MessageText = 'Sessione creata' ) )

      ENTITY Recovery
        CREATE BY \_VkorgRanges FIELDS ( SelSign SelOption Low High )
        WITH VALUE #( (
          %cid_ref = 'RECOVERY'
          %target  = COND #( WHEN is_parameter-VkorgLow IS INITIAL
                              THEN VALUE #( )
                              ELSE VALUE #( (
                                %cid      = 'VKORG'
                                SelSign   = 'I'
                                SelOption = COND #( WHEN is_parameter-VkorgHigh IS INITIAL THEN 'EQ' ELSE 'BT' )
                                Low       = is_parameter-VkorgLow
                                High      = is_parameter-VkorgHigh ) ) ) ) )

      ENTITY Recovery
        CREATE BY \_VtwegRanges FIELDS ( SelSign SelOption Low High )
        WITH VALUE #( (
          %cid_ref = 'RECOVERY'
          %target  = COND #( WHEN is_parameter-VtwegLow IS INITIAL
                              THEN VALUE #( )
                              ELSE VALUE #( (
                                %cid      = 'VTWEG'
                                SelSign   = 'I'
                                SelOption = COND #( WHEN is_parameter-VtwegHigh IS INITIAL THEN 'EQ' ELSE 'BT' )
                                Low       = is_parameter-VtwegLow
                                High      = is_parameter-VtwegHigh ) ) ) ) )
      FAILED DATA(failed)
      REPORTED DATA(reported).

    IF failed-recovery IS NOT INITIAL.
      ev_text = 'Creazione sessione estrazione non riuscita.'.
      RETURN.
    ENDIF.

    ev_ok = abap_true.
    ev_text = 'Sessione creata. Aggiornare la lista, aprire la riga e lanciare Estrai.'.
  ENDMETHOD.

  METHOD extract.
    ev_ok = abap_false.
    CLEAR ev_text.

    SELECT SINGLE *
      FROM /eacm/mfxn_h
      WHERE uuid = @iv_uuid
      INTO @DATA(ls_header).

    IF sy-subrc <> 0.
      ev_text = 'Sessione RAP MFXN non trovata.'.
      RETURN.
    ENDIF.

    IF ls_header-bukrs IS INITIAL OR ls_header-zamcf IS INITIAL OR ls_header-zcdaz IS INITIAL.
      ev_text = 'Inserire societa, competenza finale e agente.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    SELECT SINGLE zeuro
      FROM /eacm/zpr01
      WHERE bukrs = @ls_header-bukrs
      INTO @ls_header-euro_mode.

    SELECT SINGLE waers
      FROM /eacm/t001
      WHERE bukrs = @ls_header-bukrs
      INTO @ls_header-loccur.

    IF sy-subrc <> 0.
      ev_text = |Societa { ls_header-bukrs } non trovata in T001.|.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    SELECT name1
      FROM /eacm/zpraa
      WHERE zcdaz = @ls_header-zcdaz
        AND zstre <> 'A'
        AND zstre <> 'S'
      ORDER BY erdat DESCENDING
      INTO @ls_header-agent_name
      UP TO 1 ROWS.
    ENDSELECT.

    IF ls_header-agent_name IS INITIAL.
      ev_text = |Agente { ls_header-zcdaz } non valido o non attivo.|.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Recovery
        UPDATE FIELDS ( AgentName LocalCurrency EuroMode )
        WITH VALUE #( (
          Uuid          = iv_uuid
          AgentName     = ls_header-agent_name
          LocalCurrency = ls_header-loccur
          EuroMode      = ls_header-euro_mode ) )
      FAILED DATA(header_failed)
      REPORTED DATA(header_reported).

    IF header_failed IS NOT INITIAL.
      ev_text = 'Aggiornamento testata estrazione non riuscito.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    DATA(lr_vkorg) = build_vkorg_range( ls_header ).
    DATA(lr_vtweg) = build_vtweg_range( iv_uuid ).
    DATA(lr_anti)  = build_doc_type_range( abap_true ).
    DATA(lr_recu)  = build_doc_type_range( abap_false ).

    IF lr_vkorg IS INITIAL.
      ev_text = 'Nessuna organizzazione vendita disponibile o autorizzata.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    IF lr_vtweg IS INITIAL.
      SELECT vtweg
        FROM /eacm/tvtw
        INTO TABLE @DATA(lt_all_vtweg).

      lr_vtweg = VALUE #( FOR ls_vtweg IN lt_all_vtweg
        ( sign = 'I' option = 'EQ' low = ls_vtweg-vtweg ) ).
    ENDIF.

    SELECT uuid, line_uuid
      FROM /eacm/mfxn_adv
      WHERE uuid = @iv_uuid
      INTO TABLE @DATA(lt_old_adv_keys).

    SELECT uuid, line_uuid
      FROM /eacm/mfxn_sum
      WHERE uuid = @iv_uuid
      INTO TABLE @DATA(lt_old_sum_keys).

    SELECT uuid, post_uuid
      FROM /eacm/mfxn_post
      WHERE uuid = @iv_uuid
      INTO TABLE @DATA(lt_old_post_keys).

    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Advance
        DELETE FROM VALUE #( FOR ls_old_adv IN lt_old_adv_keys
          ( Uuid = ls_old_adv-uuid LineUuid = ls_old_adv-line_uuid ) )
      ENTITY Summary
        DELETE FROM VALUE #( FOR ls_old_sum IN lt_old_sum_keys
          ( Uuid = ls_old_sum-uuid LineUuid = ls_old_sum-line_uuid ) )
      ENTITY Posting
        DELETE FROM VALUE #( FOR ls_old_post IN lt_old_post_keys
          ( Uuid = ls_old_post-uuid PostUuid = ls_old_post-post_uuid ) )
      FAILED DATA(delete_failed)
      REPORTED DATA(delete_reported).

    IF delete_failed IS NOT INITIAL.
      ev_text = 'Pulizia staging precedente non riuscita.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    SELECT *
      FROM /eacm/zprdp
      WHERE ( zclpr IN @lr_anti
              AND zamco <= @ls_header-zamcf
              AND vkorg IN @lr_vkorg
              AND vtweg IN @lr_vtweg
              AND zcdaz = @ls_header-zcdaz
              AND ztpcd = @space
              AND zstre <> 'D' )
         OR ( zclpr IN @lr_recu
              AND vkorg IN @lr_vkorg
              AND vtweg IN @lr_vtweg
              AND zcdaz = @ls_header-zcdaz
              AND zamco <= @ls_header-zamcf
              AND zdtsf = '00000000'
              AND ztpcd = @space
              AND zstre <> 'D' )
      ORDER BY zamco, waerk
      INTO TABLE @DATA(lt_zprdp).

    IF lt_zprdp IS INITIAL.
      ev_text = 'Nessun record recuperabile trovato in /EACM/ZPRDP.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    SELECT *
      FROM /eacm/zprar
      WHERE zamco <= @ls_header-zamcf
        AND vkorg IN @lr_vkorg
        AND vtweg IN @lr_vtweg
        AND zclpr IN @lr_recu
        AND zcdaz = @ls_header-zcdaz
      INTO TABLE @DATA(lt_zprar).

    DATA lt_adv TYPE STANDARD TABLE OF /eacm/mfxn_adv.
TYPES ty_sum TYPE /eacm/mfxn_sum.
TYPES tt_sum TYPE STANDARD TABLE OF ty_sum WITH EMPTY KEY.
DATA lt_sum TYPE tt_sum.
*    DATA lt_sum TYPE STANDARD TABLE OF /eacm/mfxn_sum.

    LOOP AT lt_zprdp ASSIGNING FIELD-SYMBOL(<ls_zprdp>) WHERE zclpr IN lr_anti.
      DATA(lv_ziman) = CONV /eacm/mfxn_adv-ziman( <ls_zprdp>-ziman ).
      DATA(lv_zirec) = CONV /eacm/mfxn_adv-zirec( <ls_zprdp>-zirec ).

      IF lv_ziman <= lv_zirec.
        CONTINUE.
      ENDIF.

      DATA(lv_zimanlc) = lv_ziman.
      DATA(lv_zireclc) = lv_zirec.
      DATA(lv_display_currency) = CONV waerk( <ls_zprdp>-waerk ).
      DATA(lv_lc_currency) = ls_header-loccur.

      IF ls_header-euro_mode = abap_true.
        convert_to_local(
          EXPORTING iv_date = <ls_zprdp>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_ziman cv_currency = lv_display_currency ).
        lv_zimanlc = lv_ziman.

        lv_display_currency = CONV waerk( <ls_zprdp>-waerk ).
        convert_to_local(
          EXPORTING iv_date = <ls_zprdp>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_zirec cv_currency = lv_display_currency ).
        lv_zireclc = lv_zirec.
      ELSE.
        convert_to_local(
          EXPORTING iv_date = <ls_zprdp>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_zimanlc cv_currency = lv_lc_currency ).

        lv_lc_currency = ls_header-loccur.
        convert_to_local(
          EXPORTING iv_date = <ls_zprdp>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_zireclc cv_currency = lv_lc_currency ).
      ENDIF.

      DATA(lv_mwskz) = get_tax_code(
        iv_vkorg = <ls_zprdp>-vkorg
        iv_vtweg = <ls_zprdp>-vtweg
        iv_zclpr = <ls_zprdp>-zclpr
        iv_vbeln = <ls_zprdp>-vbeln
        iv_posnr = <ls_zprdp>-posnr
        iv_zidag = <ls_zprdp>-zidag
        iv_zcdaz = <ls_zprdp>-zcdaz
        iv_bukrs = <ls_zprdp>-bukrs
        iv_kunrg = <ls_zprdp>-kunrg
        iv_fkdat = <ls_zprdp>-fkdat ).

      APPEND VALUE /eacm/mfxn_adv(
        client        = sy-mandt
        uuid          = iv_uuid
        line_uuid     = cl_system_uuid=>create_uuid_x16_static( )
        vkorg         = <ls_zprdp>-vkorg
        vtweg         = <ls_zprdp>-vtweg
        zclpr         = <ls_zprdp>-zclpr
        vbeln         = <ls_zprdp>-vbeln
        posnr         = <ls_zprdp>-posnr
        zcdaz         = <ls_zprdp>-zcdaz
        zidag         = <ls_zprdp>-zidag
        zidrg         = <ls_zprdp>-zidrg
        bukrs         = <ls_zprdp>-bukrs
        gjahr         = <ls_zprdp>-gjahr
        belnr         = <ls_zprdp>-belnr
        kunrg         = <ls_zprdp>-kunrg
        fkdat         = <ls_zprdp>-fkdat
        zamco         = <ls_zprdp>-zamco
        zamcos        = conversion_period( <ls_zprdp>-zamco )
        source_waerk  = <ls_zprdp>-waerk
        display_waerk = lv_display_currency
        mwskz         = lv_mwskz
        source_ziman  = <ls_zprdp>-ziman
        source_zirec  = <ls_zprdp>-zirec
        ziman         = lv_ziman
        zirec         = lv_zirec
        max_rec       = lv_ziman - lv_zirec
        zimanlc       = lv_zimanlc
        zireclc       = lv_zireclc ) TO lt_adv.
    ENDLOOP.

    LOOP AT lt_zprdp ASSIGNING <ls_zprdp> WHERE zclpr IN lr_recu
                                            AND zamco <= ls_header-zamcf.
      DATA(lv_vbtyp) = VALUE /eacm/prdo-vbtyp( ).


      SELECT SINGLE vbtyp
        FROM /eacm/prdo
        WHERE vkorg = @<ls_zprdp>-vkorg
          AND vtweg = @<ls_zprdp>-vtweg
          AND zclpr = @<ls_zprdp>-zclpr
          AND vbeln = @<ls_zprdp>-vbeln
          AND posnr = @<ls_zprdp>-posnr
          AND zcdaz = @<ls_zprdp>-zcdaz
          AND zidag = @<ls_zprdp>-zidag
        INTO @lv_vbtyp.

*      DATA(lv_sign) = CONV i( 1 ).

      DATA lv_zsegn TYPE /eacm/zpr48-zsegn.

      SELECT SINGLE zsegn
        FROM /eacm/zpr48
        WHERE vbtyp = @lv_vbtyp
        INTO @lv_zsegn.

      IF sy-subrc <> 0.
        lv_zsegn = 1.
      ENDIF.

DATA(lv_sign) = CONV i( lv_zsegn ).

      DATA(lv_ziprv) = CONV /eacm/mfxn_sum-ziprv( <ls_zprdp>-ziprv * lv_sign ).
      DATA(lv_ziprvlc) = lv_ziprv.
      DATA(lv_sum_currency) = CONV waerk( <ls_zprdp>-waerk ).

      IF ls_header-euro_mode = abap_true.
        convert_to_local(
          EXPORTING iv_date = <ls_zprdp>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_ziprv cv_currency = lv_sum_currency ).
        lv_ziprvlc = lv_ziprv.
      ELSE.
        DATA(lv_sum_lc_currency) = ls_header-loccur.
        convert_to_local(
          EXPORTING iv_date = <ls_zprdp>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_ziprvlc cv_currency = lv_sum_lc_currency ).
      ENDIF.

      lv_mwskz = get_tax_code(
        iv_vkorg = <ls_zprdp>-vkorg
        iv_vtweg = <ls_zprdp>-vtweg
        iv_zclpr = <ls_zprdp>-zclpr
        iv_vbeln = <ls_zprdp>-vbeln
        iv_posnr = <ls_zprdp>-posnr
        iv_zidag = <ls_zprdp>-zidag
        iv_zcdaz = <ls_zprdp>-zcdaz
        iv_bukrs = <ls_zprdp>-bukrs
        iv_kunrg = <ls_zprdp>-kunrg
        iv_fkdat = <ls_zprdp>-fkdat ).

      append_summary(
        EXPORTING
          is_header = ls_header
          is_line   = VALUE /eacm/mfxn_sum(
            client        = sy-mandt
            uuid          = iv_uuid
            vkorg         = <ls_zprdp>-vkorg
            vtweg         = <ls_zprdp>-vtweg
            zclpr       = <ls_zprdp>-zclpr
            waerk         = lv_sum_currency
            mwskz         = lv_mwskz
            ziprv         = lv_ziprv
            zirec         = 0
            available_rec = lv_ziprv
            ziprvlc       = lv_ziprvlc
            zireclc       = 0 )
        CHANGING
          ct_sum = lt_sum ).
    ENDLOOP.

    LOOP AT lt_zprar ASSIGNING FIELD-SYMBOL(<ls_zprar>) WHERE ztpan = space.
      DATA(lv_ar_zirec) = CONV /eacm/mfxn_sum-zirec( <ls_zprar>-zirec ).
      DATA(lv_ar_zireclc) = lv_ar_zirec.
      DATA(lv_ar_currency) = CONV waerk( <ls_zprar>-zwaer ).

      IF ls_header-euro_mode = abap_true.
        convert_to_local(
          EXPORTING iv_date = <ls_zprar>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_ar_zirec cv_currency = lv_ar_currency ).
        lv_ar_zireclc = lv_ar_zirec.
      ELSE.
        DATA(lv_ar_lc_currency) = ls_header-loccur.
        convert_to_local(
          EXPORTING iv_date = <ls_zprar>-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_ar_zireclc cv_currency = lv_ar_lc_currency ).
      ENDIF.

      append_summary(
        EXPORTING
          is_header = ls_header
          is_line   = VALUE /eacm/mfxn_sum(
            client        = sy-mandt
            uuid          = iv_uuid
            vkorg         = <ls_zprar>-vkorg
            vtweg         = <ls_zprar>-vtweg
            zclpr       = <ls_zprar>-zclpr
            waerk         = lv_ar_currency
            mwskz         = <ls_zprar>-mwskz
            ziprv         = 0
            zirec         = lv_ar_zirec
            available_rec = 0 - lv_ar_zirec
            ziprvlc       = 0
            zireclc       = lv_ar_zireclc )
        CHANGING
*          ct_sum = lt_sum ).
  ct_sum = lt_sum ).
    ENDLOOP.

    LOOP AT lt_sum ASSIGNING FIELD-SYMBOL(<ls_sum>).
      <ls_sum>-available_rec = <ls_sum>-ziprv - <ls_sum>-zirec.
    ENDLOOP.

    DELETE lt_sum WHERE ziprv = 0 AND zirec = 0.

    IF lt_adv IS INITIAL AND lt_sum IS INITIAL.
      ev_text = 'Nessun anticipo o recupero trovato per i criteri indicati.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    IF lt_adv IS NOT INITIAL.
      MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
        ENTITY Recovery
          CREATE BY \_Advances FIELDS (
            Vkorg Vtweg Zclpr Vbeln Posnr Zcdaz Zidag Zidrg LineUuid Bukrs Gjahr Belnr Kunrg
            Fkdat Zamco Zamcos SourceWaerk DisplayWaerk Mwskz SourceZiman SourceZirec
            Ziman Zirec Rec MaxRec ZimanLc ZirecLc )
          WITH VALUE #( (
            Uuid = iv_uuid
            %target = VALUE #(
              FOR ls_adv IN lt_adv INDEX INTO lv_adv_idx
              ( %cid         = |ADV{ lv_adv_idx }|
                Vkorg        = ls_adv-vkorg
                Vtweg        = ls_adv-vtweg
                Zclpr        = ls_adv-zclpr
                Vbeln        = ls_adv-vbeln
                Posnr        = ls_adv-posnr
                Zcdaz        = ls_adv-zcdaz
                Zidag        = ls_adv-zidag
                Zidrg        = ls_adv-zidrg
*                LineUuid     = cl_system_uuid=>create_uuid_x16_static( )
LineUuid = ls_adv-line_uuid
                Bukrs        = ls_adv-bukrs
                Gjahr        = ls_adv-gjahr
                Belnr        = ls_adv-belnr
                Kunrg        = ls_adv-kunrg
                Fkdat        = ls_adv-fkdat
                Zamco        = ls_adv-zamco
                Zamcos       = ls_adv-zamcos
                SourceWaerk  = ls_adv-source_waerk
                DisplayWaerk = ls_adv-display_waerk
                Mwskz        = ls_adv-mwskz
                SourceZiman  = ls_adv-source_ziman
                SourceZirec  = ls_adv-source_zirec
                Ziman        = ls_adv-ziman
                Zirec        = ls_adv-zirec
                Rec          = ls_adv-rec
                MaxRec       = ls_adv-max_rec
                ZimanLc      = ls_adv-zimanlc
                ZirecLc      = ls_adv-zireclc ) ) ) )
        FAILED DATA(adv_failed)
        REPORTED DATA(adv_reported).

      IF adv_failed IS NOT INITIAL.
        ev_text = 'Creazione anticipi recuperabili non riuscita.'.
        set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
        RETURN.
      ENDIF.
    ENDIF.

    IF lt_sum IS NOT INITIAL.
      MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
        ENTITY Recovery
          CREATE BY \_Summaries FIELDS (
            Vkorg Vtweg Zclpr Waerk Mwskz LineUuid Ziprv Zirec AvailableRec ZiprvLc ZirecLc )
          WITH VALUE #( (
            Uuid = iv_uuid
            %target = VALUE #(
              FOR ls_sum IN lt_sum INDEX INTO lv_sum_idx
              ( %cid         = |SUM{ lv_sum_idx }|
                Vkorg        = ls_sum-vkorg
                Vtweg        = ls_sum-vtweg
                Zclpr        = ls_sum-zclpr
                Waerk        = ls_sum-waerk
                Mwskz        = ls_sum-mwskz
*                LineUuid     = cl_system_uuid=>create_uuid_x16_static( )
LineUuid = ls_sum-line_uuid
                Ziprv        = ls_sum-ziprv
                Zirec        = ls_sum-zirec
                AvailableRec = ls_sum-available_rec
                ZiprvLc      = ls_sum-ziprvlc
                ZirecLc      = ls_sum-zireclc ) ) ) )
        FAILED DATA(sum_failed)
        REPORTED DATA(sum_reported).

      IF sum_failed IS NOT INITIAL.
        ev_text = 'Creazione riepiloghi recupero non riuscita.'.
        set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
        RETURN.
      ENDIF.
    ENDIF.

    ev_ok = abap_true.
    ev_text = |Estrazione completata: { lines( lt_adv ) } anticipi, { lines( lt_sum ) } riepiloghi.|.
    set_header_message( iv_uuid = iv_uuid iv_status = 'C' iv_text = ev_text ).
  ENDMETHOD.

  METHOD apply_amount.
    ev_ok = abap_false.
    CLEAR ev_text.

    IF is_parameter-SummaryUuid IS INITIAL.
      ev_text = 'Selezionare la riga riepilogo su cui attribuire il recupero.'.
      RETURN.
    ENDIF.

    SELECT SINGLE *
      FROM /eacm/mfxn_h
      WHERE uuid = @iv_uuid
      INTO @DATA(ls_header).

    SELECT SINGLE *
      FROM /eacm/mfxn_adv
      WHERE uuid = @iv_uuid
        AND line_uuid = @iv_line_uuid
      INTO @DATA(ls_adv).

    IF sy-subrc <> 0.
      ev_text = 'Riga anticipo non trovata.'.
      RETURN.
    ENDIF.

    SELECT SINGLE *
      FROM /eacm/mfxn_sum
      WHERE uuid = @iv_uuid
        AND line_uuid = @is_parameter-SummaryUuid
      INTO @DATA(ls_sum).

    IF sy-subrc <> 0.
      ev_text = 'Riga riepilogo non trovata.'.
      RETURN.
    ENDIF.

    IF ls_adv-rec IS INITIAL OR ls_adv-rec <= 0.
      ev_text = 'Inserire un importo da recuperare maggiore di zero.'.
      RETURN.
    ENDIF.

    IF ls_adv-display_waerk <> ls_sum-waerk.
      ev_text = |Valuta diversa: anticipo { ls_adv-display_waerk }, riepilogo { ls_sum-waerk }.|.
      RETURN.
    ENDIF.

    IF ( ls_adv-vkorg <> ls_sum-vkorg OR ls_adv-vtweg <> ls_sum-vtweg OR ls_adv-mwskz <> ls_sum-mwskz )
       AND is_parameter-ForceDifferentOrgTax <> abap_true.
      ev_text = 'Organizzazione/canale/codice IVA differente. Rilanciare con conferma differenza.'.
      RETURN.
    ENDIF.

    DATA(lv_amount) = ls_adv-rec.
    DATA(lv_max) = CONV /eacm/mfxn_adv-rec( 0 ).

    IF iv_reverse = abap_true.
      lv_max = COND #( WHEN ls_sum-zirec <= ls_adv-zirec THEN ls_sum-zirec ELSE ls_adv-zirec ).
    ELSE.
      IF ls_sum-ziprv < 0.
        ev_text = 'Totale provvigioni negativo: attribuzione non consentita.'.
        RETURN.
      ENDIF.
      DATA(lv_theoretical) = ls_adv-ziman - ls_adv-zirec.
      DATA(lv_real) = ls_sum-ziprv - ls_sum-zirec.
      lv_max = COND #( WHEN lv_real <= lv_theoretical THEN lv_real ELSE lv_theoretical ).
    ENDIF.

    IF lv_amount > lv_max.
      ev_text = |Importo massimo consentito: { lv_max } { ls_adv-display_waerk }.|.
      RETURN.
    ENDIF.

    IF iv_reverse = abap_true.
      ls_adv-zirec = ls_adv-zirec - lv_amount.
      ls_sum-zirec = ls_sum-zirec - lv_amount.
      lv_amount = lv_amount * -1.
    ELSE.
      ls_adv-zirec = ls_adv-zirec + lv_amount.
      ls_sum-zirec = ls_sum-zirec + lv_amount.
    ENDIF.

    ls_adv-max_rec = ls_adv-ziman - ls_adv-zirec.
    CLEAR ls_adv-rec.
    ls_adv-changed_by = sy-uname.
    GET TIME STAMP FIELD ls_adv-changed_at.

    ls_sum-available_rec = ls_sum-ziprv - ls_sum-zirec.

    IF ls_header-euro_mode IS INITIAL.
      DATA(lv_local_currency) = ls_header-loccur.
      DATA(lv_lc_amount) = ls_adv-zirec.
      convert_to_local(
        EXPORTING iv_date = ls_adv-fkdat iv_local_currency = ls_header-loccur
        CHANGING  cv_amount = lv_lc_amount cv_currency = lv_local_currency ).
      ls_adv-zireclc = lv_lc_amount.

      lv_local_currency = ls_header-loccur.
      lv_lc_amount = ls_sum-zirec.
      convert_to_local(
        EXPORTING iv_date = ls_adv-fkdat iv_local_currency = ls_header-loccur
        CHANGING  cv_amount = lv_lc_amount cv_currency = lv_local_currency ).
      ls_sum-zireclc = lv_lc_amount.
    ELSE.
      ls_adv-zireclc = ls_adv-zirec.
      ls_sum-zireclc = ls_sum-zirec.
    ENDIF.

    DATA(lv_ts) = VALUE timestampl( ).
    GET TIME STAMP FIELD lv_ts.

    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Advance
        UPDATE FIELDS ( Zirec Rec MaxRec ZirecLc ChangedBy ChangedAt )
        WITH VALUE #( (
          Uuid      = iv_uuid
          LineUuid  = iv_line_uuid
          Zirec     = ls_adv-zirec
          Rec       = ls_adv-rec
          MaxRec    = ls_adv-max_rec
          ZirecLc   = ls_adv-zireclc
          ChangedBy = ls_adv-changed_by
          ChangedAt = ls_adv-changed_at ) )
      ENTITY Summary
        UPDATE FIELDS ( Zirec AvailableRec ZirecLc )
        WITH VALUE #( (
          Uuid         = iv_uuid
          LineUuid     = is_parameter-SummaryUuid
          Zirec        = ls_sum-zirec
          AvailableRec = ls_sum-available_rec
          ZirecLc      = ls_sum-zireclc ) )
      FAILED DATA(assign_failed)
      REPORTED DATA(assign_reported).

    IF assign_failed IS NOT INITIAL.
      ev_text = 'Aggiornamento attribuzione non riuscito.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

DATA(lv_post_uuid) = cl_system_uuid=>create_uuid_x16_static( ).

    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Recovery
        CREATE BY \_Postings FIELDS (
          PostUuid AdvanceUuid SummaryUuid PostType Vkorg Vtweg Zclpr Zcdaz Zwaer Zamco
          Zirec Bukrs Gjahr Ziman Belnr Ztpan Zamca Zesfa Znrfa Mwskz Fkdat CreatedBy CreatedAt )
        WITH VALUE #( (
          Uuid        = iv_uuid
          %target = VALUE #( (
            %cid        = 'POST'
*            PostUuid    = cl_system_uuid=>create_uuid_x16_static( )
        PostUuid = lv_post_uuid
            AdvanceUuid = iv_line_uuid
            SummaryUuid = is_parameter-SummaryUuid
            PostType    = COND #( WHEN iv_reverse = abap_true THEN 'D' ELSE 'A' )
            Vkorg       = ls_sum-vkorg
            Vtweg       = ls_sum-vtweg
            Zclpr       = ls_sum-zclpr
            Zcdaz       = ls_adv-zcdaz
            Zwaer       = ls_adv-display_waerk
            Zamco       = ls_header-zamcf
            Zirec       = lv_amount
            Bukrs       = ls_adv-bukrs
            Gjahr       = ls_header-zamcf(4)
            Ziman       = 0
            Belnr       = ls_adv-belnr
            Ztpan       = space
            Zamca       = ls_adv-zamco
            Zesfa       = ls_adv-gjahr
            Znrfa       = ls_adv-vbeln
            Mwskz       = ls_sum-mwskz
            Fkdat       = ls_adv-fkdat
            CreatedBy   = sy-uname
            CreatedAt   = lv_ts ) ) ) )
      FAILED DATA(post_failed)
      REPORTED DATA(post_reported).

    IF post_failed IS NOT INITIAL.
      ev_text = 'Creazione staging attribuzione non riuscita.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    ev_ok = abap_true.
    ev_text = COND string(
      WHEN iv_reverse = abap_true THEN 'Deattribuzione registrata nello staging.'
      ELSE 'Attribuzione registrata nello staging.' ).
    set_header_message( iv_uuid = iv_uuid iv_status = 'C' iv_text = ev_text ).
  ENDMETHOD.

  METHOD save_to_sap.
    ev_ok = abap_false.
    CLEAR ev_text.

    SELECT SINGLE *
      FROM /eacm/mfxn_h
      WHERE uuid = @iv_uuid
      INTO @DATA(ls_header).

    IF sy-subrc <> 0.
      ev_text = 'Sessione RAP MFXN non trovata.'.
      RETURN.
    ENDIF.

    SELECT *
      FROM /eacm/mfxn_adv
      WHERE uuid = @iv_uuid
      INTO TABLE @DATA(lt_adv).

    SELECT *
      FROM /eacm/mfxn_post
      WHERE uuid = @iv_uuid
      ORDER BY created_at, post_uuid
      INTO TABLE @DATA(lt_post).

    IF lt_post IS INITIAL.
      ev_text = 'Nessuna modifica da salvare.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'I' iv_text = ev_text ).
      ev_ok = abap_true.
      RETURN.
    ENDIF.

    LOOP AT lt_adv INTO DATA(ls_adv).
      DATA(lv_source_zirec) = CONV /eacm/mfxn_adv-source_zirec( ls_adv-zirec ).

      IF ls_adv-zirec = ls_adv-ziman.
        lv_source_zirec = ls_adv-source_ziman.
      ELSEIF ls_adv-display_waerk <> ls_adv-source_waerk.
        DATA(lv_back_currency) = ls_adv-source_waerk.
        DATA(lv_back_amount) = ls_adv-zirec.
        convert_from_local(
          EXPORTING iv_date = ls_adv-fkdat iv_local_currency = ls_header-loccur
          CHANGING  cv_amount = lv_back_amount cv_currency = lv_back_currency ).
        lv_source_zirec = lv_back_amount.
      ENDIF.

      UPDATE /eacm/zprdp
        SET zirec = @lv_source_zirec,
            zcamd = @sy-uname,
            zdtmd = @sy-datum,
            zormd = @sy-uzeit,
            tcode = 'RAP'
        WHERE vkorg = @ls_adv-vkorg
          AND vtweg = @ls_adv-vtweg
          AND zclpr = @ls_adv-zclpr
          AND vbeln = @ls_adv-vbeln
          AND posnr = @ls_adv-posnr
          AND zcdaz = @ls_adv-zcdaz
          AND zidag = @ls_adv-zidag
          AND zidrg = @ls_adv-zidrg.
    ENDLOOP.

    LOOP AT lt_post INTO DATA(ls_post).
      SELECT MAX( zprec )
        FROM /eacm/zprar
        WHERE vkorg = @ls_post-vkorg
          AND vtweg = @ls_post-vtweg
          AND zclpr = @ls_post-zclpr
          AND zcdaz = @ls_post-zcdaz
          AND zwaer = @ls_post-zwaer
          AND zamco = @ls_post-zamco
        INTO @DATA(lv_zprec).

      lv_zprec = lv_zprec + 1.

      MODIFY /eacm/zprar FROM @( VALUE /eacm/zprar(
        client = sy-mandt
        vkorg = ls_post-vkorg
        vtweg = ls_post-vtweg
        zclpr = ls_post-zclpr
        zcdaz = ls_post-zcdaz
        zwaer = ls_post-zwaer
        zamco = ls_post-zamco
        zprec = lv_zprec
        zirec = ls_post-zirec
        bukrs = ls_post-bukrs
        gjahr = ls_post-gjahr
        ziman = 0
        belnr = ls_post-belnr
        ztpan = ls_post-ztpan
        zamca = ls_post-zamca
        zesfa = ls_post-zesfa
        znrfa = ls_post-znrfa
        mwskz = ls_post-mwskz
        fkdat = ls_post-fkdat ) ).
    ENDLOOP.

    SELECT uuid, post_uuid
      FROM /eacm/mfxn_post
      WHERE uuid = @iv_uuid
      INTO TABLE @DATA(lt_post_delete_keys).

    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Posting
        DELETE FROM VALUE #( FOR ls_post_delete IN lt_post_delete_keys
          ( Uuid = ls_post_delete-uuid PostUuid = ls_post_delete-post_uuid ) )
      FAILED DATA(post_delete_failed)
      REPORTED DATA(post_delete_reported).

    IF post_delete_failed IS NOT INITIAL.
      ev_text = 'Pulizia staging movimenti non riuscita.'.
      set_header_message( iv_uuid = iv_uuid iv_status = 'E' iv_text = ev_text ).
      RETURN.
    ENDIF.

    ev_ok = abap_true.
    ev_text = |Salvataggio completato: { lines( lt_post ) } movimenti aggiornati.|.
    set_header_message( iv_uuid = iv_uuid iv_status = 'S' iv_text = ev_text ).
  ENDMETHOD.

  METHOD build_vkorg_range.
    SELECT sel_sign AS sign,
           sel_option AS option,
           low,
           high
      FROM /eacm/mfxn_rngvk
      WHERE uuid = @is_header-uuid
      INTO TABLE @rt_range.

    IF rt_range IS NOT INITIAL.
      RETURN.
    ENDIF.

    SELECT vkorg
      FROM /eacm/tvko
      WHERE bukrs = @is_header-bukrs
      INTO TABLE @DATA(lt_tvko).

    rt_range = VALUE #( FOR ls_tvko IN lt_tvko
      ( sign = 'I' option = 'EQ' low = ls_tvko-vkorg ) ).

*    LOOP AT lt_tvko INTO DATA(ls_tvko).
*      CALL FUNCTION 'AUTHORITY_CHECK'
*        EXPORTING
*          object = 'V_VBRK_VKO'
*          field1 = 'VKORG'
*          value1 = CONV xuval( ls_tvko-vkorg )
*          field2 = 'ACTVT'
*          value2 = '03'
*        EXCEPTIONS
*          user_is_authorized = 2
*          OTHERS             = 5.
*
*      IF sy-subrc = 2.
*        APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_tvko-vkorg ) TO rt_range.
*      ENDIF.
*    ENDLOOP.
  ENDMETHOD.

  METHOD build_vtweg_range.
    SELECT sel_sign AS sign,
           sel_option AS option,
           low,
           high
      FROM /eacm/mfxn_rngvt
      WHERE uuid = @iv_uuid
      INTO TABLE @rt_range.
  ENDMETHOD.

  METHOD build_doc_type_range.
    SELECT zclpr
      FROM /eacm/zpr08
      WHERE zant = @( COND #( WHEN iv_advance = abap_true THEN 'X' ELSE space ) )
      INTO TABLE @DATA(lt_zclpr).

    rt_range = VALUE #( FOR ls_zclpr IN lt_zclpr
      ( sign = 'I' option = 'EQ' low = ls_zclpr-zclpr ) ).
  ENDMETHOD.

  METHOD conversion_period.
    rv_text = iv_zamco+4(2) && iv_zamco(4).
  ENDMETHOD.

  METHOD convert_to_local.
    IF cv_currency = iv_local_currency OR cv_currency IS INITIAL OR iv_local_currency IS INITIAL.
      RETURN.
    ENDIF.

*    DATA(lv_rate) = CONV tcurr-ukurs( 1 ).
*    CALL FUNCTION 'READ_EXCHANGE_RATE'
*      EXPORTING
*        date             = iv_date
*        foreign_currency = cv_currency
*        local_currency   = iv_local_currency
*      IMPORTING
*        exchange_rate    = lv_rate
*      EXCEPTIONS
*        OTHERS           = 1.
*
*    CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
*      EXPORTING
*        date             = iv_date
*        foreign_amount   = cv_amount
*        foreign_currency = cv_currency
*        local_currency   = iv_local_currency
*        rate             = lv_rate
*      IMPORTING
*        local_amount     = cv_amount
*      EXCEPTIONS
*        OTHERS           = 1.

    cv_currency = iv_local_currency.
  ENDMETHOD.

  METHOD convert_from_local.
    IF cv_currency = iv_local_currency OR cv_currency IS INITIAL OR iv_local_currency IS INITIAL.
      RETURN.
    ENDIF.

*    CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
*      EXPORTING
*        date             = iv_date
*        foreign_amount   = cv_amount
*        foreign_currency = iv_local_currency
*        local_currency   = cv_currency
*      IMPORTING
*        local_amount     = cv_amount
*      EXCEPTIONS
*        OTHERS           = 1.
  ENDMETHOD.

  METHOD get_tax_code.
    DATA: lv_company_group TYPE /eacm/zzage VALUE '0',
          lv_agent_group   TYPE /eacm/zzage VALUE '0',
          lv_customer_group TYPE /eacm/zzage VALUE '0',
          lv_ship_group    TYPE /eacm/zzage VALUE '0',
          lv_land1         TYPE land1,
          lv_lifnr         TYPE lifnr,
          lv_zdest         TYPE /eacm/zdest.

    SELECT SINGLE land1
      FROM /eacm/t001
      WHERE bukrs = @iv_bukrs
      INTO @lv_land1.
    IF sy-subrc = 0.
      lv_company_group = country_group( iv_land1 = lv_land1 iv_date = iv_fkdat ).
    ENDIF.

    SELECT lifnr
      FROM /eacm/zpraa
      WHERE zcdaz = @iv_zcdaz
        AND zstre <> 'A'
        AND zstre <> 'S'
      ORDER BY erdat DESCENDING
      INTO @lv_lifnr
      UP TO 1 ROWS.
    ENDSELECT.

*    SELECT SINGLE land1
*      FROM lfa1
*      WHERE lifnr = @lv_lifnr
*      INTO @lv_land1.
*    IF sy-subrc = 0.
*      lv_agent_group = country_group( iv_land1 = lv_land1 iv_date = iv_fkdat ).
*    ENDIF.
*
*    SELECT SINGLE land1
*      FROM kna1
*      WHERE kunnr = @iv_kunrg
*      INTO @lv_land1.
*    IF sy-subrc = 0.
*      lv_customer_group = country_group( iv_land1 = lv_land1 iv_date = iv_fkdat ).
*    ENDIF.

    SELECT SINGLE zdest
      FROM /eacm/prdo
      WHERE vkorg = @iv_vkorg
        AND vtweg = @iv_vtweg
        AND zclpr = @iv_zclpr
        AND vbeln = @iv_vbeln
        AND posnr = @iv_posnr
        AND zcdaz = @iv_zcdaz
        AND zidag = @iv_zidag
      INTO @lv_zdest.

*    SELECT SINGLE land1
*      FROM kna1
*      WHERE kunnr = @lv_zdest
*      INTO @lv_land1.
*    IF sy-subrc = 0.
*      lv_ship_group = country_group( iv_land1 = lv_land1 iv_date = iv_fkdat ).
*    ENDIF.

    SELECT SINGLE mwskz
      FROM /eacm/zpr14
      WHERE znzag = @lv_agent_group
        AND znmco = @lv_company_group
        AND znzcl = @lv_customer_group
        AND lifnr = @lv_lifnr
      INTO @rv_mwskz.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    SELECT SINGLE mwskz
      FROM /eacm/zpr12
      WHERE znzag = @lv_agent_group
        AND znmco = @lv_company_group
        AND znzcl = @lv_customer_group
        AND znzmc = @lv_ship_group
      INTO @rv_mwskz.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    SELECT SINGLE mwskz
      FROM /eacm/zpr12
      WHERE znzag = @lv_agent_group
        AND znmco = @lv_company_group
        AND znzcl = @lv_customer_group
      INTO @rv_mwskz.
  ENDMETHOD.

  METHOD country_group.
    CHECK iv_land1 IS NOT INITIAL.

    SELECT SINGLE znzag
      FROM /eacm/zpr39
      WHERE land1 = @iv_land1
        AND zdtin <= @iv_date
        AND zdtfi >= @iv_date
      INTO @rv_group.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.
*
*    SELECT SINGLE xegld
*      FROM  t005
*      WHERE land1 = @iv_land1
*      INTO @DATA(lv_xegld).

*    IF sy-subrc = 0.
*      rv_group = COND #( WHEN lv_xegld = 'X' THEN '1' ELSE '2' ).
*    ENDIF.
  ENDMETHOD.

  METHOD append_summary.
    READ TABLE ct_sum ASSIGNING FIELD-SYMBOL(<ls_sum>)
      WITH KEY uuid   = is_line-uuid
               vkorg  = is_line-vkorg
               vtweg  = is_line-vtweg
               zclpr = is_line-zclpr
               waerk  = is_line-waerk
               mwskz  = is_line-mwskz.

    IF sy-subrc <> 0.
      DATA(ls_new) = is_line.
      ls_new-line_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      INSERT ls_new INTO TABLE ct_sum.
    ELSE.
      <ls_sum>-ziprv = <ls_sum>-ziprv + is_line-ziprv.
      <ls_sum>-zirec = <ls_sum>-zirec + is_line-zirec.
      <ls_sum>-ziprvlc = <ls_sum>-ziprvlc + is_line-ziprvlc.
      <ls_sum>-zireclc = <ls_sum>-zireclc + is_line-zireclc.
    ENDIF.
  ENDMETHOD.

  METHOD set_header_message.
    MODIFY ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Recovery
        UPDATE FIELDS ( Status MessageText )
        WITH VALUE #( (
          Uuid        = iv_uuid
          Status      = iv_status
          MessageText = iv_text ) )
      FAILED DATA(failed)
      REPORTED DATA(reported).
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Recovery DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Recovery RESULT result.

    METHODS Extract FOR MODIFY
      IMPORTING keys FOR ACTION Recovery~Extract RESULT result.

    METHODS StartExtraction FOR MODIFY
      IMPORTING keys FOR ACTION Recovery~StartExtraction.

    METHODS SaveToSap FOR MODIFY
      IMPORTING keys FOR ACTION Recovery~SaveToSap RESULT result.
ENDCLASS.

CLASS lhc_Recovery IMPLEMENTATION.
  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys
      ( %tky = key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD Extract.
    LOOP AT keys INTO DATA(key).
      lcl_mfxn_logic=>extract(
        EXPORTING iv_uuid = key-Uuid
        IMPORTING ev_ok = DATA(lv_ok) ev_text = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-recovery.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-recovery.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-recovery.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Recovery
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_recovery).

    result = VALUE #( FOR recovery IN lt_recovery
      ( %tky = recovery-%tky %param = recovery ) ).
  ENDMETHOD.

  METHOD StartExtraction.
    LOOP AT keys INTO DATA(key).
      lcl_mfxn_logic=>start_extraction(
        EXPORTING is_parameter = key-%param
        IMPORTING ev_ok        = DATA(lv_ok)
                  ev_text      = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %cid = key-%cid ) TO failed-recovery.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-recovery.
      ELSE.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-recovery.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD SaveToSap.
    LOOP AT keys INTO DATA(key).
      lcl_mfxn_logic=>save_to_sap(
        EXPORTING iv_uuid = key-Uuid
        IMPORTING ev_ok = DATA(lv_ok) ev_text = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-recovery.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-recovery.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-recovery.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Recovery
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_recovery).

    result = VALUE #( FOR recovery IN lt_recovery
      ( %tky = recovery-%tky %param = recovery ) ).
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Advance DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS Attribute FOR MODIFY
      IMPORTING keys FOR ACTION Advance~Attribute RESULT result.

    METHODS Deattribute FOR MODIFY
      IMPORTING keys FOR ACTION Advance~Deattribute RESULT result.
ENDCLASS.

CLASS lhc_Advance IMPLEMENTATION.
  METHOD Attribute.
    LOOP AT keys INTO DATA(key).
      lcl_mfxn_logic=>apply_amount(
        EXPORTING
          iv_uuid      = key-Uuid
          iv_line_uuid = key-LineUuid
          iv_reverse   = abap_false
          is_parameter = key-%param
        IMPORTING
          ev_ok        = DATA(lv_ok)
          ev_text      = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-advance.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-advance.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-advance.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Advance
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_adv).

    result = VALUE #( FOR adv IN lt_adv
      ( %tky = adv-%tky %param = adv ) ).
  ENDMETHOD.

  METHOD Deattribute.
    LOOP AT keys INTO DATA(key).
      lcl_mfxn_logic=>apply_amount(
        EXPORTING
          iv_uuid      = key-Uuid
          iv_line_uuid = key-LineUuid
          iv_reverse   = abap_true
          is_parameter = key-%param
        IMPORTING
          ev_ok        = DATA(lv_ok)
          ev_text      = DATA(lv_text) ).

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = key-%tky ) TO failed-advance.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_text ) ) TO reported-advance.
      ELSE.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text     = lv_text ) ) TO reported-advance.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF /EACM/I_MFXN_HDR IN LOCAL MODE
      ENTITY Advance
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_adv).

    result = VALUE #( FOR adv IN lt_adv
      ( %tky = adv-%tky %param = adv ) ).
  ENDMETHOD.
ENDCLASS.

