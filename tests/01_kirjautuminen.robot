*** Settings ***
Documentation    Testijoukko 1: Kirjautuminen, istunto ja profiili.
...    Testaa rekisteröinnin, kirjautumisen, istunnon, uloskirjautumisen sekä Clerkin
...    Manage account -ikkunassa tehtävän profiilin hallinnan ja tilin poiston.
...    Profiilia muuttavat testit rekisteröivät oman testikäyttäjän ja poistavat sen
...    lopuksi, jotta vakiotestitili pysyy muuttumattomana. Salasanan vaihtotestin
...    uusi salasana luetaan .env-tiedostosta (UUSI_SALASANA).
...    Kattaa testitapaukset TC01-001 - TC01-009.
...    Esivaatimukset: .env-tiedoston testitili on luotu sovellukseen, ja Renderin
...    backend on käynnissä (tilin poisto kulkee webhookin kautta).
Resource    ../resources/yhteiset.robot
Suite Setup    Avaa Selain
Suite Teardown    Close Browser
Test Setup    Avaa Uusi Istunto
Test Teardown    Sulje Istunto


*** Test Cases ***
Rekisteröityminen ja tilin poisto onnistuvat
    [Documentation]    TC01-001. Odotettu tulos: uusi tili luodaan satunnaisella
    ...    testisähköpostilla ja käyttäjä pääsee dashboardille. Tilin poiston jälkeen
    ...    samalla sähköpostilla ei voi enää kirjautua.
    [Tags]    selain
    ${sahkoposti}=    Luo Testisahkoposti
    Rekisteroidy    ${sahkoposti}
    Poista Tili Sovelluksesta
    Varmista Etta Tili On Poistettu    ${sahkoposti}
    [Teardown]    Poista Tili Jos Testi Epaonnistui

Kirjautuminen testitunnuksella onnistuu
    [Documentation]    TC01-002. Odotettu tulos: oikeilla tunnuksilla käyttäjä pääsee
    ...    sisään ja dashboard näkyy.
    [Tags]    selain
    Kirjaudu Sisaan

Väärä salasana hylätään
    [Documentation]    TC01-003. Odotettu tulos: väärällä salasanalla ei päästä sisään,
    ...    Clerk näyttää virheilmoituksen eikä dashboard avaudu.
    [Tags]    selain    tietoturva
    Click    text=ENTER WORKSPACE
    Fill Text    input[name="identifier"]    ${TESTITUNNUS}
    Click    .cl-formButtonPrimary
    Fill Text    input[name="password"]    VaaraSalasana123!
    Click    .cl-formButtonPrimary
    Wait For Elements State    .cl-formFieldErrorText    visible    timeout=10s
    Get Element Count    h1 >> text=Dashboard    ==    0

Kirjautuminen säilyy sivun päivityksen yli
    [Documentation]    TC01-004. Odotettu tulos: sivun päivityksen jälkeen käyttäjä on
    ...    yhä kirjautuneena ja dashboard näkyy ilman uutta kirjautumista.
    [Tags]    selain
    Kirjaudu Sisaan
    Reload
    Wait For Elements State    h1 >> text=Dashboard    visible    timeout=20s

Uloskirjautuminen palauttaa etusivulle
    [Documentation]    TC01-005. Odotettu tulos: uloskirjautumisen jälkeen näkyy etusivu,
    ...    eikä dashboard palaa sivun päivityksessä.
    [Tags]    selain    tietoturva
    Kirjaudu Sisaan
    Kirjaudu Ulos
    Reload
    Wait For Elements State    text=ENTER WORKSPACE    visible    timeout=15s
    Get Element Count    h1 >> text=Dashboard    ==    0

Dashboard ei näy ilman kirjautumista
    [Documentation]    TC01-006. Odotettu tulos: kirjautumaton käyttäjä näkee vain
    ...    etusivun, eikä sovelluksen näkymiä näytetä.
    [Tags]    selain    tietoturva
    Wait For Elements State    text=ENTER WORKSPACE    visible    timeout=15s
    Get Element Count    h1 >> text=Dashboard    ==    0
    Get Element Count    text=Projects    ==    0

Nimen muutos näkyy headerin tervehdyksessä
    [Documentation]    TC01-007. Odotettu tulos: kun etunimi vaihdetaan Manage account
    ...    -ikkunassa, headerin tervehdys näyttää uuden nimen, myös sivun päivityksen
    ...    jälkeen.
    [Tags]    selain
    ${sahkoposti}=    Luo Testisahkoposti
    Rekisteroidy    ${sahkoposti}
    ${nimi}=    Generate Random String    6    [LOWER]
    ${nimi}=    Set Variable    Robotti${nimi}
    Avaa Profiili-ikkuna
    Click    .cl-profileSectionPrimaryButton__profile
    Fill Text    input[name="firstName"]    ${nimi}
    Click    .cl-formButtonPrimary
    Wait For Elements State    input[name="firstName"]    detached    timeout=10s
    Sulje Profiili-ikkuna
    Wait For Elements State    text=Welcome back, ${nimi}    visible    timeout=10s
    Reload
    Wait For Elements State    text=Welcome back, ${nimi}    visible    timeout=20s
    [Teardown]    Poista Testitili Ja Sulje Istunto

Salasanan vaihto toimii
    [Documentation]    TC01-008. Odotettu tulos: kun salasana vaihdetaan Manage account
    ...    -ikkunassa, Clerk pyytää nykyisen salasanan vahvistukseksi, ja vaihdon
    ...    jälkeen vanhalla salasanalla ei enää pääse sisään, mutta uudella pääsee.
    [Tags]    selain    tietoturva
    ${sahkoposti}=    Luo Testisahkoposti
    Rekisteroidy    ${sahkoposti}
    Avaa Profiili-ikkuna
    Click    text=Security
    Click    .cl-profileSectionPrimaryButton__password
    ${nykyinen}=    Get Element Count    input[name="currentPassword"]
    IF    ${nykyinen} > 0
        Fill Text    input[name="currentPassword"]    ${TESTISALASANA}
    END
    Fill Text    input[name="newPassword"]    ${UUSI_SALASANA}
    Fill Text    input[name="confirmPassword"]    ${UUSI_SALASANA}
    Click    .cl-formButtonPrimary
    Vahvista Salasanalla Jos Pyydetaan    ${TESTISALASANA}
    Wait For Elements State    input[name="newPassword"]    detached    timeout=15s
    Sulje Profiili-ikkuna
    Kirjaudu Ulos
    Click    text=ENTER WORKSPACE
    Fill Text    input[name="identifier"]    ${sahkoposti}
    Click    .cl-formButtonPrimary
    Fill Text    input[name="password"]    ${TESTISALASANA}
    Click    .cl-formButtonPrimary
    Wait For Elements State    .cl-formFieldErrorText    visible    timeout=10s
    Get Element Count    h1 >> text=Dashboard    ==    0
    Close Context
    Avaa Uusi Istunto
    Kirjaudu Sisaan    ${sahkoposti}    ${UUSI_SALASANA}
    [Teardown]    Poista Testitili Ja Sulje Istunto    ${UUSI_SALASANA}

Tilin poisto vaatii vahvistuksen ja oikean salasanan
    [Documentation]    TC01-009. Odotettu tulos: tilin poistopainike ei ole käytössä,
    ...    ennen kuin vahvistusteksti "Delete account" on kirjoitettu oikein, ja väärällä
    ...    salasanalla poisto ei onnistu. Oikealla vahvistuksella ja salasanalla tili
    ...    poistuu.
    [Tags]    selain    tietoturva
    ${sahkoposti}=    Luo Testisahkoposti
    Rekisteroidy    ${sahkoposti}
    Avaa Profiili-ikkuna
    Click    text=Security
    Click    button >> text=Delete account
    ${vahvistus}=    Set Variable    button[data-localization-key="userProfile.deletePage.confirm"]
    Fill Text    input[name="deleteConfirmation"]    Delete acount
    Get Element States    ${vahvistus}    contains    disabled
    Fill Text    input[name="deleteConfirmation"]    Delete account
    Get Element States    ${vahvistus}    contains    enabled
    Click    ${vahvistus}
    Wait For Elements State    input[name="password"]    visible    timeout=10s
    Fill Text    input[name="password"]    VaaraSalasana123!
    Click    .cl-formButtonPrimary >> text=Continue
    Wait For Elements State    .cl-formFieldErrorText    visible    timeout=10s
    Get Element Count    text=ENTER WORKSPACE    ==    0
    Fill Text    input[name="password"]    ${TESTISALASANA}
    Click    .cl-formButtonPrimary >> text=Continue
    Wait For Elements State    text=ENTER WORKSPACE    visible    timeout=20s
    Varmista Etta Tili On Poistettu    ${sahkoposti}
    [Teardown]    Poista Tili Jos Testi Epaonnistui


*** Keywords ***
Avaa Profiili-ikkuna
    [Documentation]    Avaa Clerkin Manage account -ikkunan käyttäjävalikosta.
    Avaa Kayttajavalikko
    Click    text=Manage account
    Wait For Elements State    .cl-userProfile-root    visible    timeout=10s

Sulje Profiili-ikkuna
    [Documentation]    Sulkee Clerkin Manage account -ikkunan.
    Click    .cl-modalCloseButton
    Wait For Elements State    .cl-userProfile-root    detached    timeout=10s

Sulje Avoimet Ikkunat
    [Documentation]    Sulkee kaikki auki jääneet Clerkin ikkunat Escapella, jotta ne
    ...    eivät peitä sivun painikkeita. Ikkunoita voi olla päällekkäin, esimerkiksi
    ...    salasanan vahvistus profiili-ikkunan päällä.
    FOR    ${i}    IN RANGE    3
        ${auki}=    Get Element Count    .cl-modalBackdrop
        IF    ${auki} == 0    BREAK
        Keyboard Key    press    Escape
        Sleep    0.5s
    END

Poista Testitili Ja Sulje Istunto
    [Documentation]    Teardown profiilitesteille: sulkee auki jääneet ikkunat, poistaa
    ...    testin luoman tilin sovelluksen kautta ja sulkee istunnon. Jos poisto
    ...    epäonnistuu, raporttiin tulee varoitus, ja tili poistetaan käsin.
    [Arguments]    ${salasana}=${TESTISALASANA}
    Run Keyword And Ignore Error    Sulje Avoimet Ikkunat
    ${tila}    ${viesti}=    Run Keyword And Ignore Error
    ...    Poista Tili Sovelluksesta    ${salasana}
    IF    '${tila}' == 'FAIL'
        Log    Testitilin poisto epäonnistui, poista se Clerkin hallintapaneelista: ${viesti}    WARN
    END
    Sulje Istunto

Poista Tili Jos Testi Epaonnistui
    [Documentation]    Teardown tilin poistoa testaaville testeille. Onnistuneessa
    ...    ajossa testi on jo poistanut tilin itse, joten tässä suljetaan vain istunto.
    ...    Jos testi kaatui ennen poistoa, tili poistetaan, jottei se jää Clerkiin.
    IF    '${TEST STATUS}' == 'FAIL'
        Poista Testitili Ja Sulje Istunto
    ELSE
        Sulje Istunto
    END