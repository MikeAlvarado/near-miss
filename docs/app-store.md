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
| Name | "Near Miss: You almost met". The plain "Near Miss" was already taken on the App Store. The name under the icon is still Near Miss. |
| Primary language | English (U.S.). Add Spanish (Mexico) as a second localization. |
| Category | Lifestyle |
| Price | Free |
| Age rating | 4+ (answer "No" to every content question) |
| Privacy policy URL | https://mikealvarado.github.io/near-miss/privacidad/ |
| Support URL | https://github.com/MikeAlvarado/near-miss/issues |
| Marketing URL | https://mikealvarado.github.io/near-miss/ |

The privacy and marketing URLs work only after the site is published on GitHub Pages.
The page follows the browser language and has an ES / EN switch.

## English (U.S.)

**Subtitle (30 characters max):** The times you almost met

**Promotional text:**

Were you on the same street, on the same day, years before you met? Near Miss looks for it in your photos and paints it on a map.

**Description:**

Near Miss finds the times you and your partner almost met before you met.

Your photos keep the date and the place where they were taken. So do your partner's. Near Miss compares the two trails and paints on a map every time you were a few streets apart, on the same day, without knowing it.

HOW IT WORKS
1. Each of you opens Near Miss on your own iPhone and lets it read the date and place of your photos.
2. You send each other your trail over AirDrop or Messages. It is a small file with approximate places and days.
3. Near Miss paints both trails on the map, year by year, and comes down to the street where you almost crossed paths.

THERE IS ALWAYS AN ANSWER
If you never crossed paths, Near Miss shows the closest you ever got. You can adjust what counts as "almost": the distance, the days apart, and only what happened before you met.

YOUR PRIVACY
• No server and no account. Everything is computed on your iPhone.
• Near Miss reads only the date and location of your photos. It never opens or copies the images.
• The only thing that leaves your phone is the file you choose to send to your partner.
• The code is open, under the MIT license.

Nobody to send your trail to yet? Try the demo mode.

**Keywords (100 characters max):**

couple,photos,map,love,memories,almost,met,coincidence,story,anniversary,location,partner

## Spanish (Mexico)

**Subtitle:** Las veces que casi se conocen

**Promotional text:**

¿Estuvieron en la misma calle, el mismo día, años antes de conocerse? Near Miss lo busca en sus fotos y lo pinta en un mapa.

**Description:**

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

**Keywords:**

pareja,fotos,mapa,amor,novios,recuerdos,casi,coincidencia,historia,aniversario,ubicación

## App privacy answers

- Data collection: **No, we do not collect data from this app.**
- Tracking: none.

## Notes for App Review

Near Miss compares the date and place of the photos of two people, on device. To review it without a
second phone: tap "Start", scroll to the bottom and tap "Try it with demo data", choose
"Demo: they did cross paths", then "Paint the map". No account or sign-in exists.
The photo library permission is used only to read each asset's creation date and location.

## Screenshots

App Store Connect asks for 6.9-inch iPhone screenshots (1320 x 2868), per language. The ones in
`docs/` come from a 6.3-inch simulator and are not the right size: take them again on an iPhone
Pro Max simulator before submitting. To launch the app in one language:

```sh
xcrun simctl launch booted io.github.mikealvarado.nearmiss -AppleLanguages "(en)" -AppleLocale en_US
```

TestFlight does not need screenshots.

## TestFlight

Steps, in order:

1. In App Store Connect, create the app: platform iOS, name Near Miss, primary language
   English (U.S.), bundle ID `io.github.mikealvarado.nearmiss`, SKU `nearmiss`.
2. Upload `build/export/NearMiss.ipa` with Transporter or Xcode's Organizer.
3. Wait for the build to finish processing. There are no export compliance questions.
4. Internal testing: add the build to an internal group. No review is needed.
5. External testing: fill in the test information below and submit the build for beta review.

Test information:

- Beta app description (English): the first two paragraphs of the English description above.
- Beta app description (Spanish): the first two paragraphs of the Spanish description above.
- What to test (English): "Read your photos, share your trail with your partner and paint the map.
  Tell me if the map is slow with many photos and if the file arrives well over AirDrop and Messages."
- What to test (Spanish): "Lee tus fotos, comparte tu rastro con tu pareja y pinten el mapa. Dime si el
  mapa va lento con muchas fotos y si el archivo llega bien por AirDrop y Mensajes."
- Feedback email and contact details: yours; they are not kept in this repo.
- Sign-in required: No.
- Review notes: the same as "Notes for App Review" above.
