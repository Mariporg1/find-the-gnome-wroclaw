import SwiftUI
import MapKit
import UIKit
import AVKit

// 1. EXTENSIÓN NECESARIA PARA EVITAR EL ERROR DE MAPKIT
extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
               lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

// 2. WRAPPER PARA GESTIONAR LAS HOJAS (SHEETS) DE FORMA ROBUSTA
// Esto soluciona que las ventanas salgan en blanco.
struct GnomeSelection: Identifiable, Equatable {
    let id: Int
}

struct Gnome: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    var description: String
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var completedGnomes: Set<Int> = Set<Int>()
    @State private var gnomeImages: Dictionary<Int, UIImage> = Dictionary<Int, UIImage>()
    
    // --- ESTADOS DE NAVEGACIÓN CORREGIDOS (ROBUSTEZ) ---
    // En lugar de Bool, usamos el objeto. Si es nil, se cierra. Si tiene valor, se abre con datos.
    @State private var activePhotoSheet: GnomeSelection? = nil      // Para la cámara/librería
    @State private var activeDetailSheet: GnomeSelection? = nil     // Para ver/editar gnomo con foto
    @State private var activeDescriptionSheet: GnomeSelection? = nil // Para gnomo sin foto (descripción)
    @State private var activeGallerySheet: GnomeSelection? = nil    // Para el detalle desde Galería/Favoritos
    @State private var activeGnomeOfDaySheet: GnomeSelection? = nil
    
    @State private var favorites: Set<Int> = []
    @State private var searchText: String = ""
    @State private var gallerySearchText: String = ""
    @State private var filteredGnomes: [Gnome] = []
    @State private var gnomeOfTheDayID: Int = 1
    @State private var showShareSheetForID: Int? = nil
    @State private var preferredColorSchemeOverride: ColorScheme? = nil
    @State private var showStats = false
    @State private var showSettings = false
    
    @State private var showIntro: Bool = true
    @State private var isSearchExpanded: Bool = false
    
    private let originalRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.1079, longitude: 17.0385),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    @State private var region: MKCoordinateRegion
    @State private var regionHistory: [MKCoordinateRegion] = []
    
    @State private var gnomes: [Gnome] = [
        Gnome(id: 1, coordinate: CLLocationCoordinate2D(latitude: 51.1106, longitude: 17.0319), description: "Papa Gnome, the legendary founder of all Wrocław gnomes."),
        Gnome(id: 2, coordinate: CLLocationCoordinate2D(latitude: 51.1105, longitude: 17.0322), description: "Świderek, a friendly gnome greeting passersby."),
        Gnome(id: 3, coordinate: CLLocationCoordinate2D(latitude: 51.1103, longitude: 17.0317), description: "Życzliwek, a smiling gnome symbolizing kindness."),
        Gnome(id: 4, coordinate: CLLocationCoordinate2D(latitude: 51.1098, longitude: 17.0325), description: "Syzyfki, two gnomes endlessly pushing a heavy stone."),
        Gnome(id: 5, coordinate: CLLocationCoordinate2D(latitude: 51.1153, longitude: 17.0371), description: "Pracz Odrzański, a gnome washing clothes by the river."),
        Gnome(id: 6, coordinate: CLLocationCoordinate2D(latitude: 51.1112, longitude: 17.0301), description: "Rzeźnik, a butcher gnome holding his tools."),
        Gnome(id: 7, coordinate: CLLocationCoordinate2D(latitude: 51.1116, longitude: 17.0334), description: "Więziennik, a gnome trapped behind prison bars."),
        Gnome(id: 8, coordinate: CLLocationCoordinate2D(latitude: 51.1102, longitude: 17.0314), description: "WrocLovek, a romantic gnome showing love for the city."),
        Gnome(id: 9, coordinate: CLLocationCoordinate2D(latitude: 51.1101, longitude: 17.0310), description: "Piwosz, a gnome happily drinking a mug of beer."),
        Gnome(id: 10, coordinate: CLLocationCoordinate2D(latitude: 51.1104, longitude: 17.0312), description: "Gołębnik, a gnome surrounded by pigeons."),
        Gnome(id: 11, coordinate: CLLocationCoordinate2D(latitude: 51.1131, longitude: 17.0326), description: "Kuźnik, a blacksmith gnome working with metal."),
        Gnome(id: 12, coordinate: CLLocationCoordinate2D(latitude: 51.1100, longitude: 17.0318), description: "Turysta, a gnome with a camera and backpack."),
        Gnome(id: 13, coordinate: CLLocationCoordinate2D(latitude: 51.1107, longitude: 17.0315), description: "Księgarz, a gnome absorbed in reading books."),
        Gnome(id: 14, coordinate: CLLocationCoordinate2D(latitude: 51.1109, longitude: 17.0319), description: "Mleczarz, a gnome carrying bottles of milk."),
        Gnome(id: 15, coordinate: CLLocationCoordinate2D(latitude: 51.1108, longitude: 17.0312), description: "Złotnik, a gnome crafting precious jewelry."),
        Gnome(id: 16, coordinate: CLLocationCoordinate2D(latitude: 51.1137, longitude: 17.0330), description: "Profesor, a wise gnome teaching students."),
        Gnome(id: 17, coordinate: CLLocationCoordinate2D(latitude: 51.1134, longitude: 17.0335), description: "Student, a gnome carrying books and notes."),
        Gnome(id: 18, coordinate: CLLocationCoordinate2D(latitude: 51.1125, longitude: 17.0342), description: "Bibliotekarz, a quiet gnome guarding knowledge."),
        Gnome(id: 19, coordinate: CLLocationCoordinate2D(latitude: 51.1130, longitude: 17.0328), description: "Żak, a playful academic gnome."),
        Gnome(id: 20, coordinate: CLLocationCoordinate2D(latitude: 51.1120, longitude: 17.0286), description: "Piekarczyk, a baker gnome holding fresh bread."),
        Gnome(id: 21, coordinate: CLLocationCoordinate2D(latitude: 51.1123, longitude: 17.0340), description: "Szewczyk, a shoemaker gnome repairing shoes."),
        Gnome(id: 22, coordinate: CLLocationCoordinate2D(latitude: 51.1089, longitude: 17.0348), description: "Kupczyk, a merchant gnome trading goods."),
        Gnome(id: 23, coordinate: CLLocationCoordinate2D(latitude: 51.1095, longitude: 17.0289), description: "Listonosz, a postman gnome delivering letters."),
        Gnome(id: 24, coordinate: CLLocationCoordinate2D(latitude: 51.1085, longitude: 17.0265), description: "Drogowiec, a road worker gnome in a helmet."),
        Gnome(id: 25, coordinate: CLLocationCoordinate2D(latitude: 51.1079, longitude: 17.0302), description: "Bankier, a gnome counting money."),
        Gnome(id: 26, coordinate: CLLocationCoordinate2D(latitude: 51.1074, longitude: 17.0269), description: "Biznesmen, a business gnome with a briefcase."),
        Gnome(id: 27, coordinate: CLLocationCoordinate2D(latitude: 51.1148, longitude: 17.0404), description: "Mostek, a gnome guarding the bridge."),
        Gnome(id: 28, coordinate: CLLocationCoordinate2D(latitude: 51.1150, longitude: 17.0407), description: "Zakochany, a gnome holding a heart."),
        Gnome(id: 29, coordinate: CLLocationCoordinate2D(latitude: 51.1142, longitude: 17.0416), description: "Latarnik, a gnome lighting the way with a lantern."),
        Gnome(id: 30, coordinate: CLLocationCoordinate2D(latitude: 51.1145, longitude: 17.0429), description: "Dzwonnik, a cathedral gnome ringing bells."),
        Gnome(id: 31, coordinate: CLLocationCoordinate2D(latitude: 51.1093, longitude: 17.0294), description: "Filmowiec, a gnome filming with a camera."),
        Gnome(id: 32, coordinate: CLLocationCoordinate2D(latitude: 51.1096, longitude: 17.0291), description: "Artysta, a creative gnome expressing art."),
        Gnome(id: 33, coordinate: CLLocationCoordinate2D(latitude: 51.1090, longitude: 17.0281), description: "Jazzman, a gnome playing jazz music."),
        Gnome(id: 34, coordinate: CLLocationCoordinate2D(latitude: 51.1088, longitude: 17.0278), description: "Muzykant, a gnome performing music."),
        Gnome(id: 35, coordinate: CLLocationCoordinate2D(latitude: 51.1086, longitude: 17.0276), description: "Imprezowicz, a party-loving gnome."),
        Gnome(id: 36, coordinate: CLLocationCoordinate2D(latitude: 51.1121, longitude: 17.0338), description: "Detektyw, a gnome investigating clues."),
        Gnome(id: 37, coordinate: CLLocationCoordinate2D(latitude: 51.1138, longitude: 17.0352), description: "Strażnik, a gnome guarding the area."),
        Gnome(id: 38, coordinate: CLLocationCoordinate2D(latitude: 51.1115, longitude: 17.0287), description: "Rycerz, a brave knight gnome."),
        Gnome(id: 39, coordinate: CLLocationCoordinate2D(latitude: 51.1112, longitude: 17.0284), description: "Kataryniarz, a gnome playing a street organ."),
        Gnome(id: 40, coordinate: CLLocationCoordinate2D(latitude: 51.1099, longitude: 17.0329), description: "Fotograf, a gnome taking photos."),
        Gnome(id: 41, coordinate: CLLocationCoordinate2D(latitude: 51.1097, longitude: 17.0332), description: "Reporter, a gnome reporting news."),
        Gnome(id: 42, coordinate: CLLocationCoordinate2D(latitude: 51.1109, longitude: 17.0339), description: "Kucharz, a chef gnome preparing food."),
        Gnome(id: 43, coordinate: CLLocationCoordinate2D(latitude: 51.1096, longitude: 17.0306), description: "Zbieracz, a gnome collecting items."),
        Gnome(id: 44, coordinate: CLLocationCoordinate2D(latitude: 51.1098, longitude: 17.0304), description: "Handlarz, a market trader gnome."),
        Gnome(id: 45, coordinate: CLLocationCoordinate2D(latitude: 51.1095, longitude: 17.0301), description: "Florystka, a gnome arranging flowers."),
        Gnome(id: 46, coordinate: CLLocationCoordinate2D(latitude: 51.1129, longitude: 17.0386), description: "Rybak, a gnome fishing by the river."),
        Gnome(id: 47, coordinate: CLLocationCoordinate2D(latitude: 51.1126, longitude: 17.0389), description: "Wodniak, a gnome connected to river life."),
        Gnome(id: 48, coordinate: CLLocationCoordinate2D(latitude: 51.1082, longitude: 17.0313), description: "Spacerowicz, a gnome enjoying a walk."),
        Gnome(id: 49, coordinate: CLLocationCoordinate2D(latitude: 51.1080, longitude: 17.0310), description: "Ogrodnik, a gnome taking care of plants."),
        Gnome(id: 50, coordinate: CLLocationCoordinate2D(latitude: 51.0987, longitude: 17.0361), description: "Kolejarz, a railway worker gnome."),
        Gnome(id: 51, coordinate: CLLocationCoordinate2D(latitude: 51.0989, longitude: 17.0365), description: "Podróżnik, a gnome ready to explore the world."),
        Gnome(id: 52, coordinate: CLLocationCoordinate2D(latitude: 51.1097, longitude: 17.0324), description: "Czasomierz, a gnome associated with the passage of time."),
        Gnome(id: 53, coordinate: CLLocationCoordinate2D(latitude: 51.1101, longitude: 17.0327), description: "Pomnikowy, the very first gnome monument in Wrocław."),
        Gnome(id: 54, coordinate: CLLocationCoordinate2D(latitude: 51.1100, longitude: 17.0316), description: "Życzliwy, a friendly gnome encouraging smiles and kindness."),
        Gnome(id: 55, coordinate: CLLocationCoordinate2D(latitude: 51.1118, longitude: 17.0296), description: "Ratuszowy, a gnome connected to the city hall."),
        Gnome(id: 56, coordinate: CLLocationCoordinate2D(latitude: 51.1126, longitude: 17.0315), description: "Uniwersytecki, a gnome representing academic life."),
        Gnome(id: 57, coordinate: CLLocationCoordinate2D(latitude: 51.1092, longitude: 17.0300), description: "Solny, a gnome linked to the historic salt market."),
        Gnome(id: 58, coordinate: CLLocationCoordinate2D(latitude: 51.1094, longitude: 17.0282), description: "Ruski, a nightlife-loving gnome from the Ruska area."),
        Gnome(id: 59, coordinate: CLLocationCoordinate2D(latitude: 51.1140, longitude: 17.0409), description: "Tumski, a peaceful gnome connected to Ostrów Tumski."),
        Gnome(id: 60, coordinate: CLLocationCoordinate2D(latitude: 51.1098, longitude: 17.0311), description: "Kupiecki, a gnome symbolizing trade and craftsmanship.")
    ]
    
    init() {
        _region = State(initialValue: originalRegion)
    }
    
    private func applySearch() {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredGnomes = gnomes
        } else {
            let q = searchText.lowercased()
            filteredGnomes = gnomes.filter { "#\($0.id) \($0.description)".lowercased().contains(q) }
        }
    }
    
    private struct LoopingPlayerView: View {
        let player: AVPlayer
        @State private var observer: NSObjectProtocol?
        
        init(url: URL) {
            let p = AVPlayer(url: url)
            p.isMuted = true
            p.actionAtItemEnd = .none
            self.player = p
        }
        var body: some View {
            VideoPlayer(player: player)
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .disabled(true)
                .onAppear {
                    player.play()
                    observer = NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: player.currentItem,
                        queue: .main
                    ) { _ in
                        player.seek(to: .zero)
                        player.play()
                    }
                }
                .onDisappear {
                    if let obs = observer {
                        NotificationCenter.default.removeObserver(obs)
                        observer = nil
                    }
                }
        }
    }
    
    var body: some View {
        ZStack {
            if showIntro {
                ZStack {
                    if let url = Bundle.main.url(forResource: "video-begin", withExtension: "mov") {
                        LoopingPlayerView(url: url)
                            .ignoresSafeArea()
                            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
                                showIntro = false
                            }
                        
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                }
            } else {
                Group {
                    TabView(selection: $selectedTab) {
                        MapTabView(
                            region: $region,
                            regionHistory: $regionHistory,
                            filteredGnomes: filteredGnomes,
                            gnomes: gnomes,
                            completedGnomes: $completedGnomes,
                            gnomeImages: $gnomeImages,
                            activeDetailSheet: $activeDetailSheet,
                            activeDescriptionSheet: $activeDescriptionSheet,
                            searchText: $searchText,
                            applySearch: applySearch,
                            activeGnomeOfDaySheet: $activeGnomeOfDaySheet,
                            isSearchExpanded: $isSearchExpanded,
                            gnomeOfTheDayID: $gnomeOfTheDayID
                        )
                        .tabItem {
                            Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                            Text("Map")
                        }
                        .tag(0)
                        
                        GalleryTabView(
                            favorites: $favorites,
                            gallerySearchText: $gallerySearchText,
                            gnomeImages: $gnomeImages,
                            completedGnomes: $completedGnomes,
                            activePhotoSheet: $activePhotoSheet,
                            activeGallerySheet: $activeGallerySheet,
                            gnomes: gnomes
                        )
                        .tabItem {
                            Image(systemName: selectedTab == 1 ? "photo.on.rectangle.fill" : "photo.on.rectangle")
                            Text("Gallery")
                        }
                        .tag(1)
                        
                        FavoritesTabView(
                            favorites: $favorites,
                            gnomeImages: $gnomeImages,
                            gnomes: gnomes,
                            activeGallerySheet: $activeGallerySheet
                        )
                        .tabItem {
                            Image(systemName: selectedTab == 2 ? "heart.fill" : "heart")
                            Text("Favorites")
                        }
                        .tag(2)
                    }
                    .onAppear { filteredGnomes = gnomes }
                    .accentColor(.blue)
                    .preferredColorScheme(preferredColorSchemeOverride)
                    // --- HOJAS CORREGIDAS: Usan 'item' en lugar de 'isPresented' ---
                    // 1. Selector de Fotos
                    .sheet(item: $activePhotoSheet) { selection in
                        VStack {
                            ImagePicker(sourceType: UIImagePickerController.SourceType.photoLibrary) { image in
                                gnomeImages[selection.id] = image
                                completedGnomes.insert(selection.id)
                                
                                activePhotoSheet = nil
                                activeDetailSheet = nil
                                activeGallerySheet = nil
                            }
                        }
                    }
                    // 2. Detalle del Gnomo (Desde Mapa con foto)
                    .sheet(item: $activeDetailSheet) { selection in
                        if let img = gnomeImages[selection.id] {
                            GnomeDetailView(
                                id: selection.id,
                                img: img,
                                gnome: gnomes.first(where: { $0.id == selection.id }),
                                favorites: $favorites,
                                completedGnomes: $completedGnomes,
                                gnomeImages: $gnomeImages,
                                activePhotoSheet: $activePhotoSheet,
                                closeSheet: { activeDetailSheet = nil }
                            )
                        } else {
                            Text("Error loading photo").onAppear { activeDetailSheet = nil }
                        }
                    }
                    // 3. Descripción (Desde Mapa sin foto)
                    .sheet(item: $activeDescriptionSheet) { selection in
                         if let gnome = gnomes.first(where: { $0.id == selection.id }) {
                             VStack(spacing: 24) {
                                 Text("Gnome #\(gnome.id)")
                                     .font(.system(size: 20, weight: .bold))
                                 Text(gnome.description)
                                     .font(.system(size: 15))
                                     .multilineTextAlignment(.center)
                                     .foregroundColor(.secondary)
                                 Button {
                                     activeDescriptionSheet = nil
                                     // Pequeño delay para asegurar transición suave
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                         activePhotoSheet = GnomeSelection(id: selection.id)
                                     }
                                 } label: {
                                     Label("Add Photo", systemImage: "photo")
                                         .font(.system(size: 17, weight: .semibold))
                                         .frame(maxWidth: .infinity)
                                 }
                                 .buttonStyle(.borderedProminent)
                                 .frame(height: 44)
                             }
                             .padding()
                             .presentationDetents([.medium, .large])
                         }
                    }
                    // 4. Detalle Completo (Desde Galería/Favoritos)
                    .sheet(item: $activeGallerySheet) { selection in
                        if let gnome = gnomes.first(where: { $0.id == selection.id }) {
                            GalleryDetailView(
                                id: selection.id,
                                gnome: gnome,
                                gnomeImages: $gnomeImages,
                                favorites: $favorites,
                                completedGnomes: $completedGnomes,
                                activePhotoSheet: $activePhotoSheet,
                                closeSheet: { activeGallerySheet = nil }
                            )
                        }
                    }
                    // 5. Gnome of the Day (Accionado por botón)
                    .sheet(item: $activeGnomeOfDaySheet) { selection in
                         if let gnome = gnomes.first(where: { $0.id == selection.id }) {
                             VStack(spacing: 20) {
                                 Text("Gnome of the Day").font(.system(size: 22, weight: .bold))
                                 Text("#\(gnome.id)").font(.system(size: 36, weight: .heavy))
                                 Text(gnome.description)
                                     .font(.system(size: 15))
                                     .multilineTextAlignment(.center)
                                     .foregroundColor(.secondary)
                                     .padding(.horizontal)
                                 Button {
                                     var newRegion = region
                                     newRegion.center = gnome.coordinate
                                     newRegion.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                     withAnimation { region = newRegion }
                                     selectedTab = 0
                                     activeGnomeOfDaySheet = nil
                                 } label: {
                                     Label("View on Map", systemImage: "map")
                                         .font(.system(size: 17, weight: .semibold))
                                         .frame(maxWidth: .infinity)
                                 }
                                 .buttonStyle(.borderedProminent)
                                 .frame(height: 44)
                             }
                             .padding()
                             .presentationDetents([.medium, .large])
                         }
                    }
                    // Hojas extras
                    .sheet(isPresented: Binding<Bool>(
                        get: { showShareSheetForID != nil },
                        set: { if !$0 { showShareSheetForID = nil } }
                    )) {
                        Text("Sharing not available").padding()
                    }
                    .sheet(isPresented: $showStats) { Text("Stats coming soon").padding() }
                    .sheet(isPresented: $showSettings) { Text("Settings coming soon").padding() }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showStats = true } label: { Image(systemName: "chart.pie.fill") }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        }
                    }
                }
            }
        }
    }
    
    // --- COMPONENTES EXTRAÍDOS PARA LIMPIEZA ---
    
    struct GnomeDetailView: View {
        let id: Int
        let img: UIImage
        let gnome: Gnome?
        @Binding var favorites: Set<Int>
        @Binding var completedGnomes: Set<Int>
        @Binding var gnomeImages: Dictionary<Int, UIImage>
        @Binding var activePhotoSheet: GnomeSelection?
        let closeSheet: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Gnome #\(id)")
                        .font(.system(size: 20, weight: .bold))
                    if let gnome = gnome {
                        Text(gnome.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                .padding(.horizontal)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding(.horizontal)
                VStack(spacing: 12) {
                    Button {
                        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
                    } label: {
                        Label(favorites.contains(id) ? "Unfavorite" : "Favorite",
                              systemImage: favorites.contains(id) ? "heart.slash" : "heart.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .frame(height: 44)
                    Button(role: .destructive) {
                        gnomeImages.removeValue(forKey: id)
                        completedGnomes.remove(id)
                        closeSheet()
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(height: 44)
                    Button {
                        closeSheet()
                        // Delay pequeño para permitir cierre
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            activePhotoSheet = GnomeSelection(id: id)
                        }
                    } label: {
                        Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .frame(height: 44)
                }
                .padding(.horizontal)
            }
            .presentationDetents([.medium, .large])
        }
    }

    struct GalleryDetailView: View {
        let id: Int
        let gnome: Gnome
        @Binding var gnomeImages: Dictionary<Int, UIImage>
        @Binding var favorites: Set<Int>
        @Binding var completedGnomes: Set<Int>
        @Binding var activePhotoSheet: GnomeSelection?
        let closeSheet: () -> Void
        
        var body: some View {
             VStack(spacing: 16) {
                Text("Gnome #\(id)")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top)
                ScrollView {
                    VStack(spacing: 16) {
                        if let img = gnomeImages[id] {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .padding(.horizontal)
                            VStack(spacing: 12) {
                                Button {
                                     if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
                                } label: {
                                    Label(favorites.contains(id) ? "Unfavorite" : "Favorite",
                                          systemImage: favorites.contains(id) ? "heart.slash" : "heart.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .frame(height: 44)
                                Button(role: .destructive) {
                                    gnomeImages.removeValue(forKey: id)
                                    completedGnomes.remove(id)
                                    closeSheet()
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(height: 44)
                                Button {
                                    closeSheet()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        activePhotoSheet = GnomeSelection(id: id)
                                    }
                                } label: {
                                    Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .frame(height: 44)
                            }
                            .padding(.horizontal)
                        } else {
                            Button {
                                closeSheet()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    activePhotoSheet = GnomeSelection(id: id)
                                }
                            } label: {
                                Label("Add Photo", systemImage: "photo")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(height: 44)
                            .padding(.horizontal)
                        }
                        Text(gnome.description)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Spacer()
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    struct GnomeMapMarker: View {
        let gnome: Gnome
        let isCompleted: Bool
        let onTap: () -> Void
        
        var body: some View {
            VStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.red)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(gnome.id))
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .bold))
                    )
                    .onTapGesture {
                        onTap()
                    }
            }
        }
    }
    
    private struct MapTabView: View {
        @Binding var region: MKCoordinateRegion
        @Binding var regionHistory: [MKCoordinateRegion]
        let filteredGnomes: [Gnome]
        let gnomes: [Gnome]
        @Binding var completedGnomes: Set<Int>
        @Binding var gnomeImages: Dictionary<Int, UIImage>
        
        // BINDINGS CORREGIDOS
        @Binding var activeDetailSheet: GnomeSelection?
        @Binding var activeDescriptionSheet: GnomeSelection?
        
        @Binding var searchText: String
        let applySearch: () -> Void
        @Binding var activeGnomeOfDaySheet: GnomeSelection?
        @Binding var isSearchExpanded: Bool
        @Binding var gnomeOfTheDayID: Int
        
        @State private var cameraPosition: MapCameraPosition = .automatic
        
        var visibleGnomes: [Gnome] {
            filteredGnomes.isEmpty ? gnomes : filteredGnomes
        }
        
        var body: some View {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    HStack {
                        if isSearchExpanded {
                            HStack(spacing: 8) {
                                TextField("Search gnome or #id", text: $searchText)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: searchText) { _, _ in applySearch() }
                                if !searchText.isEmpty {
                                    Button { searchText = ""; applySearch() } label: { Image(systemName: "xmark.circle.fill") }
                                }
                                Button {
                                    isSearchExpanded = false
                                    searchText = ""
                                    applySearch()
                                } label: {
                                    Image(systemName: "chevron.up")
                                }
                            }
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        } else {
                            Button {
                                isSearchExpanded = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let previous = regionHistory.popLast() {
                                withAnimation { region = previous }
                            } else {
                                withAnimation {
                                    region = MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: 51.1079, longitude: 17.0385),
                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    )
                                }
                            }
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Button { activeGnomeOfDaySheet = GnomeSelection(id: gnomeOfTheDayID) } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Gnome of the Day: #\(gnomeOfTheDayID)")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                .zIndex(1)
                
                Map(position: $cameraPosition) {
                    ForEach(visibleGnomes) { gnome in
                        Annotation("", coordinate: gnome.coordinate) {
                            GnomeMapMarker(
                                gnome: gnome,
                                isCompleted: completedGnomes.contains(gnome.id),
                                onTap: {
                                    // Lógica corregida para abrir el sheet correcto
                                    if gnomeImages[gnome.id] != nil {
                                        activeDetailSheet = GnomeSelection(id: gnome.id)
                                    } else {
                                        activeDescriptionSheet = GnomeSelection(id: gnome.id)
                                    }
                                }
                            )
                        }
                        .annotationTitles(.hidden)
                    }
                }
                .ignoresSafeArea()
                .onMapCameraChange { context in
                    region = context.region
                }
                .onChange(of: region) { _, newRegion in
                    cameraPosition = .region(newRegion)
                }
                .onAppear {
                    cameraPosition = .region(region)
                }
                .highPriorityGesture(
                    TapGesture(count: 2).onEnded {
                        regionHistory.append(region)
                        var newRegion = region
                        let minDelta = 0.001
                        newRegion.span = MKCoordinateSpan(
                            latitudeDelta: max(newRegion.span.latitudeDelta / 2.0, minDelta),
                            longitudeDelta: max(newRegion.span.longitudeDelta / 2.0, minDelta)
                        )
                        withAnimation { region = newRegion }
                    }
                )
            }
        }
    }
    
    private struct GalleryTabView: View {
        @Binding var favorites: Set<Int>
        @Binding var gallerySearchText: String
        @Binding var gnomeImages: Dictionary<Int, UIImage>
        @Binding var completedGnomes: Set<Int>
        @Binding var activePhotoSheet: GnomeSelection?
        @Binding var activeGallerySheet: GnomeSelection?
        let gnomes: [Gnome]
        
        private var galleryFilteredGnomes: [Gnome] {
            let base = gnomes.sorted { $0.id < $1.id }
            let trimmed = gallerySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return base }
            let q = trimmed.lowercased()
            return base.filter { "#\($0.id) \($0.description)".lowercased().contains(q) }
        }
        
        private var galleryDescriptions: [Int: String] {
            Dictionary(uniqueKeysWithValues: galleryFilteredGnomes.map { ($0.id, $0.description) })
        }
        
        private var galleryImages: [Int: UIImage] {
            Dictionary(uniqueKeysWithValues: gnomeImages.filter { key, _ in galleryFilteredGnomes.contains(where: { $0.id == key }) })
        }
        
        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: gallerySearchText.isEmpty ? "magnifyingglass" : "xmark.circle.fill")
                        .onTapGesture { if !gallerySearchText.isEmpty { gallerySearchText = "" } }
                    TextField("Search gallery or #id", text: $gallerySearchText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                GalleryView(
                    images: galleryImages,
                    gnomeDescriptions: galleryDescriptions,
                    onReplace: { id in
                        // Abre la librería de fotos directamente
                        activePhotoSheet = GnomeSelection(id: id)
                    },
                    onRemove: { id in
                        gnomeImages.removeValue(forKey: id)
                        completedGnomes.remove(id)
                    }
                )
                .overlay(alignment: .topLeading) {
                    // Detecta taps en la galería para abrir detalle
                    // Nota: Como GalleryView es un componente externo, asumimos que
                    // la lógica de tap viene de onReplace/onRemove o que GalleryView
                    // necesita manejar el tap para ver detalle.
                    // Si GalleryView no tiene callback de 'onTap', este overlay es un truco
                    // pero idealmente deberías añadir 'onTap' a GalleryView.
                    EmptyView()
                }
            }
        }
    }
    
    private struct FavoritesTabView: View {
        @Binding var favorites: Set<Int>
        @Binding var gnomeImages: Dictionary<Int, UIImage>
        let gnomes: [Gnome]
        @Binding var activeGallerySheet: GnomeSelection?
        
        let columns = [
            GridItem(.adaptive(minimum: 150), spacing: 16)
        ]
        
        private var validFavorites: [Gnome] {
            gnomes.filter { gnome in
                favorites.contains(gnome.id) && gnomeImages[gnome.id] != nil
            }
            .sorted { $0.id < $1.id }
        }
        
        var body: some View {
            NavigationView {
                VStack {
                    if validFavorites.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("No favourite photos yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Take a photo to some gnomes and add them to favourites.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(validFavorites) { gnome in
                                    if let image = gnomeImages[gnome.id] {
                                        ZStack(alignment: .bottomTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .frame(height: 150)
                                                .clipped()
                                            
                                            Text("#\(gnome.id)")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(.black.opacity(0.6))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(8)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            // Abre el detalle robusto
                                            activeGallerySheet = GnomeSelection(id: gnome.id)
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                favorites.remove(gnome.id)
                                            } label: {
                                                Label("Remove from favourites", systemImage: "heart.slash")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Favourites")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
