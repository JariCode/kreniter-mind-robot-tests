*** Settings ***
Documentation    Testijoukko 4: Injektiot, XSS ja syötteiden validointi.
...    Testaa, että backend hylkää NoSQL-injektiot, prototyyppisaastutuksen,
...    tyyppisekaannuksen, virheelliset tunnisteet ja virheelliset syötteet, että
...    XSS-syötteet näytetään tekstinä kaikissa näkymissä, ja että virheilmoitukset,
...    tiedostonimet ja CORS-asetukset eivät avaa hyökkäysreittejä.
...    Kattaa testitapaukset TC03-001 - TC03-013 ja TC03-015 - TC03-018 sekä
...    TC05-003, TC09-005 ja TC09-006. TC03-018 on merkitty tagilla hidas, koska se
...    vaatii backendin alkuperäiset pyyntörajat ja lukitsee AI Assistantin
...    testitililtä 15 minuutiksi. Se ajetaan erikseen:
...    python -m robot --include hidas tests/04_injektiot_validointi_api.robot
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Validointitestit
Suite Teardown    Siivoa Validointitestit


*** Variables ***
${XSS_SYOTE}         <img src=x onerror="window.__xss=1">
${VIERAS_OSOITE}     https://hyokkaaja.example


*** Test Cases ***
NoSQL-operaattori pyynnön rungossa hylätään
    [Documentation]    TC03-001. Odotettu tulos: kun projektin nimeksi lähetetään
    ...    MongoDB-operaattori {"$gt": ""}, pyyntö hylätään vastauksella 400 eikä
    ...    projektia luoda.
    [Tags]    api    tietoturva
    ${runko}=    Evaluate    {"name": {"$gt": ""}}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /projects
    Should Be Equal As Integers    ${vastaus.status_code}    400

NoSQL-operaattori kyselyparametrissa hylätään
    [Documentation]    TC03-002. Odotettu tulos: kyselyparametrissa oleva
    ...    MongoDB-operaattori hylätään vastauksella 400 tehtävissä, tiedostoissa,
    ...    muistiinpanoissa ja kalenterissa.
    [Tags]    api    tietoturva
    [Template]    Kirjautunut Pyynto Palauttaa
    GET    /tasks?projectId[$ne]=x                                400
    GET    /files?folderId[$ne]=x                                 400
    GET    /notes?projectId[$gt]=                                 400
    GET    /calendar-events?from[$gt]=2026-01-01&to=2026-12-31    400
    GET    /calendar/items?from=2026-01-01&to[$ne]=x              400

Virheellinen tunniste hylätään
    [Documentation]    TC03-003. Odotettu tulos: muodoltaan virheellinen tunniste
    ...    hylätään vastauksella 400, eikä palvelin kaadu (ei 500).
    [Tags]    api    tietoturva
    [Template]    Kirjautunut Pyynto Palauttaa
    GET       /projects/eiolemassa      400
    GET       /tasks/eiolemassa         400
    GET       /notes/eiolemassa         400
    DELETE    /calendar-events/eiolemassa    400

Liian pitkä syöte hylätään
    [Documentation]    TC03-004. Odotettu tulos: enimmäispituuden ylittävä nimi tai
    ...    otsikko hylätään vastauksella 400 eikä tietoa tallenneta.
    [Tags]    api
    ${pitka_151}=    Evaluate    "a" * 151
    ${pitka_201}=    Evaluate    "a" * 201
    Luonti Palauttaa 400    /projects    name=${pitka_151}
    Luonti Palauttaa 400    /tasks       title=${pitka_201}
    Luonti Palauttaa 400    /notes       title=${pitka_201}

Virheellinen tila tai prioriteetti hylätään
    [Documentation]    TC03-005. Odotettu tulos: arvo, joka ei kuulu sallittuihin
    ...    vaihtoehtoihin, hylätään vastauksella 400.
    [Tags]    api
    Luonti Palauttaa 400    /projects    name=${ETULIITE} validointi    status=hakkeroitu
    Luonti Palauttaa 400    /tasks       title=${ETULIITE} validointi    status=hakkeroitu
    Luonti Palauttaa 400    /notes       title=${ETULIITE} validointi    priority=hakkeroitu

Dashboardin virheelliset widgetit hylätään
    [Documentation]    TC03-006. Odotettu tulos: tuntematon widget-tyyppi tai liian
    ...    monta widgettiä hylätään vastauksella 400.
    [Tags]    api    tietoturva
    ${tuntematon}=    Evaluate    {"widgets": ["projects", "<script>"]}
    ${vastaus}=    Tee Kirjautunut Pyynto    PUT    /dashboard-layout    ${tuntematon}
    Should Be Equal As Integers    ${vastaus.status_code}    400
    ${liikaa}=    Evaluate    {"widgets": ["projects"] * 21}
    ${vastaus}=    Tee Kirjautunut Pyynto    PUT    /dashboard-layout    ${liikaa}
    Should Be Equal As Integers    ${vastaus.status_code}    400

XSS-syöte projektin nimessä ja kuvauksessa näytetään tekstinä
    [Documentation]    TC03-007. Odotettu tulos: projektin nimeen ja kuvaukseen
    ...    tallennettu HTML näkyy projektilistassa tekstinä, eikä sen sisältämä koodi
    ...    suoritu. XSS-projektin kuvauksessa on sama syöte (luotu suite setupissa).
    [Tags]    selain    tietoturva
    ${runko}=    Create Dictionary    name=${ETULIITE} ${XSS_SYOTE}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /projects
    Click    .sidebar-item >> text="Projects"
    Wait For Elements State    h1 >> text="Projects"    visible    timeout=10s
    XSS Nakyy Tekstina Eika Suoritu

Regex- ja where-operaattorit hylätään
    [Documentation]    TC03-008. Odotettu tulos: $regex- ja $where-operaattorit pyynnön
    ...    rungossa ja kyselyparametrissa hylätään vastauksella 400.
    [Tags]    api    tietoturva
    ${regex}=    Evaluate    {"name": {"$regex": ".*"}}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${regex}
    Tallenna Jos Luotiin    ${vastaus}    /projects
    Should Be Equal As Integers    ${vastaus.status_code}    400
    ${where}=    Evaluate    {"title": {"$where": "sleep(1000)"}}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /tasks    ${where}
    Tallenna Jos Luotiin    ${vastaus}    /tasks
    Should Be Equal As Integers    ${vastaus.status_code}    400
    Kirjautunut Pyynto Palauttaa    GET    /tasks?projectId[$regex]=.*    400
    Kirjautunut Pyynto Palauttaa    GET    /notes?projectId[$where]=1    400

Prototyyppisaastutus ei muuta sovelluksen toimintaa
    [Documentation]    TC03-009. Odotettu tulos: kun pyynnössä on __proto__- tai
    ...    constructor-avain, sen sisältö ei päädy tallennettuun tietoon eikä muuta
    ...    palvelimen toimintaa. Seuraava tavallinen pyyntö toimii normaalisti.
    [Tags]    api    tietoturva
    ${runko}=    Evaluate
    ...    {"name": $ETULIITE + " proto", "__proto__": {"isAdmin": True}, "constructor": {"prototype": {"isAdmin": True}}}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /projects
    Should Be True    ${vastaus.status_code} in (201, 400)
    Should Not Contain    ${vastaus.text}    isAdmin
    ${tarkistus}=    Tee Kirjautunut Pyynto    GET    /projects
    Should Be Equal As Integers    ${tarkistus.status_code}    200
    Should Not Contain    ${tarkistus.text}    isAdmin

Tyyppisekaannus tekstikentässä hylätään
    [Documentation]    TC03-010. Odotettu tulos: kun tekstikenttään lähetetään taulukko,
    ...    objekti tai luku, pyyntö hylätään vastauksella 400 projekteissa, tehtävissä,
    ...    muistiinpanoissa ja kalenterissa.
    [Tags]    api    tietoturva
    Tyyppi Hylataan    /projects    {"name": ["Robot taulukko"]}
    Tyyppi Hylataan    /projects    {"name": {"a": "b"}}
    Tyyppi Hylataan    /projects    {"name": 12345}
    Tyyppi Hylataan    /tasks    {"title": ["Robot taulukko"]}
    Tyyppi Hylataan    /notes    {"title": {"a": "b"}}
    Tyyppi Hylataan    /calendar-events    {"title": ["Robot"], "date": "2026-06-15", "allDay": True}

Liian suuri pyyntö hylätään
    [Documentation]    TC03-011. Odotettu tulos: yli 10 Mt:n pyyntö hylätään
    ...    vastauksella 413 eikä palvelin kaadu.
    [Tags]    api    tietoturva
    ${iso}=    Evaluate    '{"name": "' + 'a' * 11000000 + '"}'
    ${tunniste}=    Hae Kirjautumistunniste
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${tunniste}
    ...    Content-Type=application/json
    ${vastaus}=    POST    ${API}/projects    data=${iso}    headers=${otsakkeet}
    ...    expected_status=any
    Should Be Equal As Integers    ${vastaus.status_code}    413

XSS-syöte muissa kentissä näytetään tekstinä
    [Documentation]    TC03-012. Odotettu tulos: tehtävän otsikkoon ja kuvaukseen,
    ...    muistiinpanon otsikkoon ja sisältöön sekä kalenterimerkinnän, kansion ja
    ...    tiedoston nimeen tallennettu HTML näkyy tekstinä jokaisessa näkymässä, eikä
    ...    sen sisältämä koodi suoritu.
    [Tags]    selain    tietoturva
    ${nimi}=    Set Variable    ${ETULIITE} ${XSS_SYOTE}
    ${tanaan}=    Evaluate    datetime.date.today().isoformat()    modules=datetime
    ${runko}=    Create Dictionary    title=${nimi}    description=${XSS_SYOTE}
    ...    projectId=${XSS_PROJEKTI_ID}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /tasks
    ${runko}=    Create Dictionary    title=${nimi}    content=${XSS_SYOTE}
    ...    projectId=${XSS_PROJEKTI_ID}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /notes    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /notes
    ${runko}=    Create Dictionary    title=${nimi}    date=${tanaan}    allDay=${True}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /calendar-events    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /calendar-events
    ${runko}=    Create Dictionary    name=${nimi}    projectId=${XSS_PROJEKTI_ID}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /folders    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /folders
    ${vastaus}=    Lataa Tiedosto Rajapinnalla    ${nimi}.txt    XSS-testi
    ...    projekti_id=${XSS_PROJEKTI_ID}
    Tallenna Jos Luotiin    ${vastaus}    /files
    Reload
    Click    .sidebar-item >> text="Tasks"
    Wait For Elements State    h1 >> text="Tasks"    visible    timeout=10s
    Select Options By    id=tasks-project    value    ${XSS_PROJEKTI_ID}
    XSS Nakyy Tekstina Eika Suoritu
    Click    .sidebar-item >> text="Notes"
    Wait For Elements State    h1 >> text="Notes"    visible    timeout=10s
    XSS Nakyy Tekstina Eika Suoritu
    Click    .sidebar-item >> text="Calendar"
    Wait For Elements State    h1 >> text="Calendar"    visible    timeout=10s
    Click    .calendar-nav-today
    XSS Nakyy Tekstina Eika Suoritu
    Click    .sidebar-item >> text="Files"
    Wait For Elements State    h1 >> text="Files"    visible    timeout=10s
    Select Options By    id=files-project    value    ${XSS_PROJEKTI_ID}
    XSS Nakyy Tekstina Eika Suoritu

Javascript-osoite repository-linkissä hylätään
    [Documentation]    TC03-013. Odotettu tulos: kun projektin repository-osoitteeksi
    ...    annetaan javascript:-osoite, palvelin hylkää sen vastauksella 400, eikä
    ...    projektia luoda. Klikattava javascript:-linkki suorittaisi koodia.
    [Tags]    api    tietoturva
    ${runko}=    Create Dictionary    name=${ETULIITE} javascript-linkki
    ...    repositoryUrl=javascript:window.__xss=1
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    /projects
    Should Be Equal As Integers    ${vastaus.status_code}    400

Tiedostonimen injektio ei rikkoa latausotsaketta
    [Documentation]    TC03-015. Odotettu tulos: tiedostonimi, jossa on ../-polku ja
    ...    lainausmerkki, ei riko latauksen Content-Disposition-otsaketta: otsakkeessa on
    ...    vain tiedostonimen rajaavat lainausmerkit, eikä polku näy siinä sellaisenaan.
    ...    Jos palvelin hylkää nimen kokonaan (400), sekin on hyväksyttävä tulos.
    [Tags]    api    tietoturva
    ${nimi}=    Set Variable    ../../${ETULIITE} injektio".txt
    ${vastaus}=    Lataa Tiedosto Rajapinnalla    ${nimi}    Injektiotesti
    ...    projekti_id=${XSS_PROJEKTI_ID}
    Tallenna Jos Luotiin    ${vastaus}    /files
    IF    ${vastaus.status_code} == 400
        Log    Palvelin hylkäsi tiedostonimen, mikä on hyväksyttävä tulos.
    ELSE
        Should Be Equal As Integers    ${vastaus.status_code}    201
        ${lataus}=    Tee Kirjautunut Pyynto    GET    /files/${vastaus.json()}[_id]/download
        Should Be Equal As Integers    ${lataus.status_code}    200
        ${otsake}=    Set Variable    ${lataus.headers}[Content-Disposition]
        Should Start With    ${otsake}    attachment
        ${lainausmerkit}=    Evaluate    $otsake.count('"')
        Should Be True    ${lainausmerkit} <= 2
        ...    msg=Tiedostonimen lainausmerkki rikkoo otsakkeen: ${otsake}
        Should Not Contain    ${otsake}    ../
        Should Not Contain    ${otsake}    \n
    END

Virheilmoitukset eivät paljasta sisäisiä tietoja
    [Documentation]    TC03-016. Odotettu tulos: rikkinäinen JSON hylätään vastauksella
    ...    400, eikä vastaus paljasta virhepinoa, tiedostopolkuja, kirjastojen nimiä
    ...    eikä tietokannan rakennetta. Sama tarkistetaan virheellisen tunnisteen ja
    ...    virheellisen syötteen vastauksista.
    [Tags]    api    tietoturva
    ${tunniste}=    Hae Kirjautumistunniste
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${tunniste}
    ...    Content-Type=application/json
    ${rikki}=    POST    ${API}/projects    data={"name": "Robot    headers=${otsakkeet}
    ...    expected_status=any
    Vastaus Ei Paljasta Sisaisia Tietoja    ${rikki}
    Should Be Equal As Integers    ${rikki.status_code}    400
    ...    msg=Rikkinäinen JSON palautti ${rikki.status_code}, odotettiin 400
    ${tunnus}=    Tee Kirjautunut Pyynto    GET    /projects/eiolemassa
    Vastaus Ei Paljasta Sisaisia Tietoja    ${tunnus}
    ${runko}=    Create Dictionary    name=Robot    status=hakkeroitu
    ${syote}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Tallenna Jos Luotiin    ${syote}    /projects
    Vastaus Ei Paljasta Sisaisia Tietoja    ${syote}

Vieras osoite ei saa CORS-lupaa
    [Documentation]    TC03-017. Odotettu tulos: kun pyyntö tulee vieraasta osoitteesta
    ...    (Origin), palvelin hylkää sen vastauksella 403 eikä anna sille lupaa
    ...    (Access-Control-Allow-Origin), jolloin selain estää vierasta sivustoa
    ...    lukemasta vastausta. Sovelluksen oma osoite saa luvan.
    [Tags]    api    tietoturva
    ${otsakkeet}=    Create Dictionary    Origin=${VIERAS_OSOITE}
    ${vieras}=    GET    ${API}/health    headers=${otsakkeet}    expected_status=any
    ${lupa}=    Get From Dictionary    ${vieras.headers}    Access-Control-Allow-Origin    ${EMPTY}
    Should Not Be Equal    ${lupa}    ${VIERAS_OSOITE}
    Should Not Be Equal    ${lupa}    *
    Should Be Equal As Integers    ${vieras.status_code}    403
    ${otsakkeet}=    Create Dictionary    Origin=${URL}
    ${oma}=    GET    ${API}/health    headers=${otsakkeet}    expected_status=any
    Should Be Equal    ${oma.headers}[Access-Control-Allow-Origin]    ${URL}

Pyyntörajoitus estää liialliset pyynnöt
    [Documentation]    TC03-018. Odotettu tulos: kun AI-reittien raja (60 pyyntöä 15
    ...    minuutissa) ylittyy, palvelin vastaa 429. Testi vaatii backendin
    ...    alkuperäiset pyyntörajat: testauksen ajaksi nostetulla AI-rajalla (600) 70
    ...    pyyntöä ei riitä rajan ylittämiseen. Testi lukitsee AI Assistantin
    ...    testitililtä 15 minuutiksi, joten se on merkitty tagilla hidas ja ajetaan
    ...    erikseen.
    [Tags]    api    tietoturva    hidas
    ${rajoitettu}=    Set Variable    ${False}
    FOR    ${i}    IN RANGE    70
        ${vastaus}=    Tee Kirjautunut Pyynto    GET    /ai/conversations
        IF    ${vastaus.status_code} == 429
            ${rajoitettu}=    Set Variable    ${True}
            BREAK
        END
    END
    Should Be True    ${rajoitettu}
    ...    msg=Palvelin ei rajoittanut 70 peräkkäistä pyyntöä. Tarkista, että backendin pyyntörajat ovat alkuperäiset.

Tehtävän kehäviittaus estetään
    [Documentation]    TC05-003. Odotettu tulos: tehtävää ei voi asettaa oman
    ...    alatehtävänsä alatehtäväksi, vaan muutos hylätään vastauksella 400.
    [Tags]    api
    ${runko}=    Create Dictionary    title=${ETULIITE} päätehtävä
    ${paa}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Tallenna Jos Luotiin    ${paa}    /tasks
    ${runko}=    Create Dictionary    title=${ETULIITE} alatehtävä    parentTaskId=${paa.json()}[_id]
    ${ala}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Tallenna Jos Luotiin    ${ala}    /tasks
    ${runko}=    Create Dictionary    parentTaskId=${ala.json()}[_id]
    ${vastaus}=    Tee Kirjautunut Pyynto    PATCH    /tasks/${paa.json()}[_id]    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    400

Kalenterin virheellinen aikaväli hylätään
    [Documentation]    TC09-005. Odotettu tulos: yli 366 päivän aikaväli hylätään
    ...    vastauksella 400.
    [Tags]    api
    [Template]    Kirjautunut Pyynto Palauttaa
    GET    /calendar-events?from=2026-01-01&to=2027-12-31    400
    GET    /calendar/items?from=2026-01-01&to=2027-12-31     400

Kalenterin virheelliset kellonajat hylätään
    [Documentation]    TC09-006. Odotettu tulos: virheellinen kellonaika tai
    ...    loppuaika ennen alkuaikaa hylätään vastauksella 400.
    [Tags]    api
    Luonti Palauttaa 400    /calendar-events    title=${ETULIITE} merkintä    date=2026-06-15
    ...    allDay=${False}    startTime=25:99    endTime=26:00
    Luonti Palauttaa 400    /calendar-events    title=${ETULIITE} merkintä    date=2026-06-15
    ...    allDay=${False}    startTime=14:00    endTime=13:00


*** Keywords ***
Valmistele Validointitestit
    [Documentation]    Kirjautuu testitunnuksella, luo ajolle satunnaisen etuliitteen ja
    ...    XSS-testien projektin, jonka kuvauksessa on XSS-syöte, ja alustaa listan,
    ...    johon tallennetaan testien luomat tiedot siivousta varten.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${luodut}=    Create List
    Set Suite Variable    ${LUODUT}    ${luodut}
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    ${runko}=    Create Dictionary    name=${ETULIITE} XSS-projekti    description=${XSS_SYOTE}
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    Set Suite Variable    ${XSS_PROJEKTI_ID}    ${projekti.json()}[_id]

Tallenna Jos Luotiin
    [Documentation]    Jos pyyntö loi tiedon (201), tallennetaan sen polku siivousta varten.
    ...    Näin testin jäljiltä ei jää dataa, vaikka validointi pettäisi.
    [Arguments]    ${vastaus}    ${polku}
    IF    ${vastaus.status_code} == 201
        Append To List    ${LUODUT}    ${polku}/${vastaus.json()}[_id]
    END

Kirjautunut Pyynto Palauttaa
    [Documentation]    Lähettää pyynnön kirjautuneena ja tarkistaa tilakoodin.
    [Arguments]    ${metodi}    ${polku}    ${odotettu}
    ${vastaus}=    Tee Kirjautunut Pyynto    ${metodi}    ${polku}
    Should Be Equal As Integers    ${vastaus.status_code}    ${odotettu}
    ...    msg=${metodi} ${polku} palautti ${vastaus.status_code}, odotettiin ${odotettu}

Luonti Palauttaa 400
    [Documentation]    Yrittää luoda tiedon annetuilla kentillä ja tarkistaa, että
    ...    vastaus on 400. Jos tieto silti luotiin, se tallennetaan siivousta varten.
    [Arguments]    ${polku}    &{kentat}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    ${polku}    ${kentat}
    Tallenna Jos Luotiin    ${vastaus}    ${polku}
    Should Be Equal As Integers    ${vastaus.status_code}    400
    ...    msg=POST ${polku} palautti ${vastaus.status_code}, odotettiin 400

Tyyppi Hylataan
    [Documentation]    Lähettää Python-muodossa annetun rungon ja tarkistaa, että
    ...    vastaus on 400.
    [Arguments]    ${polku}    ${runko_teksti}
    ${runko}=    Evaluate    ${runko_teksti}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    ${polku}    ${runko}
    Tallenna Jos Luotiin    ${vastaus}    ${polku}
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Integers    ${vastaus.status_code}    400
    ...    msg=POST ${polku} ${runko_teksti} palautti ${vastaus.status_code}, odotettiin 400

XSS Nakyy Tekstina Eika Suoritu
    [Documentation]    Tarkistaa, että XSS-syöte näkyy sivulla tekstinä ja ettei sen
    ...    koodi suorittunut (window.__xss puuttuu).
    Wait For Load State    networkidle    timeout=10s
    Get Text    body    contains    ${XSS_SYOTE}
    ${suoritettiin}=    Evaluate JavaScript    ${None}    () => window.__xss === 1
    Should Not Be True    ${suoritettiin}    msg=XSS-syötteen koodi suoritettiin

Vastaus Ei Paljasta Sisaisia Tietoja
    [Documentation]    Tarkistaa, ettei virhevastaus sisällä virhepinoa, tiedostopolkuja,
    ...    kirjastojen nimiä eikä tietokannan sisäisiä termejä.
    [Arguments]    ${vastaus}
    FOR    ${sana}    IN    at Object.    node_modules    SyntaxError    Mongoose
    ...    CastError    ValidationError    stack    \\backend\\    /backend/
        Run Keyword And Continue On Failure    Should Not Contain    ${vastaus.text}    ${sana}
        ...    msg=Vastaus paljastaa sisäistä tietoa (${sana}): ${vastaus.text}
    END

Siivoa Validointitestit
    [Documentation]    Poistaa testien luomat tiedot käänteisessä järjestyksessä, jotta
    ...    alatehtävät, tiedostot ja muistiinpanot poistuvat ennen kansioita ja
    ...    projekteja, ja lopuksi XSS-projektin tehtävineen.
    Reverse List    ${LUODUT}
    FOR    ${polku}    IN    @{LUODUT}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    ${polku}
    END
    ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${XSS_PROJEKTI_ID}
    FOR    ${tehtava}    IN    @{tehtavat.json()}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava}[_id]
    END
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${XSS_PROJEKTI_ID}
    Close Browser