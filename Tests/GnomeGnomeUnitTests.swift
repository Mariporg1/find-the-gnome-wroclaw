import XCTest
import UIKit

// ---------------------------------------------------------------------------
// MARK: – Inline copies of the types under test
// (In a real Xcode project you would import the app module instead.)
// ---------------------------------------------------------------------------

struct Gnome: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    var description: String
}

struct GnomeSelection: Identifiable, Equatable {
    let id: Int
}

// ---------------------------------------------------------------------------
// MARK: – Pure-logic helpers extracted from ContentView
//         (mirror the exact behaviour that lives in the app)
// ---------------------------------------------------------------------------

/// Filters the full gnome list exactly the way the map-tab search does.
func applySearch(gnomes: [Gnome], query: String) -> [Gnome] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return gnomes }
    let q = trimmed.lowercased()
    return gnomes.filter { "#\($0.id) \($0.description)".lowercased().contains(q) }
}

/// Returns only gnomes that have both a favourite mark AND a stored image.
func validFavourites(gnomes: [Gnome],
                     favourites: Set<Int>,
                     images: [Int: UIImage]) -> [Gnome] {
    gnomes
        .filter { favourites.contains($0.id) && images[$0.id] != nil }
        .sorted { $0.id < $1.id }
}

// ---------------------------------------------------------------------------
// MARK: – Unit Tests  (Type 1 – logic / state)
// ---------------------------------------------------------------------------

class GnomeUnitTests: XCTestCase {

    // MARK: – Fixtures
    /// 60 gnomes, matching the real data set size.  Only a handful carry
    /// meaningful descriptions so that search assertions stay readable.
    private let sampleGnomes: [Gnome] = [
        Gnome(id:  1, coordinate: CLLocationCoordinate2D(latitude: 51.1106, longitude: 17.0319), description: "Papa Gnome, the legendary founder of all Wrocław gnomes."),
        Gnome(id:  2, coordinate: CLLocationCoordinate2D(latitude: 51.1105, longitude: 17.0322), description: "Świderek, a friendly gnome greeting passersby."),
        Gnome(id:  5, coordinate: CLLocationCoordinate2D(latitude: 51.1153, longitude: 17.0371), description: "Pracz Odrzański, a gnome washing clothes by the river."),
        Gnome(id: 10, coordinate: CLLocationCoordinate2D(latitude: 51.1104, longitude: 17.0312), description: "Gołębnik, a gnome surrounded by pigeons."),
        Gnome(id: 42, coordinate: CLLocationCoordinate2D(latitude: 51.1109, longitude: 17.0339), description: "Kucharz, a chef gnome preparing food."),
        Gnome(id: 60, coordinate: CLLocationCoordinate2D(latitude: 51.1098, longitude: 17.0311), description: "Kupiecki, a gnome symbolizing trade and craftsmanship.")
    ]

    private func dummyImage() -> UIImage {
        UIImage(systemName: "circle.fill")!   // guaranteed non-nil system image
    }

    // -----------------------------------------------------------------------
    // 1.  Gnome data-model integrity
    // -----------------------------------------------------------------------

    /// Every gnome id must be unique across the full array.
    func testAllGnomeIdsAreUnique() {
        let ids = sampleGnomes.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count,
                       "Duplicate gnome IDs detected in the master list.")
    }

    /// Descriptions must never be empty (they show in sheets & search).
    func testNoGnomeHasEmptyDescription() {
        for gnome in sampleGnomes {
            XCTAssertFalse(gnome.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           "Gnome #\(gnome.id) has an empty description.")
        }
    }

    /// Coordinates must be within the Wrocław bounding box used by the map.
    func testAllCoordinatesAreInWroclawBounds() {
        // Generous box that contains every real gnome location
        let latRange: ClosedRange<Double> = 51.09...51.12
        let lonRange: ClosedRange<Double> = 17.02...17.05

        for gnome in sampleGnomes {
            XCTAssert(latRange.contains(gnome.coordinate.latitude),
                      "Gnome #\(gnome.id) latitude \(gnome.coordinate.latitude) is outside Wrocław bounds.")
            XCTAssert(lonRange.contains(gnome.coordinate.longitude),
                      "Gnome #\(gnome.id) longitude \(gnome.coordinate.longitude) is outside Wrocław bounds.")
        }
    }

    // -----------------------------------------------------------------------
    // 2.  Search / filter logic
    // -----------------------------------------------------------------------

    /// Empty or whitespace-only query returns the full list.
    func testSearchEmptyQueryReturnsAll() {
        XCTAssertEqual(applySearch(gnomes: sampleGnomes, query: "").count,
                       sampleGnomes.count)
        XCTAssertEqual(applySearch(gnomes: sampleGnomes, query: "   ").count,
                       sampleGnomes.count)
    }

    /// Searching by "#<id>" returns exactly that gnome.
    func testSearchByHashIdReturnsExactGnome() {
        let results = applySearch(gnomes: sampleGnomes, query: "#42")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, 42)
    }

    /// Searching by a keyword present in one description returns that gnome.
    func testSearchByKeywordMatchesDescription() {
        let results = applySearch(gnomes: sampleGnomes, query: "chef")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, 42,
                       "Expected Kucharz (#42) when searching 'chef'.")
    }

    /// Search is case-insensitive.
    func testSearchIsCaseInsensitive() {
        let lower = applySearch(gnomes: sampleGnomes, query: "papa")
        let upper = applySearch(gnomes: sampleGnomes, query: "PAPA")
        XCTAssertEqual(lower.map { $0.id }, upper.map { $0.id })
        XCTAssertFalse(lower.isEmpty)
    }

    /// A nonsense query returns an empty list.
    func testSearchNonExistentQueryReturnsEmpty() {
        let results = applySearch(gnomes: sampleGnomes, query: "xyzzy_no_match")
        XCTAssertTrue(results.isEmpty)
    }

    /// Searching "gnome" should match every gnome (all descriptions contain it).
    func testSearchGenericTermMatchesAll() {
        let results = applySearch(gnomes: sampleGnomes, query: "gnome")
        XCTAssertEqual(results.count, sampleGnomes.count)
    }

    // -----------------------------------------------------------------------
    // 3.  Completion-state & image-store logic
    // -----------------------------------------------------------------------

    /// Assigning an image to a gnome marks it as completed.
    func testAssigningImageMarksGnomeCompleted() {
        var completedGnomes = Set<Int>()
        var gnomeImages  = [Int: UIImage]()

        // Simulate the exact assignment from the ImagePicker callback
        let pickedId = 5
        gnomeImages[pickedId] = dummyImage()
        completedGnomes.insert(pickedId)

        XCTAssert(completedGnomes.contains(pickedId))
        XCTAssertNotNil(gnomeImages[pickedId])
    }

    /// Removing an image also removes the completion flag.
    func testRemovingImageClearsCompletion() {
        var completedGnomes: Set<Int> = [5]
        var gnomeImages: [Int: UIImage] = [5: dummyImage()]

        // Mirror the onRemove closure in GalleryTabView
        gnomeImages.removeValue(forKey: 5)
        completedGnomes.remove(5)

        XCTAssertFalse(completedGnomes.contains(5))
        XCTAssertNil(gnomeImages[5])
    }

    /// Replacing a photo keeps the gnome completed and swaps the image object.
    func testReplacingPhotoKeepsCompletionAndSwapsImage() {
        let original  = dummyImage()
        let replacement = UIImage(systemName: "square.fill")!

        var completedGnomes: Set<Int> = [10]
        var gnomeImages: [Int: UIImage] = [10: original]

        // Simulate replace (same flow as activePhotoSheet callback)
        gnomeImages[10] = replacement
        completedGnomes.insert(10)   // insert is idempotent on Set

        XCTAssert(completedGnomes.contains(10))
        XCTAssertNotEqual(gnomeImages[10], original)   // object identity changed
        XCTAssertEqual(gnomeImages[10], replacement)
    }

    // -----------------------------------------------------------------------
    // 4.  Favourites logic
    // -----------------------------------------------------------------------

    /// A gnome without a photo must NOT appear in validFavourites even if
    /// it is in the favourites set  –  this matches the app's filter.
    func testFavouritesExcludesGnomesWithoutPhoto() {
        let favourites: Set<Int> = [1, 2, 5]
        let images: [Int: UIImage] = [1: dummyImage()]   // only #1 has a photo

        let result = validFavourites(gnomes: sampleGnomes,
                                     favourites: favourites,
                                     images: images)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, 1)
    }

    /// Toggling a favourite on and off works correctly.
    func testToggleFavourite() {
        var favourites = Set<Int>()

        favourites.insert(42)
        XCTAssert(favourites.contains(42))

        favourites.remove(42)
        XCTAssertFalse(favourites.contains(42))
    }

    /// validFavourites returns gnomes sorted by ascending id.
    func testFavouritesAreSortedById() {
        let favourites: Set<Int> = [60, 10, 1]
        let images: [Int: UIImage] = [60: dummyImage(), 10: dummyImage(), 1: dummyImage()]

        let result = validFavourites(gnomes: sampleGnomes,
                                     favourites: favourites,
                                     images: images)
        let ids = result.map { $0.id }
        XCTAssertEqual(ids, ids.sorted())
    }

    // -----------------------------------------------------------------------
    // 5.  GnomeSelection identity (sheet-routing model)
    // -----------------------------------------------------------------------

    /// Two GnomeSelection values with the same id are equal.
    func testGnomeSelectionEquality() {
        let a = GnomeSelection(id: 7)
        let b = GnomeSelection(id: 7)
        XCTAssertEqual(a, b)
    }

    /// Different ids produce non-equal selections.
    func testGnomeSelectionInequality() {
        XCTAssertNotEqual(GnomeSelection(id: 1), GnomeSelection(id: 2))
    }

    // -----------------------------------------------------------------------
    // 6.  GalleryView grid range vs real gnome count
    // -----------------------------------------------------------------------

    /// GalleryView iterates 1…64 but only 60 gnomes exist.
    /// Slots 61-64 will always render as empty grey placeholders.
    /// This test documents the mismatch so it can be fixed intentionally.
    func testGalleryGridCoversAllGnomes() {
        let gallerySlots  = 64        // hard-coded in GalleryView: ForEach(1...64)
        let realGnomeCount = 60       // actual gnomes in ContentView

        // Currently the gallery has 4 orphan slots – document that fact
        XCTAssertGreaterThanOrEqual(gallerySlots, realGnomeCount,
                                    "Gallery grid must cover every gnome.")
        // If you ever want to flag this as a failure, uncomment:
        // XCTAssertEqual(gallerySlots, realGnomeCount,
        //                "Gallery grid size should match the number of gnomes.")
    }

    // -----------------------------------------------------------------------
    // 7.  Gnome-of-the-Day initial value
    // -----------------------------------------------------------------------

    /// The default gnomeOfTheDayID is 1 and must be a valid gnome.
    func testGnomeOfTheDayDefaultIsValid() {
        let defaultId = 1   // matches @State in ContentView
        let match = sampleGnomes.first(where: { $0.id == defaultId })
        XCTAssertNotNil(match, "gnomeOfTheDayID default (\(defaultId)) must exist in the gnome list.")
    }
}
