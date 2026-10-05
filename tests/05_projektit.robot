*** Settings ***
Documentation    Testijoukko 5: Projektit.
...    Testaa projektien luonnin, muokkauksen, peruutuksen, repository-linkin ja
...    poistosäännöt selaimessa kuten oikea käyttäjä, sen, että projektin poisto
...    poistaa sen aikakirjaukset ja nollaa näkymävalinnat, sekä projektilistan
...    kokonaisajan.
...    Kattaa testitapaukset TC04-001 - TC04-009 ja TC04-012.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Projektitestit
Suite Teardown    Siivoa Projektitestit
Test Setup    Mene Projekteihin


*** Test Cases ***
Projektin luonti lomakkeella onnistuu
    [Documentation]    TC04-001. Odotettu tulos: lomakkeella luotu projekti näkyy
    ...    listassa annetulla nimellä, kuvauksella ja tilalla Active.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} luonti
    Avaa Projektilomake
    Fill Text    ${KENTTA_NIMI}    ${nimi}
    Fill Text    ${KENTTA_KUVAUS}    Robotin luoma kuvaus
    Click    ${TALLENNA}
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${nimi}"))    visible    timeout=10s
    Projektin Tila On    ${nimi}    active
    Get Text    ${KORTTI}:has(h3:text-is("${nimi}")) >> p    ==    Robotin luoma kuvaus

Projektia ei voi luoda ilman nimeä
    [Documentation]    TC04-002. Odotettu tulos: tyhjällä nimellä lomaketta ei lähetetä,
    ...    lomake pysyy auki eikä listaan tule uutta projektia.
    [Tags]    selain
    ${ennen}=    Get Element Count    ${KORTTI}
    Avaa Projektilomake
    Click    ${TALLENNA}
    Wait For Elements State    .project-form-panel    visible
    Get Element Count    ${KORTTI}    ==    ${ennen}
    Click    .project-form-actions >> text="Cancel"

Projektin muokkaus tallentuu
    [Documentation]    TC04-003. Odotettu tulos: muokattu nimi ja tila näkyvät listassa
    ...    ja säilyvät sivun päivityksen jälkeen.
    [Tags]    selain
    ${vanha}=    Set Variable    ${ETULIITE} muokattava
    ${uusi}=    Set Variable    ${ETULIITE} muokattu
    Luo Projekti Rajapinnalla    ${vanha}
    Reload
    Mene Projekteihin
    Click    ${KORTTI}:has(h3:text-is("${vanha}")) >> button >> text="Edit"
    Fill Text    ${KENTTA_NIMI}    ${uusi}
    Select Options By    ${KENTTA_TILA}    value    completed
    Click    ${TALLENNA}
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${uusi}"))    visible    timeout=10s
    Reload
    Mene Projekteihin
    Projektin Tila On    ${uusi}    completed
    Get Element Count    ${KORTTI}:has(h3:text-is("${vanha}"))    ==    0

Muokkauksen peruutus ei muuta projektia
    [Documentation]    TC04-004. Odotettu tulos: kun muokkaus perutaan, projektin nimi
    ...    pysyy ennallaan.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} peruutus
    Luo Projekti Rajapinnalla    ${nimi}
    Reload
    Mene Projekteihin
    Click    ${KORTTI}:has(h3:text-is("${nimi}")) >> button >> text="Edit"
    Fill Text    ${KENTTA_NIMI}    ${nimi} ei saa tallentua
    Click    .project-form-actions >> text="Cancel"
    Wait For Elements State    .project-form-panel    detached    timeout=5s
    Get Element Count    ${KORTTI}:has(h3:text-is("${nimi}"))    ==    1

Repository-linkki avautuu turvallisesti
    [Documentation]    TC04-005. Odotettu tulos: repository-linkki avautuu uuteen
    ...    välilehteen, eikä avattu sivu saa viittausta sovellukseen (rel=noreferrer).
    [Tags]    selain    tietoturva
    ${nimi}=    Set Variable    ${ETULIITE} repository
    Luo Projekti Rajapinnalla    ${nimi}    repositoryUrl=https://github.com/example/repo
    Reload
    Mene Projekteihin
    ${linkki}=    Set Variable    ${KORTTI}:has(h3:text-is("${nimi}")) >> a.project-repository
    Get Attribute    ${linkki}    href    ==    https://github.com/example/repo
    Get Attribute    ${linkki}    target    ==    _blank
    Get Attribute    ${linkki}    rel    contains    noreferrer

Tyhjän projektin poisto onnistuu
    [Documentation]    TC04-006. Odotettu tulos: poistovahvistus avautuu, ja vahvistuksen
    ...    jälkeen projekti katoaa listasta myös sivun päivityksen jälkeen.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} poistettava
    Luo Projekti Rajapinnalla    ${nimi}
    Reload
    Mene Projekteihin
    Click    ${KORTTI}:has(h3:text-is("${nimi}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete project?"    visible    timeout=10s
    Click    role=dialog >> button >> text="Delete project"
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${nimi}"))    detached    timeout=10s
    Reload
    Mene Projekteihin
    Get Element Count    ${KORTTI}:has(h3:text-is("${nimi}"))    ==    0

Ei-tyhjän projektin poisto estetään
    [Documentation]    TC04-007. Odotettu tulos: kun projektissa on tehtävä, poistodialogi
    ...    kertoo syyn eikä näytä poistopainiketta. Projekti säilyy.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} ei tyhjä
    ${projekti_id}=    Luo Projekti Rajapinnalla    ${nimi}
    ${runko}=    Create Dictionary    title=Robotin tehtävä    projectId=${projekti_id}
    ${tehtava}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${tehtava.status_code}    201
    Reload
    Mene Projekteihin
    Click    ${KORTTI}:has(h3:text-is("${nimi}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text=/Delete them first/    visible    timeout=10s
    Get Element Count    role=dialog >> button >> text="Delete project"    ==    0
    Keyboard Key    press    Escape
    Get Element Count    ${KORTTI}:has(h3:text-is("${nimi}"))    ==    1

Poistodialogi sulkeutuu Escapella
    [Documentation]    TC04-008. Odotettu tulos: Escape sulkee poistodialogin, eikä
    ...    projektia poisteta.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} escape
    Luo Projekti Rajapinnalla    ${nimi}
    Reload
    Mene Projekteihin
    Click    ${KORTTI}:has(h3:text-is("${nimi}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog    visible    timeout=10s
    Keyboard Key    press    Escape
    Wait For Elements State    role=dialog    detached    timeout=5s
    Get Element Count    ${KORTTI}:has(h3:text-is("${nimi}"))    ==    1

Projektin poisto poistaa aikakirjaukset ja nollaa näkymävalinnan
    [Documentation]    TC04-009. Odotettu tulos: kun projektille on kirjattu aikaa ilman
    ...    tehtävää ja projekti on valittuna Tasks-näkymässä, poistodialogi kertoo
    ...    poistuvasta ajasta. Poiston jälkeen projektin aikakirjaukset ovat poistuneet
    ...    ja Tasks-näkymän valinta on nollattu.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} aikaprojekti
    ${projekti_id}=    Luo Projekti Rajapinnalla    ${nimi}
    Kirjaa Aikaa Rajapinnalla    ${projekti_id}
    ${maara}=    Aikakirjausten Maara    projectId    ${projekti_id}
    Should Be Equal As Integers    ${maara}    1
    ${runko}=    Create Dictionary    selectedProjectId=${projekti_id}
    ${valinta}=    Tee Kirjautunut Pyynto    PUT    /tasks-view    ${runko}
    Should Be Equal As Integers    ${valinta.status_code}    200
    Reload
    Mene Projekteihin
    Click    ${KORTTI}:has(h3:text-is("${nimi}")) >> button >> text="Delete"
    Wait For Elements State    role=dialog >> text="Delete project?"    visible    timeout=10s
    Get Text    role=dialog    contains    tracked time
    Click    role=dialog >> button >> text="Delete project"
    Wait For Elements State    ${KORTTI}:has(h3:text-is("${nimi}"))    detached    timeout=10s
    ${maara}=    Aikakirjausten Maara    projectId    ${projekti_id}
    Should Be Equal As Integers    ${maara}    0
    ${nakyma}=    Tee Kirjautunut Pyynto    GET    /tasks-view
    Should Be Equal As Integers    ${nakyma.status_code}    200
    ${nollattu}=    Evaluate    ($nakyma.json() or {}).get('selectedProjectId') in (None, '')
    Should Be True    ${nollattu}    msg=Tasks-näkymän valinta ei nollautunut: ${nakyma.text}

Projektilistan kokonaisaika näkyy oikein
    [Documentation]    TC04-012. Odotettu tulos: projektikortin Total time näyttää
    ...    kokonaisajan. Kun projektin tehtävän arvio on 30 min ja sille on kirjattu
    ...    5 min, kokonaisaika on 35 min. Tyhjän projektin kokonaisaika on 0 h.
    [Tags]    selain
    ${nimi}=    Set Variable    ${ETULIITE} kokonaisaika
    ${tyhja}=    Set Variable    ${ETULIITE} tyhjä kokonaisaika
    ${projekti_id}=    Luo Projekti Rajapinnalla    ${nimi}
    Luo Projekti Rajapinnalla    ${tyhja}
    ${runko}=    Create Dictionary    title=${ETULIITE} arvioitu tehtävä    projectId=${projekti_id}
    ...    estimatedMinutes=${30}
    ${tehtava}=    Tee Kirjautunut Pyynto    POST    /tasks    ${runko}
    Should Be Equal As Integers    ${tehtava.status_code}    201
    Kirjaa Aikaa Rajapinnalla    ${projekti_id}    ${tehtava.json()}[_id]
    Reload
    Mene Projekteihin
    Get Text    ${KORTTI}:has(h3:text-is("${nimi}")) >> .project-tracked-time    ==    35 min
    Get Text    ${KORTTI}:has(h3:text-is("${tyhja}")) >> .project-tracked-time    ==    0 h


*** Keywords ***
Valmistele Projektitestit
    [Documentation]    Kirjautuu testitunnuksella ja luo ajolle satunnaisen etuliitteen,
    ...    jotta testien projektit erottuvat aiemmista ajoista ja siivous osuu vain niihin.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${tunniste}=    Generate Random String    6    [LOWER][NUMBERS]
    Set Suite Variable    ${ETULIITE}    Robot ${tunniste}
    Set Suite Variable    ${KORTTI}    .project-item
    Set Suite Variable    ${KENTTA_NIMI}    .project-form-grid label:has-text("Name") input
    Set Suite Variable    ${KENTTA_TILA}    .project-form-grid label:has-text("Status") select
    Set Suite Variable    ${KENTTA_KUVAUS}    .project-form-grid label:has-text("Description") textarea
    Set Suite Variable    ${TALLENNA}    .project-save-button

Mene Projekteihin
    [Documentation]    Avaa Projects-sivun sivupalkista ja odottaa sen latautuvan.
    Click    .sidebar-item >> text="Projects"
    Wait For Elements State    h1 >> text="Projects"    visible    timeout=10s

Avaa Projektilomake
    [Documentation]    Avaa uuden projektin lomakkeen.
    Click    .projects-create-button
    Wait For Elements State    .project-form-panel    visible    timeout=5s

Projektin Tila On
    [Documentation]    Tarkistaa projektin tilan tilamerkin CSS-luokasta. Näkyvää tekstiä
    ...    ei verrata, koska CSS näyttää sen isoilla kirjaimilla.
    [Arguments]    ${nimi}    ${tila}
    Get Element Count
    ...    ${KORTTI}:has(h3:text-is("${nimi}")) >> .project-status.${tila}    ==    1

Luo Projekti Rajapinnalla
    [Documentation]    Luo projektin suoraan rajapinnan kautta testin esivalmisteluksi
    ...    ja palauttaa sen tunnisteen. Näin testi keskittyy vain testattavaan asiaan.
    [Arguments]    ${nimi}    &{lisakentat}
    ${runko}=    Create Dictionary    name=${nimi}    &{lisakentat}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /projects    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    RETURN    ${vastaus.json()}[_id]

Siivoa Projektitestit
    [Documentation]    Poistaa tämän ajon projektit (nimi alkaa ajon etuliitteellä) ja niiden
    ...    tehtävät. Tehtävät poistetaan ensin, koska ei-tyhjää projektia ei voi poistaa.
    ...    Tehtävän poisto poistaa myös sen aikakirjaukset.
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /projects
    FOR    ${projekti}    IN    @{vastaus.json()}
        IF    $projekti['name'].startswith($ETULIITE)
            Poista Projekti Tehtavineen    ${projekti}[_id]
        END
    END
    Close Browser

Poista Projekti Tehtavineen
    [Documentation]    Poistaa projektin tehtävät ja sen jälkeen projektin.
    [Arguments]    ${projekti_id}
    ${tehtavat}=    Tee Kirjautunut Pyynto    GET    /tasks?projectId=${projekti_id}
    FOR    ${tehtava}    IN    @{tehtavat.json()}
        Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /tasks/${tehtava}[_id]
    END
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /projects/${projekti_id}