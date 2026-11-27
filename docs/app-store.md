# Near Miss: TestFlight and App Store checklist

Everything here is ready to paste into App Store Connect. Nothing in this file is uploaded by a script.

## Build

```sh
TEAM_ID=<your team id> tools/archive.sh
```

That writes `build/export/NearMiss.ipa`, signed for App Store Connect. Upload it with Xcode
(Window > Organizer > Distribute App) or with Transporter. The app record has to exist in
App Store Connect first.

| Field | Value |
| --- | --- |
| Bundle ID | `io.github.mikealvarado.nearmiss` |
| Version / build | 1.0.0 (1). Raise `CURRENT_PROJECT_VERSION` in `project.yml` for every upload. |
| Devices | iPhone only, portrait, iOS 17 or later |
| Encryption | `ITSAppUsesNonExemptEncryption` is `false`: no export compliance questions |
| Privacy manifest | `App/PrivacyInfo.xcprivacy`: no tracking, no collected data, UserDefaults (CA92.1) |

## App record

| Field | Value |
| --- | --- |
| Name | Near Miss (if taken: "Near Miss: You almost met") |
| Subtitle | Las veces que casi se conocen |
| Primary language | English (U.S.), plus a Spanish (Mexico) localization. The store text below is still only in Spanish; the English version is pending. |
| Category | Lifestyle |
| Price | Free |
| Age rating | 4+ (answer "No" to every content question) |
| Privacy policy URL | https://mikealvarado.github.io/near-miss/privacidad/ |
| Support URL | https://github.com/MikeAlvarado/near-miss/issues |
| Marketing URL | https://mikealvarado.github.io/near-miss/ |

The three URLs work only after the site is published on GitHub Pages.

## Promotional text

¿Estuvieron en la misma calle, el mismo día, años antes de conocerse? Near Miss lo busca en sus fotos y lo pinta en un mapa.

## Description

Near Miss encuentra las veces que tú y tu pareja casi se conocen antes de conocerse.

Tus fotos guardan la fecha y el lugar donde se tomaron. Las de tu pareja también. Near Miss compara los dos rastros y pinta en un mapa cada vez que estuvieron a unas calles, el mismo día, sin saberlo.

CÓMO FUNCIONA
1. Cada quien abre Near Miss en su iPhone y deja que lea la fecha y el lugar de sus fotos.
2. Se mandan su rastro por AirDrop o Mensajes. Es un archivo pequeño con lugares aproximados y días.
3. Near Miss pinta los dos rastros en el mapa, año por año, y baja hasta la calle donde casi se cruzan.

SIEMPRE HAY RESPUESTA
Si nunca coincidieron, Near Miss muestra lo más cerca que estuvieron. Puedes ajustar qué cuenta como "casi": la distancia, los días de diferencia y solo lo que pasó antes de conocerse.

TU PRIVACIDAD
• Sin servidor y sin cuenta. Todo se calcula en tu iPhone.
• Near Miss lee solo la fecha y la ubicación de tus fotos. Nunca abre ni copia las imágenes.
• Lo único que sale de tu teléfono es el archivo que tú decides mandarle a tu pareja.
• El código es abierto, con licencia MIT.

¿No tienes a quién mandarle tu rastro todavía? Prueba el modo demo.

## Keywords (100 characters max)

pareja,fotos,mapa,amor,novios,recuerdos,casi,coincidencia,historia,aniversario,ubicación

## App privacy answers

- Data collection: **No, we do not collect data from this app.**
- Tracking: none.

## Notes for App Review

Near Miss compares the date and place of the photos of two people, on device. To review it without a
second phone: tap "Empezar", scroll to the bottom and tap "Probar con datos de demostración",
choose "Demo: sí se cruzaron", then "Pintar el mapa". No account or sign-in exists.
The photo library permission is used only to read each asset's creation date and location.

## Screenshots

App Store Connect asks for 6.9-inch iPhone screenshots (1320 x 2868). The ones in `docs/` come
from a 6.3-inch simulator and are not the right size: take them again on an iPhone Pro Max
simulator before submitting. TestFlight does not need screenshots.

## TestFlight

- Beta description: the first paragraph of the description above.
- What to test: "Lee tus fotos, comparte tu rastro con tu pareja y pinten el mapa. Dime si el
  mapa va lento con muchas fotos y si el archivo llega bien por AirDrop y Mensajes."
- Internal testers need no review. External testers need a short beta review.
