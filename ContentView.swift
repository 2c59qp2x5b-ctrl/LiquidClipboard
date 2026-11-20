import SwiftUI
import UIKit

struct ContentView: View {
    private let appGroupID = "group.com.ryan.liquidclipboard"
    private let storageKey = "clipboard_history"

    @State private var items: [String] = []
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Activation") {
                    Text("1. Ouvre Réglages > Général > Clavier > Claviers.\n2. Ajoute Liquid Clips.\n3. Entre dans Liquid Clips et active Autoriser l'accès complet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Scanner le presse-papier maintenant") {
                        syncPasteboard()
                    }
                }

                Section("Textes enregistrés (\(items.count))") {
                    if items.isEmpty {
                        Text("Aucun texte enregistré pour l'instant.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(items, id: \.self) { text in
                            Text(text)
                                .lineLimit(3)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("Liquid Clips")
            .toolbar {
                if !items.isEmpty {
                    Button("Tout effacer", role: .destructive) {
                        clearAll()
                    }
                }
            }
            .onAppear {
                syncPasteboard()
            }
            .overlay(alignment: .bottom) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: Capsule())
                        .padding(.bottom, 16)
                }
            }
        }
    }

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private func loadItems() {
        items = sharedDefaults.stringArray(forKey: storageKey) ?? []
    }

    private func syncPasteboard() {
        loadItems()
        guard let copied = UIPasteboard.general.string else { return }
        let cleaned = copied.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        var updated = items
        if updated.first != copied {
            updated.removeAll { $0 == copied }
            updated.insert(copied, at: 0)
            if updated.count > 25 {
                updated = Array(updated.prefix(25))
            }
            sharedDefaults.set(updated, forKey: storageKey)
            items = updated
            showStatus("Nouveau texte ajouté")
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        sharedDefaults.set(items, forKey: storageKey)
    }

    private func clearAll() {
        items.removeAll()
        sharedDefaults.removeObject(forKey: storageKey)
        showStatus("Historique vidé")
    }

    private func showStatus(_ message: String) {
        withAnimation(.snappy(duration: 0.25)) {
            statusMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.snappy(duration: 0.25)) {
                if statusMessage == message {
                    statusMessage = nil
                }
            }
        }
    }
}