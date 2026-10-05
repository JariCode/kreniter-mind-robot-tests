*** Settings ***
Documentation    Testijoukko 3: Käyttäjäeristys rajapinnassa.
...    Kaksi käyttäjää on kirjautuneena yhtä aikaa omissa selainistunnoissaan.
...    Käyttäjä A luo tietoja, ja käyttäjä B yrittää lukea, muokata ja poistaa niitä
...    sekä liittää omia tietojaan niihin. Toisen käyttäjän tiedon pitää näyttää
...    olemattomalta (404). Testataan myös massasijoitus ja poistetun käyttäjän
...    vanhan kirjautumistunnisteen hylkääminen.
...    Kattaa testitapaukset TC02-005 - TC02-016.
...    Esivaatimukset: .env-tiedoston testitili (käyttäjä A) on luotu sovellukseen,
...    ja Renderin backend on käynnissä (TC02-016 poistaa käyttäjän B webhookin kautta).
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Kaksi Kayttajaa
Suite Teardown    Siivoa Kayttajien Tiedot


*** Variables ***
${KALENTERIVALI}    ?from=2026-01-01&to=2026-12-31


*** Test Cases ***
Toinen käyttäjä ei näe projektia
    [Documentation]    TC02-005. Odotettu tulos: käyttäjä B ei voi lukea, muokata eikä
    ...    poistaa käyttäjän A projektia. Jokainen yritys palauttaa 404.
    [Tags]    api    tietoturva
    [Template]    Kayttaja B Saa 404
    GET       /projects/${PROJEKTI_ID}
    PATCH     /projects/${PROJEKTI_ID}
    DELETE    /projects/${PROJEKTI_ID}
    GET       /projects/${PROJEKTI_ID}/delete-preview

Toinen käyttäjä ei näe tehtävää
    [Documentation]    TC02-006. Odotettu tulos: käyttäjä B ei voi lukea, muokata eikä
    ...    poistaa käyttäjän A tehtävää.
    [Tags]    api    tietoturva
    [Template]    Kayttaja B Saa 404
    GET       /tasks/${TEHTAVA_ID}
    PATCH     /tasks/${TEHTAVA_ID}
    DELETE    /tasks/${TEHTAVA_ID}
    GET       /tasks/${TEHTAVA_ID}/delete-preview

Toinen käyttäjä ei näe muistiinpanoa
    [Documentation]    TC02-007. Odotettu tulos: käyttäjä B ei voi lukea, muokata eikä
    ...    poistaa käyttäjän A muistiinpanoa.
    [Tags]    api    tietoturva
    [Template]    Kayttaja B Saa 404
    GET       /notes/${MUISTIINPANO_ID}
    PATCH     /notes/${MUISTIINPANO_ID}
    DELETE    /notes/${MUISTIINPANO_ID}

Toinen käyttäjä ei voi muokata kansiota
    [Documentation]    TC02-008. Odotettu tulos: käyttäjä B ei voi nimetä uudelleen eikä
    ...    poistaa käyttäjän A kansiota.
    [Tags]    api    tietoturva
    [Template]    Kayttaja B Saa 404
    PUT       /folders/${KANSIO_ID}
    DELETE    /folders/${KANSIO_ID}

Toinen käyttäjä ei voi muokata kalenterimerkintää
    [Documentation]    TC02-009. Odotettu tulos: käyttäjä B ei voi muokata eikä poistaa
    ...    käyttäjän A kalenterimerkintää. Muokkauksessa lähetetään kelvollinen
    ...    merkintä, jotta pyyntö läpäisee validoinnin ja pääsee omistajuustarkistukseen.
    [Tags]    api    tietoturva
    [Template]    Kayttaja B Saa 404
    PATCH     /calendar-events/${MERKINTA_ID}    ${KELVOLLINEN_MERKINTA}
    DELETE    /calendar-events/${MERKINTA_ID}

Toisen käyttäjän tiedot eivät näy omissa listoissa
    [Documentation]    TC02-010. Odotettu tulos: käyttäjän B projekti-, tehtävä-,
    ...    muistiinpano-, kansio-, kalenterimerkintä- ja kalenterinäkymän listoissa ei
    ...    ole yhtään käyttäjän A tietoa. Kalenterinäkymän lista sisältää myös tehtävien
    ...    eräpäivät, joten A:n tehtävällä on eräpäivä.
    [Tags]    api    tietoturva
    Vaihda Kayttajaan    B
    Lista Ei Sisalla    /projects    ${PROJEKTI_ID}
    Lista Ei Sisalla    /tasks    ${TEHTAVA_ID}
    Lista Ei Sisalla    /notes    ${MUISTIINPANO_ID}
    Lista Ei Sisalla    /folders?projectId=${PROJEKTI_ID}    ${KANSIO_ID}
    Lista Ei Sisalla    /calendar-events${KALENTERIVALI}    ${MERKINTA_ID}
    Lista Ei Sisalla    /calendar/items${KALENTERIVALI}    ${TEHTAVA_ID}
    Lista Ei Sisalla    /calendar/items${KALENTERIVALI}    ${MERKINTA_ID}

Omat tiedot säilyvät ennallaan
    [Documentation]    TC02-011. Odotettu tulos: käyttäjän B yritysten jälkeen käyttäjän A
    ...    projekti, tehtävä ja muistiinpano ovat yhä olemassa ja muuttumattomia.
    [Tags]    api    tietoturva
    Vaihda Kayttajaan    A
    ${projekti}=    Tee Kirjautunut Pyynto    GET    /projects/${PROJEKTI_ID}
    Should Be Equal As Integers    ${projekti.status_code}    200
    Should Be Equal    ${projekti.json()}[name]    ${ETULIITE} eristysprojekti
    ${tehtava}=    Tee Kirjautunut Pyynto    GET    /tasks/${TEHTAVA_ID}
    Should Be Equal As Integers    ${tehtava.status_code}    200
    Should Be Equal    ${tehtava.json()}[title]    ${ETULIITE} eristystehtävä
    ${muistiinpano}=    Tee Kirjautunut Pyynto    GET    /notes/${MUISTIINPANO_ID}
    Should Be Equal As Integers    ${muistiinpano.status_code}    200
    Should Be Equal    ${muistiinpano.json()}[title]    ${ETULIITE} eristysmuistiinpano

Toinen käyttäjä ei pääse tiedostoon
    [Documentation]    TC02-012. Odotettu tulos: käyttäjä B ei voi ladata, nimetä
    ...    uudelleen, siirtää, muokata sisältöä eikä poistaa käyttäjän A tiedostoa, eikä
    ...    tiedosto näy B:lle A:n projektin tiedostolistassa. A:n tiedoston sisältö on
    ...    lopuksi ennallaan. Sisällön muokkaus lähettää uuden tiedoston lomakelatauksena,
    ...    kuten sovellus, jotta pyyntö pääsee omistajuustarkistukseen asti.
    [Tags]    api    tietoturva
    ${uusi_nimi}=    Create Dictionary    name=Muokattu.txt
    ${siirto}=    Create Dictionary    folderId=${KANSIO_ID}
    Kayttaja B Saa 404    GET       /files/${TIEDOSTO_ID}/download
    Kayttaja B Saa 404    PUT       /files/${TIEDOSTO_ID}    ${uusi_nimi}
    Kayttaja B Saa 404    PUT       /files/${TIEDOSTO_ID}    ${siirto}
    Kayttaja B Saa 404    DELETE    /files/${TIEDOSTO_ID}
    Vaihda Kayttajaan    B
    ${muokkaus}=    Korvaa Tiedoston Sisalto    ${TIEDOSTO_ID}    B:n muokkaama sisältö
    Should Be Equal As Integers    ${muokkaus.status_code}    404
    ...    msg=Sisällön muokkaus palautti ${muokkaus.status_code}, odotettiin 404
    ${lista}=    Tee Kirjautunut Pyynto    GET    /files?projectId=${PROJEKTI_ID}
    Should Not Contain    ${lista.text}    ${TIEDOSTO_ID}
    Vaihda Kayttajaan    A
    ${oma}=    Tee Kirjautunut Pyynto    GET    /files/${TIEDOSTO_ID}/download
    Should Be Equal As Integers    ${oma.status_code}    200
    Should Be Equal    ${oma.content.decode('utf-8')}    A:n tiedosto

Massasijoitus ei vaihda tiedon omistajaa
    [Documentation]    TC02-013. Odotettu tulos: kun käyttäjä A lähettää luontipyynnön
    ...    mukana käyttäjän B tunnisteen (userId), palvelin ohittaa sen. Tieto tallentuu
    ...    käyttäjälle A, eikä käyttäjä B näe sitä.
    [Tags]    api    tietoturva
    Vaihda Kayttajaan    A
    ${runko}=    Create Dictionary    name=${ETULIITE} massasijoitus    userId=${KAYTTAJA_B_ID}
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    ${massa_id}=    Set Variable    ${projekti.json()}[_id]
    Set Suite Variable    ${MASSA_PROJEKTI_ID}    ${massa_id}
    ${runko}=    Create Dictionary    title=${ETULIITE} massatehtävä    projectId=${massa_id}
    ...    userId=${KAYTTAJA_B_ID}
    ${tehtava}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${tehtava.status_code}    201
    ${oma}=    Tee Kirjautunut Pyynto    GET    /projects/${massa_id}
    Should Be Equal As Integers    ${oma.status_code}    200
    Vaihda Kayttajaan    B
    ${vieras}=    Tee Kirjautunut Pyynto    GET    /projects/${massa_id}
    Should Be Equal As Integers    ${vieras.status_code}    404
    Lista Ei Sisalla    /tasks    ${ETULIITE} massatehtävä

Omia tietoja ei voi liittää toisen käyttäjän tietoihin
    [Documentation]    TC02-014. Odotettu tulos: käyttäjä B ei voi luoda tehtävää,
    ...    muistiinpanoa, kalenterimerkintää eikä kansiota käyttäjän A projektiin, ei
    ...    alatehtävää A:n tehtävän alle, eikä ladata tai siirtää tiedostoa A:n kansioon.
    ...    Jokainen yritys hylätään (400 tai 404), eikä mitään tallennu A:n tietoihin.
    [Tags]    api    tietoturva
    Vaihda Kayttajaan    B
    ${otsikko}=    Set Variable    ${ETULIITE} vieras
    ${runko}=    Create Dictionary    title=${otsikko} tehtävä    projectId=${PROJEKTI_ID}
    Kayttaja B Hylataan    POST    /tasks    ${runko}
    ${runko}=    Create Dictionary    title=${otsikko} alatehtävä    parentTaskId=${TEHTAVA_ID}
    Kayttaja B Hylataan    POST    /tasks    ${runko}
    ${runko}=    Create Dictionary    title=${otsikko} muistiinpano    projectId=${PROJEKTI_ID}
    Kayttaja B Hylataan    POST    /notes    ${runko}
    ${runko}=    Create Dictionary    title=${otsikko} merkintä    date=2026-06-20
    ...    allDay=${True}    projectId=${PROJEKTI_ID}
    Kayttaja B Hylataan    POST    /calendar-events    ${runko}
    ${runko}=    Create Dictionary    name=${otsikko} kansio    projectId=${PROJEKTI_ID}
    Kayttaja B Hylataan    POST    /folders    ${runko}
    ${runko}=    Create Dictionary    name=${otsikko} alikansio    parentFolderId=${KANSIO_ID}
    Kayttaja B Hylataan    POST    /folders    ${runko}
    ${lataus}=    Lataa Tiedosto Rajapinnalla    ${otsikko}.txt    Vieras tiedosto
    ...    kansio_id=${KANSIO_ID}
    Should Be True    ${lataus.status_code} in (400, 404)
    ...    msg=Tiedoston lataus A:n kansioon palautti ${lataus.status_code}
    ${siirto}=    Create Dictionary    folderId=${KANSIO_ID}
    Kayttaja B Hylataan    PUT    /files/${B_TIEDOSTO_ID}    ${siirto}
    Vaihda Kayttajaan    A
    Lista Ei Sisalla    /tasks?projectId=${PROJEKTI_ID}    ${otsikko}
    Lista Ei Sisalla    /notes    ${otsikko}
    Lista Ei Sisalla    /folders?projectId=${PROJEKTI_ID}    ${otsikko}
    Lista Ei Sisalla    /files?projectId=${PROJEKTI_ID}&folderId=${KANSIO_ID}    ${otsikko}

Toinen käyttäjä ei pääse aikakirjauksiin, ajastimeen eikä näkymävalintoihin
    [Documentation]    TC02-015. Odotettu tulos: käyttäjä B ei näe, muokkaa eikä poista
    ...    käyttäjän A aikakirjausta. Kun A:lla on ajastin käynnissä, B ei näe sitä eikä
    ...    voi tauottaa, jatkaa tai pysäyttää sitä, eikä B voi käynnistää ajastinta A:n
    ...    tehtävälle. B ei myöskään voi tallentaa A:n projektia omaksi
    ...    näkymävalinnakseen. A:n ajastin on lopuksi edelleen käynnissä.
    [Tags]    api    tietoturva
    Vaihda Kayttajaan    B
    Lista Ei Sisalla    /time-entries    ${AIKAKIRJAUS_ID}
    ${runko}=    Create Dictionary    description=Muokattu
    Kayttaja B Saa 404    GET       /time-entries/${AIKAKIRJAUS_ID}
    Kayttaja B Saa 404    PATCH     /time-entries/${AIKAKIRJAUS_ID}    ${runko}
    Kayttaja B Saa 404    DELETE    /time-entries/${AIKAKIRJAUS_ID}
    Vaihda Kayttajaan    A
    ${nyt}=    Evaluate    int(time.time() * 1000)    modules=time
    ${runko}=    Create Dictionary    taskId=${TEHTAVA_ID}    projectId=${PROJEKTI_ID}    now=${nyt}
    ${a_ajastin}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${a_ajastin.status_code}    201
    Vaihda Kayttajaan    B
    ${b_ajastin}=    Tee Kirjautunut Pyynto    GET    /active-timer
    Should Be Equal As Integers    ${b_ajastin.status_code}    200
    Should Be Equal    ${b_ajastin.json()}    ${None}    msg=B näki A:n ajastimen
    ${nyt}=    Evaluate    int(time.time() * 1000)    modules=time
    ${aikaleima}=    Create Dictionary    now=${nyt}
    Kayttaja B Saa 404    POST    /active-timer/pause    ${aikaleima}
    Kayttaja B Saa 404    POST    /active-timer/resume    ${aikaleima}
    Kayttaja B Saa 404    POST    /active-timer/stop    ${aikaleima}
    ${runko}=    Create Dictionary    taskId=${TEHTAVA_ID}    projectId=${PROJEKTI_ID}    now=${nyt}
    Kayttaja B Hylataan    POST    /active-timer/start    ${runko}
    Vaihda Kayttajaan    A
    ${tarkistus}=    Tee Kirjautunut Pyynto    GET    /active-timer
    Should Not Be Equal    ${tarkistus.json()}    ${None}    msg=A:n ajastin pysähtyi
    Tee Kirjautunut Pyynto    DELETE    /active-timer
    Vaihda Kayttajaan    B
    ${runko}=    Create Dictionary    selectedProjectId=${PROJEKTI_ID}
    Kayttaja B Hylataan    PUT    /tasks-view    ${runko}
    Kayttaja B Hylataan    PUT    /time-view    ${runko}
    Kayttaja B Hylataan    PUT    /timeline    ${runko}
    Kayttaja B Hylataan    PUT    /reports-view    ${runko}

Poistetun käyttäjän tunniste hylätään
    [Documentation]    TC02-016. Odotettu tulos: kun käyttäjä B poistaa tilinsä, hänen
    ...    vielä voimassa oleva kirjautumistunnisteensa hylätään (401) jo ennen kuin
    ...    tunniste vanhenee, eikä poistettua käyttäjää luoda uudelleen. Testi tarkistaa,
    ...    että hylkäys tapahtuu tunnisteen voimassaoloaikana, jottei vanhentuminen
    ...    hämää tulosta. Tämä testi poistaa käyttäjän B, joten se on viimeisenä.
    [Tags]    api    tietoturva
    Vaihda Kayttajaan    B
    ${tunniste}=    Hae Kirjautumistunniste
    ${vanhenee}=    Tunnisteen Vanhenemisaika    ${tunniste}
    Poista Tili Sovelluksesta
    Set Suite Variable    ${B_POISTETTU}    ${True}
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${tunniste}
    ${hylatty}=    Set Variable    ${False}
    FOR    ${i}    IN RANGE    30
        ${nyt}=    Evaluate    int(time.time())    modules=time
        IF    ${nyt} >= ${vanhenee}    BREAK
        ${vastaus}=    GET    ${API}/projects    headers=${otsakkeet}    expected_status=any
        IF    ${vastaus.status_code} == 401
            ${hylatty}=    Set Variable    ${True}
            BREAK
        END
        Sleep    2s
    END
    Should Be True    ${hylatty}
    ...    msg=Poistetun käyttäjän tunniste toimi koko voimassaoloaikansa


*** Keywords ***
Valmistele Kaksi Kayttajaa
    [Documentation]    Kirjaa käyttäjän A sisään ja luo hänelle testitiedot. Rekisteröi
    ...    käyttäjän B toiseen selainistuntoon ja luo hänelle oman tiedoston siirtotestiä
    ...    varten. Istuntojen tunnisteet tallennetaan, jotta käyttäjien välillä voidaan
    ...    vaihtaa. Käyttäjän B tunniste luetaan /users/me-vastauksen user-kentästä.
    Set Suite Variable    ${B_POISTETTU}    ${False}
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    Avaa Selain
    ${konteksti_a}=    New Context    viewport={'width': 1280, 'height': 900}
    New Page    ${URL}
    Kirjaudu Sisaan
    Set Suite Variable    ${KONTEKSTI_A}    ${konteksti_a}
    Luo Kayttajan A Testitiedot
    ${konteksti_b}=    New Context    viewport={'width': 1280, 'height': 900}
    New Page    ${URL}
    ${sahkoposti}=    Luo Testisahkoposti
    Rekisteroidy    ${sahkoposti}
    Set Suite Variable    ${KONTEKSTI_B}    ${konteksti_b}
    ${b}=    Tee Kirjautunut Pyynto    GET    /users/me
    Should Be Equal As Integers    ${b.status_code}    200
    Set Suite Variable    ${KAYTTAJA_B_ID}    ${b.json()}[user][_id]
    ${b_tiedosto}=    Lataa Tiedosto Rajapinnalla    ${ETULIITE} B-tiedosto.txt    B:n oma tiedosto
    Should Be Equal As Integers    ${b_tiedosto.status_code}    201
    Set Suite Variable    ${B_TIEDOSTO_ID}    ${b_tiedosto.json()}[_id]
    ${kelvollinen}=    Create Dictionary    title=Muokattu    date=2026-06-16    allDay=${True}
    Set Suite Variable    ${KELVOLLINEN_MERKINTA}    ${kelvollinen}

Luo Kayttajan A Testitiedot
    [Documentation]    Luo käyttäjälle A projektin, tehtävän (eräpäivällä), muistiinpanon,
    ...    kansion, kalenterimerkinnän, tiedoston ja aikakirjauksen rajapinnan kautta ja
    ...    tallentaa niiden tunnisteet.
    ${runko}=    Create Dictionary    name=${ETULIITE} eristysprojekti
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    Set Suite Variable    ${PROJEKTI_ID}    ${projekti.json()}[_id]

    ${runko}=    Create Dictionary    title=${ETULIITE} eristystehtävä    projectId=${PROJEKTI_ID}
    ...    dueDate=2026-06-15
    ${tehtava}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${tehtava.status_code}    201
    Set Suite Variable    ${TEHTAVA_ID}    ${tehtava.json()}[_id]

    ${runko}=    Create Dictionary    title=${ETULIITE} eristysmuistiinpano    projectId=${PROJEKTI_ID}
    ${muistiinpano}=    Tee Kirjautunut Pyynto    POST    /notes    ${runko}
    Should Be Equal As Integers    ${muistiinpano.status_code}    201
    Set Suite Variable    ${MUISTIINPANO_ID}    ${muistiinpano.json()}[_id]

    ${runko}=    Create Dictionary    name=${ETULIITE} eristyskansio    projectId=${PROJEKTI_ID}
    ${kansio}=    Tee Kirjautunut Pyynto    POST    /folders    ${runko}
    Should Be Equal As Integers    ${kansio.status_code}    201
    Set Suite Variable    ${KANSIO_ID}    ${kansio.json()}[_id]

    ${runko}=    Create Dictionary    title=${ETULIITE} eristysmerkintä    date=2026-06-15
    ...    allDay=${True}
    ${merkinta}=    Tee Kirjautunut Pyynto    POST    /calendar-events    ${runko}
    Should Be Equal As Integers    ${merkinta.status_code}    201
    Set Suite Variable    ${MERKINTA_ID}    ${merkinta.json()}[_id]

    ${tiedosto}=    Lataa Tiedosto Rajapinnalla    ${ETULIITE} eristystiedosto.txt
    ...    A:n tiedosto    projekti_id=${PROJEKTI_ID}
    Should Be Equal As Integers    ${tiedosto.status_code}    201
    Set Suite Variable    ${TIEDOSTO_ID}    ${tiedosto.json()}[_id]

    Kirjaa Aikaa Rajapinnalla    ${PROJEKTI_ID}    ${TEHTAVA_ID}
    ${kirjaukset}=    Tee Kirjautunut Pyynto    GET    /time-entries
    ${tunnisteet}=    Evaluate
    ...    [m['_id'] for m in $kirjaukset.json() if (m['taskId']['_id'] if isinstance(m.get('taskId'), dict) else m.get('taskId')) == $TEHTAVA_ID]
    Should Not Be Empty    ${tunnisteet}
    Set Suite Variable    ${AIKAKIRJAUS_ID}    ${tunnisteet}[0]

Vaihda Kayttajaan
    [Documentation]    Vaihtaa aktiivisen selainistunnon käyttäjän A tai B istuntoon.
    ...    Kirjautumistunniste haetaan aina aktiivisesta istunnosta.
    [Arguments]    ${kayttaja}
    IF    '${kayttaja}' == 'A'
        Switch Context    ${KONTEKSTI_A}
    ELSE
        Switch Context    ${KONTEKSTI_B}
    END

Kayttaja B Saa 404
    [Documentation]    Lähettää pyynnön käyttäjänä B ja tarkistaa, että vastaus on 404.
    ...    Jos bodya ei anneta, käytetään yksinkertaista muokkausta.
    [Arguments]    ${metodi}    ${polku}    ${runko}=${None}
    Vaihda Kayttajaan    B
    IF    $runko is None
        ${runko}=    Create Dictionary    name=Muokattu    title=Muokattu
    END
    ${vastaus}=    Tee Kirjautunut Pyynto    ${metodi}    ${polku}    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    404
    ...    msg=${metodi} ${polku} palautti ${vastaus.status_code}, odotettiin 404

Kayttaja B Hylataan
    [Documentation]    Lähettää pyynnön käyttäjänä B ja tarkistaa, että palvelin hylkää
    ...    sen (400 tai 404). Molemmat ovat hyväksyttäviä, koska ne estävät toiminnon.
    [Arguments]    ${metodi}    ${polku}    ${runko}
    Vaihda Kayttajaan    B
    ${vastaus}=    Tee Kirjautunut Pyynto    ${metodi}    ${polku}    ${runko}
    Should Be True    ${vastaus.status_code} in (400, 404)
    ...    msg=${metodi} ${polku} palautti ${vastaus.status_code}, odotettiin 400 tai 404

Korvaa Tiedoston Sisalto
    [Documentation]    Lähettää tiedostolle uuden sisällön aktiivisena käyttäjänä samalla
    ...    tavalla kuin sovelluksen editori: uusi tiedosto lomakelatauksena (multipart).
    ...    Palauttaa vastauksen tarkistamatta tilakoodia.
    [Arguments]    ${tiedosto_id}    ${sisalto}
    ${tunniste}=    Hae Kirjautumistunniste
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${tunniste}
    ${tiedosto}=    Evaluate    {'file': ('muokattu.txt', $sisalto.encode('utf-8'), 'text/plain')}
    ${vastaus}=    PUT    ${API}/files/${tiedosto_id}/content    headers=${otsakkeet}
    ...    files=${tiedosto}    expected_status=any
    RETURN    ${vastaus}

Lista Ei Sisalla
    [Documentation]    Hakee listan aktiivisena käyttäjänä ja tarkistaa, ettei siinä ole
    ...    annettua tunnistetta tai tekstiä. Jos palvelin hylkää koko haun (404),
    ...    tietoa ei myöskään näy.
    [Arguments]    ${polku}    ${etsittava}
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    ${polku}
    Should Be True    ${vastaus.status_code} in (200, 404)
    ...    msg=${polku} palautti ${vastaus.status_code}
    Should Not Contain    ${vastaus.text}    ${etsittava}
    ...    msg=${polku} palautti toisen käyttäjän tiedon ${etsittava}

Siivoa Kayttajien Tiedot
    [Documentation]    Poistaa käyttäjän A ajastimen ja testitiedot rajapinnan kautta
    ...    sekä käyttäjän B tilin sovelluksen kautta, jos testi TC02-016 ei jo poistanut
    ...    sitä. Tiedosto poistetaan ennen kansiota ja tehtävät ennen projektia, koska
    ...    ei-tyhjää kansiota tai projektia ei voi poistaa. Jos jokin poisto epäonnistuu,
    ...    raporttiin tulee varoitus.
    Run Keyword And Ignore Error    Vaihda Kayttajaan    A
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    Poista Ja Varoita    /calendar-events/${MERKINTA_ID}
    Poista Ja Varoita    /files/${TIEDOSTO_ID}
    Poista Ja Varoita    /folders/${KANSIO_ID}
    Poista Ja Varoita    /notes/${MUISTIINPANO_ID}
    Poista Ja Varoita    /tasks/${TEHTAVA_ID}
    Poista Ja Varoita    /projects/${PROJEKTI_ID}
    ${massa}=    Get Variable Value    ${MASSA_PROJEKTI_ID}    ${None}
    IF    $massa
        ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${massa}
        FOR    ${tehtava}    IN    @{tehtavat.json()}
            Poista Ja Varoita    /tasks/${tehtava}[_id]
        END
        Poista Ja Varoita    /projects/${massa}
    END
    IF    not ${B_POISTETTU}
        Run Keyword And Ignore Error    Vaihda Kayttajaan    B
        Run Keyword And Ignore Error    Poista Tili Sovelluksesta
    END
    Close Browser

Poista Ja Varoita
    [Documentation]    Poistaa tiedon ja kirjoittaa raporttiin varoituksen, jos poisto
    ...    epäonnistuu. Siivous jatkuu silti seuraavaan kohtaan.
    [Arguments]    ${polku}
    ${tila}    ${vastaus}=    Run Keyword And Ignore Error
    ...    Tee Kirjautunut Pyynto    DELETE    ${polku}
    IF    '${tila}' == 'FAIL'
        Log    Siivous epäonnistui: DELETE ${polku}: ${vastaus}    WARN
    ELSE IF    ${vastaus.status_code} >= 300
        Log    Siivous epäonnistui: DELETE ${polku} palautti ${vastaus.status_code}: ${vastaus.text}
        ...    WARN
    END