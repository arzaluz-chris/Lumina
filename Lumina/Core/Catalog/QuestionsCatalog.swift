import Foundation

/// The 48 blind questions of the Lumina test, in the exact order the
/// client authored them.
///
/// Each question is paired to a mascot illustration (`bearAsset`) that
/// matches its content — the image set lives in
/// `Assets.xcassets/Bears/bear_NN.imageset`.
///
/// Quiz presentation shuffles these at runtime, but their `id` is the
/// stable key used when persisting answers in `TestResult.scores`.
enum QuestionsCatalog {
    static let all: [Question] = [
        Question(id: 1,  textES: "Busco aprender una habilidad nueva cada vez que tengo oportunidad.",         strengthID: "amor_aprendizaje",    bearAsset: "bear_01"),
        Question(id: 2,  textES: "Siento que mi vida tiene un propósito o sentido profundo.",                  strengthID: "espiritualidad",      bearAsset: "bear_02"),
        Question(id: 3,  textES: "Tengo metas claras para el futuro y creo que las alcanzaré.",                strengthID: "esperanza",           bearAsset: "bear_03"),
        Question(id: 4,  textES: "Busco el lado divertido de la vida para animar a los demás.",                strengthID: "humor",               bearAsset: "bear_04"),
        Question(id: 5,  textES: "La gente suele acudir a mí para entender mejor sus problemas.",              strengthID: "perspectiva",         bearAsset: "bear_05"),
        Question(id: 6,  textES: "Disfruto encontrando formas originales de resolver problemas cotidianos.",   strengthID: "creatividad",         bearAsset: "bear_06"),
        Question(id: 7,  textES: "Me siento afortunado por la vida que tengo.",                                strengthID: "gratitud",            bearAsset: "bear_07"),
        Question(id: 8,  textES: "Me siento orgulloso cuando mi grupo tiene éxito aunque yo no sea el centro.", strengthID: "trabajo_equipo",     bearAsset: "bear_08"),
        Question(id: 9,  textES: "Entiendo por qué los demás actúan de la forma en que lo hacen.",             strengthID: "inteligencia_social", bearAsset: "bear_09"),
        Question(id: 10, textES: "Los obstáculos no me desaniman; sigo intentando con fuerza.",                strengthID: "perseverancia",       bearAsset: "bear_10"),
        Question(id: 11, textES: "Sé cómo encajar en diferentes ambientes sociales fácilmente.",               strengthID: "inteligencia_social", bearAsset: "bear_11"),
        Question(id: 12, textES: "Suelo dar las gracias por las pequeñas cosas buenas que me pasan.",          strengthID: "gratitud",            bearAsset: "bear_12"),
        Question(id: 13, textES: "Me preocupa el bienestar de las personas que ni siquiera conozco.",          strengthID: "bondad",              bearAsset: "bear_13"),
        Question(id: 14, textES: "Siempre espero que suceda lo mejor en cada situación.",                      strengthID: "esperanza",           bearAsset: "bear_14"),
        Question(id: 15, textES: "Se me da bien motivar a un grupo para lograr un objetivo común.",            strengthID: "liderazgo",           bearAsset: "bear_15"),
        Question(id: 16, textES: "Puedo ver el panorama general de las cosas sin perderme en detalles.",       strengthID: "perspectiva",         bearAsset: "bear_16"),
        Question(id: 17, textES: "Cuando empiezo una tarea difícil no descanso hasta terminarla.",             strengthID: "perseverancia",       bearAsset: "bear_17"),
        Question(id: 18, textES: "No guardo rencor, prefiero reparar las relaciones.",                         strengthID: "perdon",              bearAsset: "bear_18"),
        Question(id: 19, textES: "Siento una conexión profunda con el resto de los seres humanos.",            strengthID: "humanidad",           bearAsset: "bear_19"),
        Question(id: 20, textES: "Hago mi parte del trabajo con entusiasmo para no fallar a los demás.",       strengthID: "trabajo_equipo",      bearAsset: "bear_20"),
        Question(id: 21, textES: "Me aseguro de que todos tengan las mismas oportunidades en un grupo.",       strengthID: "justicia",            bearAsset: "bear_21"),
        Question(id: 22, textES: "Mantengo mi entusiasmo incluso cuando las cosas se ponen difíciles.",        strengthID: "coraje",              bearAsset: "bear_22"),
        Question(id: 23, textES: "Tengo creencias que me dan paz en los momentos difíciles.",                  strengthID: "espiritualidad",      bearAsset: "bear_23"),
        Question(id: 24, textES: "Pienso en las consecuencias futuras antes de actuar por impulso.",           strengthID: "prudencia",           bearAsset: "bear_24"),
        Question(id: 25, textES: "Afronto los retos de la vida con vigor y energía.",                          strengthID: "coraje",              bearAsset: "bear_25"),
        Question(id: 26, textES: "Organizo actividades donde todos se sienten integrados y activos.",          strengthID: "liderazgo",           bearAsset: "bear_26"),
        Question(id: 27, textES: "Analizo todas las opciones lógicamente antes de tomar una decisión.",        strengthID: "juicio",              bearAsset: "bear_27"),
        Question(id: 28, textES: "Me conmueve ver que alguien hace algo de forma excelente.",                  strengthID: "apreciacion_belleza", bearAsset: "bear_28"),
        Question(id: 29, textES: "Trato a todo el mundo con las mismas reglas, sin favoritismos.",             strengthID: "justicia",            bearAsset: "bear_29"),
        Question(id: 30, textES: "No me dejo llevar por rumores, busco pruebas antes de creer algo.",          strengthID: "juicio",              bearAsset: "bear_30"),
        Question(id: 31, textES: "Me enfrento a situaciones que me dan miedo si sé que son importantes.",      strengthID: "valentia",            bearAsset: "bear_31"),
        Question(id: 32, textES: "Me gusta explorar lugares y situaciones desconocidas.",                      strengthID: "curiosidad",          bearAsset: "bear_32"),
        Question(id: 33, textES: "Evito decir cosas de las que luego podría arrepentirme.",                    strengthID: "prudencia",           bearAsset: "bear_33"),
        Question(id: 34, textES: "Me detengo a admirar un paisaje o una canción hermosa.",                     strengthID: "apreciacion_belleza", bearAsset: "bear_34"),
        Question(id: 35, textES: "Hago cosas buenas por los demás sin esperar nada a cambio.",                 strengthID: "bondad",              bearAsset: "bear_35"),
        Question(id: 36, textES: "Me resulta fácil reírme de mis propios errores.",                            strengthID: "humor",               bearAsset: "bear_36"),
        Question(id: 37, textES: "Prefiero decir una verdad incómoda que una mentira fácil.",                  strengthID: "honestidad",          bearAsset: "bear_37"),
        Question(id: 38, textES: "Soy fiel a mis valores incluso cuando nadie me está mirando.",               strengthID: "honestidad",          bearAsset: "bear_38"),
        Question(id: 39, textES: "Tengo personas en mi vida que se preocupan por mí profundamente.",           strengthID: "amor",                bearAsset: "bear_39"),
        Question(id: 40, textES: "Puedo controlar mi temperamento incluso cuando estoy muy estresado.",        strengthID: "autorregulacion",     bearAsset: "bear_40"),
        Question(id: 41, textES: "Me fascinan casi todos los temas y siempre hago preguntas.",                 strengthID: "curiosidad",          bearAsset: "bear_41"),
        Question(id: 42, textES: "Soy disciplinado con mis hábitos (comida, ejercicio, trabajo).",             strengthID: "autorregulacion",     bearAsset: "bear_42"),
        Question(id: 43, textES: "Me encanta profundizar en temas nuevos por puro placer.",                    strengthID: "amor_aprendizaje",    bearAsset: "bear_43"),
        Question(id: 44, textES: "Me gusta crear cosas nuevas, ya sea arte, ideas o proyectos.",               strengthID: "creatividad",         bearAsset: "bear_44"),
        Question(id: 45, textES: "Suelo dar segundas oportunidades a quienes se han equivocado.",              strengthID: "perdon",              bearAsset: "bear_45"),
        Question(id: 46, textES: "Valoro mucho la intimidad y cercanía con mis seres queridos.",               strengthID: "amor",                bearAsset: "bear_46"),
        Question(id: 47, textES: "Hago lo correcto aunque otros se burlen de mí o me critiquen.",              strengthID: "valentia",            bearAsset: "bear_47"),
        Question(id: 48, textES: "Valoro la compasión por encima de los logros materiales.",                   strengthID: "humanidad",           bearAsset: "bear_48"),
    ]

    /// The number of questions per strength. The quiz is designed so that
    /// each of the 24 strengths receives exactly this many questions,
    /// giving a theoretical score range of `[questionsPerStrength, 5 × questionsPerStrength]`.
    static let questionsPerStrength = 2

    /// Theoretical minimum score per strength (all Likert answers = 1).
    static let minScorePerStrength = questionsPerStrength * 1

    /// Theoretical maximum score per strength (all Likert answers = 5).
    static let maxScorePerStrength = questionsPerStrength * 5
}
