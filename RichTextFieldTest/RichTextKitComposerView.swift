import RichTextKit
import SwiftUI

struct RichTextKitComposerView: View {
    let direction: ComposerDirection

    @State private var title: String
    @State private var richText: NSAttributedString
    @StateObject private var context = RichTextContext()

    init(direction: ComposerDirection) {
        self.direction = direction
        _title = State(initialValue: direction.sampleTitle)
        _richText = State(initialValue: AnnouncementSample.richText(for: direction))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: direction.horizontalAlignment, spacing: 16) {
                    ComposerSection(direction == .rightToLeft ? "المعلومات الأساسية" : "Basic information") {
                        ComposerTextField(
                            title: direction == .rightToLeft ? "عنوان الإعلان" : "Announcement title",
                            text: $title,
                            direction: direction
                        )

                        AnnouncementTypeChips(direction: direction)
                    }

                    ComposerSection(direction.contentLabel) {
                        VStack(spacing: 0) {
                            RichTextEditor(text: $richText, context: context) { view in
                                view.textContentInset = CGSize(width: 14, height: 14)
                                view.imageConfiguration = .composerMedia
                            }
                            .frame(minHeight: 280)
                            .background(Color(.systemBackground))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(ComposerPalette.border)
                        }
                    }

                    RichTextPreviewCard(
                        title: direction == .rightToLeft ? "معاينة المحتوى المنسق" : "Formatted content preview",
                        text: richText,
                        direction: direction
                    )

                    RichTextDiagnosticsPanel(text: richText)

                    PrimaryActionButton(title: direction == .rightToLeft ? "إنشاء إعلان" : "Create Announcement")
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(direction.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, direction.layoutDirection)
        .environment(\.locale, Locale(identifier: direction.localeIdentifier))
        .focusedValue(\.richTextContext, context)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DesignKeyboardRichTextToolbar(context: context)
        }
        .richTextFormatSheetConfig(.init(
            colorPickers: [.foreground, .background],
            fontPicker: true,
            fontSizePicker: true,
            indentButtons: true,
            styles: .all
        ))
    }
}

struct RichTextKitComposerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RichTextKitComposerView(direction: .rightToLeft)
        }
    }
}
