import SwiftUI
import WebKit

// ─── Jedina opcija koju trebaš mijenjati ──────────────────────────────
let MAX_TABS = 7
let HOME = "https://www.google.com"
// ──────────────────────────────────────────────────────────────────────

// MARK: - DOMOVINA brand tokeni (#002F6C navy / #FF0000 red / white)

extension Color {
    static let domNavy    = Color(red: 0/255,   green: 47/255,  blue: 108/255) // #002F6C
    static let domRed     = Color(red: 255/255, green: 0/255,   blue: 0/255)   // #FF0000
    static let domSurface = Color(red: 245/255, green: 247/255, blue: 249/255) // #F5F7F9
    static let domBorder  = Color(red: 225/255, green: 229/255, blue: 234/255) // #E1E5EA
}

// Brand stripe: red → white → navy, 6px, full width.
struct BrandStripe: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.domRed
            Color.white
            Color.domNavy
        }
        .frame(height: 6)
    }
}

// MARK: - Tab (jedan WKWebView + njegovo stanje)

final class BrowserTab: NSObject, ObservableObject, Identifiable {
    let id = UUID()
    let webView: WKWebView
    @Published var title = "Novi tab"
    @Published var address = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false

    private let keys = ["title", "canGoBack", "canGoForward", "URL", "loading"]

    override init() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        super.init()
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        keys.forEach { webView.addObserver(self, forKeyPath: $0, options: .new, context: nil) }
    }

    deinit { keys.forEach { webView.removeObserver(self, forKeyPath: $0) } }

    func load(_ raw: String) {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        let url: URL?
        if s.contains(" ") || !s.contains(".") {
            let q = s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
            url = URL(string: "https://www.google.com/search?q=\(q)")
        } else {
            url = URL(string: s.hasPrefix("http") ? s : "https://" + s)
        }
        if let url { webView.load(URLRequest(url: url)) }
    }

    func loadHome() { webView.load(URLRequest(url: URL(string: HOME)!)) }

    override func observeValue(forKeyPath k: String?, of o: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            self.title = (self.webView.title?.isEmpty == false) ? self.webView.title! : "Novi tab"
            self.canGoBack = self.webView.canGoBack
            self.canGoForward = self.webView.canGoForward
            self.isLoading = self.webView.isLoading
            if let u = self.webView.url?.absoluteString { self.address = u }
        }
    }
}

extension BrowserTab: WKUIDelegate {
    // target=_blank / window.open → otvori u istom tabu (bez novih prozora)
    func webView(_ webView: WKWebView, createWebViewWith config: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if action.targetFrame == nil, let url = action.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}

// MARK: - Model

final class Browser: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selectedID: UUID?

    init() { newTab() }

    var selected: BrowserTab? { tabs.first { $0.id == selectedID } }

    func newTab() {
        guard tabs.count < MAX_TABS else { return }
        let t = BrowserTab()
        tabs.append(t)
        selectedID = t.id
        t.loadHome()
    }

    func close(_ tab: BrowserTab) {
        guard let i = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tabs.remove(at: i)
        if selectedID == tab.id {
            selectedID = (i < tabs.count ? tabs[i] : tabs.last)?.id
        }
        if tabs.isEmpty { newTab() }
    }
}

// MARK: - WKWebView most prema SwiftUI-ju

struct WebViewHost: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

// MARK: - Toolbar (nav + adresa)

struct Toolbar: View {
    @ObservedObject var tab: BrowserTab
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button { tab.webView.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!tab.canGoBack)
            Button { tab.webView.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!tab.canGoForward)
            Button {
                if tab.isLoading { tab.webView.stopLoading() } else { tab.webView.reload() }
            } label: { Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise") }

            TextField("Pretraži ili upiši adresu", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { tab.load(text); focused = false }
                .onAppear { text = tab.address }
                .onChange(of: tab.address) { if !focused { text = tab.address } }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.domNavy)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Tab strip

struct TabChip: View {
    @ObservedObject var tab: BrowserTab
    let isSelected: Bool
    let select: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(tab.title).lineLimit(1).frame(maxWidth: 150, alignment: .leading)
                .foregroundStyle(isSelected ? Color.domNavy : Color.primary)
            Button(action: close) { Image(systemName: "xmark").font(.system(size: 9)) }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(isSelected ? Color.domNavy.opacity(0.12) : Color.domSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.domNavy.opacity(0.55) : Color.domBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }
}

struct TabStrip: View {
    @ObservedObject var browser: Browser
    var atMax: Bool { browser.tabs.count >= MAX_TABS }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(browser.tabs) { tab in
                TabChip(tab: tab,
                        isSelected: tab.id == browser.selectedID,
                        select: { browser.selectedID = tab.id },
                        close: { browser.close(tab) })
            }
            Button { browser.newTab() } label: { Image(systemName: "plus") }
                .buttonStyle(.borderless)
                .foregroundStyle(atMax ? Color.secondary : Color.domRed)
                .disabled(atMax)
                .help(atMax ? "Maksimalno \(MAX_TABS) tabova" : "Novi tab")
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}

// MARK: - Glavni prikaz

struct ContentView: View {
    @ObservedObject var browser: Browser

    var body: some View {
        VStack(spacing: 0) {
            BrandStripe()
            if let tab = browser.selected {
                VStack(spacing: 0) {
                    Toolbar(tab: tab).id(tab.id)
                    TabStrip(browser: browser)
                }
                .background(Color.white)
                Divider().overlay(Color.domBorder)
                WebViewHost(webView: tab.webView).id(tab.id)
            }
        }
        .tint(.domNavy)
        .preferredColorScheme(.light) // Light DOMOVINA tema — čist kontrast bez obzira na sistemski dark mode
    }
}

// MARK: - App

@main
struct DomovinaBrowserApp: App {
    @StateObject private var browser = Browser()

    var body: some Scene {
        WindowGroup("DOMOVINA Browser") {
            ContentView(browser: browser).frame(minWidth: 720, minHeight: 480)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Novi tab") { browser.newTab() }
                    .keyboardShortcut("t").disabled(browser.tabs.count >= MAX_TABS)
                Button("Zatvori tab") { if let t = browser.selected { browser.close(t) } }
                    .keyboardShortcut("w")
                Button("Osvježi") { browser.selected?.webView.reload() }
                    .keyboardShortcut("r")
            }
        }
    }
}
