*** Settings ***
Documentation    Testijoukko 10: Kalenteri ja aikajana.
...    Testaa kalenterin näkymät, navigoinnin, kuukauden ja vuoden valinnan,
...    merkintöjen lisäyksen, muokkauksen ja poiston, lomakkeen validoinnin,
...    tooltipin, tehtävien päivämäärien näkymisen kalenterissa, kalenteriwidgetin
...    sekä Timeline-sivun, sen tooltipin ja projektivalinnan sekä Timeline-widgetin.
...    Testit käyttävät kiinteitä päiviä kesä- ja heinäkuussa 2026, joten ne eivät
...    riipu ajopäivästä. Jokaisella testillä on oma päivänsä, jotta merkinnät eivät
...    piiloudu "+N more" -tekstin taakse. Dashboardin alkuperäinen asettelu
...    palautetaan testien jälkeen.
...    Kattaa testitapaukset TC09-001 - TC09-004, TC09-007 - TC09-016, TC09-018 ja
...    TC09-019.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Kalenteritestit
Suite Teardown    Siivoa Kalenteritestit
Test Setup    Valmistele Kalenteritesti


*** Variables ***
${TESTIKUUKAUSI}      June 2026


*** Test Cases ***
Näkymän vaihto päivä-, viikko- ja kuukausinäkymään
    [Documentation]    TC09-001. Odotettu tulos: näkymänvaihtajan painikkeet vaihtavat
    ...    näkymän, aktiivinen painike on merkitty (aria-pressed), ja jakson otsikko
    ...    vastaa näkymää.
    [Tags]    selain
    Click    ${NAKYMA}:text-is("Week")
    Get Attribute    ${NAKYMA}:text-is("Week")    aria-pressed    ==    true
    Get Text    .calendar-period-label    matches    ^Week \\d+, \\d{4}$
    Click    ${NAKYMA}:text-is("Day")
    Get Attribute    ${NAKYMA}:text-is("Day")    aria-pressed    ==    true
    Click    ${NAKYMA}:text-is("Month")
    Get Attribute    ${NAKYMA}:text-is("Month")    aria-pressed    ==    true
    Get Element Count    .calendar-month    ==    1

Edellinen, seuraava ja Today
    [Documentation]    TC09-002. Odotettu tulos: Next ja Previous vaihtavat kuukautta, ja
    ...    Today palauttaa nykyiseen kuukauteen.
    [Tags]    selain
    Click    .calendar-nav-today
    ${nykyinen}=    Get Text    .calendar-period-label
    Click    button[aria-label="Next"]
    Get Text    .calendar-period-label    !=    ${nykyinen}
    Click    button[aria-label="Previous"]
    Click    button[aria-label="Previous"]
    Get Text    .calendar-period-label    !=    ${nykyinen}
    Click    .calendar-nav-today
    Get Text    .calendar-period-label    ==    ${nykyinen}

Kuukauden ja vuoden valinta
    [Documentation]    TC09-003. Odotettu tulos: valitsimesta valittu kuukausi ja vuosi
    ...    näkyvät jakson otsikossa.
    [Tags]    selain
    Click    .calendar-nav-today
    Siirry Testikuukauteen
    Get Text    .calendar-period-label    ==    ${TESTIKUUKAUSI}

Merkinnän lisäys lomakkeella
    [Documentation]    TC09-004. Odotettu tulos: lomakkeella lisätty koko päivän merkintä
    ...    näkyy kalenterissa oikeana päivänä.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} lisäys
    Click    .calendar-add-button
    Wait For Elements State    role=dialog >> text="Add event"    visible    timeout=5s
    Fill Text    id=calendar-event-title    ${otsikko}
    Fill Text    id=calendar-event-date    2026-06-08
    Check Checkbox    id=calendar-event-all-day
    Click    .calendar-save-button
    Wait For Elements State    role=dialog    detached    timeout=10s
    Siirry Testikuukauteen
    Wait For Elements State    ${MERKINTA}:text-is("${otsikko}")    visible    timeout=10s

Virheellinen kellonaika näyttää virheen lomakkeessa
    [Documentation]    TC09-007. Odotettu tulos: kun loppuaika on ennen alkuaikaa,
    ...    lomake näyttää virheen eikä merkintää tallenneta.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} virheellinen aika
    Click    .calendar-add-button
    Wait For Elements State    role=dialog >> text="Add event"    visible    timeout=5s
    Fill Text    id=calendar-event-title    ${otsikko}
    Fill Text    id=calendar-event-date    2026-06-09
    Uncheck Checkbox    id=calendar-event-all-day
    Fill Text    id=calendar-event-start-time    14:00
    Fill Text    id=calendar-event-end-time    13:00
    Click    .calendar-save-button
    Wait For Elements State    role=dialog >> .calendar-field-error    visible    timeout=5s
    Keyboard Key    press    Escape
    Wait For Elements State    role=dialog    detached    timeout=5s
    Siirry Testikuukauteen
    Get Element Count    ${MERKINTA}:text-is("${otsikko}")    ==    0

Merkinnän muokkaus
    [Documentation]    TC09-008. Odotettu tulos: muokattu otsikko näkyy kalenterissa,
    ...    eikä vanhaa otsikkoa enää näy.
    [Tags]    selain
    ${vanha}=    Set Variable    ${ETULIITE} muokattava
    ${uusi}=    Set Variable    ${ETULIITE} muokattu
    Luo Merkinta Rajapinnalla    ${vanha}    2026-06-10
    Reload
    Mene Kalenteriin
    Siirry Testikuukauteen
    Click    ${MERKINTA}:text-is("${vanha}")
    Wait For Elements State    role=dialog >> text="Edit event"    visible    timeout=5s
    Fill Text    id=calendar-event-title    ${uusi}
    Click    .calendar-save-button
    Wait For Elements State    ${MERKINTA}:text-is("${uusi}")    visible    timeout=10s
    Get Element Count    ${MERKINTA}:text-is("${vanha}")    ==    0

Merkinnän poisto
    [Documentation]    TC09-009. Odotettu tulos: poistovahvistuksen jälkeen merkintä
    ...    katoaa kalenterista.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} poistettava
    Luo Merkinta Rajapinnalla    ${otsikko}    2026-06-11
    Reload
    Mene Kalenteriin
    Siirry Testikuukauteen
    Click    ${MERKINTA}:text-is("${otsikko}")
    Wait For Elements State    role=dialog >> text="Edit event"    visible    timeout=5s
    Click    .calendar-form-delete
    Wait For Elements State    role=dialog >> text="Delete event?"    visible    timeout=5s
    Click    role=dialog >> button >> text="Delete event"
    Wait For Elements State    ${MERKINTA}:text-is("${otsikko}")    detached    timeout=10s

Tooltip näyttää merkinnän päivämäärän
    [Documentation]    TC09-010. Odotettu tulos: kun hiiri viedään merkinnän päälle,
    ...    tooltip näyttää merkinnän otsikon ja päivämäärän.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} tooltip
    Luo Merkinta Rajapinnalla    ${otsikko}    2026-06-12
    Reload
    Mene Kalenteriin
    Siirry Testikuukauteen
    Hover    ${MERKINTA}:text-is("${otsikko}")
    Wait For Elements State    .calendar-tooltip    visible    timeout=5s
    Get Text    .calendar-tooltip    contains    ${otsikko}
    Get Text    .calendar-tooltip    contains    12.6.2026

Tehtävän eräpäivä näkyy kalenterissa
    [Documentation]    TC09-011. Odotettu tulos: tehtävä, jonka eräpäivä on testipäivänä,
    ...    näkyy kalenterissa, ja sen tooltip kertoo eräpäivän.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} eräpäivätehtävä
    Luo Tehtava Rajapinnalla    ${otsikko}    dueDate=2026-06-17
    Reload
    Mene Kalenteriin
    Siirry Testikuukauteen
    ${merkki}=    Set Variable    .calendar-task-marker:has-text("${otsikko}")
    Wait For Elements State    ${merkki}    visible    timeout=10s
    Hover    ${merkki}
    Wait For Elements State    .calendar-tooltip    visible    timeout=5s
    Get Text    .calendar-tooltip    contains    Due date
    Get Text    .calendar-tooltip    contains    17.6.2026

Merkintälomake sulkeutuu Escapella
    [Documentation]    TC09-012. Odotettu tulos: Escape sulkee merkintälomakkeen, eikä
    ...    keskeneräistä merkintää tallenneta.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} escape
    Click    .calendar-add-button
    Wait For Elements State    role=dialog >> text="Add event"    visible    timeout=5s
    Fill Text    id=calendar-event-title    ${otsikko}
    Keyboard Key    press    Escape
    Wait For Elements State    role=dialog    detached    timeout=5s
    Get Element Count    ${MERKINTA}:text-is("${otsikko}")    ==    0

Tehtävän alku- ja valmistumispäivä näkyvät kalenterissa
    [Documentation]    TC09-013. Odotettu tulos: valmiin tehtävän alkupäivä näkyy
    ...    kalenterissa merkillä "Start:" ja valmistumispäivä merkillä "Completed:", joka
    ...    on korostettu valmistumisen tyylillä.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} valmis tehtävä
    Luo Tehtava Rajapinnalla    ${otsikko}    status=completed    startDate=2026-06-22
    ...    completedDate=2026-06-24
    Reload
    Mene Kalenteriin
    Siirry Testikuukauteen
    Wait For Elements State    .calendar-task-marker:has-text("Start: ${otsikko}")    visible
    ...    timeout=10s
    Wait For Elements State
    ...    .calendar-task-marker.calendar-task-marker-completed:has-text("Completed: ${otsikko}")
    ...    visible    timeout=10s

Kalenteriwidget näyttää päivän merkinnät ja merkintää voi muokata ja poistaa
    [Documentation]    TC09-014. Odotettu tulos: dashboardin kalenteriwidget näyttää
    ...    tämän päivän merkinnän ja tehtävän. Merkinnän voi avata widgetistä
    ...    muokattavaksi, ja muokattu otsikko näkyy widgetissä. Merkinnän voi poistaa
    ...    widgetistä, jolloin se katoaa.
    [Tags]    selain
    ${tanaan}=    Evaluate    datetime.date.today().isoformat()    modules=datetime
    ${otsikko}=    Set Variable    ${ETULIITE} widgetmerkintä
    ${uusi}=    Set Variable    ${ETULIITE} widget muokattu
    ${tehtava}=    Set Variable    ${ETULIITE} widgettehtävä
    Luo Merkinta Rajapinnalla    ${otsikko}    ${tanaan}
    Luo Tehtava Rajapinnalla    ${tehtava}    dueDate=${tanaan}
    Reload
    Mene Dashboardille
    Varmista Widget Dashboardilla    Calendar
    ${widget}=    Set Variable    .calendar-widget
    Wait For Elements State    ${widget} >> ${MERKINTA}:text-is("${otsikko}")    visible    timeout=10s
    Get Text    ${widget}    contains    ${tehtava}
    Click    ${widget} >> ${MERKINTA}:text-is("${otsikko}")
    Wait For Elements State    role=dialog >> text="Edit event"    visible    timeout=5s
    Fill Text    id=calendar-event-title    ${uusi}
    Click    .calendar-save-button
    Wait For Elements State    ${widget} >> ${MERKINTA}:text-is("${uusi}")    visible    timeout=10s
    Click    ${widget} >> ${MERKINTA}:text-is("${uusi}")
    Wait For Elements State    role=dialog >> text="Edit event"    visible    timeout=5s
    Click    .calendar-form-delete
    Wait For Elements State    .delete-dialog-confirm    visible    timeout=5s
    Click    .delete-dialog-confirm
    Wait For Elements State    ${widget} >> ${MERKINTA}:text-is("${uusi}")    detached    timeout=10s

Timeline-sivu näyttää päivämäärälliset tehtävät
    [Documentation]    TC09-015. Odotettu tulos: Timeline-sivu näyttää projektin tehtävän,
    ...    jolla on alku- ja eräpäivä, mutta ei tehtävää, jolla päivämääriä ei ole.
    [Tags]    selain
    ${paivallinen}=    Set Variable    ${ETULIITE} aikajanatehtävä
    ${ilman}=    Set Variable    ${ETULIITE} ilman päivämääriä
    Luo Tehtava Rajapinnalla    ${paivallinen}    startDate=2026-06-01    dueDate=2026-06-05
    Luo Tehtava Rajapinnalla    ${ilman}
    Reload
    Mene Timelineen
    Wait For Elements State    .timeline-row:has(.timeline-task-title:text-is("${paivallinen}"))
    ...    visible    timeout=10s
    Get Element Count    .timeline-row:has(.timeline-task-title:text-is("${ilman}"))    ==    0

Timeline-widget näyttää käynnissä olevat ja uusimmat tehtävät
    [Documentation]    TC09-016. Odotettu tulos: Timeline-widget näyttää enintään seitsemän
    ...    tehtävää. Käynnissä oleva tehtävä näkyy aina, vaikka sen päivämäärä olisi
    ...    vanhin, ja muista näytetään uusimmat. Kaksi vanhinta muuta tehtävää jää pois.
    [Tags]    selain
    ${projekti_id}=    Luo Projekti Rajapinnalla    ${ETULIITE} widgetprojekti
    ${kaynnissa}=    Set Variable    ${ETULIITE} käynnissä
    Luo Tehtava Rajapinnalla    ${kaynnissa}    projectId=${projekti_id}    status=in-progress
    ...    dueDate=2026-07-01
    FOR    ${i}    IN RANGE    1    9
        ${paiva}=    Evaluate    f"2026-07-{${i} + 10:02d}"
        Luo Tehtava Rajapinnalla    ${ETULIITE} tehtävä ${i}    projectId=${projekti_id}
        ...    dueDate=${paiva}
    END
    ${runko}=    Create Dictionary    selectedProjectId=${projekti_id}
    ${vastaus}=    Tee Kirjautunut Pyynto    PUT    /timeline    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    200
    Reload
    Mene Dashboardille
    Varmista Widget Dashboardilla    Timeline
    ${widget}=    Set Variable    .dashboard-widget:has(button[aria-label="Remove Timeline"])
    Wait For Elements State    ${widget} >> text="${kaynnissa}"    visible    timeout=10s
    FOR    ${i}    IN RANGE    3    9
        Get Text    ${widget}    contains    ${ETULIITE} tehtävä ${i}
    END
    Get Text    ${widget}    not contains    ${ETULIITE} tehtävä 1
    Get Text    ${widget}    not contains    ${ETULIITE} tehtävä 2

Timeline-sivun tooltip näyttää tehtävän tiedot
    [Documentation]    TC09-018. Odotettu tulos: kun hiiri viedään aikajanan palkin
    ...    päälle, tooltip näyttää tehtävän nimen, aloituspäivän (1 Jun 2026),
    ...    valmistumispäivän (4 Jun 2026) ja kokonaisajan (35 min: arvio 30 min ja
    ...    kirjattu aika 5 min).
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} tooltiptehtävä
    ${tehtava_id}=    Luo Tehtava Rajapinnalla    ${otsikko}    status=completed
    ...    startDate=2026-06-01    dueDate=2026-06-05    completedDate=2026-06-04
    ...    estimatedMinutes=${30}
    Kirjaa Aikaa Rajapinnalla    ${PROJEKTI_ID}    ${tehtava_id}
    Reload
    Mene Timelineen
    ${palkki}=    Set Variable
    ...    .timeline-row:has(.timeline-task-title:text-is("${otsikko}")) >> .timeline-task-bar
    Wait For Elements State    ${palkki}    visible    timeout=10s
    Hover    ${palkki}
    Wait For Elements State    .timeline-tooltip    visible    timeout=5s
    Get Text    .timeline-tooltip    contains    ${otsikko}
    Get Text    .timeline-tooltip    contains    1 Jun 2026
    Get Text    .timeline-tooltip    contains    4 Jun 2026
    Get Text    .timeline-tooltip    contains    35 min

Timeline-sivun projektivalinta säilyy sivun päivityksen yli
    [Documentation]    TC09-019. Odotettu tulos: Timeline-sivulla valittu projekti on yhä
    ...    valittuna sivun päivityksen jälkeen ilman uutta valintaa.
    [Tags]    selain
    Mene Timelineen
    Reload
    Click    .sidebar-item >> text="Timeline"
    Wait For Elements State    h1 >> text="Timeline"    visible    timeout=10s
    Get Selected Options    id=timeline-project    value    ==    ${PROJEKTI_ID}


*** Keywords ***
Valmistele Kalenteritestit
    [Documentation]    Kirjautuu testitunnuksella, tallentaa dashboardin alkuperäisen
    ...    asettelun, luo ajolle satunnaisen etuliitteen ja testiprojektin.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${asettelu}=    Tee Kirjautunut Pyynto    GET    /dashboard-layout
    Set Suite Variable    ${ALKUPERAINEN_ASETTELU}    ${asettelu.json()}
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    ${projekti_id}=    Luo Projekti Rajapinnalla    ${ETULIITE} kalenteriprojekti
    Set Suite Variable    ${PROJEKTI_ID}    ${projekti_id}
    Set Suite Variable    ${NAKYMA}    .calendar-view-switcher-button
    Set Suite Variable    ${MERKINTA}    .calendar-event-pill

Valmistele Kalenteritesti
    [Documentation]    Lataa sivun uudelleen ennen jokaista testiä, jotta edellisen testin
    ...    tila ei vaikuta, ja avaa kalenterin.
    Reload
    Mene Kalenteriin

Mene Kalenteriin
    [Documentation]    Avaa Calendar-sivun ja valitsee kuukausinäkymän.
    Click    .sidebar-item >> text="Calendar"
    Wait For Elements State    h1 >> text="Calendar"    visible    timeout=10s
    Click    ${NAKYMA}:text-is("Month")
    Wait For Elements State    .calendar-month    visible    timeout=10s

Mene Timelineen
    [Documentation]    Avaa Timeline-sivun ja valitsee testiprojektin.
    Click    .sidebar-item >> text="Timeline"
    Wait For Elements State    h1 >> text="Timeline"    visible    timeout=10s
    Select Options By    id=timeline-project    value    ${PROJEKTI_ID}
    Wait For Load State    networkidle    timeout=10s

Mene Dashboardille
    [Documentation]    Avaa dashboardin sivupalkista.
    Click    .sidebar-item >> text="Dashboard"
    Wait For Elements State    h1 >> text="Dashboard"    visible    timeout=10s

Varmista Widget Dashboardilla
    [Documentation]    Lisää widgetin kirjastosta, jos se ei ole valmiiksi dashboardilla.
    [Arguments]    ${nimi}
    ${maara}=    Get Element Count    button[aria-label="Remove ${nimi}"]
    IF    ${maara} == 0    Click    .widget-library-item >> text="${nimi}"
    Wait For Elements State    button[aria-label="Remove ${nimi}"]    visible    timeout=5s

Siirry Testikuukauteen
    [Documentation]    Siirtyy kesäkuuhun 2026 kuukauden ja vuoden valitsimella. Valitsin
    ...    sulkeutuu heti valinnan jälkeen, joten valintojen jälkeen tarkistetaan vain
    ...    jakson otsikko. Jos valitsin sulkeutuu jo vuoden syötön jälkeen, se avataan
    ...    uudelleen kuukauden valintaa varten.
    ${otsikko}=    Get Text    .calendar-period-label
    IF    $otsikko == $TESTIKUUKAUSI    RETURN
    Avaa Kuukausivalitsin
    Run Keyword And Ignore Error    Fill Text    input[aria-label="Year"]    2026
    ${auki}=    Get Element Count    .calendar-month-year-picker
    IF    ${auki} == 0    Avaa Kuukausivalitsin
    Run Keyword And Ignore Error    Select Options By    select[aria-label="Month"]    value    5
    Wait For Elements State    .calendar-period-label >> text="${TESTIKUUKAUSI}"    visible
    ...    timeout=5s
    ${auki}=    Get Element Count    .calendar-month-year-picker
    IF    ${auki} > 0    Keyboard Key    press    Escape

Avaa Kuukausivalitsin
    [Documentation]    Avaa kuukauden ja vuoden valitsimen jakson otsikosta.
    Click    .calendar-period-label
    Wait For Elements State    .calendar-month-year-picker    visible    timeout=5s

Luo Projekti Rajapinnalla
    [Documentation]    Luo projektin rajapinnan kautta ja palauttaa sen tunnisteen.
    [Arguments]    ${nimi}
    ${runko}=    Create Dictionary    name=${nimi}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Luo Merkinta Rajapinnalla
    [Documentation]    Luo koko päivän merkinnän annetulle päivälle rajapinnan kautta
    ...    testin esivalmisteluksi.
    [Arguments]    ${otsikko}    ${paiva}
    ${runko}=    Create Dictionary    title=${otsikko}    date=${paiva}    allDay=${True}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /calendar-events    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201

Luo Tehtava Rajapinnalla
    [Documentation]    Luo tehtävän rajapinnan kautta. Projektiksi tulee testiprojekti,
    ...    ellei toista anneta.
    [Arguments]    ${otsikko}    &{lisakentat}
    ${runko}=    Create Dictionary    title=${otsikko}    projectId=${PROJEKTI_ID}
    Set To Dictionary    ${runko}    &{lisakentat}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Poista Ajon Merkinnat Aikavalilta
    [Documentation]    Poistaa annetulta aikaväliltä tämän ajon kalenterimerkinnät
    ...    (otsikko alkaa ajon etuliitteellä).
    [Arguments]    ${alku}    ${loppu}
    ${merkinnat}=    Tee Kirjautunut Pyynto    GET    /calendar-events?from=${alku}&to=${loppu}
    IF    ${merkinnat.status_code} != 200    RETURN
    FOR    ${merkinta}    IN    @{merkinnat.json()}
        IF    $merkinta['title'].startswith($ETULIITE)
            Run Keyword And Ignore Error
            ...    Tee Kirjautunut Pyynto    DELETE    /calendar-events/${merkinta}[_id]
        END
    END

Siivoa Kalenteritestit
    [Documentation]    Poistaa tämän ajon kalenterimerkinnät vuodelta 2026 ja kuluvalta
    ...    vuodelta (widgettitesti luo merkinnän tälle päivälle), tämän ajon projektit
    ...    tehtävineen (tehtävän poisto poistaa myös sen aikakirjaukset) ja palauttaa
    ...    dashboardin alkuperäisen asettelun.
    Poista Ajon Merkinnat Aikavalilta    2026-01-01    2026-12-31
    ${vuosi}=    Evaluate    datetime.date.today().year    modules=datetime
    IF    ${vuosi} != 2026
        Poista Ajon Merkinnat Aikavalilta    ${vuosi}-01-01    ${vuosi}-12-31
    END
    ${projektit}=    Tee Kirjautunut Pyynto    GET    /projects
    FOR    ${projekti}    IN    @{projektit.json()}
        IF    $projekti['name'].startswith($ETULIITE)
            ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${projekti}[_id]
            FOR    ${tehtava}    IN    @{tehtavat.json()}
                Run Keyword And Ignore Error
                ...    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava}[_id]
            END
            Run Keyword And Ignore Error
            ...    Tee Kirjautunut Pyynto    DELETE    /projects/${projekti}[_id]
        END
    END
    Run Keyword And Ignore Error
    ...    Tee Kirjautunut Pyynto    PUT    /dashboard-layout    ${ALKUPERAINEN_ASETTELU}
    Close Browser