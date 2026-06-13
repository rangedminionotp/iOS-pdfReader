import Foundation
import PDFKit

enum PDFReadingDocumentBuilder {
    nonisolated static func build(from documentData: Data) async -> PDFReadingDocument {
        await Task.detached(priority: .utility) {
            guard let document = PDFDocument(data: documentData) else {
                return .empty
            }

            let pages = (0..<document.pageCount).compactMap { index -> PDFReadingPage? in
                guard let page = document.page(at: index) else {
                    return nil
                }

                let blocks = makeBlocks(from: page.string ?? "")
                return PDFReadingPage(number: index + 1, blocks: blocks)
            }

            return PDFReadingDocument(pages: pages)
        }.value
    }

    nonisolated private static func makeBlocks(from rawPageText: String) -> [PDFReadingBlock] {
        let segments = splitIntoSegments(rawPageText)

        return segments.compactMap { lines in
            guard !lines.isEmpty else {
                return nil
            }

            if let note = makeNoteBlock(from: lines) {
                return note
            }

            if let list = makeListBlock(from: lines) {
                return list
            }

            if let heading = makeHeadingBlock(from: lines) {
                return heading
            }

            let paragraph = joinParagraphLines(lines)
            guard !paragraph.isEmpty else {
                return nil
            }

            return PDFReadingBlock(kind: .paragraph(paragraph))
        }
    }

    nonisolated private static func splitIntoSegments(_ text: String) -> [[String]] {
        var segments: [[String]] = []
        var current: [String] = []

        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        for rawLine in normalizedText.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                if !current.isEmpty {
                    segments.append(current)
                    current = []
                }
            } else {
                current.append(collapseWhitespace(in: trimmed))
            }
        }

        if !current.isEmpty {
            segments.append(current)
        }

        return segments
    }

    nonisolated private static func makeNoteBlock(from lines: [String]) -> PDFReadingBlock? {
        guard lines.count <= 2 else {
            return nil
        }

        let combined = lines.joined(separator: " ")
        let lowercased = combined.lowercased()

        guard lowercased.hasPrefix("note:")
            || lowercased.hasPrefix("important:")
            || lowercased.hasPrefix("warning:")
        else {
            return nil
        }

        return PDFReadingBlock(kind: .note(combined))
    }

    nonisolated private static func makeListBlock(from lines: [String]) -> PDFReadingBlock? {
        let bulletItems = lines.compactMap(strippedBulletText(from:))
        if bulletItems.count == lines.count {
            return PDFReadingBlock(kind: .list(items: bulletItems, ordered: false))
        }

        let orderedItems = lines.compactMap(strippedOrderedListText(from:))
        if orderedItems.count == lines.count {
            return PDFReadingBlock(kind: .list(items: orderedItems, ordered: true))
        }

        return nil
    }

    nonisolated private static func makeHeadingBlock(from lines: [String]) -> PDFReadingBlock? {
        guard lines.count <= 2 else {
            return nil
        }

        let combined = lines.joined(separator: " ")
        guard combined.count <= 90 else {
            return nil
        }

        let lastCharacter = combined.last
        if lastCharacter == "." || lastCharacter == "," || lastCharacter == ";" {
            return nil
        }

        let words = combined.split(separator: " ")
        guard !words.isEmpty else {
            return nil
        }

        let letters = combined.filter(\.isLetter)
        let uppercaseLetters = letters.filter(\.isUppercase).count
        let uppercaseRatio = letters.isEmpty ? 0 : Double(uppercaseLetters) / Double(letters.count)

        let shortHeading = words.count <= 8
        let likelyHeading = uppercaseRatio > 0.72
            || (shortHeading && !combined.contains("."))
            || combined == combined.capitalized

        guard likelyHeading else {
            return nil
        }

        let level = uppercaseRatio > 0.72 ? 1 : 2
        return PDFReadingBlock(kind: .heading(text: combined, level: level))
    }

    nonisolated private static func joinParagraphLines(_ lines: [String]) -> String {
        guard var paragraph = lines.first else {
            return ""
        }

        for line in lines.dropFirst() {
            if paragraph.hasSuffix("-"),
               let firstCharacter = line.first,
               firstCharacter.isLowercase {
                paragraph.removeLast()
                paragraph += line
            } else {
                paragraph += " " + line
            }
        }

        return collapseWhitespace(in: paragraph)
    }

    nonisolated private static func strippedBulletText(from line: String) -> String? {
        let bulletPrefixes = ["• ", "- ", "* ", "◦ "]

        for prefix in bulletPrefixes where line.hasPrefix(prefix) {
            let stripped = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return stripped.isEmpty ? nil : stripped
        }

        return nil
    }

    nonisolated private static func strippedOrderedListText(from line: String) -> String? {
        var digits = ""
        var index = line.startIndex

        while index < line.endIndex, line[index].isNumber {
            digits.append(line[index])
            index = line.index(after: index)
        }

        guard !digits.isEmpty, index < line.endIndex else {
            return nil
        }

        let marker = line[index]
        guard marker == "." || marker == ")" else {
            return nil
        }

        index = line.index(after: index)

        if index < line.endIndex, line[index] == " " {
            index = line.index(after: index)
        }

        let stripped = line[index...].trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.isEmpty ? nil : stripped
    }

    nonisolated private static func collapseWhitespace(in text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
