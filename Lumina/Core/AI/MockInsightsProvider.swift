import Foundation

/// Deterministic stand-in for ``FoundationModelsInsightsProvider``.
struct MockInsightsProvider: AIInsightsProviding {
    var isAvailable: Bool { true }
    var unavailableReason: String? { nil }

    func generateInsight(for snapshot: TestSnapshot) async throws -> StrengthInsight {
        try? await Task.sleep(for: .milliseconds(300))

        return StrengthInsight(
            summary: "Tu perfil refleja a alguien que combina una mirada curiosa con una profunda calidez humana. Usas el aprendizaje como motor y la gratitud como brújula.",
            signatureStrengths: [
                SignatureStrengthItem(
                    strengthName: "Curiosidad",
                    howItShows: "Haces preguntas donde otros dan por hecho las cosas, y eso enriquece tus conversaciones.",
                    weeklyAction: "Elige un tema que te intrigue y dedícale 20 minutos de exploración libre sin una meta específica."
                ),
                SignatureStrengthItem(
                    strengthName: "Amor por el aprendizaje",
                    howItShows: "Disfrutas profundizar en temas nuevos por el simple placer de entenderlos.",
                    weeklyAction: "Comparte con alguien cercano una idea que hayas aprendido recientemente — enseñar consolida lo aprendido."
                ),
                SignatureStrengthItem(
                    strengthName: "Bondad",
                    howItShows: "Te preocupas por el bienestar de otros incluso cuando no te conocen.",
                    weeklyAction: "Esta semana, haz un acto de bondad anónimo — sin esperar agradecimiento ni reconocimiento."
                ),
                SignatureStrengthItem(
                    strengthName: "Gratitud",
                    howItShows: "Reconoces las cosas buenas cotidianas en lugar de darlas por sentadas.",
                    weeklyAction: "Antes de dormir, anota tres momentos pequeños del día por los que te sientas agradecido."
                ),
                SignatureStrengthItem(
                    strengthName: "Esperanza",
                    howItShows: "Enmarcas el futuro con optimismo realista y eso motiva a quienes te rodean.",
                    weeklyAction: "Escribe una meta clara para los próximos tres meses y el primer paso que darás esta semana."
                ),
            ],
            growthAreas: [
                GrowthAreaItem(
                    strengthName: "Liderazgo",
                    whyItMatters: "Cultivar el liderazgo te permite poner al servicio de otros todo lo que ya sabes y sientes.",
                    firstStep: "Propón una pequeña actividad grupal esta semana y toma la iniciativa de organizarla."
                ),
                GrowthAreaItem(
                    strengthName: "Autorregulación",
                    whyItMatters: "Desarrollar tus hábitos te dará la base para sostener tu curiosidad a lo largo del tiempo.",
                    firstStep: "Elige un solo hábito (dormir, moverte, escribir) y compromete 10 minutos al día durante 7 días."
                ),
            ],
            encouragement: "Tus fortalezas ya están ahí — el siguiente paso es darles espacio de forma deliberada. Sigue explorando."
        )
    }
}
