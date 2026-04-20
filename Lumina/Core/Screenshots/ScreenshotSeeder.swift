#if DEBUG
import Foundation
import SwiftData
import SwiftUI
import UIKit

/// Populates the SwiftData store with realistic demo content for App Store
/// screenshot capture. Only compiled in DEBUG builds.
///
/// Writes three `TestResult`s spanning ~4 months so the Evolution view has
/// trend data; attaches a cached `AIInsight` to the latest test; inserts
/// six `Story` entries (each with a generated hero photo); and creates four
/// persisted Buddy `Conversation`s with multi-turn Spanish dialogue.
///
/// Also primes the AppStorage keys that the UI reads directly —
/// `dailyReflectionText` / `dailyReflectionDate`, onboarding flags, and the
/// Buddy disclaimer — so the app boots straight into a populated experience.
@MainActor
enum ScreenshotSeeder {
    /// Wipes all user data then re-seeds the store. Safe to run repeatedly.
    static func seed(container: ModelContainer) {
        let context = container.mainContext

        clearAll(context: context)
        PhotoStore.deleteAllPhotos()

        let testResults = seedTestResults(context: context)
        seedInsight(for: testResults.last, context: context)
        seedStories(context: context)
        seedConversations(context: context)
        seedAppStorageDefaults(latest: testResults.last)

        try? context.save()
    }

    /// Deletes every seeded artifact and resets the AppStorage keys this
    /// seeder owns. Leaves user settings like preferred voice intact.
    static func clear(container: ModelContainer) {
        let context = container.mainContext
        clearAll(context: context)
        PhotoStore.deleteAllPhotos()
        try? context.save()

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "dailyReflectionText")
        defaults.removeObject(forKey: "dailyReflectionDate")
    }

    // MARK: - Clearing

    private static func clearAll(context: ModelContext) {
        try? context.delete(model: ChatMessageRecord.self)
        try? context.delete(model: Conversation.self)
        try? context.delete(model: AIInsight.self)
        try? context.delete(model: StrengthScore.self)
        try? context.delete(model: TestResult.self)
        try? context.delete(model: Story.self)
    }

    // MARK: - Test results

    /// Three runs, returned oldest → newest, so the Evolution view has a
    /// clean left-to-right progression.
    private static func seedTestResults(context: ModelContext) -> [TestResult] {
        let cal = Calendar.current
        let now = Date()

        let oldestDate = cal.date(byAdding: .day, value: -112, to: now) ?? now
        let midDate    = cal.date(byAdding: .day, value: -58,  to: now) ?? now
        let newestDate = cal.date(byAdding: .day, value: -1,   to: now) ?? now

        // Ranking evolves subtly: curiosity is the consistent #1, but
        // gratitude climbs and perseverance dips, giving the delta chart
        // something interesting to show.
        let oldest = makeTestResult(
            date: oldestDate,
            scores: [
                "curiosidad": 9, "perseverancia": 9, "bondad": 8,
                "amor_aprendizaje": 8, "amor": 7, "gratitud": 7,
                "esperanza": 7, "apreciacion_belleza": 7, "honestidad": 6,
                "humor": 6, "inteligencia_social": 6, "creatividad": 6,
                "humanidad": 5, "trabajo_equipo": 5, "juicio": 5,
                "perspectiva": 5, "valentia": 5, "justicia": 5,
                "coraje": 4, "perdon": 4, "prudencia": 4,
                "espiritualidad": 4, "liderazgo": 3, "autorregulacion": 3,
            ]
        )

        let mid = makeTestResult(
            date: midDate,
            scores: [
                "curiosidad": 9, "bondad": 9, "amor_aprendizaje": 8,
                "gratitud": 8, "perseverancia": 8, "esperanza": 7,
                "amor": 7, "apreciacion_belleza": 7, "humor": 7,
                "honestidad": 7, "creatividad": 6, "inteligencia_social": 6,
                "trabajo_equipo": 6, "humanidad": 5, "juicio": 5,
                "perspectiva": 5, "valentia": 5, "justicia": 5,
                "perdon": 5, "coraje": 4, "prudencia": 4,
                "espiritualidad": 4, "liderazgo": 4, "autorregulacion": 3,
            ]
        )

        let newest = makeTestResult(
            date: newestDate,
            scores: [
                "curiosidad": 10, "amor_aprendizaje": 9, "bondad": 9,
                "gratitud": 9, "esperanza": 8, "amor": 8,
                "apreciacion_belleza": 8, "humor": 7, "perseverancia": 7,
                "honestidad": 7, "creatividad": 7, "inteligencia_social": 6,
                "humanidad": 6, "trabajo_equipo": 6, "juicio": 5,
                "perspectiva": 5, "valentia": 5, "perdon": 5,
                "justicia": 5, "coraje": 4, "prudencia": 4,
                "espiritualidad": 4, "liderazgo": 3, "autorregulacion": 3,
            ]
        )

        for result in [oldest, mid, newest] {
            context.insert(result)
            for score in result.scores {
                context.insert(score)
            }
        }
        return [oldest, mid, newest]
    }

    private static func makeTestResult(date: Date, scores: [String: Int]) -> TestResult {
        let result = TestResult(completedAt: date)
        var attached: [StrengthScore] = []
        for strength in StrengthsCatalog.all {
            let points = scores[strength.id] ?? 5
            let score = StrengthScore(strengthID: strength.id, points: points)
            score.testResult = result
            attached.append(score)
        }
        result.scores = attached
        return result
    }

    // MARK: - AI insight

    private static func seedInsight(for result: TestResult?, context: ModelContext) {
        guard let result else { return }
        let insight = StrengthInsight(
            summary: "Tu perfil muestra a alguien que combina una mirada curiosa con una calidez profunda. La curiosidad es tu motor y la gratitud tu brújula — aprendes para comprender, no para demostrar.",
            signatureStrengths: [
                SignatureStrengthItem(
                    strengthName: "Curiosidad",
                    howItShows: "Haces preguntas donde otros dan por hecho las cosas. Cada conversación la transformas en una oportunidad de descubrir algo nuevo.",
                    weeklyAction: "Elige un tema que te intrigue y dedícale 20 minutos de exploración libre, sin una meta específica."
                ),
                SignatureStrengthItem(
                    strengthName: "Amor por el aprendizaje",
                    howItShows: "Disfrutas profundizar en temas nuevos por el simple placer de entenderlos — la comprensión es tu recompensa.",
                    weeklyAction: "Comparte con alguien cercano una idea que hayas aprendido recientemente. Enseñar consolida lo aprendido."
                ),
                SignatureStrengthItem(
                    strengthName: "Bondad",
                    howItShows: "Te preocupas genuinamente por el bienestar de otros, incluso cuando no te conocen ni podrán devolverte el gesto.",
                    weeklyAction: "Esta semana, haz un acto de bondad anónimo — sin esperar agradecimiento ni reconocimiento."
                ),
                SignatureStrengthItem(
                    strengthName: "Gratitud",
                    howItShows: "Reconoces las cosas buenas cotidianas en lugar de darlas por sentadas. Tu atención misma ya es un regalo.",
                    weeklyAction: "Antes de dormir, anota tres momentos pequeños del día por los que te sientas agradecido."
                ),
                SignatureStrengthItem(
                    strengthName: "Esperanza",
                    howItShows: "Enmarcas el futuro con optimismo realista y eso motiva a quienes te rodean sin que lo notes.",
                    weeklyAction: "Escribe una meta clara para los próximos tres meses y el primer paso concreto que darás esta semana."
                ),
            ],
            growthAreas: [
                GrowthAreaItem(
                    strengthName: "Liderazgo",
                    whyItMatters: "Cultivar el liderazgo te permitirá poner al servicio de otros todo lo que ya sabes y sientes. No se trata de mandar sino de cuidar.",
                    firstStep: "Propón una pequeña actividad grupal esta semana y toma la iniciativa de organizarla tú."
                ),
                GrowthAreaItem(
                    strengthName: "Autorregulación",
                    whyItMatters: "Desarrollar tus hábitos te dará la base firme para sostener tu curiosidad y tu bondad a lo largo del tiempo.",
                    firstStep: "Elige un solo hábito (dormir, moverte, escribir) y compromete 10 minutos al día durante 7 días."
                ),
            ],
            encouragement: "Tus fortalezas ya están ahí — el siguiente paso es darles espacio de forma deliberada. Sigue explorando con la misma ternura con la que observas el mundo."
        )
        guard let data = try? JSONEncoder().encode(insight) else { return }
        let record = AIInsight(
            generatedAt: result.completedAt.addingTimeInterval(120),
            summaryJSON: data
        )
        record.testResult = result
        result.insight = record
        context.insert(record)
    }

    // MARK: - Stories

    private static let storySeeds: [StorySeed] = [
        StorySeed(
            daysAgo: 2,
            hour: 8, minute: 42,
            strengthID: "curiosidad",
            body: "Decidí tomar una clase de alfarería sin saber absolutamente nada del tema. Pasé dos horas con las manos llenas de barro, equivocándome en cada intento — y no recuerdo cuándo fue la última vez que me sentí tan viva. Hay algo en aprender desde cero que me recuerda que todavía hay mundo por descubrir."
        ),
        StorySeed(
            daysAgo: 5,
            hour: 21, minute: 15,
            strengthID: "amor",
            body: "Esta tarde llamé a mi abuela solo para escuchar sus historias. Me contó por cuarta vez cómo conoció a mi abuelo en un baile de pueblo, y por cuarta vez me reí en los mismos momentos. A veces el amor es simplemente decidir escuchar con ganas algo que ya conoces de memoria."
        ),
        StorySeed(
            daysAgo: 9,
            hour: 14, minute: 30,
            strengthID: "perseverancia",
            body: "Seis meses entrenando para la media maratón. Hoy crucé la meta con las piernas temblando y los ojos llenos de lágrimas. No fue por el tiempo que hice — fue por todas las mañanas a las 6 en que quise quedarme en la cama y me levanté igual."
        ),
        StorySeed(
            daysAgo: 14,
            hour: 19, minute: 5,
            strengthID: "apreciacion_belleza",
            body: "Me detuve veinte minutos a ver un atardecer desde el puente. El cielo estaba naranja, luego rosa, luego violeta — y nadie más parecía notarlo. Pensé que quizá la belleza siempre ha estado ahí y el trabajo es solo recordar mirarla."
        ),
        StorySeed(
            daysAgo: 20,
            hour: 11, minute: 50,
            strengthID: "bondad",
            body: "Mi vecina estaba cargando bolsas del super sola en el elevador. No le pregunté si necesitaba ayuda — solo tomé dos bolsas y caminé con ella hasta su puerta. Me dijo gracias como si le hubiera hecho el favor más grande del mundo. A veces la bondad es tan simple."
        ),
        StorySeed(
            daysAgo: 28,
            hour: 22, minute: 10,
            strengthID: "gratitud",
            body: "Escribí una carta a mi yo de hace diez años agradeciéndole por no haberse rendido. Mientras la escribía, me di cuenta de que casi nunca me hablo con esa ternura. Voy a guardarla en mi escritorio para leerla cuando me haga falta."
        ),
    ]

    private static func seedStories(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        for seed in storySeeds {
            guard let day = cal.date(byAdding: .day, value: -seed.daysAgo, to: now) else { continue }
            let components = DateComponents(
                year: cal.component(.year, from: day),
                month: cal.component(.month, from: day),
                day: cal.component(.day, from: day),
                hour: seed.hour,
                minute: seed.minute
            )
            let createdAt = cal.date(from: components) ?? day
            let photoFilename = generateAndSavePhoto(for: seed.strengthID)

            let story = Story(
                createdAt: createdAt,
                body: seed.body,
                strengthID: seed.strengthID,
                photoFilename: photoFilename
            )
            context.insert(story)
        }
    }

    private struct StorySeed {
        let daysAgo: Int
        let hour: Int
        let minute: Int
        let strengthID: String
        let body: String
    }

    /// Renders a branded, photographic-looking image for a story and
    /// writes it through ``PhotoStore``. Each strength gets a distinct
    /// color palette derived from its virtue category plus a large SF
    /// Symbol motif, so Stories rows look curated at a glance.
    private static func generateAndSavePhoto(for strengthID: String) -> String? {
        guard let strength = StrengthsCatalog.strength(id: strengthID) else { return nil }
        let color = UIColor(Theme.categoryColor(for: strengthID))

        let size = CGSize(width: 1200, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext

            // Base gradient
            let colorspace = CGColorSpaceCreateDeviceRGB()
            let top = color.withAlphaComponent(1.0).cgColor
            let bottom = color.shaded(by: -0.35).cgColor
            let gradient = CGGradient(
                colorsSpace: colorspace,
                colors: [top, bottom] as CFArray,
                locations: [0.0, 1.0]
            )!
            cg.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Soft radial highlight
            let highlight = CGGradient(
                colorsSpace: colorspace,
                colors: [
                    UIColor.white.withAlphaComponent(0.35).cgColor,
                    UIColor.white.withAlphaComponent(0.0).cgColor,
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            cg.drawRadialGradient(
                highlight,
                startCenter: CGPoint(x: size.width * 0.25, y: size.height * 0.25),
                startRadius: 0,
                endCenter: CGPoint(x: size.width * 0.25, y: size.height * 0.25),
                endRadius: size.width * 0.65,
                options: []
            )

            // Symbol
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 320, weight: .semibold)
            if let symbol = UIImage(systemName: strength.iconSF, withConfiguration: symbolConfig) {
                let tinted = symbol.withTintColor(
                    UIColor.white.withAlphaComponent(0.92),
                    renderingMode: .alwaysOriginal
                )
                let rect = CGRect(
                    x: (size.width - tinted.size.width) / 2,
                    y: (size.height - tinted.size.height) / 2,
                    width: tinted.size.width,
                    height: tinted.size.height
                )
                tinted.draw(in: rect)
            }
        }

        return try? PhotoStore.save(image)
    }

    // MARK: - Conversations

    private static func seedConversations(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        let conversations: [(title: String, daysAgo: Int, turns: [(role: String, content: String)])] = [
            (
                title: "Curiosidad en el trabajo",
                daysAgo: 1,
                turns: [
                    ("user", "¿Cómo puedo usar mi curiosidad en un trabajo que se siente rutinario?"),
                    ("assistant", "Una ruta que funciona muy bien con tu perfil es **reenmarcar lo familiar**. Elige una tarea que ya hagas en automático y, durante una semana, hazte una pregunta nueva cada día sobre ella: *¿quién la diseñó?*, *¿qué pasaría si la hiciera al revés?*, *¿qué parte podría automatizar?*.\n\nLa curiosidad no necesita temas nuevos — necesita ángulos nuevos. Cuéntame qué tarea eligiste y te ayudo a afinar las preguntas."),
                    ("user", "Creo que voy a empezar por mis reuniones semanales — se sienten larguísimas."),
                    ("assistant", "Perfecto punto de partida. Prueba esto en la próxima:\n\n• Antes de entrar, escribe una pregunta concreta que te gustaría que la reunión respondiera.\n• Durante la reunión, anota una cosa que te sorprenda — aunque sea pequeña.\n• Al final, dedica 60 segundos a preguntarte qué cambiarías del formato.\n\nEn dos semanas tendrás 10 observaciones tuyas sobre cómo funcionan esas reuniones. Eso ya es material para proponer un experimento concreto."),
                ]
            ),
            (
                title: "Gratitud antes de dormir",
                daysAgo: 3,
                turns: [
                    ("user", "Quiero hacer una práctica de gratitud en las noches pero me siento medio cursi haciéndolo."),
                    ("assistant", "Esa sensación es común y muy honesta — gracias por nombrarla. La gratitud \"mal hecha\" se siente cursi cuando es genérica (*\"agradezco tener salud\"*) y vacía. La gratitud que sí mueve algo por dentro es **específica, sensorial y reciente**.\n\nEn vez de una lista, prueba una sola frase al día con este formato: *\"Hoy noté ___, y eso me recordó que ___\".* Te quita la obligación de producir cantidad y te invita a observar."),
                    ("user", "¿Me das un ejemplo?"),
                    ("assistant", "Claro. Por ejemplo:\n\n*\"Hoy noté que mi café estaba exactamente como me gusta, y eso me recordó que hago bien en darme pequeños lujos cotidianos.\"*\n\n*\"Hoy noté que mi amiga se acordó de un detalle que le conté hace meses, y eso me recordó que soy más importante para ella de lo que asumo.\"*\n\nEs la diferencia entre un inventario y una observación. Prueba con una sola frase esta noche y me cuentas."),
                ]
            ),
            (
                title: "Cómo cultivar la paciencia",
                daysAgo: 6,
                turns: [
                    ("user", "La autorregulación es de mis puntuaciones más bajas. ¿Por dónde empiezo?"),
                    ("assistant", "Un dato que suele tranquilizar: la autorregulación baja no significa que te falte disciplina — suele significar que la usas mucho en un área y no te queda para otras. Con tu curiosidad y bondad altas, probablemente gastas mucha energía emocional acompañando a otros.\n\nEl primer paso útil no es añadir un hábito nuevo, sino **identificar una sola fricción diaria** que te roba energía. ¿Hay algo que pospongas sistemáticamente por las mañanas?"),
                ]
            ),
            (
                title: "Apoyo para una decisión difícil",
                daysAgo: 9,
                turns: [
                    ("user", "Tengo que decidir si acepto una oferta de trabajo nueva y no puedo dormir pensando en eso."),
                    ("assistant", "Entiendo. Antes de entrar en pros y contras, una pregunta: cuando piensas en la oferta y no duermes, *¿qué sientes en el cuerpo?* ¿Es una tensión tipo miedo a perderte algo, o una tensión tipo ya sabes la respuesta pero no quieres decirla?\n\nCon tu perfil (curiosidad y honestidad altas), muchas veces el cuerpo sabe antes que la lista de razones. Vamos despacio."),
                    ("user", "Más bien es miedo a equivocarme. Es un cambio grande."),
                    ("assistant", "Eso ya es información valiosa — no es una señal de que la decisión sea mala, es una señal de que es **importante**. Las decisiones triviales no quitan el sueño.\n\nTe propongo un ejercicio concreto: escribe dos cartas desde tu yo de dentro de un año. En una, te felicitas por haber aceptado. En la otra, te felicitas por haberla rechazado. Fíjate cuál se te sale más fácil y cuál te cuesta completar.\n\nA veces lo que escribimos con soltura dice más que lo que razonamos con esfuerzo."),
                ]
            ),
        ]

        for (index, template) in conversations.enumerated() {
            guard let day = cal.date(byAdding: .day, value: -template.daysAgo, to: now) else { continue }
            let hour = 9 + (index * 3) % 10
            let minute = (index * 17) % 60
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            let baseDate = cal.date(from: comps) ?? day

            let conversation = Conversation(title: template.title)
            conversation.createdAt = baseDate
            conversation.updatedAt = baseDate.addingTimeInterval(Double(template.turns.count) * 45)
            context.insert(conversation)

            for (turnIndex, turn) in template.turns.enumerated() {
                let record = ChatMessageRecord(role: turn.role, content: turn.content)
                record.createdAt = baseDate.addingTimeInterval(Double(turnIndex) * 45)
                record.conversation = conversation
                conversation.messages.append(record)
                context.insert(record)
            }
        }
    }

    // MARK: - AppStorage priming

    private static func seedAppStorageDefaults(latest: TestResult?) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "hasCompletedOnboarding")
        defaults.set(true, forKey: "hasCompletedQuiz")
        defaults.set(true, forKey: "hasSeenBuddyDisclaimer")

        // Daily reflection — render a warm, specific micro-reflection so the
        // "Mis 24" screen shows the card even without Apple Intelligence.
        let reflection = "Tu **curiosidad** es una forma de ternura disfrazada: te acercas a lo que no entiendes en lugar de descartarlo. Hoy, detente un momento antes de responder en automático — y pregunta algo que no sepas."
        let today = dateKey(for: Date())
        defaults.set(reflection, forKey: "dailyReflectionText")
        defaults.set(today, forKey: "dailyReflectionDate")
    }

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Helpers

private extension PhotoStore {
    /// Wipes every file under `Application Support/Photos/`. Used by the
    /// seeder to keep the directory from accumulating orphaned images
    /// across repeated seed runs.
    static func deleteAllPhotos() {
        let fm = FileManager.default
        guard let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }
        let dir = appSupport.appendingPathComponent("Photos", isDirectory: true)
        guard let contents = try? fm.contentsOfDirectory(atPath: dir.path) else { return }
        for item in contents {
            try? fm.removeItem(at: dir.appendingPathComponent(item))
        }
    }
}

private extension UIColor {
    /// Returns a copy of the color nudged lighter (`amount > 0`) or darker
    /// (`amount < 0`) in HSB space. Small values keep gradients on-brand.
    func shaded(by amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        let nb = max(0, min(1, b + amount))
        return UIColor(hue: h, saturation: s, brightness: nb, alpha: a)
    }
}
#endif
