import NearMissCore
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let trail = UTType(exportedAs: "io.github.mikealvarado.nearmiss.trail", conformingTo: .json)
}

struct SetupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var showingExport = false
    @State private var showingImporter = false

    var showResults: () -> Void

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("Tres pasos", "Three steps"))
                        .font(Theme.title(38))
                        .foregroundStyle(Theme.text)
                    Text(L("Cada quien lee sus fotos en su teléfono y se mandan el rastro.", "Each of you reads your photos on your own phone, then you send each other the trail."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.bottom, 8)

                if model.demo != nil { demoBanner }

                step(number: 1, title: L("Tu rastro", "Your trail"), color: Theme.coral, done: model.myTrail != nil) { myTrailStep }
                step(number: 2, title: L("Mándaselo a tu pareja", "Send it to your partner"), color: Theme.text, done: false) { shareStep }
                step(number: 3, title: L("El rastro de tu pareja", "Your partner's trail"), color: Theme.teal, done: model.partnerTrail != nil) { partnerStep }

                Button(L("Pintar el mapa", "Paint the map"), action: showResults)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!model.canCompare)
                    .padding(.top, 6)

                if model.demo == nil { demoMenu }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .sheet(isPresented: $showingExport) {
            ExportSheet().presentationBackground(Theme.bg)
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.trail, .json]) { result in
            if case .success(let url) = result { model.importPartner(from: url) }
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var myTrailStep: some View {
        if let trail = model.myTrail {
            Text(summary(of: trail))
                .foregroundStyle(Theme.text)
            if case .done(let total, let located) = model.scanState {
                Text(L("De \(Phrase.count(total, "foto o video", "fotos y videos")), \(located.formatted()) tienen ubicación.", "Of \(Phrase.count(total, "photo or video", "photos and videos")), \(located.formatted()) have a location."))
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
        } else {
            Text(L("La app lee la fecha y la ubicación de tus fotos y las reduce a cuadros del mapa de unos 150 m y días. No abre ni copia ninguna foto.", "The app reads the date and location of your photos and reduces them to map cells of about 150 m and days. It never opens or copies a photo."))
                .foregroundStyle(Theme.muted)
        }

        switch model.scanState {
        case .scanning:
            HStack(spacing: 10) {
                ProgressView()
                Text(L("Leyendo tus fotos…", "Reading your photos…")).foregroundStyle(Theme.muted)
            }
        case .denied:
            Text(L("Sin permiso para ver tus fotos no hay rastro. Puedes darlo en Ajustes.", "Without access to your photos there is no trail. You can allow it in Settings."))
                .font(.footnote)
                .foregroundStyle(Theme.coral)
            Button(L("Abrir Ajustes", "Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(SecondaryButtonStyle())
        default:
            if model.demo == nil {
                Button(model.myTrail == nil ? L("Leer mis fotos", "Read my photos") : L("Volver a leer mis fotos", "Read my photos again")) {
                    Task { await model.scanPhotos() }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var shareStep: some View {
        Text(L("Tu pareja necesita tu rastro, y tú el suyo. Se manda como un archivo por AirDrop o Mensajes.", "Your partner needs your trail, and you need theirs. It is sent as a file over AirDrop or Messages."))
            .foregroundStyle(Theme.muted)
        Button(L("Compartir mi rastro", "Share my trail")) { showingExport = true }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(model.myTrail == nil)
    }

    @ViewBuilder
    private var partnerStep: some View {
        if let trail = model.partnerTrail {
            Text((trail.name.isEmpty ? "" : "\(trail.name): ") + summary(of: trail))
                .foregroundStyle(Theme.text)
        } else {
            Text(L("Cuando te llegue su archivo, ábrelo con Near Miss o impórtalo aquí.", "When their file arrives, open it with Near Miss or import it here."))
                .foregroundStyle(Theme.muted)
        }
        if let message = model.importMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Theme.coral)
        }
        if model.demo == nil {
            Button(model.partnerTrail == nil ? L("Importar archivo", "Import file") : L("Importar otro archivo", "Import another file")) {
                showingImporter = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Demo

    private var demoBanner: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(L("Demo: Ana y \(model.partnerName) no existen.", "Demo: Ana and \(model.partnerName) are not real."), systemImage: "theatermasks.fill")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button(L("Salir", "Exit")) { model.leaveDemo() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.coral)
        }
        .foregroundStyle(Theme.text)
        .padding(14)
        .background(Theme.coral.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.coral.opacity(0.35)))
    }

    private var demoMenu: some View {
        Menu {
            Button(L("Demo: sí se cruzaron", "Demo: they did cross paths")) { model.startDemo(.match) }
            Button(L("Demo: nunca se cruzaron", "Demo: they never crossed paths")) { model.startDemo(.noMatch) }
        } label: {
            Text(L("Probar con datos de demostración", "Try it with demo data"))
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .tint(Theme.muted)
    }

    // MARK: - Pieces

    private func step<Content: View>(
        number: Int,
        title: String,
        color: Color,
        done: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(done ? color : color.opacity(0.14))
                        Circle()
                            .strokeBorder(color.opacity(done ? 0 : 0.7), lineWidth: 1.5)
                        if done {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Theme.bg)
                        } else {
                            Text("\(number)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(color)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .shadow(color: done ? color.opacity(0.6) : .clear, radius: 8)

                    Text(title)
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundStyle(Theme.text)
                }
                content()
            }
            .font(.subheadline)
        }
    }

    private func summary(of trail: Trail) -> String {
        guard let range = trail.dayRange else {
            return L("No hay fotos con ubicación.", "No photos with a location.")
        }
        let places = Phrase.places(trail.sightings.count)
        return L("\(places), de \(Phrase.monthAndYear(range.lowerBound)) a \(Phrase.monthAndYear(range.upperBound)).", "\(places), from \(Phrase.monthAndYear(range.lowerBound)) to \(Phrase.monthAndYear(range.upperBound)).")
    }
}

/// Says in plain words what the other person gets, then opens the share sheet.
struct ExportSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var fileURL: URL?

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L("Esto es lo que recibe tu pareja", "This is what your partner gets"))
                        .font(Theme.title(28))
                        .foregroundStyle(Theme.text)

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            fact("mappin.and.ellipse", L("Lugares aproximados", "Approximate places"), L("Cuadros del mapa de unos 150 m donde tomaste fotos. Quien lo reciba puede ver por dónde anduviste.", "Map cells of about 150 m where you took photos. Whoever gets it can see where you have been."))
                            fact("calendar", L("Fechas", "Dates"), L("El día de cada foto, sin la hora.", "The day of each photo, without the time."))
                            fact("photo.badge.checkmark", L("Ninguna foto", "No photos"), L("Ni las imágenes ni las coordenadas exactas salen de tu iPhone.", "Neither the images nor the exact coordinates leave your iPhone."))
                        }
                    }

                    if let trail = model.myTrail {
                        Text(L("Tu rastro tiene \(Phrase.places(trail.sightings.count)). Va directo a quien tú elijas; no pasa por ningún servidor de la app.", "Your trail has \(Phrase.places(trail.sightings.count)). It goes straight to whoever you choose; it never passes through any server of the app."))
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }

                    if model.demo == nil {
                        TextField(L("Tu nombre (opcional)", "Your name (optional)"), text: $model.myName)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(Theme.text)
                            .padding(14)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.line))
                            .onChange(of: model.myName) { fileURL = model.exportFile() }
                    }

                    if let fileURL, model.myTrail != nil {
                        ShareLink(item: fileURL) {
                            Label(L("Elegir a quién mandarlo", "Choose who to send it to"), systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cerrar", "Close")) { dismiss() }
                }
            }
            .onAppear { fileURL = model.exportFile() }
        }
    }

    private func fact(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.coral)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                Text(detail).font(.footnote).foregroundStyle(Theme.muted)
            }
        }
    }
}
