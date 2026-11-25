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
                    Text("Tres pasos")
                        .font(Theme.title(38))
                        .foregroundStyle(Theme.text)
                    Text("Cada quien lee sus fotos en su teléfono y se mandan el rastro.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.bottom, 8)

                if model.demo != nil { demoBanner }

                step(number: 1, title: "Tu rastro", color: Theme.coral, done: model.myTrail != nil) { myTrailStep }
                step(number: 2, title: "Mándaselo a tu pareja", color: Theme.text, done: false) { shareStep }
                step(number: 3, title: "El rastro de tu pareja", color: Theme.teal, done: model.partnerTrail != nil) { partnerStep }

                Button("Pintar el mapa", action: showResults)
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
                Text("De \(Phrase.count(total, "foto o video", "fotos y videos")), \(located.formatted()) tienen ubicación.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
        } else {
            Text("La app lee la fecha y la ubicación de tus fotos y las reduce a cuadros del mapa de unos 150 m y días. No abre ni copia ninguna foto.")
                .foregroundStyle(Theme.muted)
        }

        switch model.scanState {
        case .scanning:
            HStack(spacing: 10) {
                ProgressView()
                Text("Leyendo tus fotos…").foregroundStyle(Theme.muted)
            }
        case .denied:
            Text("Sin permiso para ver tus fotos no hay rastro. Puedes darlo en Ajustes.")
                .font(.footnote)
                .foregroundStyle(Theme.coral)
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(SecondaryButtonStyle())
        default:
            if model.demo == nil {
                Button(model.myTrail == nil ? "Leer mis fotos" : "Volver a leer mis fotos") {
                    Task { await model.scanPhotos() }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var shareStep: some View {
        Text("Tu pareja necesita tu rastro, y tú el suyo. Se manda como un archivo por AirDrop o Mensajes.")
            .foregroundStyle(Theme.muted)
        Button("Compartir mi rastro") { showingExport = true }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(model.myTrail == nil)
    }

    @ViewBuilder
    private var partnerStep: some View {
        if let trail = model.partnerTrail {
            Text((trail.name.isEmpty ? "" : "\(trail.name): ") + summary(of: trail))
                .foregroundStyle(Theme.text)
        } else {
            Text("Cuando te llegue su archivo, ábrelo con Casi o impórtalo aquí.")
                .foregroundStyle(Theme.muted)
        }
        if let message = model.importMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Theme.coral)
        }
        if model.demo == nil {
            Button(model.partnerTrail == nil ? "Importar archivo" : "Importar otro archivo") {
                showingImporter = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Demo

    private var demoBanner: some View {
        HStack(alignment: .firstTextBaseline) {
            Label("Demo: Ana y \(model.partnerName) no existen.", systemImage: "theatermasks.fill")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Salir") { model.leaveDemo() }
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
            Button("Demo: sí se cruzaron") { model.startDemo(.match) }
            Button("Demo: nunca se cruzaron") { model.startDemo(.noMatch) }
        } label: {
            Text("Probar con datos de demostración")
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
            return "No hay fotos con ubicación."
        }
        let places = Phrase.count(trail.sightings.count, "lugar y día", "lugares y días")
        return "\(places), de \(Phrase.monthAndYear(range.lowerBound)) a \(Phrase.monthAndYear(range.upperBound))."
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
                    Text("Esto es lo que recibe tu pareja")
                        .font(Theme.title(28))
                        .foregroundStyle(Theme.text)

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            fact("mappin.and.ellipse", "Lugares aproximados", "Cuadros del mapa de unos 150 m donde tomaste fotos. Quien lo reciba puede ver por dónde anduviste.")
                            fact("calendar", "Fechas", "El día de cada foto, sin la hora.")
                            fact("photo.badge.checkmark", "Ninguna foto", "Ni las imágenes ni las coordenadas exactas salen de tu iPhone.")
                        }
                    }

                    if let trail = model.myTrail {
                        Text("Tu rastro tiene \(Phrase.count(trail.sightings.count, "lugar y día", "lugares y días")). Va directo a quien tú elijas; no pasa por ningún servidor de la app.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }

                    if model.demo == nil {
                        TextField("Tu nombre (opcional)", text: $model.myName)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(Theme.text)
                            .padding(14)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.line))
                            .onChange(of: model.myName) { fileURL = model.exportFile() }
                    }

                    if let fileURL, model.myTrail != nil {
                        ShareLink(item: fileURL) {
                            Label("Elegir a quién mandarlo", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
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
