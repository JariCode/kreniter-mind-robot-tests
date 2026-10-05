*** Settings ***
Documentation    Testijoukko 13: Saavutettavuus, responsiivisuus ja navigointi.
...    Käy läpi jokaisen sivupalkin sivun ja tarkistaa yhden pääotsikon, painikkeiden
...    ja lomakekenttien nimet, kuvien alt-tekstit, vaakavierityksen puuttumisen
...    puhelimen leveydellä sekä sivupalkin aktiivisen kohdan. Sivulista luetaan
...    sivupalkista, joten uudet sivut tulevat mukaan automaattisesti. Testaa lisäksi
...    sivun kielen, näppäimistönavigoinnin ja mobiilivalikon.
...    Testit käyvät kaikki sivut läpi, vaikka jokin tarkistus epäonnistuisi, ja
...    raportoivat kaikki löydökset kerralla.
...    Kattaa testitapaukset TC13-001 - TC13-007, TC13-013 ja TC13-015.
...    Esivaatimus: .env-tiedoston testitili on luotu sovellukseen.
Resource    ../resources/yhteiset.robot
Suite Setup    Valmistele Saavutettavuustestit
Suite Teardown    Close Browser


*** Variables ***
${PUHELIN_LEVEYS}     ${390}
${PUHELIN_KORKEUS}    ${844}
${TOGGLE}             .sidebar-mobile-toggle


*** Test Cases ***
Sivun kieli on määritelty
    [Documentation]    TC13-001. Odotettu tulos: html-elementillä on lang-attribuutti, jotta
    ...    ruudunlukija lukee tekstin oikealla kielellä.
    [Tags]    selain
    ${kieli}=    Get Attribute    html    lang
    Should Not Be Empty    ${kieli}

Jokaisella sivulla on yksi pääotsikko
    [Documentation]    TC13-002. Odotettu tulos: jokaisella sivulla on täsmälleen yksi
    ...    h1-otsikko.
    [Tags]    selain
    FOR    ${sivu}    IN    @{SIVUT}
        Avaa Sivu    ${sivu}
        ${maara}=    Get Element Count    h1
        Run Keyword And Continue On Failure    Should Be Equal As Integers    ${maara}    1
        ...    msg=Sivulla ${sivu} on ${maara} h1-otsikkoa, odotettiin 1
    END

Jokaisella painikkeella on nimi
    [Documentation]    TC13-003. Odotettu tulos: jokaisella näkyvällä painikkeella on
    ...    teksti, aria-label tai title, jotta ruudunlukija osaa kertoa sen tarkoituksen.
    [Tags]    selain
    FOR    ${sivu}    IN    @{SIVUT}
        Avaa Sivu    ${sivu}
        ${nimettomat}=    Evaluate JavaScript    ${None}
        ...    () => [...document.querySelectorAll('button')].filter(b => b.offsetParent !== null && !(b.innerText.trim() || b.getAttribute('aria-label') || b.getAttribute('aria-labelledby') || b.getAttribute('title'))).map(b => b.outerHTML.slice(0, 150))
        Run Keyword And Continue On Failure    Should Be Empty    ${nimettomat}
        ...    msg=Sivulla ${sivu} on nimettömiä painikkeita: ${nimettomat}
    END

Jokaisella lomakekentällä on otsikko
    [Documentation]    TC13-004. Odotettu tulos: jokaisella näkyvällä tekstikentällä,
    ...    valikolla ja tekstialueella on label, aria-label tai aria-labelledby.
    [Tags]    selain
    FOR    ${sivu}    IN    @{SIVUT}
        Avaa Sivu    ${sivu}
        ${nimettomat}=    Evaluate JavaScript    ${None}
        ...    () => [...document.querySelectorAll('input, select, textarea')].filter(k => k.offsetParent !== null && !['hidden', 'submit', 'button', 'file'].includes(k.type) && !(k.labels?.length || k.getAttribute('aria-label') || k.getAttribute('aria-labelledby'))).map(k => k.outerHTML.slice(0, 150))
        Run Keyword And Continue On Failure    Should Be Empty    ${nimettomat}
        ...    msg=Sivulla ${sivu} on otsikottomia kenttiä: ${nimettomat}
    END

Jokaisella kuvalla on alt-teksti
    [Documentation]    TC13-005. Odotettu tulos: jokaisella kuvalla on alt-attribuutti
    ...    (koristekuvilla se voi olla tyhjä).
    [Tags]    selain
    FOR    ${sivu}    IN    @{SIVUT}
        Avaa Sivu    ${sivu}
        ${ilman_alt}=    Evaluate JavaScript    ${None}
        ...    () => [...document.images].filter(i => !i.hasAttribute('alt')).map(i => i.outerHTML.slice(0, 150))
        Run Keyword And Continue On Failure    Should Be Empty    ${ilman_alt}
        ...    msg=Sivulla ${sivu} on kuvia ilman alt-tekstiä: ${ilman_alt}
    END

Sivuilla ei ole vaakavieritystä puhelimessa
    [Documentation]    TC13-006. Odotettu tulos: puhelimen leveydellä (390 px) mikään sivu
    ...    ei ole näyttöä leveämpi, eikä sivua tarvitse vierittää sivusuunnassa.
    [Tags]    selain
    FOR    ${sivu}    IN    @{SIVUT}
        Set Viewport Size    1280    900
        Avaa Sivu    ${sivu}
        Set Viewport Size    ${PUHELIN_LEVEYS}    ${PUHELIN_KORKEUS}
        Sleep    0.5s
        ${ylitys}=    Evaluate JavaScript    ${None}
        ...    () => document.documentElement.scrollWidth - document.documentElement.clientWidth
        Run Keyword And Continue On Failure    Should Be True    ${ylitys} <= 0
        ...    msg=Sivu ${sivu} on puhelimessa ${ylitys} px näyttöä leveämpi
    END
    [Teardown]    Set Viewport Size    1280    900

Navigointi toimii näppäimistöllä
    [Documentation]    TC13-007. Odotettu tulos: sivupalkin kohtaan voi siirtyä
    ...    näppäimistöllä, ja Enter avaa sivun ilman hiirtä.
    [Tags]    selain
    Avaa Sivu    Dashboard
    Focus    .sidebar-item >> text="Projects"
    Keyboard Key    press    Enter
    Wait For Elements State    h1 >> text="Projects"    visible    timeout=10s
    ${kohdistettu}=    Evaluate JavaScript    ${None}
    ...    () => document.activeElement?.innerText?.trim()
    Should Be Equal    ${kohdistettu}    Projects

Mobiilivalikon avaus ja sulku
    [Documentation]    TC13-013. Odotettu tulos: puhelimen leveydellä sivupalkki on
    ...    piilossa ja avautuu Open navigation -painikkeesta (aria-expanded=true).
    ...    Valikko sulkeutuu painikkeesta uudelleen, Escapella, taustaa klikkaamalla
    ...    ja sivun valinnan jälkeen, jolloin valittu sivu avautuu.
    [Tags]    selain
    Avaa Sivu    Dashboard
    Set Viewport Size    ${PUHELIN_LEVEYS}    ${PUHELIN_KORKEUS}
    Sleep    0.5s
    Mobiilivalikko On Kiinni
    Click    ${TOGGLE}
    Mobiilivalikko On Auki
    Click    ${TOGGLE}
    Mobiilivalikko On Kiinni
    Click    ${TOGGLE}
    Mobiilivalikko On Auki
    Keyboard Key    press    Escape
    Mobiilivalikko On Kiinni
    Click    ${TOGGLE}
    Mobiilivalikko On Auki
    Evaluate JavaScript    .sidebar-mobile-overlay    (tausta) => tausta.click()
    Mobiilivalikko On Kiinni
    Click    ${TOGGLE}
    Mobiilivalikko On Auki
    Click    .sidebar-item >> text="Notes"
    Wait For Elements State    h1 >> text="Notes"    visible    timeout=10s
    Mobiilivalikko On Kiinni
    [Teardown]    Set Viewport Size    1280    900

Sivupalkin aktiivinen kohta vastaa avattua sivua
    [Documentation]    TC13-015. Odotettu tulos: kun sivu avataan sivupalkista,
    ...    sivupalkissa on täsmälleen yksi aktiivinen kohta, ja se on avattu sivu.
    [Tags]    selain
    FOR    ${sivu}    IN    @{SIVUT}
        Avaa Sivu    ${sivu}
        ${aktiiviset}=    Evaluate JavaScript    ${None}
        ...    () => [...document.querySelectorAll('.sidebar-item.active')].map(s => s.innerText.trim())
        ${odotettu}=    Create List    ${sivu}
        Run Keyword And Continue On Failure    Should Be Equal    ${aktiiviset}    ${odotettu}
        ...    msg=Sivulla ${sivu} aktiivisena on ${aktiiviset}, odotettiin ${odotettu}
    END


*** Keywords ***
Valmistele Saavutettavuustestit
    [Documentation]    Kirjautuu testitunnuksella ja lukee sivupalkista kaikkien sivujen
    ...    nimet testattavaksi.
    Avaa Selain
    Avaa Uusi Istunto
    Kirjaudu Sisaan
    ${sivut}=    Evaluate JavaScript    ${None}
    ...    () => [...document.querySelectorAll('.sidebar-item')].map(s => s.innerText.trim()).filter(Boolean)
    Should Not Be Empty    ${sivut}    msg=Sivupalkista ei löytynyt sivuja
    Log    Testattavat sivut: ${sivut}
    Set Suite Variable    ${SIVUT}    ${sivut}

Avaa Sivu
    [Documentation]    Avaa sivun sivupalkista ja odottaa hetken, että sivun sisältö
    ...    ehtii latautua.
    [Arguments]    ${sivu}
    Click    .sidebar-item >> text="${sivu}"
    Wait For Load State    networkidle    timeout=10s

Mobiilivalikko On Auki
    [Documentation]    Tarkistaa, että mobiilivalikko on auki: painikkeen aria-expanded
    ...    on true ja sivupalkilla on mobile-open-luokka.
    Wait For Elements State    .sidebar.mobile-open    visible    timeout=5s
    Get Attribute    ${TOGGLE}    aria-expanded    ==    true

Mobiilivalikko On Kiinni
    [Documentation]    Tarkistaa, että mobiilivalikko on kiinni: painikkeen
    ...    aria-expanded on false eikä sivupalkilla ole mobile-open-luokkaa.
    Wait For Elements State    .sidebar.mobile-open    detached    timeout=5s
    Get Attribute    ${TOGGLE}    aria-expanded    ==    false