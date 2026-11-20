import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private let appGroupID = "group.com.ryan.liquidclipboard"
    private let storageKey = "clipboard_history"

    private var currentHistory: [String] {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        return defaults.stringArray(forKey: storageKey) ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let rootView = KeyboardGlassRootView(
            initialItems: currentHistory,
            onRefreshClipboard: { [weak self] in
                self?.captureCurrentClipboard() ?? []
            },
            onInsertText: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            onBackspace: { [weak self] in
                self?.textDocumentProxy.deleteBackward()
            },
            onReturnKey: { [weak self] in
                self?.textDocumentProxy.insertText("\n")
            },
            onClearAll: { [weak self] in
                self?.clearHistory()
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 270)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = captureCurrentClipboard()
    }

    private func captureCurrentClipboard() -> [String] {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        var list = defaults.stringArray(forKey: storageKey) ?? []

        if let copied = UIPasteboard.general.string,
           !copied.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if list.first != copied {
                list.removeAll { $0 == copied }
                list.insert(copied, at: 0)
                if list.count > 25 {
                    list = Array(list.prefix(25))
                }
                defaults.set(list, forKey: storageKey)
            }
        }
        return list
    }

    private func clearHistory() {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        defaults.removeObject(forKey: storageKey)
    }
}

struct KeyboardGlassRootView: View {
    @State var initialItems: [String]
    let onRefreshClipboard: () -> [String]
    let onInsertText: (String) -> Void
    let onNextKeyboard: () -> Void
    let onBackspace: () -> Void
    let onReturnKey: () -> Void
    let onClearAll: () -> Void

    @State private var activeClip: String?
    @Namespace private var flowNamespace

    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                if initialItems.isEmpty {
                    Text("Copie un texte puis ouvre le clavier.\nVérifie que l'Accès complet est activé.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 42)
                        .padding(.horizontal, 16)
                } else {
                    GlassEffectContainer(spacing: 10) {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(initialItems.enumerated()), id: \.element) { idx, item in
                                let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

                                Button {
                                    withAnimation(.snappy(duration: 0.25)) {
                                        activeClip = item
                                    }
                                    onInsertText(item)

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        withAnimation(.snappy(duration: 0.25)) {
                                            if activeClip == item {
                                                activeClip = nil
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Text(item)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        Spacer(minLength: 8)

                                        Image(systemName: activeClip == item ? "checkmark.circle.fill" : "doc.on.clipboard")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(activeClip == item ? .green : .secondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .glassEffect(.regular.interactive(), in: cardShape)
                                    .glassEffectID("clip-row-\(idx)-\(item.hashValue)", in: flowNamespace)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 2)
                    }
                }
            }

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: onNextKeyboard) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 40)
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .glassEffectID("key-globe", in: flowNamespace)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            initialItems = onRefreshClipboard()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .frame(width: 44, height: 40)
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .glassEffectID("key-refresh", in: flowNamespace)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.snappy(duration: 0.28)) {
                            onClearAll()
                            initialItems = []
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(width: 44, height: 40)
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .glassEffectID("key-trash", in: flowNamespace)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onBackspace) {
                        Image(systemName: "delete.left")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 52, height: 40)
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .glassEffectID("key-backspace", in: flowNamespace)
                    }
                    .buttonStyle(.plain)

                    Button(action: onReturnKey) {
                        Text("Entrée")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 78, height: 40)
                            .glassEffect(.regular.tint(.blue).interactive(), in: Capsule())
                            .glassEffectID("key-return", in: flowNamespace)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
            }
            .padding(.bottom, 6)
        }
        .padding(.top, 6)
        .onAppear {
            withAnimation(.snappy(duration: 0.28)) {
                initialItems = onRefreshClipboard()
            }
        }
    }
}