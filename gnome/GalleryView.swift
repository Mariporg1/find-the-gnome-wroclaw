// GalleryView.swift
import SwiftUI
import UIKit

public struct GalleryView: View {
    public let images: Dictionary<Int, UIImage>
    public let gnomeDescriptions: [Int: String]
    
    public var onReplace: ((Int) -> Void)? = nil
    public var onRemove: ((Int) -> Void)? = nil
    
    @State private var editingId: Int? = nil
    @State private var showGnomeDetailSheet = false

    public init(
        images: Dictionary<Int, UIImage>,
        gnomeDescriptions: [Int: String],
        onReplace: ((Int) -> Void)? = nil,
        onRemove: ((Int) -> Void)? = nil
    ) {
        self.images = images
        self.gnomeDescriptions = gnomeDescriptions
        self.onReplace = onReplace
        self.onRemove = onRemove
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(1...64, id: \.self) { id in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            if let uiImage = images[id] {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 140, height: 140)
                                    .cornerRadius(12)
                            }

                            Text("\(id)")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(6)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingId = id
                            if images[id] != nil {
                                showGnomeDetailSheet = true
                            } else {
                                onReplace?(id)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showGnomeDetailSheet) {
            if let id = editingId {
                GnomeDetailSheetView(
                    id: id,
                    image: images[id],
                    onOpenGallery: { onReplace?(id) }
                )
            }
        }
    }
}

// Componente separado para el sheet
struct GnomeDetailSheetView: View {
    let id: Int
    let image: UIImage?
    let onOpenGallery: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Encabezado con información del gnomo
            VStack(spacing: 4) {
                Text("Gnome #\(id)")
                    .font(.headline)
                    .fontWeight(.bold)
                
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            // Imagen del gnomo
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding(.horizontal)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Botón para abrir galería
            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    onOpenGallery()
                }) {
                    Label("Open Gallery", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    GalleryView(
        images: [
            1: UIImage(systemName: "leaf.fill") ?? UIImage(),
            2: UIImage(systemName: "flame.fill") ?? UIImage()
        ],
        gnomeDescriptions: Dictionary(uniqueKeysWithValues: (1...64).map { i in
            (i, "Gnome \(i) description")
        })
    )
    .frame(width: 300, height: 800)
}
