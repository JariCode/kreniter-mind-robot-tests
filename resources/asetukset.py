import os
from pathlib import Path
from dotenv import load_dotenv

# .env sijaitsee testikansion juuressa, yhden tason ylempänä
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

# Sovelluksen osoitteet. RENDER_API tarvitaan vain webhook-testissä (TC12-003).
URL = os.getenv("URL", "")
API = os.getenv("API", "")
RENDER_API = os.getenv("RENDER_API", "")

# Vakiotestitili ja salasanan vaihtotestin uusi salasana
TESTITUNNUS = os.getenv("TESTITUNNUS", "")
TESTISALASANA = os.getenv("TESTISALASANA", "")
UUSI_SALASANA = os.getenv("UUSI_SALASANA", "")

# Clerkin kehitysinstanssin testiasetukset
CLERK_TESTIKOODI = os.getenv("CLERK_TESTIKOODI", "")
TESTISAHKOPOSTI_ETULIITE = os.getenv("TESTISAHKOPOSTI_ETULIITE", "")
TESTISAHKOPOSTI_DOMAIN = os.getenv("TESTISAHKOPOSTI_DOMAIN", "")

# Selain: HEADLESS=true ajaa selaimen piilossa, SLOWMO hidastaa jokaista toimintoa
HEADLESS_TEKSTI = os.getenv("HEADLESS", "")
SLOWMO_TEKSTI = os.getenv("SLOWMO", "")

# Pysäytetään heti, jos pakolliset arvot puuttuvat, eikä ajeta testejä tyhjillä arvoilla
PAKOLLISET = {
    "URL": URL,
    "API": API,
    "TESTITUNNUS": TESTITUNNUS,
    "TESTISALASANA": TESTISALASANA,
    "UUSI_SALASANA": UUSI_SALASANA,
    "CLERK_TESTIKOODI": CLERK_TESTIKOODI,
    "TESTISAHKOPOSTI_ETULIITE": TESTISAHKOPOSTI_ETULIITE,
    "TESTISAHKOPOSTI_DOMAIN": TESTISAHKOPOSTI_DOMAIN,
    "HEADLESS": HEADLESS_TEKSTI,
    "SLOWMO": SLOWMO_TEKSTI,
}
PUUTTUVAT = [nimi for nimi, arvo in PAKOLLISET.items() if not arvo]
if PUUTTUVAT:
    raise RuntimeError(
        "Nämä arvot puuttuvat .env-tiedostosta: " + ", ".join(PUUTTUVAT)
    )

# Muunnetaan selaimen asetukset Robotin tarvitsemaan muotoon
HEADLESS = HEADLESS_TEKSTI.strip().lower() == "true"
SLOWMO = f"{float(SLOWMO_TEKSTI)}s"