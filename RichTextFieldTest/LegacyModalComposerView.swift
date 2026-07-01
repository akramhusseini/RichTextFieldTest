import RichTextKit
import SwiftUI
import UIKit
import WebKit

struct LegacyModalComposerView: View {
    let direction: ComposerDirection

    @State private var title: String
    @State private var richText: NSAttributedString
    @State private var savedHTML: String
    @State private var isEditorPresented = false

    init(direction: ComposerDirection) {
        let initialText = AnnouncementSample.richText(for: direction)
        self.direction = direction
        _title = State(initialValue: direction.sampleTitle)
        _richText = State(initialValue: initialText)
        _savedHTML = State(initialValue: RichTextHTMLConverter.html(from: initialText, direction: direction))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: direction.horizontalAlignment, spacing: 16) {
                ComposerSection(direction == .rightToLeft ? "المعلومات الأساسية" : "Basic information") {
                    ComposerTextField(
                        title: direction == .rightToLeft ? "عنوان الإعلان" : "Announcement title",
                        text: $title,
                        direction: direction
                    )

                    AnnouncementTypeChips(direction: direction)

                    AnnouncementContentPreviewField(
                        html: savedHTML,
                        direction: direction
                    ) {
                        isEditorPresented = true
                    }
                }

                PrimaryActionButton(title: direction == .rightToLeft ? "إنشاء إعلان" : "Create Announcement")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(direction.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, direction.layoutDirection)
        .environment(\.locale, Locale(identifier: direction.localeIdentifier))
        .sheet(isPresented: $isEditorPresented) {
            LegacyRichTextSheet(text: richText, direction: direction) { savedText in
                richText = savedText
                savedHTML = RichTextHTMLConverter.html(from: savedText, direction: direction)
            }
        }
    }
}

private struct LegacyRichTextSheet: View {
    let direction: ComposerDirection
    let onSave: (NSAttributedString) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftText: NSAttributedString
    @StateObject private var context = RichTextContext()
    @State private var previousDraftString = ""
    @State private var isApplyingListContinuation = false

    init(
        text: NSAttributedString,
        direction: ComposerDirection,
        onSave: @escaping (NSAttributedString) -> Void
    ) {
        self.direction = direction
        self.onSave = onSave
        _draftText = State(initialValue: text)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.7))
                .frame(width: 42, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    onSave(draftText)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text(direction == .rightToLeft ? "حفظ" : "Save")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .foregroundStyle(.white)
                    .background(ComposerPalette.purple)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            VStack(alignment: direction.horizontalAlignment, spacing: 10) {
                Text(direction.contentLabel)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: direction.textAlignment == .right ? .trailing : .leading)

                RichTextEditor(text: $draftText, context: context) { view in
                    view.textContentInset = CGSize(width: 14, height: 14)
                    view.imageConfiguration = .composerMedia
                }
                .frame(minHeight: 230)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ComposerPalette.border)
                }

                Text(direction == .rightToLeft ? "حدد النص ثم استخدم شريط التنسيق." : "Select text, then use the formatting toolbar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 0)
        }
        .background(Color(.systemGroupedBackground))
        .environment(\.layoutDirection, direction.layoutDirection)
        .environment(\.locale, Locale(identifier: direction.localeIdentifier))
        .focusedValue(\.richTextContext, context)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DesignKeyboardRichTextToolbar(context: context)
        }
        .onAppear {
            previousDraftString = draftText.string
        }
        .onChange(of: draftText.string) { newString in
            handleDraftStringChange(newString)
        }
        .richTextFormatSheetConfig(.init(
            colorPickers: [.foreground, .background],
            fontPicker: true,
            fontSizePicker: true,
            indentButtons: true,
            styles: .all
        ))
        .presentationDetents([.large])
    }

    private func handleDraftStringChange(_ newString: String) {
        if isApplyingListContinuation {
            previousDraftString = newString
            return
        }

        guard let change = ComposerListFormatter.returnChange(
            previous: previousDraftString,
            current: newString
        ) else {
            previousDraftString = newString
            return
        }

        previousDraftString = newString
        isApplyingListContinuation = true

        switch change {
        case .insert(let text, let location):
            context.trigger(.pasteText(.text(text, at: location, moveCursor: true)))
        case .replace(let range, let cursorLocation):
            context.trigger(.replaceText(in: range, with: NSAttributedString(string: "")))
            context.trigger(.selectRange(NSRange(location: cursorLocation, length: 0)))
        }

        DispatchQueue.main.async {
            isApplyingListContinuation = false
        }
    }
}

private struct AnnouncementContentPreviewField: View {
    let html: String
    let direction: ComposerDirection
    let action: () -> Void

    var body: some View {
        VStack(alignment: direction.horizontalAlignment, spacing: 8) {
            RequiredFieldLabel(
                title: direction.contentLabel,
                direction: direction
            )

            Button(action: action) {
                HTMLPreviewWebView(html: html)
                    .allowsHitTesting(false)
                    .frame(height: 126)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(ComposerPalette.border)
                    }
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(direction.contentLabel)
        }
    }
}

private struct RequiredFieldLabel: View {
    let title: String
    let direction: ComposerDirection

    var body: some View {
        HStack(spacing: 4) {
            if direction == .rightToLeft {
                Text("*")
                    .foregroundStyle(.red)
                Text(title)
            } else {
                Text(title)
                Text("*")
                    .foregroundStyle(.red)
            }
        }
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, alignment: direction.textAlignment == .right ? .trailing : .leading)
    }
}

private struct HTMLPreviewWebView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        view.scrollView.showsHorizontalScrollIndicator = false
        view.scrollView.showsVerticalScrollIndicator = false
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.html != html else { return }
        context.coordinator.html = html
        view.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator {
        var html = ""
    }
}

private enum RichTextHTMLConverter {
    static func html(from text: NSAttributedString, direction: ComposerDirection) -> String {
        let body = htmlBody(from: text)
        let cssDirection = direction == .rightToLeft ? "rtl" : "ltr"
        let textAlignment = cssTextAlignment(from: text) ?? (direction == .rightToLeft ? "right" : "left")
        let language = direction == .rightToLeft ? "ar" : "en"

        return """
        <!doctype html>
        <html lang="\(language)" dir="\(cssDirection)">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        html, body { margin: 0; padding: 0; background: transparent; }
        body {
            box-sizing: border-box;
            color: #1f2328;
            direction: \(cssDirection);
            font: -apple-system-body;
            line-height: 1.45;
            padding: 14px;
            text-align: \(textAlignment);
            word-wrap: break-word;
        }
        .media-attachment {
            border-radius: 12px;
            display: block;
            height: auto;
            margin: 12px 0;
            max-width: 100%;
        }
        .video-attachment {
            background: #111318;
            width: 100%;
        }
        ol, ul {
            margin: 0 0 8px;
            padding-inline-start: 1.35em;
        }
        li {
            margin: 4px 0;
        }
        ul.checklist {
            list-style: none;
            padding-inline-start: 0;
        }
        ul.checklist li::before {
            content: "☐";
            margin-inline-end: 0.45em;
        }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }

    private static func htmlBody(from text: NSAttributedString) -> String {
        guard text.length > 0 else { return "<br>" }

        var html = ""
        var openListKind: HTMLListKind?

        attributedLines(in: text).forEach { line in
            let lineString = line.string as NSString
            let newlineLength = trailingNewlineLength(in: lineString)
            let bodyLength = max(lineString.length - newlineLength, 0)
            let bodyRange = NSRange(location: 0, length: bodyLength)

            guard bodyLength > 0 else {
                closeListIfNeeded(&html, openListKind: &openListKind)
                if newlineLength > 0 {
                    html += "<br>"
                }
                return
            }

            let body = line.attributedSubstring(from: bodyRange)
            if let prefix = listPrefix(in: body.string) {
                if openListKind != prefix.kind {
                    closeListIfNeeded(&html, openListKind: &openListKind)
                    html += prefix.kind.openingTag
                    openListKind = prefix.kind
                }

                let contentRange = NSRange(
                    location: prefix.markerLength,
                    length: max(body.length - prefix.markerLength, 0)
                )
                let item = body.attributedSubstring(from: contentRange)
                let itemHTML = inlineHTML(from: item)
                html += "<li>\(itemHTML.isEmpty ? "<br>" : itemHTML)</li>"
                return
            }

            closeListIfNeeded(&html, openListKind: &openListKind)
            html += inlineHTML(from: body)

            if newlineLength > 0 {
                html += "<br>"
            }
        }

        closeListIfNeeded(&html, openListKind: &openListKind)
        return html.isEmpty ? "<br>" : html
    }

    private static func inlineHTML(from text: NSAttributedString) -> String {
        var html = ""
        let fullRange = NSRange(location: 0, length: text.length)

        text.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment {
                html += attachmentHTML(attachment, attributes: attributes)
                return
            }

            let plainText = text.attributedSubstring(from: range).string
            let escapedText = escape(plainText.replacingOccurrences(of: "\u{fffc}", with: ""))
                .replacingOccurrences(of: "\n", with: "<br>")
            guard !escapedText.isEmpty else { return }

            html += styledSpan(escapedText, attributes: attributes)
        }

        return html
    }

    private enum HTMLListKind: Equatable {
        case ordered
        case unordered
        case checklist

        var openingTag: String {
            switch self {
            case .ordered:
                return "<ol>"
            case .unordered:
                return "<ul>"
            case .checklist:
                return "<ul class=\"checklist\">"
            }
        }

        var closingTag: String {
            switch self {
            case .ordered:
                return "</ol>"
            case .unordered, .checklist:
                return "</ul>"
            }
        }
    }

    private struct HTMLListPrefix {
        let kind: HTMLListKind
        let markerLength: Int
    }

    private static func attributedLines(in text: NSAttributedString) -> [NSAttributedString] {
        let nsString = text.string as NSString
        guard nsString.length > 0 else { return [] }

        var lines: [NSAttributedString] = []
        var location = 0

        while location < nsString.length {
            let range = nsString.lineRange(for: NSRange(location: location, length: 0))
            lines.append(text.attributedSubstring(from: range))
            location = range.location + max(range.length, 1)
        }

        return lines
    }

    private static func closeListIfNeeded(_ html: inout String, openListKind: inout HTMLListKind?) {
        guard let listKind = openListKind else { return }
        html += listKind.closingTag
        openListKind = nil
    }

    private static func listPrefix(in line: String) -> HTMLListPrefix? {
        if let markerLength = markerLength(pattern: #"^\s*[☐☑]\s+"#, in: line) {
            return HTMLListPrefix(kind: .checklist, markerLength: markerLength)
        }

        if let markerLength = markerLength(pattern: #"^\s*\d+[.)]\s+"#, in: line) {
            return HTMLListPrefix(kind: .ordered, markerLength: markerLength)
        }

        if let markerLength = markerLength(pattern: #"^\s*[•\-*]\s+"#, in: line) {
            return HTMLListPrefix(kind: .unordered, markerLength: markerLength)
        }

        return nil
    }

    private static func markerLength(pattern: String, in line: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: (line as NSString).length)
        return regex.firstMatch(in: line, range: range)?.range.length
    }

    private static func trailingNewlineLength(in string: NSString) -> Int {
        guard string.length > 0 else { return 0 }
        let last = string.character(at: string.length - 1)
        guard last == 10 || last == 13 else { return 0 }

        if string.length >= 2,
           string.character(at: string.length - 2) == 13,
           last == 10 {
            return 2
        }

        return 1
    }

    private static func styledSpan(_ content: String, attributes: [NSAttributedString.Key: Any]) -> String {
        var styles: [String] = []

        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
            if traits.contains(.traitBold) {
                styles.append("font-weight: 700")
            }
            if traits.contains(.traitItalic) {
                styles.append("font-style: italic")
            }
            styles.append("font-size: \(Int(font.pointSize.rounded()))px")
        }

        var decorations: [String] = []
        if let underline = attributes[.underlineStyle] as? Int, underline != 0 {
            decorations.append("underline")
        }
        if let strike = attributes[.strikethroughStyle] as? Int, strike != 0 {
            decorations.append("line-through")
        }
        if !decorations.isEmpty {
            styles.append("text-decoration: \(decorations.joined(separator: " "))")
        }

        if let color = attributes[.foregroundColor] as? UIColor, let css = cssColor(color) {
            styles.append("color: \(css)")
        }
        if let color = attributes[.backgroundColor] as? UIColor, let css = cssColor(color) {
            styles.append("background-color: \(css)")
        }

        guard !styles.isEmpty else { return content }
        return "<span style=\"\(styles.joined(separator: "; "))\">\(content)</span>"
    }

    private static func attachmentHTML(
        _ attachment: NSTextAttachment,
        attributes: [NSAttributedString.Key: Any]
    ) -> String {
        if
            attributes[.composerMediaKind] as? String == ComposerMediaKind.video.rawValue,
            let videoData = attributes[.composerVideoDataBase64] as? String
        {
            let mimeType = attributes[.composerVideoMimeType] as? String ?? "video/mp4"
            let poster = attachment.contents.map {
                " poster=\"data:image/jpeg;base64,\($0.base64EncodedString())\""
            } ?? ""
            return """
            <video class="media-attachment video-attachment" controls playsinline\(poster)>
                <source src="data:\(mimeType);base64,\(videoData)" type="\(mimeType)">
            </video>
            """
        }

        guard let imageData = attachment.contents else { return "" }
        let mimeType = attachment.fileType == "public.png" ? "image/png" : "image/jpeg"
        return "<img class=\"media-attachment\" src=\"data:\(mimeType);base64,\(imageData.base64EncodedString())\">"
    }

    private static func cssTextAlignment(from text: NSAttributedString) -> String? {
        var result: String?
        let fullRange = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, _, stop in
            guard let paragraph = value as? NSParagraphStyle else { return }

            switch paragraph.alignment {
            case .left:
                result = "left"
            case .right:
                result = "right"
            case .center:
                result = "center"
            case .justified:
                result = "justify"
            default:
                result = nil
            }

            if result != nil {
                stop.pointee = true
            }
        }
        return result
    }

    private static func cssColor(_ color: UIColor) -> String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return "rgba(\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)), \(alpha))"
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

struct LegacyModalComposerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LegacyModalComposerView(direction: .rightToLeft)
        }
    }
}
