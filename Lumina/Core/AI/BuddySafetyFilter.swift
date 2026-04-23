import Foundation

/// Deterministic pre-flight check that intercepts medical, clinical, and
/// crisis-related prompts before they reach the on-device language model.
///
/// **Why this exists.** Apple's App Review Guideline 1.4.1 holds apps
/// that touch health/psychology to a high bar. Foundation Models — like
/// any modern LLM — will happily answer "¿cuál es el tratamiento de X?"
/// unless we stop it upstream. Prompt instructions alone are not reliable
/// (they can be bypassed by creative phrasing or model drift). A
/// deterministic Swift-side filter is the only way to guarantee, across
/// every future model update, that Lumina never returns medical advice.
///
/// **Design.** The filter errs on the side of false positives in clearly
/// medical territory. When in doubt we redirect the user to a qualified
/// professional rather than let Buddy improvise. Each category has a
/// canned response that (a) states the limitation, (b) redirects to a
/// real resource when relevant (crisis helplines), and (c) offers to
/// pivot back to the VIA-strengths conversation.
enum BuddySafetyFilter {
    struct Decision {
        let isBlocked: Bool
        let reason: BlockReason?
    }

    enum BlockReason {
        /// Medical, pharmacological, surgical, diagnostic, or physical-health query.
        case medical
        /// Mental-health crisis indicator (suicide, self-harm, severe distress).
        case mentalHealthCrisis
        /// Substance use or addiction-related query.
        case substances
    }

    /// Evaluates the user's raw prompt. The check is case- and
    /// diacritic-insensitive (Spanish `á`, `é`, etc. are normalized).
    static func evaluate(_ prompt: String) -> Decision {
        let normalized = prompt.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es")
        )
        let range = NSRange(normalized.startIndex..., in: normalized)

        // Order matters: crisis first (most urgent), then substances, then
        // medical (broadest). A crisis phrasing like "quiero quitarme la
        // vida" might incidentally match nothing in the medical list, but
        // we want the crisis response in any case.
        if crisisPattern.firstMatch(in: normalized, range: range) != nil {
            return Decision(isBlocked: true, reason: .mentalHealthCrisis)
        }
        if substancePattern.firstMatch(in: normalized, range: range) != nil {
            return Decision(isBlocked: true, reason: .substances)
        }
        if medicalPattern.firstMatch(in: normalized, range: range) != nil {
            return Decision(isBlocked: true, reason: .medical)
        }
        return Decision(isBlocked: false, reason: nil)
    }

    /// Canned, safe response for a given block reason. Stays in Buddy's
    /// voice (second person, cálido) but is fully deterministic — no LLM
    /// involvement.
    static func response(for reason: BlockReason) -> String {
        switch reason {
        case .medical:
            return """
            Esa pregunta sale de lo que puedo ayudarte a explorar. Lumina es una \
            herramienta educativa de fortalezas de carácter; no doy información \
            médica, de diagnóstico ni de tratamientos.

            Para cualquier tema de salud, por favor consulta a un profesional \
            calificado. Si quieres, podemos hablar de cómo tus fortalezas te \
            acompañan en momentos difíciles.
            """
        case .mentalHealthCrisis:
            return """
            Lamento que estés pasando por esto. Soy una herramienta educativa y \
            no sustituyo a un profesional de la salud mental.

            Si tú o alguien cercano está en peligro inmediato, por favor contacta \
            a un servicio de emergencia de tu país. En México puedes llamar a \
            **SAPTEL: 55 5259 8121** (24 h, gratuito y confidencial) o a la \
            **Línea de la Vida: 800 290 0024**.

            Cuando te sientas en un espacio seguro para seguir, con gusto exploramos \
            las fortalezas que te apoyan en momentos de mucha presión.
            """
        case .substances:
            return """
            No puedo orientarte sobre sustancias o adicciones — eso requiere \
            acompañamiento profesional.

            Si buscas ayuda en México, puedes contactar a los **Centros de \
            Integración Juvenil (CIJ): 55 5212 1212**. Cuando quieras, podemos \
            hablar de alguna fortaleza de carácter que te gustaría desarrollar \
            para apoyarte en tu proceso.
            """
        }
    }

    // MARK: - Patterns

    // Compile once. Patterns use lookarounds rather than `\b` because the
    // input is already ASCII-folded (diacritics stripped) and we want
    // simple char-class boundaries that cope with Spanish punctuation.
    private static let boundaryPrefix = "(?<![a-z0-9])"
    private static let boundarySuffix = "(?![a-z0-9])"

    private static func compile(_ alternatives: [String]) -> NSRegularExpression {
        let body = alternatives.joined(separator: "|")
        let pattern = "\(boundaryPrefix)(?:\(body))\(boundarySuffix)"
        // Force-try is safe: patterns are static and developer-authored.
        // A crash here would only happen in debug builds.
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    /// Medical, pharmacological, surgical, diagnostic, physical-health.
    /// All alternatives are written diacritic-free (no accents) because
    /// the input is folded before matching.
    private static let medicalPattern = compile([
        // Pregnancy / obstetrics / neonatal
        "embarazo", "preterm(ino|inos)?", "gestacion(al)?", "fet(o|al|ales)",
        "neonat(al|o)", "cesare(a|o)", "aborto",
        // Medications & pharmacology
        "medicament(o|os|ar)", "farmac(o|os|ologic(o|a))",
        "antibiotic(o|os)?", "analgesic(o|os)?", "anticoagulant(e|es)?",
        "antidepresiv(o|os)?", "ansiolitic(o|os)?", "antipsicot(ic|ic)",
        "corticoid(e|es)?", "dosis", "receta medica", "posologi(a|as)",
        // Surgery
        "cirugi(a|as)", "quirurgic(o|a|as|os)", "operacion quirurgica",
        "anestesia",
        // Treatment (medical context only — "tratamiento" solo es ambiguo)
        "tratamiento (medic(o|a|as|os)|farmacolog|quimic|quimioterap|radioterap|hormonal|dental|oncolog)",
        // Diagnostic / symptoms / disease
        "diagnostic(o|os|ar)", "sintoma(s)?", "enfermedad(es)?",
        "infeccion(es)?", "hongo patogen",
        "virus", "bacteri(a|ana|ano|as|anas|anos)",
        // Named conditions
        "diabetes", "cancer", "tumor(es)?", "vih", "sida", "covid", "pandemi(a|as)",
        "hiperten(sion|so|sa)?", "hipotensi(on|vo|va)?",
        "colesterol", "glucosa elevada", "anemi(a|as)", "asma", "epilepsi(a|as)",
        "alzheimer", "parkinson", "esclerosis",
        // Vaccines / clinical
        "vacuna(s|r|rme)?", "inmunizac(ion|iones)",
        "radiografi(a|as)", "resonancia magnetica", "tomografi(a|as)",
        "ecografi(a|as)", "biopsia(s)?", "analisis de sangre",
        // Body-systems in clinical phrasing
        "cardiac(o|a|as|os)", "infarto(s)?",
        "pulmonar(es)?", "ren(al|ales)", "hepatic(o|a|os|as)",
        // Symptoms (scoped to clearly medical phrasings)
        "dolor (de cabeza|abdominal|toracic|articular|de pecho|de huesos)",
        "fiebre", "vomit(ar|o|os)", "diarrea", "hemorragi(a|as)", "convulsion(es)?",
        // Therapy (medical-clinical)
        "psicoterapi(a|as)", "terapeut(ico|ica|icos|icas)",
        "terapi(a|as) (fisic|cognitiv|conductual|ocupacional|respiratori|familiar)",
        // Primeros auxilios
        "primeros auxilios", "rcp",
    ])

    /// Mental-health crisis / self-harm indicators.
    private static let crisisPattern = compile([
        "suicid(arme|ar|io|a|arse|aba)?",
        "quitarme la vida", "quitarle la vida", "acabar con mi vida",
        "autolesion(arme|es)?", "autoagred", "cortarme( |$|[^a-z])",
        "hacerme dano", "lastimarme( |$|[^a-z])",
        "querer morir", "mejor muert(o|a)", "ya no quiero vivir",
        "no quiero seguir viviendo", "no tiene sentido vivir",
        "ataque de panico", "ataque de ansiedad fuerte",
        "crisis emocional (grave|severa|fuerte)",
    ])

    /// Substance use and addiction-related queries.
    private static let substancePattern = compile([
        "drog(a|as|arme)",
        "cocain(a|as)", "heroin(a|as)", "marihuana", "cannabis", "canabis",
        "metanfetam(ina|inas)", "extasis", "lsd", "fentanilo",
        "adiccion(es)?", "alcoholism(o|a)", "desintoxic(ar|acion)",
        "abstinenci(a|as)", "dependencia quimica",
        "sobredosis", "overdose",
    ])
}
