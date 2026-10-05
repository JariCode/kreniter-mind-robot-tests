*** Settings ***
Documentation    Testijoukko 7: Ajanseuranta.
...    Testaa ajastimen käynnistyksen, tauon, jatkamisen ja pysäytyksen selaimessa,
...    ajastimen säilymisen sivun päivityksen yli, kahden välilehden synkronoinnin,
...    ajan laskennan ja ristiriitojen käsittelyn rajapinnassa, ajastimen poiston
...    tehtävän mukana, aikakirjausten muokkauksen ja poiston, ajastimen vaihdon
...    toiseen tehtävään sekä Time-sivun projektivalinnan säilymisen.
...    Kattaa testitapaukset TC06-001 - TC06-012 ja TC06-015.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Ajanseurantatestit
Suite Teardown    Siivoa Ajanseurantatestit
Test Setup    Valmistele Ajastintesti


*** Test Cases ***
Ajastimen käynnistys tehtävästä
    [Documentation]    TC06-001. Odotettu tulos: Start-painikkeesta käynnistetty ajastin
    ...    näkyy tehtäväkortissa tilalla Tracking.
    [Tags]    selain
    Click    ${TEHTAVAKORTTI} >> button >> text="Start"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    visible    timeout=10s
    Get Text    ${TEHTAVAKORTTI} >> .task-timer-active    contains    Tracking

Ajastimen tauko ja jatkaminen
    [Documentation]    TC06-002. Odotettu tulos: Pause vaihtaa tilaksi Paused ja Resume
    ...    takaisin tilaksi Tracking.
    [Tags]    selain
    Click    ${TEHTAVAKORTTI} >> button >> text="Start"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    visible    timeout=10s
    Click    ${TEHTAVAKORTTI} >> button >> text="Pause"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active >> text=/Paused/
    ...    visible    timeout=10s
    Click    ${TEHTAVAKORTTI} >> button >> text="Resume"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active >> text=/Tracking/
    ...    visible    timeout=10s

Ajastimen pysäytys tallentaa ajan
    [Documentation]    TC06-003. Odotettu tulos: Stop pysäyttää ajastimen, ajastin katoaa
    ...    kortista ja tehtävälle tallentuu aikakirjaus.
    [Tags]    selain
    ${ennen}=    Tehtavan Aikakirjausten Kestot
    Click    ${TEHTAVAKORTTI} >> button >> text="Start"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    visible    timeout=10s
    Sleep    2s
    Click    ${TEHTAVAKORTTI} >> button >> text="Stop"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    detached    timeout=10s
    ${jalkeen}=    Tehtavan Aikakirjausten Kestot
    ${uusia}=    Evaluate    len($jalkeen) - len($ennen)
    Should Be Equal As Integers    ${uusia}    1

Ajastin säilyy sivun päivityksen yli
    [Documentation]    TC06-004. Odotettu tulos: käynnissä oleva ajastin näkyy edelleen
    ...    sivun päivityksen jälkeen.
    [Tags]    selain
    Click    ${TEHTAVAKORTTI} >> button >> text="Start"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    visible    timeout=10s
    Reload
    Mene Testitehtavaan
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    visible    timeout=10s

Ajastin synkronoituu välilehtien välillä
    [Documentation]    TC06-005. Odotettu tulos: kun ajastin pysäytetään toisessa
    ...    välilehdessä, ensimmäinen välilehti päivittyy ilman sivun päivitystä.
    [Tags]    selain
    Click    ${TEHTAVAKORTTI} >> button >> text="Start"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    visible    timeout=10s
    ${ensimmainen}=    Get Page Ids    CURRENT    CURRENT    CURRENT
    New Page    ${URL}
    Mene Testitehtavaan
    Click    ${TEHTAVAKORTTI} >> button >> text="Stop"
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    detached    timeout=10s
    Close Page    CURRENT
    Switch Page    ${ensimmainen}[0]
    Wait For Elements State    ${TEHTAVAKORTTI} >> .task-timer-active    detached    timeout=10s

Toista ajastinta ei voi käynnistää päällekkäin
    [Documentation]    TC06-006. Odotettu tulos: kun ajastin on jo käynnissä, uuden
    ...    käynnistys hylätään vastauksella 409.
    [Tags]    api
    ${nyt}=    Nykyhetki Millisekunteina
    ${runko}=    Create Dictionary    taskId=${TEHTAVA_ID}    projectId=${PROJEKTI_ID}    now=${nyt}
    ${eka}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${eka.status_code}    201
    ${toka}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${toka.status_code}    409

Taukoa ei voi tehdä ilman ajastinta
    [Documentation]    TC06-007. Odotettu tulos: kun ajastinta ei ole, tauko palauttaa 404.
    [Tags]    api
    ${nyt}=    Nykyhetki Millisekunteina
    ${runko}=    Create Dictionary    now=${nyt}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/pause    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    404

Kirjattu aika lasketaan oikein
    [Documentation]    TC06-008. Odotettu tulos: ajastin käynnistetään ja pysäytetään
    ...    viiden minuutin välein olevilla aikaleimoilla, ja aikakirjauksen kesto on
    ...    tasan 5 minuuttia. Aikaleimat ovat 2,5 minuuttia nykyhetken kummallakin
    ...    puolella, jotta ne mahtuvat palvelimen 5 minuutin toleranssiin.
    [Tags]    api
    ${ennen}=    Tehtavan Aikakirjausten Kestot
    ${alku}=    Evaluate    int(time.time() * 1000) - 150000    modules=time
    ${loppu}=    Evaluate    ${alku} + 300000
    ${runko}=    Create Dictionary    taskId=${TEHTAVA_ID}    projectId=${PROJEKTI_ID}    now=${alku}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    ${runko}=    Create Dictionary    now=${loppu}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/stop    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${jalkeen}=    Tehtavan Aikakirjausten Kestot
    ${uudet}=    Evaluate    $jalkeen[len($ennen):]
    Should Be Equal As Integers    ${uudet}[0]    5

Epäuskottava aikaleima hylätään
    [Documentation]    TC06-009. Odotettu tulos: pysäytys aikaleimalla, joka on 100 päivää
    ...    tulevaisuudessa, hylätään vastauksella 400, eikä aikakirjausta tallenneta.
    ...    Muuten käyttäjä voisi kirjata itselleen todellisuutta enemmän aikaa.
    [Tags]    api    tietoturva
    ${ennen}=    Tehtavan Aikakirjausten Kestot
    ${nyt}=    Nykyhetki Millisekunteina
    ${tulevaisuus}=    Evaluate    ${nyt} + 100 * 24 * 60 * 60 * 1000
    ${runko}=    Create Dictionary    taskId=${TEHTAVA_ID}    projectId=${PROJEKTI_ID}    now=${nyt}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    ${runko}=    Create Dictionary    now=${tulevaisuus}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/stop    ${runko}
    ${jalkeen}=    Tehtavan Aikakirjausten Kestot
    Should Be Equal As Integers    ${vastaus.status_code}    400
    Length Should Be    ${jalkeen}    ${{len($ennen)}}

Tehtävän poisto poistaa käynnissä olevan ajastimen
    [Documentation]    TC06-010. Odotettu tulos: kun tehtävä, jonka ajastin on käynnissä,
    ...    poistetaan, myös ajastin poistuu, eikä käynnissä olevaa ajastinta enää ole.
    [Tags]    api
    ${tehtava_id}=    Luo Tehtava    ${ETULIITE} poistuva ajastin
    ${nyt}=    Nykyhetki Millisekunteina
    ${runko}=    Create Dictionary    taskId=${tehtava_id}    projectId=${PROJEKTI_ID}    now=${nyt}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    ${vastaus}=    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava_id}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${ajastin}=    Tee Kirjautunut Pyynto    GET    /active-timer
    Should Be Equal As Integers    ${ajastin.status_code}    200
    Should Be Equal    ${ajastin.json()}    ${None}
    ...    msg=Ajastin jäi käyntiin poistetulle tehtävälle: ${ajastin.text}

Aikakirjauksen muokkaus ja poisto näkyvät Time-sivulla
    [Documentation]    TC06-011. Odotettu tulos: tehtävälle kirjattu 5 minuuttia näkyy
    ...    Time-sivulla. Kun kirjauksen kesto muutetaan rajapinnassa 10 minuutiksi, Time-
    ...    sivu näyttää 10 minuuttia, ja kirjauksen poiston jälkeen aikaa ei enää näy.
    ...    Muokkaus lähettää kaikki kentät, koska rajapinta korvaa koko kirjauksen.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} time-sivu
    ${tehtava_id}=    Luo Tehtava    ${otsikko}
    Kirjaa Aikaa Rajapinnalla    ${PROJEKTI_ID}    ${tehtava_id}
    ${rivi}=    Set Variable    .time-task-row:has(.time-task-name:text-is("${otsikko}"))
    Mene Time-sivulle
    Get Text    ${rivi} >> .time-task-duration    contains    5 min
    ${kirjaus}=    Hae Tehtavan Aikakirjaus    ${tehtava_id}
    ${runko}=    Create Dictionary    projectId=${PROJEKTI_ID}    taskId=${tehtava_id}
    ...    description=${EMPTY}    duration=${10}    startedAt=${kirjaus}[startedAt]
    ${vastaus}=    Tee Kirjautunut Pyynto    PATCH    /time-entries/${kirjaus}[_id]    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    Reload
    Mene Time-sivulle
    Get Text    ${rivi} >> .time-task-duration    contains    10 min
    ${vastaus}=    Tee Kirjautunut Pyynto    DELETE    /time-entries/${kirjaus}[_id]
    Should Be Equal As Integers    ${vastaus.status_code}    200
    Reload
    Mene Time-sivulle
    Get Text    ${rivi} >> .time-task-duration    not contains    10 min
    Get Text    ${rivi} >> .time-task-duration    not contains    5 min

Ajastimen vaihto toiseen tehtävään tallentaa edellisen ajan
    [Documentation]    TC06-012. Odotettu tulos: kun käynnissä oleva ajastin vaihdetaan
    ...    toiseen tehtävään, ensimmäiselle tehtävälle tallentuu siihen asti kertynyt
    ...    aika (2 min), ja ajastin jatkuu toisella tehtävällä. Pysäytyksen jälkeen
    ...    toiselle tehtävälle tallentuu oma aikansa (1 min).
    [Tags]    api
    ${eka_id}=    Luo Tehtava    ${ETULIITE} vaihto eka
    ${toka_id}=    Luo Tehtava    ${ETULIITE} vaihto toka
    ${nyt}=    Nykyhetki Millisekunteina
    ${alku}=    Evaluate    ${nyt} - 120000
    ${runko}=    Create Dictionary    taskId=${eka_id}    projectId=${PROJEKTI_ID}    now=${alku}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    ${runko}=    Create Dictionary    taskId=${toka_id}    projectId=${PROJEKTI_ID}    now=${nyt}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/switch    ${runko}
    Should Be True    ${vastaus.status_code} in (200, 201)
    ...    msg=Ajastimen vaihto palautti ${vastaus.status_code}: ${vastaus.text}
    ${ajastin}=    Tee Kirjautunut Pyynto    GET    /active-timer
    ${ajastimen_tehtava}=    Evaluate
    ...    ($ajastin.json()['taskId']['_id'] if isinstance($ajastin.json().get('taskId'), dict) else $ajastin.json().get('taskId'))
    Should Be Equal    ${ajastimen_tehtava}    ${toka_id}
    ${loppu}=    Evaluate    ${nyt} + 60000
    ${runko}=    Create Dictionary    now=${loppu}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/stop    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${eka}=    Hae Tehtavan Aikakirjaus    ${eka_id}
    ${toka}=    Hae Tehtavan Aikakirjaus    ${toka_id}
    Should Be Equal As Integers    ${eka}[duration]    2
    Should Be Equal As Integers    ${toka}[duration]    1

Time-sivun projektivalinta säilyy sivun päivityksen yli
    [Documentation]    TC06-015. Odotettu tulos: Time-sivulla valittu projekti on yhä
    ...    valittuna sivun päivityksen jälkeen ilman uutta valintaa.
    [Tags]    selain
    Mene Time-sivulle
    Reload
    Click    .sidebar-item >> text="Time"
    Wait For Elements State    h1 >> text="Time"    visible    timeout=10s
    Get Selected Options    id=time-project    value    ==    ${PROJEKTI_ID}


*** Keywords ***
Valmistele Ajanseurantatestit
    [Documentation]    Kirjautuu testitunnuksella ja luo testiprojektin ja -tehtävän,
    ...    joiden ajastinta testit käyttävät.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    ${runko}=    Create Dictionary    name=${ETULIITE} ajanseuranta
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    Set Suite Variable    ${PROJEKTI_ID}    ${projekti.json()}[_id]
    ${tehtava_id}=    Luo Tehtava    ${ETULIITE} ajastettava
    Set Suite Variable    ${TEHTAVA_ID}    ${tehtava_id}
    Set Suite Variable    ${TEHTAVAKORTTI}    .task-item:has(h3:text-is("${ETULIITE} ajastettava"))
    Reload

Valmistele Ajastintesti
    [Documentation]    Varmistaa, ettei edellisestä testistä jää ajastinta käyntiin, ja
    ...    avaa testitehtävän Tasks-sivulla. Jäänyt ajastin poistetaan ilman kirjausta.
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    Reload
    Mene Testitehtavaan

Mene Testitehtavaan
    [Documentation]    Avaa Tasks-sivun ja valitsee testiprojektin.
    Click    .sidebar-item >> text="Tasks"
    Wait For Elements State    h1 >> text="Tasks"    visible    timeout=10s
    Select Options By    id=tasks-project    value    ${PROJEKTI_ID}
    Wait For Elements State    ${TEHTAVAKORTTI}    visible    timeout=10s

Mene Time-sivulle
    [Documentation]    Avaa Time-sivun ja valitsee testiprojektin.
    Click    .sidebar-item >> text="Time"
    Wait For Elements State    h1 >> text="Time"    visible    timeout=10s
    Select Options By    id=time-project    value    ${PROJEKTI_ID}
    Wait For Load State    networkidle    timeout=10s

Luo Tehtava
    [Documentation]    Luo testiprojektiin tehtävän rajapinnan kautta ja palauttaa sen
    ...    tunnisteen.
    [Arguments]    ${otsikko}
    ${runko}=    Create Dictionary    title=${otsikko}    projectId=${PROJEKTI_ID}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Nykyhetki Millisekunteina
    [Documentation]    Palauttaa nykyhetken millisekunteina, samassa muodossa kuin
    ...    selaimen Date.now().
    ${nyt}=    Evaluate    int(time.time() * 1000)    modules=time
    RETURN    ${nyt}

Tehtavan Aikakirjausten Kestot
    [Documentation]    Palauttaa testitehtävän aikakirjausten kestot listana
    ...    luontijärjestyksessä. taskId voi olla merkkijono tai haettu objekti.
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /time-entries
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${kestot}=    Evaluate
    ...    [m['duration'] for m in sorted($vastaus.json(), key=lambda m: m.get('createdAt', '')) if (m['taskId']['_id'] if isinstance(m.get('taskId'), dict) else m.get('taskId')) == $TEHTAVA_ID]
    RETURN    ${kestot}

Hae Tehtavan Aikakirjaus
    [Documentation]    Palauttaa annetun tehtävän ainoan aikakirjauksen. Kaatuu, jos
    ...    kirjauksia ei ole täsmälleen yksi.
    [Arguments]    ${tehtava_id}
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /time-entries
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${kirjaukset}=    Evaluate
    ...    [m for m in $vastaus.json() if (m['taskId']['_id'] if isinstance(m.get('taskId'), dict) else m.get('taskId')) == $tehtava_id]
    Length Should Be    ${kirjaukset}    1
    RETURN    ${kirjaukset}[0]

Siivoa Ajanseurantatestit
    [Documentation]    Poistaa mahdollisen ajastimen, testiprojektin tehtävät (ja niiden
    ...    mukana aikakirjaukset) sekä testiprojektin.
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${PROJEKTI_ID}
    FOR    ${tehtava}    IN    @{tehtavat.json()}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava}[_id]
    END
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${PROJEKTI_ID}
    Close Browser