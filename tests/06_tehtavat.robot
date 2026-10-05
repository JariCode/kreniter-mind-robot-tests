*** Settings ***
Documentation    Testijoukko 6: Tehtävät ja alatehtävät.
...    Testaa tehtävien luonnin, muokkauksen, tilan vaihdon valikosta ja raahaamalla,
...    alatehtävät, päätehtävän poiston, kirjatun ajan poiston tehtävän mukana ja
...    projektivalinnan säilymisen selaimessa kuten oikea käyttäjä.
...    Kattaa testitapaukset TC05-001, TC05-002, TC05-004 - TC05-011 ja TC05-014.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Tehtavatestit
Suite Teardown    Siivoa Tehtavatestit
Test Setup    Mene Testiprojektin Tehtaviin


*** Test Cases ***
Tehtävän luonti lomakkeella onnistuu
    [Documentation]    TC05-001. Odotettu tulos: lomakkeella luotu tehtävä näkyy listassa
    ...    annetulla otsikolla, aloittamattomana (todo) ja prioriteetilla high.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} luonti
    Avaa Tehtavalomake
    Fill Text    ${KENTTA_OTSIKKO}    ${otsikko}
    Select Options By    ${KENTTA_PRIORITEETTI}    value    high
    Fill Text    ${KENTTA_KUVAUS}    Robotin luoma tehtävä
    Click    ${TALLENNA}
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${otsikko}"))    visible    timeout=10s
    Get Element Count    ${KORTTI}.status-todo:has(h3:text-is("${otsikko}"))    ==    1
    Get Element Count    ${KORTTI}:has(h3:text-is("${otsikko}")) >> .task-priority.high    ==    1
    Get Text    ${KORTTI}:has(h3:text-is("${otsikko}")) >> .task-description    ==    Robotin luoma tehtävä

Tehtävää ei voi luoda ilman otsikkoa
    [Documentation]    TC05-002. Odotettu tulos: tyhjällä otsikolla lomaketta ei lähetetä,
    ...    eikä listaan tule uutta tehtävää.
    [Tags]    selain
    ${ennen}=    Get Element Count    ${KORTTI}
    Avaa Tehtavalomake
    Click    ${TALLENNA}
    Get Element Count    ${KORTTI}    ==    ${ennen}
    Click    .task-form-actions >> text="Cancel"

Tehtävän tilan vaihto tallentuu
    [Documentation]    TC05-004. Odotettu tulos: kortin tilavalikosta vaihdettu tila
    ...    näkyy heti ja säilyy sivun päivityksen jälkeen.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} tilan vaihto
    Luo Tehtava Rajapinnalla    ${otsikko}
    Reload
    Mene Testiprojektin Tehtaviin
    Select Options By    select[aria-label="Change status for ${otsikko}"]    value    in-progress
    Wait For Elements State    ${KORTTI}.status-in-progress:has(h3:text-is("${otsikko}"))
    ...    visible    timeout=10s
    Reload
    Mene Testiprojektin Tehtaviin
    Get Element Count    ${KORTTI}.status-in-progress:has(h3:text-is("${otsikko}"))    ==    1

Tehtävän muokkaus tallentuu
    [Documentation]    TC05-005. Odotettu tulos: muokkausikkunassa muutettu otsikko näkyy
    ...    listassa ja säilyy sivun päivityksen jälkeen.
    [Tags]    selain
    ${vanha}=    Set Variable    ${ETULIITE} muokattava
    ${uusi}=    Set Variable    ${ETULIITE} muokattu
    Luo Tehtava Rajapinnalla    ${vanha}
    Reload
    Mene Testiprojektin Tehtaviin
    Click    ${KORTTI}:has(h3:text-is("${vanha}")) >> button >> text="Edit"
    Wait For Elements State    role=dialog >> text="Edit task"    visible    timeout=5s
    Fill Text    ${KENTTA_OTSIKKO}    ${uusi}
    Click    ${TALLENNA}
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${uusi}"))    visible    timeout=10s
    Reload
    Mene Testiprojektin Tehtaviin
    Get Element Count    ${KORTTI}:has(h3:text-is("${uusi}"))    ==    1
    Get Element Count    ${KORTTI}:has(h3:text-is("${vanha}"))    ==    0

Muokkausikkuna sulkeutuu Escapella
    [Documentation]    TC05-006. Odotettu tulos: Escape sulkee muokkausikkunan, eikä
    ...    tehtävään tehty muutos tallennu.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} escape
    Luo Tehtava Rajapinnalla    ${otsikko}
    Reload
    Mene Testiprojektin Tehtaviin
    Click    ${KORTTI}:has(h3:text-is("${otsikko}")) >> button >> text="Edit"
    Wait For Elements State    role=dialog >> text="Edit task"    visible    timeout=5s
    Fill Text    ${KENTTA_OTSIKKO}    ${otsikko} ei saa tallentua
    Keyboard Key    press    Escape
    Wait For Elements State    role=dialog    detached    timeout=5s
    Get Element Count    ${KORTTI}:has(h3:text-is("${otsikko}"))    ==    1

Alatehtävän luonti onnistuu
    [Documentation]    TC05-007. Odotettu tulos: lomakkeella luotu alatehtävä näyttää
    ...    päätehtävänsä nimen kortissa.
    [Tags]    selain
    ${paa}=    Set Variable    ${ETULIITE} päätehtävä
    ${ala}=    Set Variable    ${ETULIITE} alatehtävä
    Luo Tehtava Rajapinnalla    ${paa}
    Reload
    Mene Testiprojektin Tehtaviin
    Avaa Tehtavalomake
    Fill Text    ${KENTTA_OTSIKKO}    ${ala}
    Select Options By    ${KENTTA_PAATEHTAVA}    label    ${paa}
    Click    ${TALLENNA}
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${ala}"))    visible    timeout=10s
    Get Text    ${KORTTI}:has(h3:text-is("${ala}")) >> .task-meta    contains    Parent: ${paa}

Päätehtävän poisto varoittaa ja irrottaa alatehtävät
    [Documentation]    TC05-008. Odotettu tulos: poistodialogi kertoo, että alatehtävästä
    ...    tulee tehtävä ilman päätehtävää. Poiston jälkeen alatehtävä säilyy ilman
    ...    päätehtävää.
    [Tags]    selain
    ${paa}=    Set Variable    ${ETULIITE} poistettava pää
    ${ala}=    Set Variable    ${ETULIITE} irtoava ala
    ${paa_id}=    Luo Tehtava Rajapinnalla    ${paa}
    Luo Tehtava Rajapinnalla    ${ala}    parentTaskId=${paa_id}
    Reload
    Mene Testiprojektin Tehtaviin
    Click    ${KORTTI}:has(h3:text-is("${paa}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete task?"    visible    timeout=10s
    Wait For Elements State    role=dialog >> text=/without a parent/    visible    timeout=10s
    Get Text    role=dialog    contains    ${ala}
    Click    role=dialog >> button >> text="Delete task"
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${paa}"))    detached    timeout=10s
    Reload
    Mene Testiprojektin Tehtaviin
    Get Element Count    ${KORTTI}:has(h3:text-is("${ala}"))    ==    1
    Get Text    ${KORTTI}:has(h3:text-is("${ala}")) >> .task-meta    not contains    Parent:

Poistodialogi sulkeutuu Escapella
    [Documentation]    TC05-009. Odotettu tulos: Escape sulkee poistodialogin, eikä
    ...    tehtävää poisteta.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} poiston peruutus
    Luo Tehtava Rajapinnalla    ${otsikko}
    Reload
    Mene Testiprojektin Tehtaviin
    Click    ${KORTTI}:has(h3:text-is("${otsikko}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete task?"    visible    timeout=10s
    Keyboard Key    press    Escape
    Wait For Elements State    role=dialog    detached    timeout=5s
    Get Element Count    ${KORTTI}:has(h3:text-is("${otsikko}"))    ==    1

Tehtävän poisto varoittaa kirjatusta ajasta ja poistaa sen
    [Documentation]    TC05-010. Odotettu tulos: kun tehtävälle on kirjattu aikaa,
    ...    poistodialogi kertoo poistuvasta ajasta. Poiston jälkeen tehtävän
    ...    aikakirjaukset ovat poistuneet.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} aikatehtävä
    ${tehtava_id}=    Luo Tehtava Rajapinnalla    ${otsikko}
    Kirjaa Aikaa Rajapinnalla    ${PROJEKTI_ID}    ${tehtava_id}
    ${maara}=    Aikakirjausten Maara    taskId    ${tehtava_id}
    Should Be Equal As Integers    ${maara}    1
    Reload
    Mene Testiprojektin Tehtaviin
    Click    ${KORTTI}:has(h3:text-is("${otsikko}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete task?"    visible    timeout=10s
    Get Text    role=dialog    contains    tracked time
    Get Text    role=dialog    contains    5 min
    Click    role=dialog >> button >> text="Delete task"
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${otsikko}"))    detached    timeout=10s
    ${maara}=    Aikakirjausten Maara    taskId    ${tehtava_id}
    Should Be Equal As Integers    ${maara}    0

Projektivalinta säilyy sivun päivityksen yli
    [Documentation]    TC05-011. Odotettu tulos: Tasks-sivulla valittu projekti on yhä
    ...    valittuna sivun päivityksen jälkeen ilman uutta valintaa.
    [Tags]    selain
    Reload
    Click    .sidebar-item >> text="Tasks"
    Wait For Elements State    h1 >> text="Tasks"    visible    timeout=10s
    Get Selected Options    id=tasks-project    value    ==    ${PROJEKTI_ID}

Tilan vaihto raahaamalla tallentuu
    [Documentation]    TC05-014. Odotettu tulos: kun tehtäväkortti raahataan Not started
    ...    -sarakkeesta Completed-sarakkeeseen, kortti siirtyy sarakkeeseen, tehtävän
    ...    tila on completed sivun päivityksen jälkeen ja tila on tallentunut myös
    ...    rajapintaan. Raahaus tehdään selaimen omilla raahaustapahtumilla, koska
    ...    tehtävätaulu käyttää HTML5-raahausta, jota pelkkä hiiren liike ei käynnistä.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} raahattava
    ${tehtava_id}=    Luo Tehtava Rajapinnalla    ${otsikko}
    Reload
    Mene Testiprojektin Tehtaviin
    ${kortti}=    Set Variable    ${KORTTI}:has(h3:text-is("${otsikko}"))
    Wait For Elements State    ${SARAKE.format("Not started")} >> ${kortti}    visible    timeout=10s
    Raahaa Tehtava Sarakkeeseen    ${otsikko}    Completed
    Wait For Elements State    ${SARAKE.format("Completed")} >> ${kortti}    visible    timeout=10s
    Reload
    Mene Testiprojektin Tehtaviin
    Get Element Count    ${SARAKE.format("Completed")} >> ${kortti}    ==    1
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /tasks/${tehtava_id}
    Should Be Equal    ${vastaus.json()}[status]    completed


*** Keywords ***
Valmistele Tehtavatestit
    [Documentation]    Kirjautuu testitunnuksella, luo ajolle satunnaisen etuliitteen ja
    ...    oman testiprojektin, jonka tehtäviä testit käsittelevät.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    ${runko}=    Create Dictionary    name=${ETULIITE} tehtäväprojekti
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    Set Suite Variable    ${PROJEKTI_ID}    ${projekti.json()}[_id]
    Set Suite Variable    ${KORTTI}    .task-item
    Set Suite Variable    ${SARAKE}    .task-column:has(.task-column-header h3:text-is("{}"))
    Set Suite Variable    ${KENTTA_OTSIKKO}    .task-form-grid label:has-text("Title") input
    Set Suite Variable    ${KENTTA_PRIORITEETTI}    .task-form-grid label:has-text("Priority") select
    Set Suite Variable    ${KENTTA_PAATEHTAVA}    .task-form-grid label:has-text("Parent task") select
    Set Suite Variable    ${KENTTA_KUVAUS}    .task-form-grid label:has-text("Description") textarea
    Set Suite Variable    ${TALLENNA}    .task-save-button
    Reload

Mene Testiprojektin Tehtaviin
    [Documentation]    Avaa Tasks-sivun ja valitsee testiprojektin projektivalikosta.
    Click    .sidebar-item >> text="Tasks"
    Wait For Elements State    h1 >> text="Tasks"    visible    timeout=10s
    Select Options By    id=tasks-project    value    ${PROJEKTI_ID}

Avaa Tehtavalomake
    [Documentation]    Avaa uuden tehtävän lomakkeen.
    Click    .tasks-create-button
    Wait For Elements State    ${KENTTA_OTSIKKO}    visible    timeout=5s

Raahaa Tehtava Sarakkeeseen
    [Documentation]    Raahaa tehtäväkortin annettuun sarakkeeseen lähettämällä samat
    ...    HTML5-raahaustapahtumat kuin selain oikeassa raahauksessa: dragstart kortille,
    ...    dragover ja drop sarakkeelle sekä dragend kortille. Tapahtumien välissä on
    ...    lyhyt tauko, jotta sovellus ehtii tallentaa raahattavan kortin ennen pudotusta.
    [Arguments]    ${otsikko}    ${sarake}
    ${tulos}=    Evaluate JavaScript    ${None}
    ...    async () => {
    ...        const tauko = () => new Promise(r => setTimeout(r, 200));
    ...        const kortti = [...document.querySelectorAll('.task-item')]
    ...            .find(k => k.querySelector('h3')?.textContent.trim() === '${otsikko}');
    ...        const kohde = [...document.querySelectorAll('.task-column')]
    ...            .find(s => s.querySelector('.task-column-header h3')?.textContent.trim() === '${sarake}');
    ...        if (!kortti || !kohde) return 'ei löytynyt';
    ...        const siirto = new DataTransfer();
    ...        kortti.dispatchEvent(new DragEvent('dragstart', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        await tauko();
    ...        kohde.dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        await tauko();
    ...        kohde.dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        await tauko();
    ...        kortti.dispatchEvent(new DragEvent('dragend', { bubbles: true, cancelable: true, dataTransfer: siirto }));
    ...        return 'ok';
    ...    }
    Should Be Equal    ${tulos}    ok    msg=Raahattavaa korttia tai kohdesaraketta ei löytynyt

Luo Tehtava Rajapinnalla
    [Documentation]    Luo testiprojektiin tehtävän rajapinnan kautta testin
    ...    esivalmisteluksi ja palauttaa sen tunnisteen.
    [Arguments]    ${otsikko}    &{lisakentat}
    ${runko}=    Create Dictionary    title=${otsikko}    projectId=${PROJEKTI_ID}    &{lisakentat}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Siivoa Tehtavatestit
    [Documentation]    Poistaa testiprojektin kaikki tehtävät ja sen jälkeen projektin.
    ...    Alatehtävät irtoavat automaattisesti, kun päätehtävä poistetaan, ja tehtävän
    ...    poisto poistaa myös sen aikakirjaukset.
    ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${PROJEKTI_ID}
    FOR    ${tehtava}    IN    @{tehtavat.json()}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava}[_id]
    END
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${PROJEKTI_ID}
    Close Browser