*** Settings ***
Documentation    Testijoukko 11: Dashboard ja raportit.
...    Testaa widgettien poiston, lisäyksen ja järjestyksen, jokaisen widgetin
...    sisällön ja linkit, Tracked time -widgetin ajastinpainikkeet ja AI-widgetin
...    pikakeskustelun sekä raportin kaikki osiot, projektin vaihdon, tyhjän
...    projektin raportin ja tulostuksen. Dashboardin alkuperäinen asettelu
...    palautetaan testien jälkeen.
...    Raporttiprojektin kokonaisaika on 50 min (arvioitu aika 45 min ja kirjattu
...    aika 5 min).
...    Kattaa testitapaukset TC10-001 - TC10-006 ja TC10-009 - TC10-025.
...    TC10-025 tekee oikean AI-kutsun ja on merkitty tagilla ai.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Dashboardtestit
Suite Teardown    Siivoa Dashboardtestit
Test Setup    Valmistele Dashboardtesti


*** Variables ***
${WIDGET}    .dashboard-widget:has(button[aria-label="Remove {}"])


*** Test Cases ***
Widgetin poisto dashboardilta
    [Documentation]    TC10-001. Odotettu tulos: poistettu widget katoaa dashboardilta,
    ...    näkyy Add widget -kirjastossa ja pysyy poistettuna sivun päivityksen jälkeen.
    [Tags]    selain
    Varmista Widget Dashboardilla    Notes
    Click    button[aria-label="Remove Notes"]
    Get Element Count    button[aria-label="Remove Notes"]    ==    0
    Get Element Count    .widget-library-item >> text="Notes"    ==    1
    Reload
    Mene Dashboardille
    Get Element Count    button[aria-label="Remove Notes"]    ==    0

Widgetin lisäys kirjastosta
    [Documentation]    TC10-002. Odotettu tulos: Add widget -kirjastosta lisätty widget
    ...    näkyy dashboardilla, poistuu kirjastosta ja säilyy sivun päivityksen jälkeen.
    [Tags]    selain
    Varmista Widget Kirjastossa    Notes
    Click    .widget-library-item >> text="Notes"
    Get Element Count    button[aria-label="Remove Notes"]    ==    1
    Get Element Count    .widget-library-item >> text="Notes"    ==    0
    Reload
    Mene Dashboardille
    Get Element Count    button[aria-label="Remove Notes"]    ==    1

Widgettien järjestys muuttuu raahaamalla
    [Documentation]    TC10-003. Odotettu tulos: kun widget raahataan toisen päälle,
    ...    järjestys muuttuu ja uusi järjestys säilyy sivun päivityksen jälkeen.
    [Tags]    selain
    ${ennen}=    Widgettien Jarjestys
    ${eka}=    Set Variable    ${ennen}[0]
    ${toka}=    Set Variable    ${ennen}[1]
    Drag And Drop    ${WIDGET.format("${toka}")}    ${WIDGET.format("${eka}")}
    ${jalkeen}=    Widgettien Jarjestys
    Should Not Be Equal    ${jalkeen}    ${ennen}    msg=Järjestys ei muuttunut raahauksessa
    Reload
    Mene Dashboardille
    ${paivityksen_jalkeen}=    Widgettien Jarjestys
    Should Be Equal    ${paivityksen_jalkeen}    ${jalkeen}
    ...    msg=Järjestys ei säilynyt sivun päivityksen yli

Raportti näyttää projektin nimen, tilan ja kokonaisajan
    [Documentation]    TC10-004. Odotettu tulos: raportin otsikossa näkyy projektin nimi,
    ...    tila (active) ja kokonaisaika 50 min.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Get Text    .reports-header-panel h3    ==    ${PROJEKTIN_NIMI}
    Get Text    .reports-project-meta    contains    active
    Get Text    .reports-total-time    ==    50 min

Raportti näyttää projektin tehtävät
    [Documentation]    TC10-005. Odotettu tulos: raportin tehtävälistassa näkyvät
    ...    projektin molemmat tehtävät.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Get Element Count    .reports-task-row:has-text("${TEHTAVA_A}")    ==    1
    Get Element Count    .reports-task-row:has-text("${TEHTAVA_B}")    ==    1

Raportin tulostus avautuu
    [Documentation]    TC10-006. Odotettu tulos: kun projekti on valittu, Print report
    ...    käynnistää selaimen tulostuksen. Testi korvaa tulostusikkunan nauhurilla,
    ...    joka vain kirjaa tulostuspyynnön, jottei ikkuna pysäytä testiä.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Evaluate JavaScript    ${None}
    ...    () => { window.__tulostettiin = false; window.print = () => { window.__tulostettiin = true } }
    Click    .reports-print-button
    ${tulostettiin}=    Evaluate JavaScript    ${None}    () => window.__tulostettiin === true
    Should Be True    ${tulostettiin}    msg=Print report ei käynnistänyt tulostusta

Widgettien View all -painikkeet avaavat oikean sivun
    [Documentation]    TC10-009. Odotettu tulos: jokaisen widgetin View all -painike
    ...    avaa widgetin aihetta vastaavan sivun.
    [Tags]    selain
    [Template]    View All Avaa Sivun
    Projects           Projects
    Tasks              Tasks
    Recent projects    Projects
    Time               Time
    Notes              Notes
    Timeline           Timeline
    Calendar           Calendar

AI-widgetin Open avaa AI Assistantin
    [Documentation]    TC10-010. Odotettu tulos: AI-widgetin Open-painike avaa
    ...    AI Assistant -sivun.
    [Tags]    selain
    Varmista Widget Dashboardilla    AI Assistant
    Click    ${WIDGET.format("AI Assistant")} >> .panel-header button
    Wait For Elements State    h1 >> text="AI Assistant"    visible    timeout=10s

Raportin yhteenvetokortit vastaavat projektin tietoja
    [Documentation]    TC10-011. Odotettu tulos: yhteenvetokorteissa näkyy 2 tehtävää,
    ...    arvioitu aika 45 min, kirjattu aika 5 min ja 1 muistiinpano.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Get Text    ${KORTTI.format("Tasks")}    ==    2
    Get Text    ${KORTTI.format("Estimated time")}    ==    45 min
    Get Text    ${KORTTI.format("Tracked time")}    ==    5 min
    Get Text    ${KORTTI.format("Notes")}    ==    1

Task overview näyttää tilat, arvioidun ajan ja eräpäivän
    [Documentation]    TC10-012. Odotettu tulos: tilakohtaiset määrät ovat To do 1,
    ...    In progress 0 ja Completed 1. Tehtävän A rivillä näkyy arvioitu aika 30 min
    ...    ja eräpäivä 20.6.2026, tehtävän B rivillä arvioitu aika 15 min.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Get Text    ${TILA.format("To do")}    ==    1
    Get Text    ${TILA.format("In progress")}    ==    0
    Get Text    ${TILA.format("Completed")}    ==    1
    ${rivi_a}=    Set Variable    .reports-task-row:has-text("${TEHTAVA_A}")
    Get Text    ${rivi_a}    contains    30 min
    Get Text    ${rivi_a}    contains    20.6.2026
    Get Text    .reports-task-row:has-text("${TEHTAVA_B}")    contains    15 min

Tracked time -osio näyttää kirjaukset päivittäin
    [Documentation]    TC10-013. Odotettu tulos: Tracked time -osiossa on tämän päivän
    ...    rivi, jolla on 5 min, ja osion yhteissumma on 5 min.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    ${tanaan}=    Evaluate    f"{datetime.date.today().day}.{datetime.date.today().month}.{datetime.date.today().year}"
    ...    modules=datetime
    ${rivi}=    Set Variable    .reports-time-row:has-text("${tanaan}")
    Wait For Elements State    ${rivi}    visible    timeout=10s
    Get Text    ${rivi}    contains    5 min
    Get Text    .reports-section:has(h3:text-is("Tracked time")) >> .reports-section-total
    ...    ==    5 min

Project dates -osio näyttää tehtävien päivämäärät
    [Documentation]    TC10-014. Odotettu tulos: Project dates -osiossa näkyvät tehtävän A
    ...    alku- ja eräpäivä (1.6.2026 ja 20.6.2026) sekä tehtävän B valmistumispäivä
    ...    (10.6.2026).
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    ${osio}=    Set Variable    .reports-section:has(h3:text-is("Project dates"))
    Get Text    ${osio}    contains    1.6.2026
    Get Text    ${osio}    contains    20.6.2026
    Get Text    ${osio}    contains    10.6.2026

Project notes -osio näyttää muistiinpanot
    [Documentation]    TC10-015. Odotettu tulos: Project notes -osiossa näkyy projektin
    ...    muistiinpano otsikkoineen.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Get Element Count    .reports-note:has-text("${MUISTIINPANO}")    ==    1

Projektin vaihto päivittää raportin
    [Documentation]    TC10-016. Odotettu tulos: kun raportin projekti vaihdetaan,
    ...    otsikko ja sisältö vaihtuvat uuteen projektiin, eikä edellisen projektin
    ...    tehtäviä enää näy.
    [Tags]    selain
    Avaa Raportti    ${PROJEKTI_ID}
    Get Element Count    .reports-task-row:has-text("${TEHTAVA_A}")    ==    1
    Select Options By    id=reports-project    value    ${TYHJA_PROJEKTI_ID}
    Wait For Elements State    .reports-header-panel h3 >> text="${TYHJAN_NIMI}"    visible
    ...    timeout=10s
    Get Element Count    .reports-task-row:has-text("${TEHTAVA_A}")    ==    0

Projekti ilman tietoja näyttää tyhjät osiot
    [Documentation]    TC10-017. Odotettu tulos: projektin, jolla ei ole tietoja, raportti
    ...    näyttää nollat yhteenvetokorteissa ja tyhjien osioiden ilmoitukset.
    [Tags]    selain
    Avaa Raportti    ${TYHJA_PROJEKTI_ID}
    Get Text    ${KORTTI.format("Tasks")}    ==    0
    Get Text    ${KORTTI.format("Notes")}    ==    0
    ${tyhjat}=    Get Element Count    .reports-empty-row
    Should Be True    ${tyhjat} >= 3    msg=Tyhjiä osioita näkyi vain ${tyhjat}

Projects-widget näyttää aktiivisten projektien määrän
    [Documentation]    TC10-018. Odotettu tulos: Projects-widgetin luku vastaa käyttäjän
    ...    aktiivisten projektien määrää, ja kokonaisaika (Project hours) on näkyvissä.
    ...    Luku lasketaan rajapinnasta, koska testitilillä voi olla muitakin projekteja.
    [Tags]    selain
    ${odotettu}=    Aktiivisten Projektien Maara
    Varmista Widget Dashboardilla    Projects
    ${widget}=    Set Variable    ${WIDGET.format("Projects")}
    Get Text    ${widget} >> strong >> nth=0    ==    ${odotettu}
    Get Text    ${widget}    contains    Project hours

Tasks-widget näyttää keskeneräisten tehtävien määrän
    [Documentation]    TC10-019. Odotettu tulos: Tasks-widgetin luku vastaa käyttäjän
    ...    keskeneräisten tehtävien määrää. Luku lasketaan rajapinnasta, koska
    ...    testitilillä voi olla muitakin tehtäviä.
    [Tags]    selain
    ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks
    ${odotettu}=    Evaluate
    ...    str(len([t for t in $tehtavat.json() if t.get('status') != 'completed']))
    Varmista Widget Dashboardilla    Tasks
    Get Text    ${WIDGET.format("Tasks")} >> .dashboard-task-count strong    ==    ${odotettu}

Tracked time -widgetin ajastinpainikkeet toimivat
    [Documentation]    TC10-020. Odotettu tulos: käynnissä oleva ajastin näkyy Tracked time
    ...    -widgetissä. Pause tauottaa, Resume jatkaa ja Stop pysäyttää ajastimen, jonka
    ...    jälkeen käynnissä olevaa ajastinta ei enää ole. Testi käyttää omaa
    ...    väliaikaista tehtävää, joka poistetaan kirjauksineen lopuksi, jotta
    ...    raporttiprojektin ajat eivät muutu.
    [Tags]    selain
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    ${tehtava_id}=    Luo Rajapinnalla    /tasks    title=${ETULIITE} ajastintehtävä
    ...    projectId=${PROJEKTI_ID}
    Set Test Variable    ${AJASTINTEHTAVA_ID}    ${tehtava_id}
    ${nyt}=    Evaluate    int(time.time() * 1000)    modules=time
    ${runko}=    Create Dictionary    taskId=${tehtava_id}    projectId=${PROJEKTI_ID}    now=${nyt}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    Reload
    Mene Dashboardille
    Varmista Widget Dashboardilla    Tracked time
    ${widget}=    Set Variable    ${WIDGET.format("Tracked time")}
    Click    ${widget} >> .time-tracker-button-pause
    Wait For Elements State    ${widget} >> .time-tracker-button-resume    visible    timeout=10s
    Click    ${widget} >> .time-tracker-button-resume
    Wait For Elements State    ${widget} >> .time-tracker-button-pause    visible    timeout=10s
    Click    ${widget} >> .time-tracker-button-stop
    Wait For Elements State    ${widget} >> .time-tracker-button-stop    detached    timeout=10s
    ${ajastin}=    Tee Kirjautunut Pyynto    GET    /active-timer
    Should Be Equal    ${ajastin.json()}    ${None}
    [Teardown]    Poista Ajastintehtava

Recent projects -widget näyttää projektit ja kokonaisajan
    [Documentation]    TC10-021. Odotettu tulos: Recent projects -widget näyttää kaksi
    ...    viimeksi luotua projektia, eli testin kaksi projektia, ja raporttiprojektin
    ...    kokonaisajan 50 min.
    [Tags]    selain
    Varmista Widget Dashboardilla    Recent projects
    ${widget}=    Set Variable    ${WIDGET.format("Recent projects")}
    ${rivi}=    Set Variable    ${widget} >> .project-item:has-text("${PROJEKTIN_NIMI}")
    Wait For Elements State    ${rivi}    visible    timeout=10s
    Get Text    ${rivi} >> .project-time    ==    50 min
    Get Element Count    ${widget} >> .project-item:has-text("${TYHJAN_NIMI}")    ==    1

Time-widget näyttää valitun projektin tehtävät
    [Documentation]    TC10-022. Odotettu tulos: kun raporttiprojekti on valittu Time-
    ...    sivulla, Time-widget näyttää sen tehtävät ja niiden kokonaisajat: tehtävä A
    ...    35 min ja tehtävä B 15 min.
    [Tags]    selain
    ${runko}=    Create Dictionary    selectedProjectId=${PROJEKTI_ID}
    ${vastaus}=    Tee Kirjautunut Pyynto    PUT    /time-view    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    Reload
    Mene Dashboardille
    Varmista Widget Dashboardilla    Time
    ${widget}=    Set Variable    ${WIDGET.format("Time")}
    Wait For Elements State    ${widget} >> text=${TEHTAVA_A}    visible    timeout=10s
    Get Text    ${widget}    contains    ${TEHTAVA_B}
    Get Text    ${widget}    contains    35 min
    Get Text    ${widget}    contains    15 min

Notes-widget näyttää muistiinpanot
    [Documentation]    TC10-023. Odotettu tulos: Notes-widgetissä näkyy projektin
    ...    muistiinpano.
    [Tags]    selain
    Varmista Widget Dashboardilla    Notes
    Wait For Elements State
    ...    ${WIDGET.format("Notes")} >> .dashboard-note-item:has-text("${MUISTIINPANO}")
    ...    visible    timeout=10s

AI-widgetin pikakeskustelu avautuu ja sulkeutuu
    [Documentation]    TC10-024. Odotettu tulos: Ask AI avaa pikakeskustelun widgetin
    ...    sisällä, ja sulkupainike sulkee sen.
    [Tags]    selain
    Varmista Widget Dashboardilla    AI Assistant
    ${widget}=    Set Variable    ${WIDGET.format("AI Assistant")}
    Click    ${widget} >> .ai-action
    Wait For Elements State    ${widget} >> .ai-chat    visible    timeout=5s
    Click    ${widget} >> button[aria-label="Close AI chat"]
    Wait For Elements State    ${widget} >> .ai-chat    detached    timeout=5s

AI-widgetin pikakeskusteluun tulee vastaus
    [Documentation]    TC10-025. Maksullinen. Odotettu tulos: pikakeskusteluun lähetetty
    ...    viesti näkyy keskustelussa, ja siihen tulee AI:n vastaus.
    [Tags]    selain    ai
    Varmista Widget Dashboardilla    AI Assistant
    ${widget}=    Set Variable    ${WIDGET.format("AI Assistant")}
    Click    ${widget} >> .ai-action
    Fill Text    ${widget} >> input[aria-label="Message Kreniter"]    Vastaa pelkästään sanalla OK.
    Click    ${widget} >> button[aria-label="Send message"]
    Wait For Elements State    ${widget} >> .ai-chat-message-user    visible    timeout=10s
    Wait For Elements State    ${widget} >> .ai-chat-message-assistant    visible    timeout=60s


*** Keywords ***
Valmistele Dashboardtestit
    [Documentation]    Kirjautuu testitunnuksella, tallentaa dashboardin alkuperäisen
    ...    asettelun ja luo raporttitesteille kaksi projektia: raporttiprojektin, jossa
    ...    on kaksi tehtävää (arviot 30 ja 15 min), 5 minuutin kirjaus ja muistiinpano,
    ...    sekä tyhjän projektin.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${asettelu}=    Tee Kirjautunut Pyynto    GET    /dashboard-layout
    Should Be Equal As Integers    ${asettelu.status_code}    200
    Set Suite Variable    ${ALKUPERAINEN_ASETTELU}    ${asettelu.json()}
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    Set Suite Variable    ${PROJEKTIN_NIMI}    ${ETULIITE} raporttiprojekti
    Set Suite Variable    ${TYHJAN_NIMI}    ${ETULIITE} tyhjä projekti
    Set Suite Variable    ${TEHTAVA_A}    ${ETULIITE} tehtävä A
    Set Suite Variable    ${TEHTAVA_B}    ${ETULIITE} tehtävä B
    Set Suite Variable    ${MUISTIINPANO}    ${ETULIITE} raportin muistiinpano
    Set Suite Variable    ${KORTTI}    .reports-summary-card:has(span:text-is("{}")) >> strong
    Set Suite Variable    ${TILA}    .reports-status-item:has(span:text-is("{}")) >> strong
    ${id}=    Luo Rajapinnalla    /projects    name=${PROJEKTIN_NIMI}
    Set Suite Variable    ${PROJEKTI_ID}    ${id}
    ${id}=    Luo Rajapinnalla    /projects    name=${TYHJAN_NIMI}
    Set Suite Variable    ${TYHJA_PROJEKTI_ID}    ${id}
    ${id}=    Luo Rajapinnalla    /tasks    title=${TEHTAVA_A}    projectId=${PROJEKTI_ID}
    ...    estimatedMinutes=${30}    startDate=2026-06-01    dueDate=2026-06-20
    Set Suite Variable    ${TEHTAVA_A_ID}    ${id}
    Luo Rajapinnalla    /tasks    title=${TEHTAVA_B}    projectId=${PROJEKTI_ID}
    ...    estimatedMinutes=${15}    status=completed    completedDate=2026-06-10
    Luo Rajapinnalla    /notes    title=${MUISTIINPANO}    projectId=${PROJEKTI_ID}
    Kirjaa Aikaa Rajapinnalla    ${PROJEKTI_ID}    ${TEHTAVA_A_ID}

Valmistele Dashboardtesti
    [Documentation]    Lataa sivun uudelleen ennen jokaista testiä ja avaa dashboardin,
    ...    jotta edellisen testin tila ei vaikuta.
    Reload
    Mene Dashboardille

Luo Rajapinnalla
    [Documentation]    Luo tiedon annettuun rajapinnan polkuun ja palauttaa sen tunnisteen.
    [Arguments]    ${polku}    &{kentat}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    ${polku}    ${kentat}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Poista Ajastintehtava
    [Documentation]    Teardown testille TC10-020: poistaa mahdollisen käynnissä olevan
    ...    ajastimen ja testin väliaikaisen tehtävän. Tehtävän poisto poistaa myös sen
    ...    aikakirjaukset.
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    ${tehtava_id}=    Get Variable Value    ${AJASTINTEHTAVA_ID}    ${None}
    IF    $tehtava_id
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava_id}
    END

Mene Dashboardille
    [Documentation]    Avaa dashboardin sivupalkista.
    Click    .sidebar-item >> text="Dashboard"
    Wait For Elements State    h1 >> text="Dashboard"    visible    timeout=10s

Avaa Raportti
    [Documentation]    Avaa Reports-sivun ja valitsee annetun projektin.
    [Arguments]    ${projekti_id}
    Click    .sidebar-item >> text="Reports"
    Wait For Elements State    h1 >> text="Reports"    visible    timeout=10s
    Select Options By    id=reports-project    value    ${projekti_id}
    Wait For Load State    networkidle    timeout=10s

Varmista Widget Dashboardilla
    [Documentation]    Lisää widgetin kirjastosta, jos se ei ole valmiiksi dashboardilla.
    [Arguments]    ${nimi}
    ${maara}=    Get Element Count    button[aria-label="Remove ${nimi}"]
    IF    ${maara} == 0    Click    .widget-library-item >> text="${nimi}"
    Wait For Elements State    button[aria-label="Remove ${nimi}"]    visible    timeout=5s

Varmista Widget Kirjastossa
    [Documentation]    Poistaa widgetin dashboardilta, jos se on siellä.
    [Arguments]    ${nimi}
    ${maara}=    Get Element Count    button[aria-label="Remove ${nimi}"]
    IF    ${maara} > 0    Click    button[aria-label="Remove ${nimi}"]
    Wait For Elements State    .widget-library-item >> text="${nimi}"    visible    timeout=5s

View All Avaa Sivun
    [Documentation]    Klikkaa widgetin View all -painiketta ja tarkistaa, että oikea sivu
    ...    avautuu. Palaa lopuksi dashboardille.
    [Arguments]    ${widgetti}    ${sivu}
    Varmista Widget Dashboardilla    ${widgetti}
    Click    ${WIDGET.format("${widgetti}")} >> .panel-header >> text="View all"
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    h1 >> text="${sivu}"    visible    timeout=10s
    Mene Dashboardille

Widgettien Jarjestys
    [Documentation]    Palauttaa dashboardin widgettien nimet näkyvässä järjestyksessä.
    ${nimet}=    Evaluate JavaScript    ${None}
    ...    () => [...document.querySelectorAll('.dashboard-widget .widget-remove')].map(b => b.getAttribute('aria-label').replace('Remove ', ''))
    RETURN    ${nimet}

Aktiivisten Projektien Maara
    [Documentation]    Laskee käyttäjän aktiivisten projektien määrän rajapinnasta ja
    ...    palauttaa sen tekstinä, jotta sitä voi verrata sivun tekstiin.
    ${projektit}=    Tee Kirjautunut Pyynto    GET    /projects
    ${maara}=    Evaluate
    ...    str(len([p for p in $projektit.json() if str(p.get('status') or '').lower() == 'active']))
    RETURN    ${maara}

Siivoa Dashboardtestit
    [Documentation]    Poistaa mahdollisen ajastimen, palauttaa dashboardin alkuperäisen
    ...    asettelun ja poistaa testien tehtävät, muistiinpanon ja projektit.
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    ${vastaus}=    Tee Kirjautunut Pyynto    PUT    /dashboard-layout    ${ALKUPERAINEN_ASETTELU}
    IF    ${vastaus.status_code} >= 300
        Log    Dashboardin asettelun palautus epäonnistui: ${vastaus.status_code} ${vastaus.text}
        ...    WARN
    END
    ${muistiinpanot}=    Tee Kirjautunut Pyynto    GET    /notes
    FOR    ${muistiinpano}    IN    @{muistiinpanot.json()}
        IF    $muistiinpano['title'].startswith($ETULIITE)
            Run Keyword And Ignore Error
            ...    Tee Kirjautunut Pyynto    DELETE    /notes/${muistiinpano}[_id]
        END
    END
    FOR    ${projekti_id}    IN    ${PROJEKTI_ID}    ${TYHJA_PROJEKTI_ID}
        ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${projekti_id}
        FOR    ${tehtava}    IN    @{tehtavat.json()}
            Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava}[_id]
        END
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${projekti_id}
    END
    Close Browser