import AppKit
import SwiftUI

/// Manages the report viewer window lifecycle.
///
/// Opens a native NSWindow hosting the SwiftUI `ReportViewerView`,
/// which renders the daily Markdown report inline (no Finder needed).
/// Ensures only one report window is open at a time.
@MainActor
final class ReportWindowController {

    /// Shared singleton instance.
    static let shared = ReportWindowController()

    private var window: NSWindow?

    private init() {}

    /// Shows the report window with the given Markdown content and source file.
    func showReport(markdown: String, fileURL: URL?, title: String) {
        let view = ReportViewerView(markdown: markdown, fileURL: fileURL)
        let hostingController = NSHostingController(rootView: view)

        if let existingWindow = window, existingWindow.isVisible {
            existingWindow.contentViewController = hostingController
            existingWindow.title = title
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = title
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.setContentSize(NSSize(width: 1000, height: 820))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = newWindow
    }
}

/// SwiftUI view that renders the Markdown report inline.
///
/// Renders block by block — headings, blockquotes, tables, lists, paragraphs —
/// using SwiftUI's built-in `AttributedString` Markdown parser for inline
/// formatting (bold, italics, links). Tables and code blocks fall back to
/// a monospace style.
struct ReportViewerView: View {
    let markdown: String
    let fileURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(parseBlocks(markdown).enumerated()), id: \.offset) { _, block in
                        renderBlock(block)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .textSelection(.enabled)
            }
            .background(Color(NSColor.textBackgroundColor))

            Divider()

            HStack {
                if let url = fileURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                    Button {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(markdown, forType: .string)
                    } label: {
                        Label("Copy Markdown", systemImage: "doc.on.doc")
                    }
                }
                Spacer()
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(12)
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Block Parsing

    private enum Block {
        case heading(level: Int, text: String)
        case blockquote(String)
        case horizontalRule
        case table(header: [String], rows: [[String]])
        case listItem(String)
        case paragraph(String)
        case blank
    }

    private func parseBlocks(_ text: String) -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                blocks.append(.blank)
                i += 1
                continue
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }

            // Headings
            if trimmed.hasPrefix("#") {
                var level = 0
                for ch in trimmed {
                    if ch == "#" { level += 1 } else { break }
                }
                let textPart = String(trimmed.dropFirst(level))
                    .trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: min(level, 6), text: textPart))
                i += 1
                continue
            }

            // Blockquote (consume consecutive)
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix(">") {
                        quoteLines.append(
                            String(t.dropFirst()).trimmingCharacters(in: .whitespaces)
                        )
                        i += 1
                    } else {
                        break
                    }
                }
                blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
                continue
            }

            // Table: header row begins with | and next row is separator
            if trimmed.hasPrefix("|") && i + 1 < lines.count {
                let nextTrim = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if nextTrim.hasPrefix("|") && nextTrim.contains("---") {
                    let header = parseTableRow(trimmed)
                    i += 2
                    var rows: [[String]] = []
                    while i < lines.count {
                        let rowTrim = lines[i].trimmingCharacters(in: .whitespaces)
                        if rowTrim.hasPrefix("|") {
                            rows.append(parseTableRow(rowTrim))
                            i += 1
                        } else {
                            break
                        }
                    }
                    blocks.append(.table(header: header, rows: rows))
                    continue
                }
            }

            // List item
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.listItem(String(trimmed.dropFirst(2))))
                i += 1
                continue
            }

            // Plain paragraph (single line; multi-line paragraphs keep separate)
            blocks.append(.paragraph(trimmed))
            i += 1
        }

        return blocks
    }

    private func parseTableRow(_ line: String) -> [String] {
        var trimmed = line
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.components(separatedBy: "|").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(attributed(text))
                .font(headingFont(for: level))
                .fontWeight(.bold)
                .padding(.top, level == 1 ? 4 : 8)

        case .blockquote(let text):
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.6))
                    .frame(width: 3)
                Text(attributed(text))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

        case .horizontalRule:
            Divider().padding(.vertical, 4)

        case .table(let header, let rows):
            tableView(header: header, rows: rows)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(.secondary)
                Text(attributed(text))
            }
            .padding(.leading, 4)

        case .paragraph(let text):
            Text(attributed(text))

        case .blank:
            Spacer().frame(height: 2)
        }
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .system(size: 24, weight: .bold)
        case 2: return .system(size: 20, weight: .bold)
        case 3: return .system(size: 17, weight: .semibold)
        case 4: return .system(size: 15, weight: .semibold)
        default: return .system(size: 14, weight: .semibold)
        }
    }

    private func attributed(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(text)
    }

    @ViewBuilder
    private func tableView(header: [String], rows: [[String]]) -> some View {
        let columnCount = max(header.count, rows.map(\.count).max() ?? 0)
        VStack(alignment: .leading, spacing: 0) {
            tableRow(cells: header, isHeader: true, columnCount: columnCount)
            Divider()
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                tableRow(cells: row, isHeader: false, columnCount: columnCount)
                    .background(idx.isMultiple(of: 2)
                        ? Color.gray.opacity(0.05)
                        : Color.clear)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }

    private func tableRow(
        cells: [String],
        isHeader: Bool,
        columnCount: Int
    ) -> some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(0..<columnCount, id: \.self) { idx in
                let value = idx < cells.count ? cells[idx] : ""
                cellView(value: value, isHeader: isHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                if idx < columnCount - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                }
            }
        }
    }

    /// Renders a table cell. Unicode block-character bars (█/░) are
    /// detected and rendered as a real graphical progress bar.
    @ViewBuilder
    private func cellView(value: String, isHeader: Bool) -> some View {
        if !isHeader, let progress = barProgress(value) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor(progress))
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 12)
        } else {
            Text(attributed(value))
                .font(isHeader ? .system(size: 13, weight: .semibold) : .system(size: 13))
        }
    }

    /// Returns 0...1 progress if the cell is a unicode block bar, else nil.
    private func barProgress(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let allowed: Set<Character> = ["\u{2588}", "\u{2591}"]
        guard trimmed.allSatisfy({ allowed.contains($0) }) else { return nil }
        let total = trimmed.count
        let filled = trimmed.filter { $0 == "\u{2588}" }.count
        return total > 0 ? Double(filled) / Double(total) : 0
    }

    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}
