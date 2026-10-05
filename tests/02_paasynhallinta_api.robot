*** Settings ***
Documentation    Testijoukko 2: Pääsynhallinta rajapinnassa.
...    Testaa backendin rajapintaa suoraan RequestsLibrary-kirjastolla ja varmistaa,
...    että jokainen suojattu reitti vaatii kirjautumisen, että väärennetty tunniste
...    hylätään ja että Clerkin webhook hylkää väärennetyn poistoilmoituksen.
...    Selainta käytetään vain oikean kirjautumistunnisteen hakemiseen.
...    Kattaa testitapaukset TC02-001 - TC02-004 ja TC12-003.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen. TC12-003 vaatii,
...    että Renderin backend on käynnissä ja RENDER_API on asetettu .env-tiedostoon.
Resource    ../resources/yhteiset.robot
Suite Setup    Kirjaudu Selaimella Tunnistetta Varten
Suite Teardown    Close Browser


*** Variables ***
# Tunniste, jota ei ole olemassa. Reitit tarkistavat kirjautumisen ennen kuin
# etsivät tietoa, joten vastauksen pitää olla 401 eikä 404.
${OLEMATON_ID}             000000000000000000000000
${VAARENNETTY_TUNNISTE}    eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyX3Zhw6RyZW5uZXR0eSJ9.vaarennettu


*** Test Cases ***
Suojatut reitit vaativat kirjautumisen
    [Documentation]    TC02-001. Odotettu tulos: jokainen backendin suojattu reitti
    ...    vastaa 401 ilman kirjautumistunnistetta. Lista kattaa kaikki reitit paitsi
    ...    /health ja Clerkin webhookin, jotka eivät vaadi kirjautumista. Testi käy
    ...    läpi kaikki reitit, vaikka jokin epäonnistuisi, ja raportoi virheet kerralla.
    [Tags]    api    tietoturva
    [Template]    Reitti Vastaa 401 Ilman Tunnistetta
    # Projektit
    GET       /projects
    POST      /projects
    GET       /projects/${OLEMATON_ID}
    GET       /projects/${OLEMATON_ID}/delete-preview
    PATCH     /projects/${OLEMATON_ID}
    DELETE    /projects/${OLEMATON_ID}
    # Tehtävät
    GET       /tasks
    POST      /tasks
    GET       /tasks/${OLEMATON_ID}
    GET       /tasks/${OLEMATON_ID}/delete-preview
    PATCH     /tasks/${OLEMATON_ID}
    DELETE    /tasks/${OLEMATON_ID}
    # Muistiinpanot
    GET       /notes
    POST      /notes
    GET       /notes/${OLEMATON_ID}
    PATCH     /notes/${OLEMATON_ID}
    DELETE    /notes/${OLEMATON_ID}
    # Aikakirjaukset
    GET       /time-entries
    GET       /time-entries/${OLEMATON_ID}
    PATCH     /time-entries/${OLEMATON_ID}
    DELETE    /time-entries/${OLEMATON_ID}
    # Ajastin
    GET       /active-timer
    DELETE    /active-timer
    POST      /active-timer/start
    POST      /active-timer/switch
    POST      /active-timer/pause
    POST      /active-timer/resume
    POST      /active-timer/stop
    # Käyttäjä ja dashboard
    GET       /users/me
    GET       /dashboard-layout
    PUT       /dashboard-layout
    # Näkymävalinnat
    GET       /timeline
    PUT       /timeline
    GET       /tasks-view
    PUT       /tasks-view
    GET       /time-view
    PUT       /time-view
    GET       /reports-view
    PUT       /reports-view
    # Kansiot
    GET       /folders
    POST      /folders
    PUT       /folders/${OLEMATON_ID}
    DELETE    /folders/${OLEMATON_ID}
    # Tiedostot
    GET       /files
    POST      /files
    GET       /files/${OLEMATON_ID}/download
    PUT       /files/${OLEMATON_ID}
    PUT       /files/${OLEMATON_ID}/content
    DELETE    /files/${OLEMATON_ID}
    # Kalenteri
    GET       /calendar-events
    POST      /calendar-events
    PATCH     /calendar-events/${OLEMATON_ID}
    DELETE    /calendar-events/${OLEMATON_ID}
    GET       /calendar/items
    # AI Assistant
    GET       /ai/conversations
    POST      /ai/conversations
    GET       /ai/conversations/${OLEMATON_ID}
    DELETE    /ai/conversations/${OLEMATON_ID}
    POST      /ai/conversations/${OLEMATON_ID}/messages
    POST      /ai/actions/${OLEMATON_ID}/confirm
    POST      /ai/actions/${OLEMATON_ID}/cancel
    POST      /ai/transcribe
    POST      /ai/speech
    POST      /ai/image

Väärennetty tunniste hylätään
    [Documentation]    TC02-002. Odotettu tulos: väärennetyllä tai muokatulla
    ...    tunnisteella suojatut reitit vastaavat 401. Testi kattaa jokaisen
    ...    reittiryhmän lukureitin.
    [Tags]    api    tietoturva
    [Template]    Reitti Vastaa 401 Vaarennetylla Tunnisteella
    GET    /projects
    GET    /tasks
    GET    /notes
    GET    /time-entries
    GET    /active-timer
    GET    /users/me
    GET    /dashboard-layout
    GET    /timeline
    GET    /tasks-view
    GET    /time-view
    GET    /reports-view
    GET    /folders
    GET    /files
    GET    /calendar-events
    GET    /calendar/items
    GET    /ai/conversations

Oikealla tunnisteella pääsee rajapintaan
    [Documentation]    TC02-003. Odotettu tulos: kirjautuneen käyttäjän tunnisteella
    ...    projektilista vastaa 200. Todistaa myös, että tunnisteen haku toimii.
    [Tags]    api
    ${vastaus}=    Tee Kirjautunut Pyynto    GET    /projects
    Should Be Equal As Integers    ${vastaus.status_code}    200

Terveystarkistus vastaa ilman kirjautumista
    [Documentation]    TC02-004. Odotettu tulos: /health vastaa 200 ilman tunnistetta,
    ...    koska se ei sisällä käyttäjän tietoja.
    [Tags]    api
    ${vastaus}=    GET    ${API}/health    expected_status=any
    Should Be Equal As Integers    ${vastaus.status_code}    200

Webhook hylkää väärennetyn poistoilmoituksen
    [Documentation]    TC12-003. Odotettu tulos: kun Renderin backendille lähetetään
    ...    väärennetty Clerkin "user.deleted"-ilmoitus vakiotestitilin tunnisteella,
    ...    palvelin hylkää sen vastauksella 400, koska allekirjoitus ei täsmää.
    ...    Testitilin tiedot ovat edelleen tallessa. Testi ohitetaan, jos RENDER_API
    ...    puuttuu .env-tiedostosta.
    [Tags]    api    tietoturva
    Skip If    not $RENDER_API    RENDER_API puuttuu .env-tiedostosta
    ${kayttaja}=    Tee Kirjautunut Pyynto    GET    /users/me
    Should Be Equal As Integers    ${kayttaja.status_code}    200
    ${clerk_id}=    Set Variable    ${kayttaja.json()}[user][clerkId]
    ${data}=    Create Dictionary    id=${clerk_id}
    ${runko}=    Create Dictionary    type=user.deleted    data=${data}
    ${aika}=    Evaluate    str(int(time.time()))    modules=time
    ${otsakkeet}=    Create Dictionary
    ...    svix-id=msg_vaarennetty
    ...    svix-timestamp=${aika}
    ...    svix-signature=v1,vaarennettuallekirjoitus
    ${vastaus}=    POST    ${RENDER_API}/webhooks/clerk    json=${runko}
    ...    headers=${otsakkeet}    expected_status=any    timeout=90
    Should Be Equal As Integers    ${vastaus.status_code}    400
    ...    msg=Webhook palautti ${vastaus.status_code}, odotettiin 400
    ${tarkistus}=    Tee Kirjautunut Pyynto    GET    /users/me
    Should Be Equal As Integers    ${tarkistus.status_code}    200
    Should Be Equal    ${tarkistus.json()}[user][clerkId]    ${clerk_id}


*** Keywords ***
Kirjaudu Selaimella Tunnistetta Varten
    [Documentation]    Kirjautuu testitunnuksella selaimeen, jotta testit saavat oikean
    ...    kirjautumistunnisteen Clerkiltä.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan

Reitti Vastaa 401 Ilman Tunnistetta
    [Documentation]    Lähettää pyynnön ilman kirjautumistunnistetta ja tarkistaa, että
    ...    vastaus on 401.
    [Arguments]    ${metodi}    ${polku}
    ${vastaus}=    Run Keyword    ${metodi}    ${API}${polku}    expected_status=any
    Should Be Equal As Integers    ${vastaus.status_code}    401
    ...    msg=${metodi} ${polku} palautti ${vastaus.status_code}, odotettiin 401

Reitti Vastaa 401 Vaarennetylla Tunnisteella
    [Documentation]    Lähettää pyynnön väärennetyllä kirjautumistunnisteella ja
    ...    tarkistaa, että vastaus on 401.
    [Arguments]    ${metodi}    ${polku}
    ${otsakkeet}=    Create Dictionary    Authorization=Bearer ${VAARENNETTY_TUNNISTE}
    ${vastaus}=    Run Keyword    ${metodi}    ${API}${polku}
    ...    headers=${otsakkeet}    expected_status=any
    Should Be Equal As Integers    ${vastaus.status_code}    401
    ...    msg=${metodi} ${polku} palautti ${vastaus.status_code}, odotettiin 401