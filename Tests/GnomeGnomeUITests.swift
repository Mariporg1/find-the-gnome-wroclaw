import XCTest

// ---------------------------------------------------------------------------
// MARK: – UI / Integration Tests  (Type 2 – end-to-end on-device)
//
// Run target : GnomeGnomeUITests  (add to your Xcode scheme)
// Device      : iOS simulator  (iPhone 15 Pro recommended)
// Pre-req     : The intro video must finish or be skipped before
//               every test.  `skipIntroIfNeeded()` handles that.
// ---------------------------------------------------------------------------

class GnomeGnomeUITests: XCTestCase {

    let app = XCUIApplication()

    // -----------------------------------------------------------------------
    // MARK: – Setup / Teardown
    // -----------------------------------------------------------------------

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // -----------------------------------------------------------------------
    // MARK: – Helpers
    // -----------------------------------------------------------------------

    /// The app opens with a looping intro video.  Wait for it to finish
    /// (or disappear) so the main TabView becomes visible.
    private func skipIntroIfNeeded() throws {
        // The Map tab label appears once the intro is done.
        let mapTab = app.tabBars.firstMatch.buttons["Map"]
        try mapTab.waitForExistence(timeout: 12)   // video is ~8 s
    }

    /// Taps the Map tab and ensures it is in the foreground.
    private func goToMap() throws {
        app.tabBars.firstMatch.buttons["Map"].tap()
    }

    /// Taps the Gallery tab and ensures it is in the foreground.
    private func goToGallery() throws {
        app.tabBars.firstMatch.buttons["Gallery"].tap()
    }

    /// Taps the Favorites tab.
    private func goToFavorites() throws {
        app.tabBars.firstMatch.buttons["Favorites"].tap()
    }

    // =======================================================================
    // MARK: – 1. Intro screen disappears and main UI loads
    // =======================================================================

    func testIntroScreenDisappears() throws {
        try skipIntroIfNeeded()

        // All three tabs must be present after the intro
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Map"].exists)
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Gallery"].exists)
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Favorites"].exists)
    }

    // =======================================================================
    // MARK: – 2. Map renders and markers are visible
    // =======================================================================

    func testMapShowsGnomeMarkers() throws {
        try skipIntroIfNeeded()
        try goToMap()

        // The map should contain at least one annotation.
        // MapKit annotations show up as accessible elements with the
        // coordinate label or the custom overlay.  We look for any
        // element whose label contains a gnome number string.
        // Give the map a moment to render tiles + annotations.
        sleep(2)

        // At the default zoom the centre-area gnomes (#1-#4 cluster) are visible.
        // Their markers carry the id as text inside the circle.
        let markerOne = app.otherElements.containing(.staticText, identifier: "1").firstMatch
        XCTAssertTrue(markerOne.waitForExistence(timeout: 3),
                      "Gnome marker #1 should be visible at default map zoom.")
    }

    // =======================================================================
    // MARK: – 3. Tapping an uncompleted marker opens the description sheet
    // =======================================================================

    func testTapUncompletedMarkerOpensDescriptionSheet() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(2)

        // Tap marker #1 (red circle, no photo yet on a fresh install)
        let markerOne = app.otherElements.containing(.staticText, identifier: "1").firstMatch
        XCTAssertTrue(markerOne.waitForExistence(timeout: 3))
        markerOne.tap()

        // The description sheet shows "Gnome #1" and an "Add Photo" button
        let title = app.staticTexts["Gnome #1"]
        XCTAssertTrue(title.waitForExistence(timeout: 2),
                      "Description sheet must display 'Gnome #1'.")

        let addPhotoBtn = app.buttons["Add Photo"]
        XCTAssertTrue(addPhotoBtn.exists,
                      "Description sheet must contain an 'Add Photo' button.")
    }

    // =======================================================================
    // MARK: – 4. "Add Photo" button opens the photo-library picker
    // =======================================================================

    func testAddPhotoOpensImagePicker() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(2)

        let markerOne = app.otherElements.containing(.staticText, identifier: "1").firstMatch
        XCTAssertTrue(markerOne.waitForExistence(timeout: 3))
        markerOne.tap()

        let addPhotoBtn = app.buttons["Add Photo"]
        XCTAssertTrue(addPhotoBtn.waitForExistence(timeout: 2))
        addPhotoBtn.tap()

        // UIImagePickerController (photo library) presents a navigation bar
        // with a "Cancel" button.  Its presence confirms the picker launched.
        let cancelBtn = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancelBtn.waitForExistence(timeout: 3),
                      "Photo-library picker must appear with a Cancel button.")

        // Dismiss without picking so the test stays clean
        cancelBtn.tap()
    }

    // =======================================================================
    // MARK: – 5. Search expands, filters, and clears correctly
    // =======================================================================

    func testSearchFilterAndClear() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(1)

        // Tap the magnifying-glass button to expand the search bar
        let searchIcon = app.buttons["magnifyingglass"]   // accessibility id from Image(systemName:)
        XCTAssertTrue(searchIcon.waitForExistence(timeout: 2))
        searchIcon.tap()

        // A text field should now appear
        let searchField = app.textFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2),
                      "Search text field must appear after tapping the search icon.")

        // Type a query that should match exactly one gnome
        searchField.tap()
        searchField.typeText("chef")

        // Wait briefly for the map to re-render with filtered markers
        sleep(1)

        // The map should now show only marker #42 (Kucharz = chef)
        let marker42 = app.otherElements.containing(.staticText, identifier: "42").firstMatch
        XCTAssertTrue(marker42.waitForExistence(timeout: 3),
                      "Marker #42 (Kucharz/chef) must be visible after filtering.")

        // Clear search via the × button
        let clearBtn = app.buttons["xmark.circle.fill"]
        XCTAssertTrue(clearBtn.waitForExistence(timeout: 2))
        clearBtn.tap()

        sleep(1)

        // After clearing, marker #1 should reappear (full list)
        let markerOne = app.otherElements.containing(.staticText, identifier: "1").firstMatch
        XCTAssertTrue(markerOne.waitForExistence(timeout: 3),
                      "After clearing search, all markers (incl. #1) must reappear.")
    }

    // =======================================================================
    // MARK: – 6. Gnome of the Day banner taps open the detail sheet
    // =======================================================================

    func testGnomeOfTheDaySheetOpens() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(1)

        // The banner text contains "Gnome of the Day:"
        let banner = app.staticTexts.containing(.staticText, identifier: "Gnome of the Day:").firstMatch
                     ?? app.buttons.containing(.staticText, identifier: "Gnome of the Day:").firstMatch
        // Fallback: look for any element whose label starts with "Gnome of the Day"
        let bannerButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS 'Gnome of the Day'")).firstMatch

        let target = banner ?? bannerButton
        XCTAssertTrue(target?.waitForExistence(timeout: 2) ?? false,
                      "'Gnome of the Day' banner must be visible on the map tab.")
        target?.tap()

        // The sheet should show "Gnome of the Day" as a title and a "View on Map" button
        let sheetTitle = app.staticTexts["Gnome of the Day"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 2),
                      "Gnome-of-the-Day sheet must show its title.")

        let viewOnMapBtn = app.buttons["View on Map"]
        XCTAssertTrue(viewOnMapBtn.exists,
                      "Gnome-of-the-Day sheet must have a 'View on Map' button.")

        // Dismiss
        viewOnMapBtn.tap()
    }

    // =======================================================================
    // MARK: – 7. Gallery tab renders the full 64-slot grid
    // =======================================================================

    func testGalleryGridDisplays() throws {
        try skipIntroIfNeeded()
        try goToGallery()
        sleep(1)

        // On a fresh install every slot is an empty grey rectangle.
        // The grid is inside a ScrollView; at minimum the first few
        // slots (with their id labels) must be on screen.
        // Slot labels are rendered as "\(id)" inside each cell.
        let slot1Label = app.staticTexts["1"]
        XCTAssertTrue(slot1Label.waitForExistence(timeout: 3),
                      "Gallery must show at least slot #1.")

        // Scroll down to confirm the grid is scrollable
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
        scrollView.swipe(from: CGPoint(x: 0.5, y: 0.8),
                         to:   CGPoint(x: 0.5, y: 0.2))
        sleep(1)

        // After scrolling, higher-numbered slots should appear
        // (exact number depends on device, so we just check > 1 exists)
        let anyHighSlot = app.staticTexts.matching(NSPredicate(format:
            "label BEGINSWITH '3'")).firstMatch   // could be 30, 31… 39
        XCTAssertTrue(anyHighSlot?.waitForExistence(timeout: 2) ?? false,
                      "Scrolling the gallery must reveal higher-numbered gnome slots.")
    }

    // =======================================================================
    // MARK: – 8. Gallery search filters displayed slots
    // =======================================================================

    func testGallerySearchFilters() throws {
        try skipIntroIfNeeded()
        try goToGallery()
        sleep(1)

        // The gallery has its own search bar always visible
        let gallerySearch = app.textFields["Search gallery or #id"]
        XCTAssertTrue(gallerySearch.waitForExistence(timeout: 2))

        gallerySearch.tap()
        gallerySearch.typeText("#42")
        sleep(1)

        // Only slot #42 should remain in the grid
        let slot42 = app.staticTexts["42"]
        XCTAssertTrue(slot42.waitForExistence(timeout: 3),
                      "Searching '#42' in gallery must show slot 42.")

        // Clear and verify the grid comes back
        gallerySearch.tripleToSelect()
        gallerySearch.typeText("")
        sleep(1)

        let slot1 = app.staticTexts["1"]
        XCTAssertTrue(slot1.waitForExistence(timeout: 3),
                      "Clearing gallery search must restore all slots.")
    }

    // =======================================================================
    // MARK: – 9. Favourites tab is empty on a fresh install
    // =======================================================================

    func testFavouritesEmptyStateShows() throws {
        try skipIntroIfNeeded()
        try goToFavorites()
        sleep(1)

        // The empty-state text that the app renders
        let emptyText = app.staticTexts["No favourite photos yet"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 2),
                      "Favourites tab must show empty-state text when no photos are favourited.")
    }

    // =======================================================================
    // MARK: – 10. Back-button (arrow.uturn.backward) resets the map region
    // =======================================================================

    func testBackButtonResetsMapView() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(2)

        // Pinch-out to zoom in, then tap the back arrow
        let map = app.maps.firstMatch ?? app.otherElements.firstMatch
        map.pinch(withScale: 3.0, velocity: 1.0, duration: 0.5)
        sleep(1)

        let backBtn = app.buttons["arrow.uturn.backward"]
        XCTAssertTrue(backBtn.waitForExistence(timeout: 2),
                      "Back button must be present on the map overlay.")
        backBtn.tap()
        sleep(1)

        // After pressing back, marker #1 (centre of default region) should be visible again
        let markerOne = app.otherElements.containing(.staticText, identifier: "1").firstMatch
        XCTAssertTrue(markerOne.waitForExistence(timeout: 3),
                      "After tapping Back, the map should return to a region showing marker #1.")
    }

    // =======================================================================
    // MARK: – 11. Stats & Settings buttons open placeholder sheets
    // =======================================================================

    func testStatsSheetOpens() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(1)

        let statsBtn = app.buttons["chart.pie.fill"]
        XCTAssertTrue(statsBtn.waitForExistence(timeout: 2))
        statsBtn.tap()

        let placeholder = app.staticTexts["Stats coming soon"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 2),
                      "Stats button must open the placeholder sheet.")
    }

    func testSettingsSheetOpens() throws {
        try skipIntroIfNeeded()
        try goToMap()
        sleep(1)

        let settingsBtn = app.buttons["gearshape"]
        XCTAssertTrue(settingsBtn.waitForExistence(timeout: 2))
        settingsBtn.tap()

        let placeholder = app.staticTexts["Settings coming soon"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 2),
                      "Settings button must open the placeholder sheet.")
    }
}
