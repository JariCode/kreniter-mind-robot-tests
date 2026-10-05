*** Settings ***
Documentation    Testijoukko 9: Tiedostot ja kansiot.
...    Testaa tiedostojen latauksen, ääkköset tiedostonimissä, samannimisten tiedostojen
...    käsittelyn, kansiot, SVG-tiedoston turvallisen esikatselun, latausotsakkeet,
...    poiston, nimeämisen, siirron valikosta ja raahaamalla, kansioissa liikkumisen,
...    kansion poiston, tiedoston lataamisen koneelle ja tekstitiedoston muokkauksen
...    editorissa. Testitiedostot luodaan ajon aikana väliaikaiskansioon.
...    Kattaa testitapaukset TC08-001 - TC08-015 ja TC08-021 - TC08-023.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Library    OperatingSystem
Suite Setup    Valmistele Tiedostotestit
Suite Teardown    Siivoa Tiedostotestit
Test Setup    Valmistele Tiedostotesti


*** Variables ***
${SVG_SKRIPTILLA}    <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><script>window.__svgxss=1</script><circle cx="50" cy="50" r="40" fill="#1688ff"/></svg>


*** Test Cases ***
Tiedoston lataus onnistuu
    [Documentation]    TC08-001. Odotettu tulos: ladattu tiedosto näkyy listassa
    ...    nimellään.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} lataus.txt
    ${polku}=    Luo Testitiedosto    ${nimi}    Robotin testitiedosto
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s

Ääkköset säilyvät tiedostonimessä
    [Documentation]    TC08-002. Odotettu tulos: tiedosto, jonka nimessä on ä, ö ja å,
    ...    näkyy listassa täsmälleen samalla nimellä.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} Kävijät öö å.txt
    ${polku}=    Luo Testitiedosto    ${nimi}    Ääkkösiä sisältävä tiedosto
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s

Samanniminen tiedosto: säilytä molemmat
    [Documentation]    TC08-003. Odotettu tulos: kun sama tiedosto ladataan uudelleen,
    ...    avautuu dialogi "File already exists". Keep both tallentaa uuden tiedoston
    ...    nimellä, jonka perään on lisätty (1).
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} molemmat.txt
    ${uusi_nimi}=    Set Variable    ${ETULIITE} molemmat (1).txt
    ${polku}=    Luo Testitiedosto    ${nimi}    Ensimmäinen versio
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s
    Lataa Tiedosto    ${polku}
    Wait For Elements State    role=dialog >> text="File already exists"    visible    timeout=10s
    Click    role=dialog >> button >> text="Keep both"
    Wait For Elements State    ${RIVI}:text-is("${uusi_nimi}")    visible    timeout=15s
    Get Element Count    ${RIVI}:text-is("${nimi}")    ==    1

Samanniminen tiedosto: korvaa
    [Documentation]    TC08-004. Odotettu tulos: Replace korvaa olemassa olevan tiedoston,
    ...    eikä listaan tule toista samannimistä tiedostoa.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} korvaa.txt
    ${polku}=    Luo Testitiedosto    ${nimi}    Ensimmäinen versio
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s
    ${polku}=    Luo Testitiedosto    ${nimi}    Toinen, pidempi versio korvaavaa tiedostoa varten
    Lataa Tiedosto    ${polku}
    Wait For Elements State    role=dialog >> text="File already exists"    visible    timeout=10s
    Click    role=dialog >> button >> text="Replace"
    Wait For Elements State    role=dialog    detached    timeout=15s
    Get Element Count    ${RIVI}:text-is("${nimi}")    ==    1
    Get Element Count    ${RIVI}:text-is("${ETULIITE} korvaa (1).txt")    ==    0

Samanniminen tiedosto: peruuta
    [Documentation]    TC08-005. Odotettu tulos: Cancel sulkee dialogin, eikä uutta
    ...    tiedostoa tallenneta.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} peruuta.txt
    ${polku}=    Luo Testitiedosto    ${nimi}    Peruutettava
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s
    ${ennen}=    Get Element Count    ${RIVI}
    Lataa Tiedosto    ${polku}
    Wait For Elements State    role=dialog >> text="File already exists"    visible    timeout=10s
    Click    role=dialog >> button >> text="Cancel"
    Wait For Elements State    role=dialog    detached    timeout=10s
    Get Element Count    ${RIVI}    ==    ${ennen}

Kansion luonti onnistuu
    [Documentation]    TC08-006. Odotettu tulos: New folder -toiminnolla luotu kansio näkyy
    ...    listassa.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} kansio
    Luo Kansio Kayttoliittymassa    ${nimi}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=10s

Samannimistä kansiota ei voi luoda
    [Documentation]    TC08-007. Odotettu tulos: kun samaan paikkaan yritetään luoda
    ...    samanniminen kansio, dialogissa näkyy virhe, dialogi pysyy auki eikä toista
    ...    kansiota luoda.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} tuplakansio
    Luo Kansio Kayttoliittymassa    ${nimi}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=10s
    Luo Kansio Kayttoliittymassa    ${nimi}
    Wait For Elements State    role=dialog >> .files-error    visible    timeout=10s
    Click    .files-dialog-actions >> text="Cancel"
    Get Element Count    ${RIVI}:text-is("${nimi}")    ==    1

SVG-tiedoston skripti ei suoritu esikatselussa
    [Documentation]    TC08-008. Odotettu tulos: SVG-kuva näytetään esikatselussa, mutta
    ...    sen sisältämä skripti ei suoritu.
    [Tags]    selain    tietoturva
    ${nimi}=    Set Variable    ${ETULIITE} skripti.svg
    ${polku}=    Luo Testitiedosto    ${nimi}    ${SVG_SKRIPTILLA}
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s
    Click    .files-row-main:has(strong:text-is("${nimi}"))
    Wait For Elements State    .files-preview-content >> img    visible    timeout=10s
    ${suoritettiin}=    Evaluate JavaScript    ${None}    () => window.__svgxss === 1
    Should Not Be True    ${suoritettiin}    msg=SVG-tiedoston skripti suoritettiin
    Click    .files-modal-close

Tiedostot ladataan turvallisilla otsakkeilla
    [Documentation]    TC08-009. Odotettu tulos: palvelin lähettää tiedoston liitteenä
    ...    (Content-Disposition: attachment), estää sisältötyypin arvailun (nosniff) ja
    ...    estää skriptien suorituksen (Content-Security-Policy, sandbox), vaikka
    ...    tiedosto avattaisiin suoraan osoitteesta.
    [Tags]    api    tietoturva
    ${nimi}=    Set Variable    ${ETULIITE} otsakkeet.svg
    ${polku}=    Luo Testitiedosto    ${nimi}    ${SVG_SKRIPTILLA}
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s
    ${tiedosto_id}=    Hae Tiedoston Tunniste    ${nimi}
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /files/${tiedosto_id}/download
    Should Be Equal As Integers    ${vastaus.status_code}    200
    Should Start With    ${vastaus.headers}[Content-Disposition]    attachment
    Should Be Equal    ${vastaus.headers}[X-Content-Type-Options]    nosniff
    Should Contain    ${vastaus.headers}[Content-Security-Policy]    sandbox
    Should Contain    ${vastaus.headers}[Content-Security-Policy]    default-src 'none'

Tiedoston poisto onnistuu
    [Documentation]    TC08-010. Odotettu tulos: poistovahvistuksen jälkeen tiedosto
    ...    katoaa listasta.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} poistettava.txt
    ${polku}=    Luo Testitiedosto    ${nimi}    Poistettava tiedosto
    Lataa Tiedosto    ${polku}
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    visible    timeout=15s
    Click    ${RIVIN_TOIMINNOT.format("${nimi}")} >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete file"    visible    timeout=10s
    Click    .files-delete-dialog-confirm
    Wait For Elements State    ${RIVI}:text-is("${nimi}")    detached    timeout=10s

Tiedoston nimeäminen ja samannimisen nimen esto
    [Documentation]    TC08-011. Odotettu tulos: tiedoston voi nimetä uudelleen, ja uusi
    ...    nimi näkyy listassa. Jos uusi nimi on jo toisella tiedostolla samassa
    ...    paikassa, dialogi näyttää virheen eikä nimeä vaihdeta.
    [Tags]    selain
    ${vanha}=    Set Variable    ${ETULIITE} nimettävä.txt
    ${uusi}=    Set Variable    ${ETULIITE} nimetty.txt
    ${varattu}=    Set Variable    ${ETULIITE} varattu.txt
    Lataa Tiedosto Rajapintaan    ${vanha}
    Lataa Tiedosto Rajapintaan    ${varattu}
    Reload
    Mene Testiprojektin Tiedostoihin
    Nimea Rivi Uudelleen    ${vanha}    ${uusi}
    Wait For Elements State    ${RIVI}:text-is("${uusi}")    visible    timeout=10s
    Get Element Count    ${RIVI}:text-is("${vanha}")    ==    0
    Nimea Rivi Uudelleen    ${uusi}    ${varattu}
    Wait For Elements State    role=dialog >> .files-error    visible    timeout=10s
    Click    .files-dialog-actions >> text="Cancel"
    Get Element Count    ${RIVI}:text-is("${uusi}")    ==    1
    Get Element Count    ${RIVI}:text-is("${varattu}")    ==    1

Tiedoston siirto toiseen kansioon
    [Documentation]    TC08-012. Odotettu tulos: Move-toiminnolla siirretty tiedosto katoaa
    ...    juurikansiosta ja näkyy kohdekansiossa.
    [Tags]    selain
    ${kansio}=    Set Variable    ${ETULIITE} siirtokansio
    ${tiedosto}=    Set Variable    ${ETULIITE} siirrettävä.txt
    Luo Kansio Rajapintaan    ${kansio}
    Lataa Tiedosto Rajapintaan    ${tiedosto}
    Reload
    Mene Testiprojektin Tiedostoihin
    Click    ${RIVIN_TOIMINNOT.format("${tiedosto}")} >> text="Move"
    Wait For Elements State    role=dialog >> .files-move-list    visible    timeout=10s
    Click    .files-move-item:has(strong:text-is("${kansio}"))
    Wait For Elements State    ${RIVI}:text-is("${tiedosto}")    detached    timeout=10s
    Avaa Kansio    ${kansio}
    Wait For Elements State    ${RIVI}:text-is("${tiedosto}")    visible    timeout=10s

Kansioissa liikkuminen ja polkunavigointi
    [Documentation]    TC08-013. Odotettu tulos: kansion avaus näyttää sen sisällön ja
    ...    polun, alikansioon voi siirtyä, ja takaisin-painike palaa edelliseen kansioon.
    [Tags]    selain
    ${ylakansio}=    Set Variable    ${ETULIITE} yläkansio
    ${alikansio}=    Set Variable    ${ETULIITE} alikansio
    ${yla_id}=    Luo Kansio Rajapintaan    ${ylakansio}
    Luo Kansio Rajapintaan    ${alikansio}    ${yla_id}
    Reload
    Mene Testiprojektin Tiedostoihin
    Get Element Count    ${RIVI}:text-is("${alikansio}")    ==    0
    Avaa Kansio    ${ylakansio}
    Get Text    .files-breadcrumb    contains    ${ylakansio}
    Wait For Elements State    ${RIVI}:text-is("${alikansio}")    visible    timeout=10s
    Avaa Kansio    ${alikansio}
    Get Text    .files-breadcrumb    contains    ${alikansio}
    Click    button[aria-label="Go back"]
    Wait For Elements State    ${RIVI}:text-is("${alikansio}")    visible    timeout=10s

Kansion nimeäminen ja ei-tyhjän kansion poisto
    [Documentation]    TC08-014. Odotettu tulos: kansion voi nimetä uudelleen. Ei-tyhjän
    ...    kansion poisto estetään sekä käyttöliittymässä että rajapinnassa (409), jotta
    ...    sen tiedostot eivät jää tietokantaan ilman kansiota. Tiedosto ja kansio
    ...    säilyvät molempien yritysten jälkeen.
    [Tags]    selain    tietoturva
    ${vanha}=    Set Variable    ${ETULIITE} nimettävä kansio
    ${uusi}=    Set Variable    ${ETULIITE} nimetty kansio
    ${kansio_id}=    Luo Kansio Rajapintaan    ${vanha}
    ${tiedosto_id}=    Lataa Tiedosto Rajapintaan    ${ETULIITE} kansion sisältö.txt    ${kansio_id}
    Reload
    Mene Testiprojektin Tiedostoihin
    Nimea Rivi Uudelleen    ${vanha}    ${uusi}
    Wait For Elements State    ${RIVI}:text-is("${uusi}")    visible    timeout=10s
    Click    ${RIVIN_TOIMINNOT.format("${uusi}")} >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete folder"    visible    timeout=10s
    Click    .files-delete-dialog-confirm
    Wait For Elements State    text=/must be empty/    visible    timeout=10s
    Get Element Count    ${RIVI}:text-is("${uusi}")    ==    1
    ${vastaus}=    Tee Kirjautunut Pyynto    DELETE    /folders/${kansio_id}
    Should Be Equal As Integers    ${vastaus.status_code}    409
    ...    msg=Rajapinta poisti ei-tyhjän kansion (${vastaus.status_code}), jolloin sen tiedosto jää orvoksi
    ${tiedosto}=    Tee Kirjautunut Pyynto    GET    /files/${tiedosto_id}/download
    Should Be Equal As Integers    ${tiedosto.status_code}    200

Tiedoston lataus koneelle säilyttää sisällön ja nimen
    [Documentation]    TC08-015. Odotettu tulos: Download-painike lataa tiedoston
    ...    koneelle alkuperäisellä nimellä ja sisällöllä.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} ladattava.txt
    ${sisalto}=    Set Variable    Robotin ladattava sisältö ja ääkköset äöå
    Lataa Tiedosto Rajapintaan    ${nimi}    sisalto=${sisalto}
    Reload
    Mene Testiprojektin Tiedostoihin
    ${lataus}=    Promise To Wait For Download    ${TIEDOSTOKANSIO}${/}ladattu.txt
    Click    ${RIVIN_TOIMINNOT.format("${nimi}")} >> text="Download"
    ${tiedosto}=    Wait For    ${lataus}
    Should Be Equal    ${tiedosto}[suggestedFilename]    ${nimi}
    ${luettu}=    Get File    ${TIEDOSTOKANSIO}${/}ladattu.txt    encoding=UTF-8
    Should Be Equal    ${luettu}    ${sisalto}

Tiedoston siirto raahaamalla kansioon
    [Documentation]    TC08-021. Odotettu tulos: kun tiedostorivi raahataan kansiorivin
    ...    päälle, tiedosto katoaa juurikansiosta ja näkyy kohdekansiossa. Raahaus
    ...    tehdään selaimen omilla raahaustapahtumilla, koska tiedostolista käyttää
    ...    HTML5-raahausta, jota pelkkä hiiren liike ei käynnistä.
    [Tags]    selain
    ${kansio}=    Set Variable    ${ETULIITE} raahauskansio
    ${tiedosto}=    Set Variable    ${ETULIITE} raahattava.txt
    Luo Kansio Rajapintaan    ${kansio}
    Lataa Tiedosto Rajapintaan    ${tiedosto}
    Reload
    Mene Testiprojektin Tiedostoihin
    Wait For Elements State    ${RIVI}:text-is("${tiedosto}")    visible    timeout=10s
    Raahaa Rivi Riville    ${tiedosto}    ${kansio}
    Wait For Elements State    ${RIVI}:text-is("${tiedosto}")    detached    timeout=10s
    Avaa Kansio    ${kansio}
    Wait For Elements State    ${RIVI}:text-is("${tiedosto}")    visible    timeout=10s

Tekstitiedoston muokkaus editorissa
    [Documentation]    TC08-022. Odotettu tulos: tekstitiedosto avautuu riviä
    ...    klikkaamalla editoriin, jossa näkyy tiedoston sisältö. Muokattu sisältö
    ...    tallentuu Save changes -painikkeella ilman virhettä, ja uusi sisältö on
    ...    tallessa myös rajapinnassa. Editori jää tarkoituksella auki tallennuksen
    ...    jälkeen, jotta muokkausta voi jatkaa, ja sen voi sulkea Cancel-painikkeella.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} muokattava.txt
    ${tiedosto_id}=    Lataa Tiedosto Rajapintaan    ${nimi}    sisalto=Alkuperäinen sisältö
    Reload
    Mene Testiprojektin Tiedostoihin
    Click    .files-row-main:has(strong:text-is("${nimi}"))
    ${editori}=    Set Variable    textarea[aria-label="File content"]
    Wait For Elements State    ${editori}    visible    timeout=10s
    Get Text    ${editori}    ==    Alkuperäinen sisältö
    Fill Text    ${editori}    Muokattu sisältö editorissa äöå
    Click    .files-editor-actions >> text="Save changes"
    Wait For Elements State    .files-editor-actions >> text="Save changes"    enabled    timeout=10s
    Get Element Count    .files-editor-modal >> .files-error    ==    0
    ${lataus}=    Tee Kirjautunut Pyynto    GET    /files/${tiedosto_id}/download
    Should Be Equal As Integers    ${lataus.status_code}    200
    Should Be Equal    ${lataus.content.decode('utf-8')}    Muokattu sisältö editorissa äöå
    Click    .files-editor-actions >> text="Cancel"
    Wait For Elements State    ${editori}    detached    timeout=10s

Polun klikkaus palaa ylempään kansioon
    [Documentation]    TC08-023. Odotettu tulos: kun ollaan kaksi kansiota syvällä,
    ...    yläkansion nimen klikkaus polussa palaa yläkansioon ja Files-juuren klikkaus
    ...    palaa juurikansioon.
    [Tags]    selain
    ${ylakansio}=    Set Variable    ${ETULIITE} polku ylä
    ${alikansio}=    Set Variable    ${ETULIITE} polku ala
    ${yla_id}=    Luo Kansio Rajapintaan    ${ylakansio}
    Luo Kansio Rajapintaan    ${alikansio}    ${yla_id}
    Reload
    Mene Testiprojektin Tiedostoihin
    Avaa Kansio    ${ylakansio}
    Avaa Kansio    ${alikansio}
    Get Text    .files-breadcrumb    contains    ${alikansio}
    Click    .files-breadcrumb-item:text-is("${ylakansio}")
    Wait For Elements State    ${RIVI}:text-is("${alikansio}")    visible    timeout=10s
    Click    .files-breadcrumb-item:text-is("Files")
    Wait For Elements State    ${RIVI}:text-is("${ylakansio}")    visible    timeout=10s
    Get Element Count    ${RIVI}:text-is("${alikansio}")    ==    0


*** Keywords ***
Valmistele Tiedostotestit
    [Documentation]    Kirjautuu testitunnuksella, luo ajolle satunnaisen etuliitteen,
    ...    testiprojektin ja väliaikaiskansion testitiedostoille.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    ${runko}=    Create Dictionary    name=${ETULIITE} tiedostoprojekti
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    Set Suite Variable    ${PROJEKTI_ID}    ${projekti.json()}[_id]
    Set Suite Variable    ${TIEDOSTOKANSIO}    ${TEMPDIR}${/}kreniter-robot-${tunniste}
    Create Directory    ${TIEDOSTOKANSIO}
    Set Suite Variable    ${RIVI}    .files-item-info >> strong
    Set Suite Variable    ${RIVIN_TOIMINNOT}
    ...    div:has(> .files-row-main strong:text-is("{}")) >> .files-row-actions
    ${luodut_tiedostot}=    Create List
    Set Suite Variable    ${LUODUT_TIEDOSTOT}    ${luodut_tiedostot}
    ${luodut_kansiot}=    Create List
    Set Suite Variable    ${LUODUT_KANSIOT}    ${luodut_kansiot}
    Reload

Valmistele Tiedostotesti
    [Documentation]    Lataa sivun uudelleen ennen jokaista testiä, jotta edellisen testin
    ...    auki jäänyt dialogi ei peitä sivua, ja avaa testiprojektin tiedostot.
    Reload
    Mene Testiprojektin Tiedostoihin

Mene Testiprojektin Tiedostoihin
    [Documentation]    Avaa Files-sivun ja valitsee testiprojektin projektivalikosta.
    Click    .sidebar-item >> text="Files"
    Wait For Elements State    h1 >> text="Files"    visible    timeout=10s
    Select Options By    id=files-project    value    ${PROJEKTI_ID}

Luo Testitiedosto
    [Documentation]    Kirjoittaa testitiedoston väliaikaiskansioon ja palauttaa sen polun.
    [Arguments]    ${nimi}    ${sisalto}
    ${polku}=    Set Variable    ${TIEDOSTOKANSIO}${/}${nimi}
    Create File    ${polku}    ${sisalto}    encoding=UTF-8
    RETURN    ${polku}

Lataa Tiedosto
    [Documentation]    Valitsee tiedoston sivun tiedostokenttään, kuten käyttäjä valitsisi
    ...    sen Upload files -painikkeen avaamasta ikkunasta.
    [Arguments]    ${polku}
    Upload File By Selector    input.files-input    ${polku}

Lataa Tiedosto Rajapintaan
    [Documentation]    Lataa tiedoston testiprojektiin (valinnaisesti kansioon) rajapinnan
    ...    kautta testin esivalmisteluksi ja palauttaa sen tunnisteen.
    [Arguments]    ${nimi}    ${kansio_id}=${None}    ${sisalto}=Robotin testitiedosto
    ${vastaus}=    Lataa Tiedosto Rajapinnalla    ${nimi}    ${sisalto}
    ...    projekti_id=${PROJEKTI_ID}    kansio_id=${kansio_id}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    Append To List    ${LUODUT_TIEDOSTOT}    ${vastaus.json()}[_id]
    RETURN    ${vastaus.json()}[_id]

Luo Kansio Rajapintaan
    [Documentation]    Luo kansion testiprojektiin (valinnaisesti toisen kansion sisään)
    ...    rajapinnan kautta ja palauttaa sen tunnisteen.
    [Arguments]    ${nimi}    ${ylakansio_id}=${None}
    ${runko}=    Create Dictionary    name=${nimi}    projectId=${PROJEKTI_ID}
    IF    $ylakansio_id    Set To Dictionary    ${runko}    parentFolderId=${ylakansio_id}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /folders    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    Append To List    ${LUODUT_KANSIOT}    ${vastaus.json()}[_id]
    RETURN    ${vastaus.json()}[_id]

Luo Kansio Kayttoliittymassa
    [Documentation]    Avaa New folder -dialogin, kirjoittaa nimen ja vahvistaa.
    [Arguments]    ${nimi}
    Click    .files-action-button >> text="+ New folder"
    Wait For Elements State    id=files-dialog-input    visible    timeout=5s
    Fill Text    id=files-dialog-input    ${nimi}
    Click    .files-dialog-actions >> .files-upload-button

Nimea Rivi Uudelleen
    [Documentation]    Avaa tiedoston tai kansion Rename-dialogin, kirjoittaa uuden nimen
    ...    ja vahvistaa.
    [Arguments]    ${nimi}    ${uusi_nimi}
    Click    ${RIVIN_TOIMINNOT.format("${nimi}")} >> text="Rename"
    Wait For Elements State    id=files-dialog-input    visible    timeout=5s
    Fill Text    id=files-dialog-input    ${uusi_nimi}
    Click    .files-dialog-actions >> .files-upload-button

Avaa Kansio
    [Documentation]    Avaa kansion klikkaamalla sen riviä ja odottaa sisällön latautuvan.
    [Arguments]    ${nimi}
    Click    .files-row-main:has(strong:text-is("${nimi}"))
    Wait For Load State    networkidle    timeout=10s

Raahaa Rivi Riville
    [Documentation]    Raahaa tiedostorivin kansiorivin päälle lähettämällä samat
    ...    HTML5-raahaustapahtumat kuin selain oikeassa raahauksessa: dragstart
    ...    tiedostoriville, dragover ja drop kansioriville sekä dragend tiedostoriville.
    ...    Tapahtumien välissä on lyhyt tauko, jotta sovellus ehtii tallentaa
    ...    raahattavan tiedoston ennen pudotusta.
    [Arguments]    ${tiedosto}    ${kansio}
    ${tulos}=    Evaluate JavaScript    ${None}
    ...    async () => {
    ...        const tauko = () => new Promise(r => setTimeout(r, 200));
    ...        const rivi = nimi => [...document.querySelectorAll('.files-row')]
    ...            .find(r => r.querySelector('.files-item-info strong')?.textContent.trim() === nimi);
    ...        const lahde = rivi('${tiedosto}');
    ...        const kohde = rivi('${kansio}');
    ...        if (!lahde || !kohde) return 'ei löytynyt';
    ...        const siirto = new DataTransfer();
    ...        lahde.dispatchEvent(new DragEvent('dragstart', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        await tauko();
    ...        kohde.dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        await tauko();
    ...        kohde.dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        await tauko();
    ...        lahde.dispatchEvent(new DragEvent('dragend', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        return 'ok';
    ...    }
    Should Be Equal    ${tulos}    ok    msg=Raahattavaa tiedostoa tai kohdekansiota ei löytynyt

Hae Tiedoston Tunniste
    [Documentation]    Hakee testiprojektin juurikansion tiedostoista annetun nimisen
    ...    tiedoston tunnisteen.
    [Arguments]    ${nimi}
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /files?projectId=${PROJEKTI_ID}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${tunnisteet}=    Evaluate    [t['_id'] for t in $vastaus.json() if t['name'] == $nimi]
    Should Not Be Empty    ${tunnisteet}    msg=Tiedostoa ${nimi} ei löytynyt
    RETURN    ${tunnisteet}[0]

Siivoa Tiedostotestit
    [Documentation]    Poistaa testiprojektin tiedostot (juurikansio ja rajapinnalla
    ...    kansioihin ladatut) ensin, jotta kansiot ovat tyhjiä, sitten kansiot
    ...    alikansiot ensin, projektin sekä väliaikaiskansion.
    ${tiedostot}=    Tee Kirjautunut Pyynto    GET    /files?projectId=${PROJEKTI_ID}
    FOR    ${tiedosto}    IN    @{tiedostot.json()}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /files/${tiedosto}[_id]
    END
    FOR    ${tiedosto_id}    IN    @{LUODUT_TIEDOSTOT}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /files/${tiedosto_id}
    END
    Reverse List    ${LUODUT_KANSIOT}
    FOR    ${kansio_id}    IN    @{LUODUT_KANSIOT}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /folders/${kansio_id}
    END
    ${kansiot}=    Tee Kirjautunut Pyynto    GET    /folders?projectId=${PROJEKTI_ID}
    FOR    ${kansio}    IN    @{kansiot.json()}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /folders/${kansio}[_id]
    END
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${PROJEKTI_ID}
    Run Keyword And Ignore Error    Remove Directory    ${TIEDOSTOKANSIO}    recursive=True
    Close Browser