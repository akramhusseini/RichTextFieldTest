import Foundation
import SwiftUI
import UIKit

enum ComposerDirection: String, Identifiable {
    case leftToRight
    case rightToLeft

    var id: String { rawValue }

    var layoutDirection: LayoutDirection {
        switch self {
        case .leftToRight: return .leftToRight
        case .rightToLeft: return .rightToLeft
        }
    }

    var textAlignment: NSTextAlignment {
        switch self {
        case .leftToRight: return .left
        case .rightToLeft: return .right
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leftToRight: return .leading
        case .rightToLeft: return .trailing
        }
    }

    var localeIdentifier: String {
        switch self {
        case .leftToRight: return "en"
        case .rightToLeft: return "ar"
        }
    }

    var navigationTitle: String {
        switch self {
        case .leftToRight: return "Create Announcement"
        case .rightToLeft: return "إنشاء إعلان"
        }
    }

    var sampleTitle: String {
        switch self {
        case .leftToRight: return "Final exam schedule"
        case .rightToLeft: return "جدول الامتحانات النهائية"
        }
    }

    var contentLabel: String {
        switch self {
        case .leftToRight: return "Announcement content"
        case .rightToLeft: return "محتوى الإعلان"
        }
    }
}

struct RichTextMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

enum AnnouncementSample {
    static func richText(for direction: ComposerDirection) -> NSAttributedString {
        let text: String

        switch direction {
        case .leftToRight:
            text = """
            Dear teachers,

            The final exam schedule for the third semester has been approved and uploaded.
            Please review the attached file before the end of the day.
            Share the relevant details with your students before Sunday.

            Important: Grade 10, Section A and Section B must receive the updated room assignments.
            """
        case .rightToLeft:
            text = """
            أعزائي المعلمين،

            تم اعتماد جدول الامتحانات النهائية للفصل الدراسي الثالث وهو متاح الآن.
            يرجى مراجعة توزيع الغرف قبل نهاية اليوم.
            إبلاغ الطلبة بالتفاصيل المطلوبة قبل يوم الأحد.

            مهم: الصف العاشر شعبة أ وشعبة ب لديهم تحديث في قاعات الامتحان.
            """
        }

        let attributed = NSMutableAttributedString(
            string: text,
            attributes: baseAttributes(for: direction)
        )

        switch direction {
        case .leftToRight:
            addTraits([.traitBold], to: "Dear teachers", in: attributed)
            addTraits([.traitBold], to: "Important", in: attributed)
            addUnderline(to: "updated room assignments", in: attributed)
            addColor(.systemIndigo, to: "Grade 10, Section A and Section B", in: attributed)
        case .rightToLeft:
            addTraits([.traitBold], to: "أعزائي المعلمين", in: attributed)
            addTraits([.traitBold], to: "مهم", in: attributed)
            addUnderline(to: "تحديث في قاعات الامتحان", in: attributed)
            addColor(.systemIndigo, to: "الصف العاشر شعبة أ وشعبة ب", in: attributed)
        }

        return attributed
    }

    static func emptyText(for direction: ComposerDirection) -> NSAttributedString {
        NSAttributedString(string: "", attributes: baseAttributes(for: direction))
    }

    static func metrics(for text: NSAttributedString) -> [RichTextMetric] {
        let range = NSRange(location: 0, length: text.length)
        var boldCharacters = 0
        var italicCharacters = 0
        var underlinedCharacters = 0
        var strikethroughCharacters = 0
        var attachments = 0

        text.enumerateAttributes(in: range) { attributes, range, _ in
            if let font = attributes[.font] as? UIFont {
                let traits = font.fontDescriptor.symbolicTraits
                if traits.contains(.traitBold) {
                    boldCharacters += range.length
                }
                if traits.contains(.traitItalic) {
                    italicCharacters += range.length
                }
            }

            if let underline = attributes[.underlineStyle] as? Int, underline != 0 {
                underlinedCharacters += range.length
            }

            if let strike = attributes[.strikethroughStyle] as? Int, strike != 0 {
                strikethroughCharacters += range.length
            }

            if attributes[.attachment] != nil {
                attachments += 1
            }
        }

        return [
            RichTextMetric(title: "Characters", value: "\(text.string.count)"),
            RichTextMetric(title: "Attachments", value: "\(attachments)"),
            RichTextMetric(title: "Bold range", value: "\(boldCharacters) chars"),
            RichTextMetric(title: "Italic range", value: "\(italicCharacters) chars"),
            RichTextMetric(title: "Underline range", value: "\(underlinedCharacters) chars"),
            RichTextMetric(title: "Strike range", value: "\(strikethroughCharacters) chars"),
            RichTextMetric(title: "RTF payload", value: rtfByteCount(for: text))
        ]
    }
}

private extension AnnouncementSample {
    static func baseAttributes(for direction: ComposerDirection) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = direction.textAlignment
        paragraph.lineSpacing = 5
        paragraph.paragraphSpacing = 8

        return [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]
    }

    static func addTraits(
        _ traits: UIFontDescriptor.SymbolicTraits,
        to phrase: String,
        in text: NSMutableAttributedString
    ) {
        let range = (text.string as NSString).range(of: phrase)
        guard range.location != NSNotFound else { return }
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) ?? baseFont.fontDescriptor
        text.addAttribute(.font, value: UIFont(descriptor: descriptor, size: baseFont.pointSize), range: range)
    }

    static func addUnderline(to phrase: String, in text: NSMutableAttributedString) {
        let range = (text.string as NSString).range(of: phrase)
        guard range.location != NSNotFound else { return }
        text.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    }

    static func addColor(_ color: UIColor, to phrase: String, in text: NSMutableAttributedString) {
        let range = (text.string as NSString).range(of: phrase)
        guard range.location != NSNotFound else { return }
        text.addAttribute(.foregroundColor, value: color, range: range)
    }

    static func rtfByteCount(for text: NSAttributedString) -> String {
        let range = NSRange(location: 0, length: text.length)
        guard let data = try? text.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            return "Unavailable"
        }
        return "\(data.count) bytes"
    }
}
