import XCTest

/// Drives the Lumina app through the 8 App Store screenshot compositions
/// and attaches each capture to the xcresult bundle. The `run_screenshots.sh`
/// script boots an iPhone 15 Pro Max simulator, pins the status bar to
/// 9:41 / full bars / charged, invokes this test, then pulls the PNGs
/// out of the result bundle.
///
/// The test runs serially — each method saves a single composition — so
/// that a failure on one screen doesn't bring the rest down with it.
final class ScreenshotTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-ScreenshotMode",
            "-SeedOnLaunch",
            "-AppleLocale", "es_MX",
            "-AppleLanguages", "(es)",
        ]
        app.launch()

        // Give the splash + TabView a beat to settle so the first tap
        // doesn't race against the splash fade-out.
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tests (ordered alphabetically by XCTest; prefixes force order)

    func test_01_misFortalezas() throws {
        tapTab("Mis 24")
        sleep(2)
        capture(named: "01_MisFortalezas")
    }

    func test_02_analisis() throws {
        tapTab("Mis 24")
        sleep(1)
        let cta = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "análisis")).firstMatch
        if cta.waitForExistence(timeout: 4) { cta.tap() }
        sleep(3)
        capture(named: "02_AnalisisPersonalizado")
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func test_03_evolucion() throws {
        tapTab("Mis 24")
        sleep(1)
        let cta = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "evolución")).firstMatch
        if cta.waitForExistence(timeout: 4) { cta.tap() }
        sleep(3)
        capture(named: "03_Evolucion")
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func test_04_historias() throws {
        tapTab("Historias")
        sleep(2)
        capture(named: "04_Historias")
    }

    func test_05_historiaDetalle() throws {
        tapTab("Historias")
        sleep(1)
        // The first story row is the most recent "Curiosidad" entry.
        let firstCell = app.buttons.element(boundBy: 2) // tab bar buttons are 0-4, so story rows start higher
        // Robust fallback: look for any descendant card containing strength label
        let curiosityRow = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "curiosidad")).firstMatch
        if curiosityRow.waitForExistence(timeout: 4) {
            curiosityRow.tap()
        } else if firstCell.exists {
            firstCell.tap()
        }
        sleep(2)
        capture(named: "05_HistoriaDetalle")
        if app.navigationBars.buttons.element(boundBy: 0).exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func test_06_buddy() throws {
        tapTab("Buddy")
        sleep(3)
        capture(named: "06_Buddy")
    }

    func test_07_conversaciones() throws {
        tapTab("Buddy")
        sleep(2)
        // Open the conversation list sheet via the top-leading nav bar
        // button (the list.bullet icon). Query by position instead of
        // accessibility label — iOS 26 toolbars don't always surface the
        // label string on XCUIElement queries.
        let navBar = app.navigationBars.firstMatch
        let leading = navBar.buttons.element(boundBy: 0)
        if leading.waitForExistence(timeout: 4) { leading.tap() }
        sleep(3)
        capture(named: "07_Conversaciones")
    }

    func test_08_ajustes() throws {
        tapTab("Ajustes")
        sleep(2)
        capture(named: "08_Ajustes")
    }

    // MARK: - Helpers

    private func tapTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        if tab.waitForExistence(timeout: 5) {
            tab.tap()
        }
    }

    /// Full-screen snapshot attached to the xcresult bundle. The shell
    /// script extracts these by name via `xcresulttool`.
    private func capture(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
