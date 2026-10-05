*** Settings ***
Documentation    Testijoukko 8: Muistiinpanot.
...    Testaa muistiinpanojen luonnin, muokkauksen, prioriteetin vaihdon lomakkeella
...    ja raahaamalla sekä poiston selaimessa kuten oikea käyttäjä.
...    Kattaa testitapaukset TC07-001 - TC07-007.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Muistiinpanotestit
Suite Teardown    Siivoa Muistiinpanotestit
Test Setup    Mene Muistiinpanoihin


*** Test Cases ***
Muistiinpanon luonti lomakkeella onnistuu
    [Documentation]    TC07-001. Odotettu tulos: lomakkeella luotu muistiinpano näkyy
    ...    high-sarakkeessa annetulla otsikolla, sisällöllä ja projektin nimellä.
    ...    Projektin nimi verrataan kirjainkoosta riippumatta, koska CSS näyttää
    ...    sen isoilla kirjaimilla.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} luonti
    Avaa Muistiinpanolomake
    Fill Text    ${KENTTA_OTSIKKO}    ${otsikko}
    Select Options By    ${KENTTA_PROJEKTI}    value    ${PROJEKTI_ID}
    Select Options By    ${KENTTA_PRIORITEETTI}    value    high
    Fill Text    ${KENTTA_SISALTO}    Robotin kirjoittama sisältö
    Click    ${TALLENNA}
    ${kortti}=    Set Variable    .notes-column-high ${KORTTI}:has(h3:text-is("${otsikko}"))
    Wait For Elements State    ${kortti}    visible    timeout=10s
    Get Text    ${kortti} >> p    ==    Robotin kirjoittama sisältö
    ${projekti}=    Get Text    ${kortti} >> .note-project
    Should Be Equal As Strings    ${projekti}    ${PROJEKTIN_NIMI}    ignore_case=True

Muistiinpanoa ei voi luoda ilman otsikkoa
    [Documentation]    TC07-002. Odotettu tulos: tyhjällä otsikolla lomaketta ei lähetetä,
    ...    eikä uutta muistiinpanoa tule näkyviin.
    [Tags]    selain
    ${ennen}=    Get Element Count    ${KORTTI}
    Avaa Muistiinpanolomake
    Fill Text    ${KENTTA_SISALTO}    Sisältö ilman otsikkoa
    Click    ${TALLENNA}
    Get Element Count    ${KORTTI}    ==    ${ennen}
    Click    .note-form-actions >> text="Cancel"

Muistiinpanon muokkaus tallentuu
    [Documentation]    TC07-003. Odotettu tulos: muokattu otsikko ja sisältö näkyvät ja
    ...    säilyvät sivun päivityksen jälkeen.
    [Tags]    selain
    ${vanha}=    Set Variable    ${ETULIITE} muokattava
    ${uusi}=    Set Variable    ${ETULIITE} muokattu
    Luo Muistiinpano Rajapinnalla    ${vanha}
    Reload
    Mene Muistiinpanoihin
    Click    ${KORTTI}:has(h3:text-is("${vanha}")) >> button >> text="Edit"
    Wait For Elements State    .note-form-panel >> text="Edit note"    visible    timeout=5s
    Fill Text    ${KENTTA_OTSIKKO}    ${uusi}
    Fill Text    ${KENTTA_SISALTO}    Muokattu sisältö
    Click    ${TALLENNA}
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${uusi}"))    visible    timeout=10s
    Reload
    Mene Muistiinpanoihin
    Get Text    ${KORTTI}:has(h3:text-is("${uusi}")) >> p    ==    Muokattu sisältö
    Get Element Count    ${KORTTI}:has(h3:text-is("${vanha}"))    ==    0

Prioriteetin vaihto lomakkeella siirtää sarakkeeseen
    [Documentation]    TC07-004. Odotettu tulos: kun prioriteetiksi vaihdetaan low,
    ...    muistiinpano siirtyy low-sarakkeeseen.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} prioriteetti lomake
    Luo Muistiinpano Rajapinnalla    ${otsikko}    priority=high
    Reload
    Mene Muistiinpanoihin
    Click    ${KORTTI}:has(h3:text-is("${otsikko}")) >> button >> text="Edit"
    Select Options By    ${KENTTA_PRIORITEETTI}    value    low
    Click    ${TALLENNA}
    Wait For Elements State    .notes-column-low ${KORTTI}:has(h3:text-is("${otsikko}"))
    ...    visible    timeout=10s
    Get Element Count    .notes-column-high ${KORTTI}:has(h3:text-is("${otsikko}"))    ==    0

Prioriteetin vaihto raahaamalla tallentuu
    [Documentation]    TC07-005. Odotettu tulos: kun muistiinpano raahataan medium-
    ...    sarakkeesta high-sarakkeeseen, se siirtyy sinne ja pysyy siellä sivun
    ...    päivityksen jälkeen.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} raahattava
    Luo Muistiinpano Rajapinnalla    ${otsikko}    priority=medium
    Reload
    Mene Muistiinpanoihin
    Drag And Drop    .notes-column-medium ${KORTTI}:has(h3:text-is("${otsikko}"))
    ...    .notes-column-high .notes-column-content
    Wait For Elements State    .notes-column-high ${KORTTI}:has(h3:text-is("${otsikko}"))
    ...    visible    timeout=10s
    Reload
    Mene Muistiinpanoihin
    Get Element Count    .notes-column-high ${KORTTI}:has(h3:text-is("${otsikko}"))    ==    1

Muistiinpanon poisto onnistuu
    [Documentation]    TC07-006. Odotettu tulos: poistovahvistuksen jälkeen muistiinpano
    ...    katoaa myös sivun päivityksen jälkeen.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} poistettava
    Luo Muistiinpano Rajapinnalla    ${otsikko}
    Reload
    Mene Muistiinpanoihin
    Click    ${KORTTI}:has(h3:text-is("${otsikko}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete note?"    visible    timeout=10s
    Click    role=dialog >> button >> text="Delete note"
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${otsikko}"))    detached    timeout=10s
    Reload
    Mene Muistiinpanoihin
    Get Element Count    ${KORTTI}:has(h3:text-is("${otsikko}"))    ==    0

Poistodialogi sulkeutuu Escapella
    [Documentation]    TC07-007. Odotettu tulos: Escape sulkee poistodialogin, eikä
    ...    muistiinpanoa poisteta.
    [Tags]    selain
    ${otsikko}=    Set Variable    ${ETULIITE} poiston peruutus
    Luo Muistiinpano Rajapinnalla    ${otsikko}
    Reload
    Mene Muistiinpanoihin
    Click    ${KORTTI}:has(h3:text-is("${otsikko}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete note?"    visible    timeout=10s
    Keyboard Key    press    Escape
    Wait For Elements State    role=dialog    detached    timeout=5s
    Get Element Count    ${KORTTI}:has(h3:text-is("${otsikko}"))    ==    1


*** Keywords ***
Valmistele Muistiinpanotestit
    [Documentation]    Kirjautuu testitunnuksella, luo ajolle satunnaisen etuliitteen ja
    ...    testiprojektin, johon muistiinpanon voi liittää.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    Set Suite Variable    ${PROJEKTIN_NIMI}    ${ETULIITE} muistiinpanoprojekti
    ${runko}=    Create Dictionary    name=${PROJEKTIN_NIMI}
    ${projekti}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${projekti.status_code}    201
    Set Suite Variable    ${PROJEKTI_ID}    ${projekti.json()}[_id]
    Set Suite Variable    ${KORTTI}    .note-item
    Set Suite Variable    ${KENTTA_OTSIKKO}    .note-form-grid label:has-text("Title") input
    Set Suite Variable    ${KENTTA_PROJEKTI}    .note-form-grid label:has-text("Project") select
    Set Suite Variable    ${KENTTA_PRIORITEETTI}    .note-form-grid label:has-text("Priority") select
    Set Suite Variable    ${KENTTA_SISALTO}    .note-form-grid label:has-text("Content") textarea
    Set Suite Variable    ${TALLENNA}    .note-form-actions >> button[type="submit"]
    Reload

Mene Muistiinpanoihin
    [Documentation]    Avaa Notes-sivun sivupalkista ja odottaa sen latautuvan.
    Click    .sidebar-item >> text="Notes"
    Wait For Elements State    h1 >> text="Notes"    visible    timeout=10s

Avaa Muistiinpanolomake
    [Documentation]    Avaa uuden muistiinpanon lomakkeen.
    Click    .notes-create-button
    Wait For Elements State    ${KENTTA_OTSIKKO}    visible    timeout=5s

Luo Muistiinpano Rajapinnalla
    [Documentation]    Luo testiprojektiin muistiinpanon rajapinnan kautta testin
    ...    esivalmisteluksi ja palauttaa sen tunnisteen.
    [Arguments]    ${otsikko}    &{lisakentat}
    ${runko}=    Create Dictionary    title=${otsikko}    projectId=${PROJEKTI_ID}    &{lisakentat}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /notes    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Siivoa Muistiinpanotestit
    [Documentation]    Poistaa tämän ajon muistiinpanot (otsikko alkaa ajon etuliitteellä)
    ...    ja sen jälkeen testiprojektin.
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /notes
    FOR    ${muistiinpano}    IN    @{vastaus.json()}
        IF    $muistiinpano['title'].startswith($ETULIITE)
            Run Keyword And Ignore Error
            ...    Tee Kirjautunut Pyynto    DELETE    /notes/${muistiinpano}[_id]
        END
    END
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${PROJEKTI_ID}
    Close Browser