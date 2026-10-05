*** Settings ***
Documentation    Yhteiset muuttujat ja avainsanat Kreniter Mindin testeille.
...    Testit vaativat käynnissä olevan frontendin ja backendin. Asetukset ja
...    tunnukset luetaan .env-tiedostosta (resources/asetukset.py).
Library    Browser
Library    RequestsLibrary
Library    String
Library    Collections
Variables    asetukset.py


*** Keywords ***
Avaa Selain
    [Documentation]    Käynnistää selaimen. Ajetaan kerran testijoukon alussa.
    ...    Näkyvyys (HEADLESS) ja hidastus (SLOWMO) luetaan .env-tiedostosta.
    New Browser    chromium    headless=${HEADLESS}    slowMo=${SLOWMO}

Avaa Uusi Istunto
    [Documentation]    Avaa puhtaan selainistunnon ilman aiempia kirjautumisia ja lataa
    ...    etusivun. Ajetaan jokaisen testin alussa, jotta testit eivät vaikuta toisiinsa.
    New Context    viewport={'width': 1280, 'height': 900}
    New Page    ${URL}

Sulje Istunto
    [Documentation]    Sulkee testin selainistunnon. Ajetaan jokaisen testin lopussa.
    Close Context

Vahvista Uusi Laite Jos Pyydetaan
    [Documentation]    Clerk pyytää sähköpostikoodin, kun kirjautuminen tulee uudelta
    ...    laitteelta ("Check your email"). Robotin jokainen istunto näyttää uudelta
    ...    laitteelta. Koodi kirjoitetaan vasta, kun Clerk on lähettänyt sen:
    ...    odotetaan "Resend"-lähtölaskentaa ja verkkoliikenteen rauhoittumista.
    ...    Liian aikaisin syötetty koodi hylätään. Testikoodi luetaan .env-tiedostosta,
    ...    ja se toimii vain +clerk_test-osoitteille Clerkin kehitysinstanssissa.
    ${pyydetaan}=    Run Keyword And Return Status
    ...    Wait For Elements State    text=Check your email    visible    timeout=5s
    IF    ${pyydetaan}
        Wait For Elements State    text=/Resend \\(\\d+\\)/    visible    timeout=15s
        Wait For Load State    networkidle    timeout=10s
        Keyboard Input    type    ${CLERK_TESTIKOODI}
    END

Kirjaudu Sisaan
    [Documentation]    Avaa Clerkin kirjautumisikkunan etusivun painikkeesta ja kirjautuu.
    ...    Jos Clerk pyytää uuden laitteen vahvistusta, syötetään testikoodi.
    ...    Onnistuminen todetaan Dashboard-otsikosta, joka näkyy vain kirjautuneelle.
    [Arguments]    ${tunnus}=${TESTITUNNUS}    ${salasana}=${TESTISALASANA}
    Click    text=ENTER WORKSPACE
    Fill Text    input[name="identifier"]    ${tunnus}
    Click    .cl-formButtonPrimary
    Fill Text    input[name="password"]    ${salasana}
    Click    .cl-formButtonPrimary
    Vahvista Uusi Laite Jos Pyydetaan
    Wait For Elements State    h1 >> text=Dashboard    visible    timeout=20s

Luo Testisahkoposti
    [Documentation]    Palauttaa satunnaisen Clerkin testisähköpostin. +clerk_test-pääte
    ...    tarkoittaa, ettei sähköpostia lähetetä ja vahvistuskoodi on Clerkin
    ...    testikoodi. Osoitteen alku ja domain luetaan .env-tiedostosta.
    ${loppuosa}=    Generate Random String    8    [LOWER][NUMBERS]
    RETURN    ${TESTISAHKOPOSTI_ETULIITE}+clerk_test_${loppuosa}@${TESTISAHKOPOSTI_DOMAIN}

Rekisteroidy
    [Documentation]    Avaa kirjautumisikkunan, siirtyy rekisteröintiin ja luo tilin.
    ...    Jos Clerk pyytää sähköpostin vahvistusta, syötetään testikoodi.
    [Arguments]    ${sahkoposti}    ${salasana}=${TESTISALASANA}
    Click    text=ENTER WORKSPACE
    Click    .cl-footerActionLink
    Fill Text    input[name="emailAddress"]    ${sahkoposti}
    Fill Text    input[name="password"]    ${salasana}
    Click    .cl-formButtonPrimary
    Vahvista Uusi Laite Jos Pyydetaan
    Wait For Elements State    h1 >> text=Dashboard    visible    timeout=20s

Avaa Kayttajavalikko
    [Documentation]    Avaa Clerkin käyttäjävalikon oikean yläkulman avatarista.
    Click    .cl-userButtonTrigger

Kirjaudu Ulos
    [Documentation]    Kirjautuu ulos käyttäjävalikosta ja odottaa etusivun latautuvan.
    Avaa Kayttajavalikko
    Click    text=Sign out
    Wait For Elements State    text=ENTER WORKSPACE    visible    timeout=15s

Vahvista Salasanalla Jos Pyydetaan
    [Documentation]    Clerk pyytää nykyisen salasanan ennen arkaluonteisia toimintoja,
    ...    kuten tilin poistoa ("Verification required"). Jos salasanakenttä
    ...    ilmestyy, syötetään salasana ja painetaan Continue. Muuten ei tehdä mitään.
    ...    Continue valitaan tekstin perusteella, koska taustalla on samaan aikaan
    ...    toinen samanluokkainen painike.
    [Arguments]    ${salasana}=${TESTISALASANA}
    ${pyydetaan}=    Run Keyword And Return Status
    ...    Wait For Elements State    input[name="password"]    visible    timeout=5s
    IF    ${pyydetaan}
        Fill Text    input[name="password"]    ${salasana}
        Click    .cl-formButtonPrimary >> text=Continue
    END

Poista Tili Sovelluksesta
    [Documentation]    Poistaa kirjautuneen käyttäjän tilin Clerkin profiilipaneelista
    ...    kuten oikea käyttäjä. Clerk pyytää poiston vahvistuksen jälkeen nykyisen
    ...    salasanan. Clerk lähettää poistosta webhookin backendille, joka poistaa
    ...    käyttäjän tiedot tietokannasta.
    [Arguments]    ${salasana}=${TESTISALASANA}
    Avaa Kayttajavalikko
    Click    text=Manage account
    Click    text=Security
    Click    button >> text=Delete account
    Fill Text    input[name="deleteConfirmation"]    Delete account
    Click    button[data-localization-key="userProfile.deletePage.confirm"]
    Vahvista Salasanalla Jos Pyydetaan    ${salasana}
    Wait For Elements State    text=ENTER WORKSPACE    visible    timeout=20s

Varmista Etta Tili On Poistettu
    [Documentation]    Yrittää kirjautua poistetun tilin sähköpostilla. Clerk ei löydä
    ...    tiliä ja näyttää virheilmoituksen "Couldn't find your account".
    [Arguments]    ${sahkoposti}
    Click    text=ENTER WORKSPACE
    Fill Text    input[name="identifier"]    ${sahkoposti}
    Click    .cl-formButtonPrimary
    Wait For Elements State    .cl-formFieldErrorText    visible    timeout=10s
    Get Text    .cl-formFieldErrorText    contains    Couldn't find your account

Hae Kirjautumistunniste
    [Documentation]    Hakee kirjautuneen käyttäjän tunnisteen (JWT) suoraan Clerkiltä
    ...    selaimen sisältä. Tunniste on lyhytikäinen, joten se haetaan aina juuri ennen
    ...    rajapintakutsua. Vaatii, että selaimessa on kirjautunut käyttäjä.
    ${tunniste}=    Evaluate JavaScript    ${None}
    ...    async () => await window.Clerk.session.getToken()
    RETURN    ${tunniste}

Tee Kirjautunut Pyynto
    [Documentation]    Lähettää rajapintaan pyynnön kirjautuneen käyttäjän tunnisteella
    ...    ja palauttaa vastauksen. Tilakoodia ei tarkisteta tässä, vaan testissä.
    [Arguments]    ${metodi}    ${polku}    ${runko}=${None}
    ${tunniste}=    Hae Kirjautumistunniste
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${tunniste}
    ${vastaus}=    Run Keyword    ${metodi}    ${API}${polku}
    ...    headers=${otsakkeet}    json=${runko}    expected_status=any
    RETURN    ${vastaus}

Lataa Tiedosto Rajapinnalla
    [Documentation]    Lataa tekstitiedoston rajapinnan kautta aktiivisena käyttäjänä
    ...    ja palauttaa vastauksen. Projekti ja kansio ovat vapaaehtoisia.
    [Arguments]    ${nimi}    ${sisalto}    ${projekti_id}=${None}    ${kansio_id}=${None}
    ${tunniste}=    Hae Kirjautumistunniste
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${tunniste}
    ${tiedosto}=    Evaluate    {'file': ($nimi, $sisalto.encode('utf-8'), 'text/plain')}
    ${kentat}=    Create Dictionary
    IF    $projekti_id    Set To Dictionary    ${kentat}    projectId=${projekti_id}
    IF    $kansio_id    Set To Dictionary    ${kentat}    folderId=${kansio_id}
    ${vastaus}=    POST    ${API}/files    headers=${otsakkeet}    files=${tiedosto}
    ...    data=${kentat}    expected_status=any
    RETURN    ${vastaus}

Tunnisteen Vanhenemisaika
    [Documentation]    Palauttaa kirjautumistunnisteen (JWT) vanhenemisajan sekunteina
    ...    Unix-aikana. Aika luetaan tunnisteen sisällöstä (exp-kenttä).
    [Arguments]    ${tunniste}
    ${vanhenee}=    Evaluate
    ...    json.loads(base64.urlsafe_b64decode($tunniste.split('.')[1] + '=' * (-len($tunniste.split('.')[1]) % 4)))['exp']
    ...    modules=json,base64
    RETURN    ${vanhenee}

Kirjaa Aikaa Rajapinnalla
    [Documentation]    Kirjaa projektille (ja valinnaisesti tehtävälle) tasan 5 minuuttia
    ...    ajastimen kautta. Aikaleimat ovat 2,5 minuuttia nykyhetken kummallakin
    ...    puolella, jotta ne mahtuvat palvelimen toleranssiin. Mahdollinen käynnissä
    ...    oleva ajastin poistetaan ensin ilman kirjausta.
    [Arguments]    ${projekti_id}    ${tehtava_id}=${None}
    Run Keyword And Ignore Error    Tee Kirjautunut Pyynto    DELETE    /active-timer
    ${alku}=    Evaluate    int(time.time() * 1000) - 150000    modules=time
    ${loppu}=    Evaluate    ${alku} + 300000
    ${runko}=    Create Dictionary    projectId=${projekti_id}    now=${alku}
    IF    $tehtava_id    Set To Dictionary    ${runko}    taskId=${tehtava_id}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/start    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    201
    ${runko}=    Create Dictionary    now=${loppu}
    ${vastaus}=    Tee Kirjautunut Pyynto    POST    /active-timer/stop    ${runko}
    Should Be Equal As Integers    ${vastaus.status_code}    200

Aikakirjausten Maara
    [Documentation]    Palauttaa, montako aikakirjausta annetulla kentällä (projectId tai
    ...    taskId) on annettu arvo. Kenttä voi olla tunniste tai haettu objekti.
    [Arguments]    ${kentta}    ${arvo}
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /time-entries
    Should Be Equal As Integers    ${vastaus.status_code}    200
    ${maara}=    Evaluate
    ...    len([m for m in $vastaus.json() if (m[$kentta]['_id'] if isinstance(m.get($kentta), dict) else m.get($kentta)) == $arvo])
    RETURN    ${maara}