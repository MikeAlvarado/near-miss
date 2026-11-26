import { ISSUES, REPO, asset, base } from './site'

export function Privacy() {
  return (
    <>
      <div className="grain" aria-hidden />
      <header className="nav">
        <a className="brand" href={base} aria-label="Casi, inicio">
          <img src={asset('icon.png')} alt="" width="30" height="30" />
          <span>Casi</span>
        </a>
        <nav aria-label="Secciones">
          <a href={base}>Inicio</a>
          <a href={REPO}>GitHub</a>
        </nav>
      </header>
      <main className="container legal">
        <p className="label coral-text">Política de privacidad</p>
        <h1 className="display">Qué lee Casi y qué nunca sale de tu iPhone</h1>
        <p className="mono">Última actualización: 26 de noviembre de 2026</p>

        <h2>En una frase</h2>
        <p>Casi no tiene servidor, no tiene cuentas y no recopila ningún dato tuyo. Todo el trabajo se hace en tu iPhone.</p>

        <h2>Qué lee la app</h2>
        <p>Si das permiso, Casi lee de tu fototeca la fecha y la ubicación de cada foto y video. No abre las imágenes, no las copia y no lee nada más de ellas.</p>

        <h2>Qué guarda</h2>
        <p>Con esos datos arma tu "rastro": una lista de celdas de mapa de unos 150 metros y los días en que estuviste en cada una. El rastro se guarda en la carpeta de la app, en tu teléfono. También se guarda ahí el rastro que te mande tu pareja y el nombre que tú escribas, si escribes uno.</p>

        <h2>Qué compartes y con quién</h2>
        <p>La app no manda nada por su cuenta. Solo tú puedes compartir tu rastro, con el botón de compartir de iOS, a quien tú elijas. Quien lo reciba verá lugares aproximados y fechas de tus fotos, y tu nombre si lo escribiste. La pantalla de exportar te lo recuerda antes de mandarlo.</p>

        <h2>El mapa</h2>
        <p>El mapa es el de Apple (MapKit). Para dibujarlo, tu iPhone descarga las imágenes del mapa desde los servidores de Apple, así que Apple sabe qué zona se está mostrando. Tus fotos y tus rastros no se envían. El botón "Abrir en Mapas" abre la app Mapas de Apple en ese punto solo si lo tocas.</p>

        <h2>Lo que no hay</h2>
        <ul>
          <li>No hay analítica, publicidad ni rastreo.</li>
          <li>No hay registro ni inicio de sesión.</li>
          <li>No hay servicios de terceros dentro de la app, aparte del mapa de Apple.</li>
        </ul>

        <h2>Cómo borrar tus datos</h2>
        <p>Borra la app y con ella se borran tu rastro y el de tu pareja. Puedes quitar el permiso de fotos cuando quieras en Ajustes &gt; Privacidad y seguridad &gt; Fotos.</p>

        <h2>Menores</h2>
        <p>Casi no recopila datos de nadie, tampoco de menores de edad.</p>

        <h2>Este sitio</h2>
        <p>Esta página está alojada en GitHub Pages. GitHub puede registrar datos técnicos de la visita, como la dirección IP, según su propia política. El sitio no usa cookies ni analítica.</p>

        <h2>Cambios y contacto</h2>
        <p>Si esta política cambia, la fecha de arriba cambia con ella. El código es abierto y cualquiera puede comprobar lo que dice esta página en el <a href={REPO}>repositorio</a>. Para dudas o problemas, abre un tema en <a href={ISSUES}>GitHub</a>.</p>
      </main>
      <footer className="footer container">
        <p>© {new Date().getFullYear()} Casi · Licencia MIT</p>
        <nav aria-label="Enlaces">
          <a href={base}>Inicio</a>
          <a href={ISSUES}>Soporte</a>
          <a href={REPO}>GitHub</a>
        </nav>
      </footer>
    </>
  )
}
