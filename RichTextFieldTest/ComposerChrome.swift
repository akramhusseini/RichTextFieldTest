import AVFoundation
import RichTextKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum ComposerPalette {
    static let purple = Color(red: 0.44, green: 0.28, blue: 0.86)
    static let fieldBackground = Color(.secondarySystemBackground)
    static let border = Color(.separator).opacity(0.45)
}

struct ComposerSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ComposerPalette.purple)
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ComposerPalette.border)
        }
    }
}

struct ComposerTextField: View {
    let title: String
    @Binding var text: String
    let direction: ComposerDirection

    var body: some View {
        VStack(alignment: direction.horizontalAlignment, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            TextField("", text: $text)
                .multilineTextAlignment(direction.textAlignment == .right ? .trailing : .leading)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ComposerPalette.border)
                }
        }
    }
}

struct AnnouncementTypeChips: View {
    let direction: ComposerDirection

    private var types: [String] {
        switch direction {
        case .leftToRight: return ["Academic", "General", "Urgent"]
        case .rightToLeft: return ["أكاديمي", "عام", "عاجل"]
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(types, id: \.self) { type in
                Text(type)
                    .font(.subheadline.weight(type == types[0] ? .semibold : .regular))
                    .foregroundStyle(type == types[0] ? ComposerPalette.purple : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(type == types[0] ? ComposerPalette.purple.opacity(0.12) : Color(.systemBackground))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(type == types[0] ? ComposerPalette.purple : ComposerPalette.border)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: direction.textAlignment == .right ? .trailing : .leading)
    }
}

struct RichTextDiagnosticsPanel: View {
    let text: NSAttributedString

    var body: some View {
        ComposerSection("Rich text diagnostics") {
            VStack(spacing: 10) {
                ForEach(AnnouncementSample.metrics(for: text)) { metric in
                    HStack {
                        Text(metric.title)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(metric.value)
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                }
            }
        }
    }
}

struct RichTextPreviewCard: View {
    let title: String
    let text: NSAttributedString
    let direction: ComposerDirection

    var body: some View {
        ComposerSection(title) {
            RichTextViewer(text)
                .frame(minHeight: 120, maxHeight: 180)
                .environment(\.layoutDirection, direction.layoutDirection)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ComposerPalette.border)
                }
        }
    }
}

struct PrimaryActionButton: View {
    let title: String

    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(ComposerPalette.purple)
    }
}

struct DesignRichTextToolbar: View {
    @ObservedObject private var context: RichTextContext

    @State private var isFormatSheetPresented = false
    @State private var mediaKind: ComposerMediaKind?
    @State private var mediaPickerRequest: ComposerMediaPickerRequest?

    init(context: RichTextContext) {
        self._context = ObservedObject(wrappedValue: context)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 13) {
                colorMenu

                toolbarButton("Underline") {
                    context.toggleStyle(.underlined)
                } label: {
                    Text("A")
                        .font(.system(size: 22, weight: .regular))
                        .underline()
                }

                toolbarButton("Insert video") {
                    mediaKind = .video
                } label: {
                    Image(systemName: "video")
                }

                toolbarButton("Insert image") {
                    mediaKind = .image
                } label: {
                    Image(systemName: "photo")
                }

                toolbarButton("Bullet list") {
                    applyList(.bullet)
                } label: {
                    Image(systemName: "list.bullet")
                }

                toolbarButton("Numbered list") {
                    applyList(.numbered)
                } label: {
                    Image(systemName: "list.number")
                }

                toolbarButton("Checklist") {
                    applyList(.checklist)
                } label: {
                    Image(systemName: "checklist")
                }

                toolbarButton("Align left") {
                    context.trigger(.setAlignment(.left))
                } label: {
                    Image(systemName: "text.alignleft")
                }

                toolbarButton("Align center") {
                    context.trigger(.setAlignment(.center))
                } label: {
                    Image(systemName: "text.aligncenter")
                }

                toolbarButton("Align right") {
                    context.trigger(.setAlignment(.right))
                } label: {
                    Image(systemName: "text.alignright")
                }

                toolbarButton("Justify") {
                    context.trigger(.setAlignment(.justified))
                } label: {
                    Image(systemName: "text.justify")
                }
            }
            .padding(.horizontal, 12)
        }
        .scrollIndicators(.hidden)
        .frame(height: 54)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(ComposerPalette.border)
        }
        .shadow(color: .black.opacity(0.14), radius: 5, x: 0, y: 3)
        .sheet(isPresented: $isFormatSheetPresented) {
            RichTextFormat.Sheet(context: context)
                .richTextFormatSheetConfig(.init(
                    colorPickers: [.foreground, .background],
                    fontPicker: true,
                    fontSizePicker: true,
                    indentButtons: true,
                    styles: .all
                ))
        }
        .confirmationDialog(
            mediaKind?.sourceTitle ?? "",
            isPresented: mediaSourceDialogBinding,
            titleVisibility: .visible
        ) {
            if let mediaKind {
                Button(mediaKind.libraryTitle) {
                    presentMediaPicker(for: mediaKind, sourceType: .photoLibrary)
                }

                if mediaKind.isAvailable(from: .camera) {
                    Button(mediaKind.cameraTitle) {
                        presentMediaPicker(for: mediaKind, sourceType: .camera)
                    }
                }
            }

            Button("Cancel", role: .cancel) {
                mediaKind = nil
            }
        }
        .sheet(item: $mediaPickerRequest) { request in
            ComposerMediaPicker(request: request) { media in
                insertMedia(media)
            }
        }
    }
}

struct DesignKeyboardRichTextToolbar: View {
    @ObservedObject private var context: RichTextContext

    init(context: RichTextContext) {
        self._context = ObservedObject(wrappedValue: context)
    }

    var body: some View {
        Group {
            if context.isEditingText {
                DesignRichTextToolbar(context: context)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: context.isEditingText)
    }
}

private extension DesignRichTextToolbar {
    var mediaSourceDialogBinding: Binding<Bool> {
        Binding {
            mediaKind != nil
        } set: { isPresented in
            if !isPresented {
                mediaKind = nil
            }
        }
    }

    var colorMenu: some View {
        Menu {
            Button("Purple text") {
                context.setColor(.foreground, to: .systemPurple)
            }

            Button("Blue text") {
                context.setColor(.foreground, to: .systemBlue)
            }

            Button("Yellow highlight") {
                context.setColor(.background, to: UIColor.systemYellow.withAlphaComponent(0.35))
            }

            Button("More formatting") {
                isFormatSheetPresented = true
            }
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(ComposerPalette.purple)
                    .frame(width: 23, height: 23)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.secondary)
            .frame(height: 38)
        }
        .accessibilityLabel("Color and format")
    }

    func presentMediaPicker(
        for kind: ComposerMediaKind,
        sourceType: UIImagePickerController.SourceType
    ) {
        mediaKind = nil
        mediaPickerRequest = ComposerMediaPickerRequest(kind: kind, sourceType: sourceType)
    }

    func toolbarButton<Label: View>(
        _ accessibilityLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button(action: action) {
            label()
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.secondary)
                .frame(width: 28, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    func insertText(_ text: String) {
        let safeIndex = insertionIndex
        context.trigger(.pasteText(.text(text, at: safeIndex, moveCursor: true)))
    }

    func insertImage(_ image: UIImage) {
        context.trigger(.pasteImage(.image(image, at: insertionIndex, moveCursor: true)))
    }

    func insertMedia(_ media: ComposerPickedMedia) {
        switch media {
        case .image(let image):
            insertImage(image)
        case .video(let video):
            insertVideo(video)
        }
    }

    func insertVideo(_ video: ComposerPickedVideo) {
        guard let previewData = Self.videoThumbnail(
            preview: video.thumbnail,
            title: video.fileName,
            duration: video.durationText
        ).jpegData(compressionQuality: 0.86) else { return }

        let attachment = RichTextImageAttachment(jpegData: previewData)
        attachment.bounds = CGRect(x: 0, y: 0, width: 300, height: 190)

        let insertion = NSMutableAttributedString(attachment: attachment)
        insertion.addAttributes([
            .composerMediaKind: ComposerMediaKind.video.rawValue,
            .composerVideoDataBase64: video.data.base64EncodedString(),
            .composerVideoMimeType: video.mimeType
        ], range: NSRange(location: 0, length: insertion.length))
        insertion.append(NSAttributedString(string: "\n"))

        insertAttributedString(insertion)
    }

    func insertAttributedString(_ text: NSAttributedString) {
        let safeIndex = insertionIndex
        let selectedLength = min(context.selectedRange.length, max(context.attributedString.length - safeIndex, 0))
        let range = NSRange(location: safeIndex, length: selectedLength)
        context.trigger(.replaceText(in: range, with: text))
        context.trigger(.selectRange(NSRange(location: safeIndex + text.length, length: 0)))
    }

    func applyList(_ kind: ComposerListKind) {
        guard let edit = ComposerListFormatter.listEdit(
            for: context.attributedString,
            selectedRange: context.selectedRange,
            kind: kind
        ) else { return }

        context.trigger(.replaceText(in: edit.range, with: edit.replacement))
        context.trigger(.selectRange(NSRange(location: edit.cursorLocation, length: 0)))
    }

    var insertionIndex: Int {
        min(max(context.selectedRange.location, 0), context.attributedString.length)
    }

    static func sampleImage() -> UIImage {
        mediaThumbnail(
            background: UIColor(red: 0.36, green: 0.57, blue: 0.95, alpha: 1),
            symbol: "photo.fill",
            title: "Image"
        )
    }

    static func videoThumbnail(
        preview: UIImage? = nil,
        title: String = "Selected video",
        duration: String? = nil
    ) -> UIImage {
        let size = CGSize(width: 300, height: 190)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cardPath = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1).setFill()
            cardPath.fill()

            let previewRect = CGRect(x: 10, y: 10, width: 280, height: 130)
            context.cgContext.saveGState()
            UIBezierPath(roundedRect: previewRect, cornerRadius: 14).addClip()

            if let preview {
                drawAspectFill(preview, in: previewRect)
            } else {
                let colors = [
                    UIColor(red: 0.31, green: 0.20, blue: 0.68, alpha: 1).cgColor,
                    UIColor(red: 0.09, green: 0.45, blue: 0.56, alpha: 1).cgColor
                ]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                    context.cgContext.drawLinearGradient(
                        gradient,
                        start: CGPoint(x: previewRect.minX, y: previewRect.minY),
                        end: CGPoint(x: previewRect.maxX, y: previewRect.maxY),
                        options: []
                    )
                }

                UIColor.white.withAlphaComponent(0.12).setStroke()
                for offset in stride(from: -120, through: 260, by: 32) {
                    let line = UIBezierPath()
                    line.move(to: CGPoint(x: CGFloat(offset), y: previewRect.maxY))
                    line.addLine(to: CGPoint(x: CGFloat(offset + 120), y: previewRect.minY))
                    line.lineWidth = 2
                    line.stroke()
                }
            }

            context.cgContext.restoreGState()

            UIColor.black.withAlphaComponent(0.28).setFill()
            UIBezierPath(roundedRect: previewRect, cornerRadius: 14).fill()

            UIColor.white.withAlphaComponent(0.92).setFill()
            let playCircle = CGRect(x: 122, y: 46, width: 56, height: 56)
            UIBezierPath(ovalIn: playCircle).fill()

            UIColor(red: 0.32, green: 0.22, blue: 0.72, alpha: 1).setFill()
            let playPath = UIBezierPath()
            playPath.move(to: CGPoint(x: 145, y: 61))
            playPath.addLine(to: CGPoint(x: 145, y: 87))
            playPath.addLine(to: CGPoint(x: 167, y: 74))
            playPath.close()
            playPath.fill()

            let durationRect = CGRect(x: 232, y: 104, width: 46, height: 24)
            UIColor.black.withAlphaComponent(0.58).setFill()
            UIBezierPath(roundedRect: durationRect, cornerRadius: 7).fill()
            let durationAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            (duration ?? "0:00").draw(in: durationRect.insetBy(dx: 9, dy: 5), withAttributes: durationAttributes)

            let badgeRect = CGRect(x: 20, y: 20, width: 58, height: 24)
            UIColor.white.withAlphaComponent(0.18).setFill()
            UIBezierPath(roundedRect: badgeRect, cornerRadius: 7).fill()
            let badgeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.92)
            ]
            "VIDEO".draw(in: badgeRect.insetBy(dx: 9, dy: 5), withAttributes: badgeAttributes)

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineBreakMode = .byTruncatingTail
                    return style
                }()
            ]
            title.draw(in: CGRect(x: 18, y: 148, width: 264, height: 23), withAttributes: titleAttributes)

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.68)
            ]
            "Rich text video attachment".draw(at: CGPoint(x: 18, y: 172), withAttributes: subtitleAttributes)
        }
    }

    static func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        guard image.size.width > 0, image.size.height > 0 else { return }

        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawOrigin = CGPoint(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2
        )
        image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
    }

    static func mediaThumbnail(background: UIColor, symbol: String, title: String) -> UIImage {
        let size = CGSize(width: 260, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            background.setFill()
            path.fill()

            UIColor.white.withAlphaComponent(0.18).setFill()
            UIBezierPath(ovalIn: CGRect(x: 176, y: -26, width: 116, height: 116)).fill()
            UIBezierPath(ovalIn: CGRect(x: -34, y: 88, width: 124, height: 124)).fill()

            let iconConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .semibold)
            let icon = UIImage(systemName: symbol, withConfiguration: iconConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
            icon?.draw(in: CGRect(x: 32, y: 32, width: 58, height: 58))

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.white
            ]
            title.draw(at: CGPoint(x: 104, y: 42), withAttributes: titleAttributes)

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.82)
            ]
            "Rich text attachment".draw(at: CGPoint(x: 104, y: 78), withAttributes: subtitleAttributes)
        }
    }
}

enum ComposerMediaKind: String, Identifiable {
    case image
    case video

    var id: String { rawValue }

    var sourceTitle: String {
        switch self {
        case .image: return "Insert image"
        case .video: return "Insert video"
        }
    }

    var libraryTitle: String {
        switch self {
        case .image: return "Choose Image"
        case .video: return "Choose Video"
        }
    }

    var cameraTitle: String {
        switch self {
        case .image: return "Take Photo"
        case .video: return "Record Video"
        }
    }

    var mediaType: String {
        switch self {
        case .image: return UTType.image.identifier
        case .video: return UTType.movie.identifier
        }
    }

    func isAvailable(from sourceType: UIImagePickerController.SourceType) -> Bool {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return false }
        return UIImagePickerController.availableMediaTypes(for: sourceType)?.contains(mediaType) == true
    }
}

private struct ComposerMediaPickerRequest: Identifiable {
    let id = UUID()
    let kind: ComposerMediaKind
    let sourceType: UIImagePickerController.SourceType
}

private enum ComposerPickedMedia {
    case image(UIImage)
    case video(ComposerPickedVideo)
}

private struct ComposerPickedVideo {
    let data: Data
    let mimeType: String
    let thumbnail: UIImage?
    let durationText: String?
    let fileName: String
}

private struct ComposerMediaPicker: UIViewControllerRepresentable {
    let request: ComposerMediaPickerRequest
    let onPick: (ComposerPickedMedia) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = request.sourceType
        picker.mediaTypes = [request.kind.mediaType]
        picker.allowsEditing = false

        if request.sourceType == .camera, request.kind == .video {
            picker.cameraCaptureMode = .video
            picker.videoMaximumDuration = 30
            picker.videoQuality = .typeMedium
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPick: (ComposerPickedMedia) -> Void
        let dismiss: DismissAction

        init(onPick: @escaping (ComposerPickedMedia) -> Void, dismiss: DismissAction) {
            self.onPick = onPick
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { dismiss() }

            if let image = info[.originalImage] as? UIImage {
                onPick(.image(image))
                return
            }

            guard
                let url = info[.mediaURL] as? URL,
                let data = try? Data(contentsOf: url)
            else { return }

            let asset = AVURLAsset(url: url)
            let video = ComposerPickedVideo(
                data: data,
                mimeType: Self.mimeType(for: url),
                thumbnail: Self.thumbnail(for: asset),
                durationText: Self.durationText(for: asset),
                fileName: Self.fileName(for: url)
            )
            onPick(.video(video))
        }

        private static func fileName(for url: URL) -> String {
            let name = url.deletingPathExtension().lastPathComponent
            return name.isEmpty ? "Selected video" : name
        }

        private static func mimeType(for url: URL) -> String {
            switch url.pathExtension.lowercased() {
            case "m4v":
                return "video/x-m4v"
            case "mov", "qt":
                return "video/quicktime"
            case "mp4":
                return "video/mp4"
            default:
                return "video/mp4"
            }
        }

        private static func thumbnail(for asset: AVAsset) -> UIImage? {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)

            guard let image = try? generator.copyCGImage(at: time, actualTime: nil) else {
                return nil
            }

            return UIImage(cgImage: image)
        }

        private static func durationText(for asset: AVAsset) -> String? {
            let seconds = CMTimeGetSeconds(asset.duration)
            guard seconds.isFinite, seconds >= 0 else { return nil }

            let totalSeconds = Int(seconds.rounded())
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let secondsPart = totalSeconds % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, secondsPart)
            }

            return String(format: "%d:%02d", minutes, secondsPart)
        }
    }
}

extension NSAttributedString.Key {
    static let composerMediaKind = NSAttributedString.Key("ComposerMediaKind")
    static let composerVideoDataBase64 = NSAttributedString.Key("ComposerVideoDataBase64")
    static let composerVideoMimeType = NSAttributedString.Key("ComposerVideoMimeType")
}

enum ComposerListKind {
    case bullet
    case numbered
    case checklist
}

enum ComposerListFormatter {
    struct ListEdit {
        let range: NSRange
        let replacement: NSAttributedString
        let cursorLocation: Int
    }

    enum ReturnChange {
        case insert(text: String, at: Int)
        case replace(range: NSRange, cursorLocation: Int)
    }

    static func listEdit(
        for text: NSAttributedString,
        selectedRange: NSRange,
        kind: ComposerListKind
    ) -> ListEdit? {
        let selectedLinesRange = lineRange(for: selectedRange, in: text.string)
        let replacement = listReplacement(
            for: text,
            in: selectedLinesRange,
            kind: kind
        )

        guard replacement.length > 0 else { return nil }
        return ListEdit(
            range: selectedLinesRange,
            replacement: replacement,
            cursorLocation: selectedLinesRange.location + replacement.length
        )
    }

    static func returnChange(previous: String, current: String) -> ReturnChange? {
        guard let newlineLocation = insertedNewlineLocation(previous: previous, current: current) else {
            return nil
        }

        let nsCurrent = current as NSString
        let previousLine = lineBefore(index: newlineLocation, in: nsCurrent)
        guard let prefix = listPrefix(in: previousLine.text) else { return nil }

        let markerRange = NSRange(
            location: previousLine.start + prefix.markerRange.location,
            length: prefix.markerRange.length
        )

        if prefix.hasContent == false {
            return .replace(
                range: markerRange,
                cursorLocation: newlineLocation + 1 - prefix.markerRange.length
            )
        }

        return .insert(
            text: prefix.nextMarker,
            at: newlineLocation + 1
        )
    }
}

private extension ComposerListFormatter {
    struct ListPrefix {
        let kind: ComposerListKind
        let markerRange: NSRange
        let indent: String
        let number: Int?
        let hasContent: Bool

        var nextMarker: String {
            switch kind {
            case .bullet:
                return "\(indent)• "
            case .checklist:
                return "\(indent)☐ "
            case .numbered:
                return "\(indent)\((number ?? 0) + 1). "
            }
        }
    }

    static func lineRange(for selectedRange: NSRange, in string: String) -> NSRange {
        let nsString = string as NSString
        let length = nsString.length
        guard length > 0 else { return NSRange(location: 0, length: 0) }

        let location = min(max(selectedRange.location, 0), length)
        var rangeLength = min(max(selectedRange.length, 0), length - location)

        if rangeLength > 0, isNewline(nsString.character(at: location + rangeLength - 1)) {
            rangeLength -= 1
        }

        if rangeLength == 0, location == length, isNewline(nsString.character(at: length - 1)) {
            return NSRange(location: length, length: 0)
        }

        return nsString.lineRange(for: NSRange(location: min(location, length - 1), length: rangeLength))
    }

    static func listReplacement(
        for text: NSAttributedString,
        in range: NSRange,
        kind: ComposerListKind
    ) -> NSAttributedString {
        guard text.length > 0 else {
            return NSAttributedString(string: marker(for: kind, index: 1, indent: ""))
        }

        if range.length == 0 {
            let attributes = prefixAttributes(from: text, at: range.location)
            return NSAttributedString(string: marker(for: kind, index: 1, indent: ""), attributes: attributes)
        }

        let result = NSMutableAttributedString()
        let nsString = text.string as NSString
        let end = range.location + range.length
        var location = range.location
        var itemIndex = 1

        while location < end {
            let fullLineRange = nsString.lineRange(for: NSRange(location: min(location, nsString.length - 1), length: 0))
            let clippedLineRange = intersection(fullLineRange, range)
            appendListedLine(
                from: text,
                lineRange: clippedLineRange,
                kind: kind,
                itemIndex: itemIndex,
                to: result
            )
            itemIndex += 1
            location = fullLineRange.location + max(fullLineRange.length, 1)
        }

        return result
    }

    static func appendListedLine(
        from text: NSAttributedString,
        lineRange: NSRange,
        kind: ComposerListKind,
        itemIndex: Int,
        to result: NSMutableAttributedString
    ) {
        guard lineRange.location <= text.length else { return }

        let line = text.attributedSubstring(from: lineRange)
        let lineString = line.string as NSString
        let newlineLength = trailingNewlineLength(in: lineString)
        let bodyLength = max(lineString.length - newlineLength, 0)
        let bodyText = lineString.substring(with: NSRange(location: 0, length: bodyLength))
        let existingPrefix = listPrefix(in: bodyText)
        let indent = existingPrefix?.indent ?? leadingWhitespace(in: bodyText)
        let contentStart = existingPrefix?.markerRange.length ?? (indent as NSString).length
        let contentLength = max(bodyLength - contentStart, 0)
        let attributes = prefixAttributes(from: text, at: lineRange.location + min(contentStart, max(bodyLength - 1, 0)))

        result.append(NSAttributedString(
            string: marker(for: kind, index: itemIndex, indent: indent),
            attributes: attributes
        ))

        if contentLength > 0 {
            result.append(line.attributedSubstring(from: NSRange(location: contentStart, length: contentLength)))
        }

        if newlineLength > 0 {
            result.append(line.attributedSubstring(from: NSRange(location: bodyLength, length: newlineLength)))
        }
    }

    static func lineBefore(index: Int, in string: NSString) -> (start: Int, text: String) {
        let safeIndex = min(max(index, 0), string.length)
        let searchRange = NSRange(location: 0, length: safeIndex)
        let previousBreak = string.range(of: "\n", options: .backwards, range: searchRange)
        let start = previousBreak.location == NSNotFound ? 0 : previousBreak.location + previousBreak.length
        let length = max(safeIndex - start, 0)
        return (start, string.substring(with: NSRange(location: start, length: length)))
    }

    static func insertedNewlineLocation(previous: String, current: String) -> Int? {
        let old = previous as NSString
        let new = current as NSString

        guard new.length == old.length + 1 else { return nil }

        var location = 0
        while location < old.length, old.character(at: location) == new.character(at: location) {
            location += 1
        }

        guard new.character(at: location) == 10 else { return nil }

        let oldTail = old.substring(from: location)
        let newTail = new.substring(from: location + 1)
        guard oldTail == newTail else { return nil }

        return location
    }

    static func listPrefix(in line: String) -> ListPrefix? {
        if let checklist = match(pattern: #"^(\s*)([☐☑])\s+"#, in: line) {
            return ListPrefix(
                kind: .checklist,
                markerRange: checklist.match.range(at: 0),
                indent: checklist.group(1),
                number: nil,
                hasContent: hasContent(after: checklist.match.range(at: 0), in: line)
            )
        }

        if let numbered = match(pattern: #"^(\s*)(\d+)([.)])\s+"#, in: line) {
            return ListPrefix(
                kind: .numbered,
                markerRange: numbered.match.range(at: 0),
                indent: numbered.group(1),
                number: Int(numbered.group(2)),
                hasContent: hasContent(after: numbered.match.range(at: 0), in: line)
            )
        }

        if let bullet = match(pattern: #"^(\s*)([•\-*])\s+"#, in: line) {
            return ListPrefix(
                kind: .bullet,
                markerRange: bullet.match.range(at: 0),
                indent: bullet.group(1),
                number: nil,
                hasContent: hasContent(after: bullet.match.range(at: 0), in: line)
            )
        }

        return nil
    }

    static func match(pattern: String, in line: String) -> (match: NSTextCheckingResult, group: (Int) -> String)? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)
        guard let match = regex.firstMatch(in: line, range: fullRange) else { return nil }

        return (match, { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsLine.substring(with: range)
        })
    }

    static func hasContent(after markerRange: NSRange, in line: String) -> Bool {
        let nsLine = line as NSString
        guard markerRange.location + markerRange.length < nsLine.length else { return false }
        let restRange = NSRange(
            location: markerRange.location + markerRange.length,
            length: nsLine.length - markerRange.location - markerRange.length
        )
        return nsLine.substring(with: restRange).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    static func marker(for kind: ComposerListKind, index: Int, indent: String) -> String {
        switch kind {
        case .bullet:
            return "\(indent)• "
        case .numbered:
            return "\(indent)\(index). "
        case .checklist:
            return "\(indent)☐ "
        }
    }

    static func leadingWhitespace(in string: String) -> String {
        let nsString = string as NSString
        var length = 0
        while length < nsString.length {
            let character = nsString.character(at: length)
            guard character == 32 || character == 9 else { break }
            length += 1
        }
        return nsString.substring(with: NSRange(location: 0, length: length))
    }

    static func prefixAttributes(from text: NSAttributedString, at location: Int) -> [NSAttributedString.Key: Any] {
        guard text.length > 0 else { return [:] }
        let safeLocation = min(max(location, 0), text.length - 1)
        var attributes = text.attributes(at: safeLocation, effectiveRange: nil)
        attributes.removeValue(forKey: .attachment)
        return attributes
    }

    static func trailingNewlineLength(in string: NSString) -> Int {
        guard string.length > 0 else { return 0 }
        let last = string.character(at: string.length - 1)
        guard isNewline(last) else { return 0 }

        if string.length >= 2,
           string.character(at: string.length - 2) == 13,
           last == 10 {
            return 2
        }

        return 1
    }

    static func isNewline(_ character: unichar) -> Bool {
        character == 10 || character == 13
    }

    static func intersection(_ lhs: NSRange, _ rhs: NSRange) -> NSRange {
        let lower = max(lhs.location, rhs.location)
        let upper = min(lhs.location + lhs.length, rhs.location + rhs.length)
        return NSRange(location: lower, length: max(upper - lower, 0))
    }
}

extension RichTextImageConfiguration {
    static var composerMedia: Self {
        .init(
            pasteConfiguration: .enabled,
            dropConfiguration: .enabled,
            maxImageSize: (width: .frame, height: .frame)
        )
    }
}
