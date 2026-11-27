import type { ReactNode } from 'react'
import { LangToggle, useLang, type Lang } from './lang'
import { ISSUES, REPO, asset, base } from './site'

type Section = { title: string; body: ReactNode }

const copy: Record<Lang, { home: string; label: string; title: string; updated: string; license: string; support: string; sections: Section[] }> = {
  es: {
    home: 'Inicio',
    label: 'Política de privacidad',
    title: 'Qué lee Near Miss y qué nunca sale de tu iPhone',
    updated: 'Última actualización: 26 de noviembre de 2026',
    license: 'Licencia MIT',
    support: 'Soporte',
    sections: [
      { title: 'En una frase', body: <p>Near Miss no tiene servidor, no tiene cuentas y no recopila ningún dato tuyo. Todo el trabajo se hace en tu iPhone.</p> },
      { title: 'Qué lee la app', body: <p>Si das permiso, Near Miss lee de tu fototeca la fecha y la ubicación de cada foto y video. No abre las imágenes, no las copia y no lee nada más de ellas.</p> },
      { title: 'Qué guarda', body: <p>Con esos datos arma tu "rastro": una lista de celdas de mapa de unos 150 metros y los días en que estuviste en cada una. El rastro se guarda en la carpeta de la app, en tu teléfono. También se guarda ahí el rastro que te mande tu pareja y el nombre que tú escribas, si escribes uno.</p> },
      { title: 'Qué compartes y con quién', body: <p>La app no manda nada por su cuenta. Solo tú puedes compartir tu rastro, con el botón de compartir de iOS, a quien tú elijas. Quien lo reciba verá lugares aproximados y fechas de tus fotos, y tu nombre si lo escribiste. La pantalla de exportar te lo recuerda antes de mandarlo.</p> },
      { title: 'El mapa', body: <p>El mapa es el de Apple (MapKit). Para dibujarlo, tu iPhone descarga las imágenes del mapa desde los servidores de Apple, así que Apple sabe qué zona se está mostrando. Tus fotos y tus rastros no se envían. El botón "Abrir en Mapas" abre la app Mapas de Apple en ese punto solo si lo tocas.</p> },
      {
        title: 'Lo que no hay',
        body: (
          <ul>
            <li>No hay analítica, publicidad ni rastreo.</li>
            <li>No hay registro ni inicio de sesión.</li>
            <li>No hay servicios de terceros dentro de la app, aparte del mapa de Apple.</li>
          </ul>
        ),
      },
      { title: 'Cómo borrar tus datos', body: <p>Borra la app y con ella se borran tu rastro y el de tu pareja. Puedes quitar el permiso de fotos cuando quieras en Ajustes &gt; Privacidad y seguridad &gt; Fotos.</p> },
      { title: 'Menores', body: <p>Near Miss no recopila datos de nadie, tampoco de menores de edad.</p> },
      { title: 'Este sitio', body: <p>Esta página está alojada en GitHub Pages. GitHub puede registrar datos técnicos de la visita, como la dirección IP, según su propia política. El sitio no usa cookies ni analítica; solo guarda en tu navegador el idioma que elijas.</p> },
      { title: 'Cambios y contacto', body: <p>Si esta política cambia, la fecha de arriba cambia con ella. El código es abierto y cualquiera puede comprobar lo que dice esta página en el <a href={REPO}>repositorio</a>. Para dudas o problemas, abre un tema en <a href={ISSUES}>GitHub</a>.</p> },
    ],
  },
  en: {
    home: 'Home',
    label: 'Privacy policy',
    title: 'What Near Miss reads and what never leaves your iPhone',
    updated: 'Last updated: November 26, 2026',
    license: 'MIT License',
    support: 'Support',
    sections: [
      { title: 'In one sentence', body: <p>Near Miss has no server, no accounts, and collects no data about you. All the work happens on your iPhone.</p> },
      { title: 'What the app reads', body: <p>If you allow it, Near Miss reads the date and location of each photo and video in your library. It does not open the images, does not copy them, and reads nothing else from them.</p> },
      { title: 'What it stores', body: <p>From that data it builds your "trail": a list of map cells of about 150 meters and the days you were in each one. The trail is stored in the app's folder, on your phone. The trail your partner sends you is stored there too, along with the name you type, if you type one.</p> },
      { title: 'What you share and with whom', body: <p>The app sends nothing on its own. Only you can share your trail, with the iOS share button, with whoever you choose. Whoever receives it will see approximate places and dates of your photos, and your name if you typed it. The export screen reminds you of this before you send it.</p> },
      { title: 'The map', body: <p>The map is Apple's (MapKit). To draw it, your iPhone downloads map images from Apple's servers, so Apple knows which area is being shown. Your photos and your trails are not sent. The "Open in Maps" button opens Apple's Maps app at that point only if you tap it.</p> },
      {
        title: 'What is not there',
        body: (
          <ul>
            <li>No analytics, advertising or tracking.</li>
            <li>No sign-up and no sign-in.</li>
            <li>No third-party services inside the app, other than Apple's map.</li>
          </ul>
        ),
      },
      { title: 'How to delete your data', body: <p>Delete the app, and your trail and your partner's are deleted with it. You can remove the photo permission at any time in Settings &gt; Privacy &amp; Security &gt; Photos.</p> },
      { title: 'Children', body: <p>Near Miss collects no data from anyone, children included.</p> },
      { title: 'This site', body: <p>This page is hosted on GitHub Pages. GitHub may log technical data about the visit, such as the IP address, under its own policy. The site uses no cookies or analytics; it only stores the language you choose in your browser.</p> },
      { title: 'Changes and contact', body: <p>If this policy changes, the date above changes with it. The code is open and anyone can check what this page says in the <a href={REPO}>repository</a>. For questions or problems, open an issue on <a href={ISSUES}>GitHub</a>.</p> },
    ],
  },
}

export function Privacy() {
  const t = copy[useLang().lang]
  return (
    <>
      <div className="grain" aria-hidden />
      <header className="nav">
        <a className="brand" href={base} aria-label={`Near Miss, ${t.home.toLowerCase()}`}>
          <img src={asset('icon.png')} alt="" width="30" height="30" />
          <span>Near Miss</span>
        </a>
        <nav>
          <a href={base}>{t.home}</a>
          <a href={REPO}>GitHub</a>
          <LangToggle />
        </nav>
      </header>
      <main className="container legal">
        <p className="label accent">{t.label}</p>
        <h1 className="display">{t.title}</h1>
        <p className="mono">{t.updated}</p>
        {t.sections.map((section) => (
          <section key={section.title}>
            <h2>{section.title}</h2>
            {section.body}
          </section>
        ))}
      </main>
      <footer className="footer container">
        <p>© {new Date().getFullYear()} Near Miss · {t.license}</p>
        <nav>
          <a href={base}>{t.home}</a>
          <a href={ISSUES}>{t.support}</a>
          <a href={REPO}>GitHub</a>
        </nav>
      </footer>
    </>
  )
}
