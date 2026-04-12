import Foundation
import FoundationModels

/// Personalized analysis of a user's VIA strengths ranking.
///
/// Designed as the target type of a Foundation Models guided-generation
/// call. `@Generable` converts this struct into a JSON schema the model
/// fills in directly — no string parsing, no fragile regex, just a
/// strongly-typed Swift value.
///
/// The shape intentionally mirrors VIA framework pedagogy: signature
/// strengths (top 5) get the most detailed treatment, growth areas
/// (bottom 2) are reframed as opportunities rather than deficits, and
/// the summary/encouragement act as warm bookends.
@Generable(description: "Análisis personalizado de fortalezas VIA del usuario")
struct StrengthInsight: Codable, Sendable {
    @Guide(description: "Resumen cálido de las fortalezas principales, 2 a 3 frases, en segunda persona")
    var summary: String

    @Guide(description: "Análisis de cada fortaleza signature del usuario", .count(5))
    var signatureStrengths: [SignatureStrengthItem]

    @Guide(description: "Áreas de crecimiento enmarcadas como oportunidades", .count(2))
    var growthAreas: [GrowthAreaItem]

    @Guide(description: "Mensaje de cierre alentador, máximo 2 frases, sin clichés")
    var encouragement: String
}

@Generable(description: "Una fortaleza signature del usuario con análisis concreto")
struct SignatureStrengthItem: Codable, Sendable {
    @Guide(description: "Nombre de la fortaleza en español, copiado tal cual de la lista proporcionada")
    var strengthName: String

    @Guide(description: "Cómo se manifiesta esta fortaleza en la vida diaria del usuario, en 1 o 2 frases")
    var howItShows: String

    @Guide(description: "Una acción concreta y específica para usar esta fortaleza esta semana")
    var weeklyAction: String
}

@Generable(description: "Un área de crecimiento enmarcada como oportunidad")
struct GrowthAreaItem: Codable, Sendable {
    @Guide(description: "Nombre de la fortaleza en español, copiado tal cual de la lista proporcionada")
    var strengthName: String

    @Guide(description: "Por qué cultivar esta fortaleza puede enriquecer la vida del usuario, sin juicio")
    var whyItMatters: String

    @Guide(description: "Un primer paso pequeño, concreto y accesible")
    var firstStep: String
}
