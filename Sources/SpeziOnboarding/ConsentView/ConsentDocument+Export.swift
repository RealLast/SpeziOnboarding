//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import PDFKit
import PencilKit
import SwiftUI
import WebKit
/// Extension of `ConsentDocument` enabling the export of the signed consent page.
extension ConsentDocument {
#if !os(macOS)
    /// As the `PKDrawing.image()` function automatically converts the ink color dependent on the used color scheme (light or dark mode),
    /// force the ink used in the `UIImage` of the `PKDrawing` to always be black by adjusting the signature ink according to the color scheme.
    private var blackInkSignatureImage: UIImage {
        var updatedDrawing = PKDrawing()
        
        for stroke in signature.strokes {
            let blackStroke = PKStroke(
                ink: PKInk(stroke.ink.inkType, color: colorScheme == .light ? .black : .white),
                path: stroke.path,
                transform: stroke.transform,
                mask: stroke.mask
            )
            
            updatedDrawing.strokes.append(blackStroke)
        }
        
#if os(iOS)
        let scale = UIScreen.main.scale
#else
        let scale = 3.0 // retina scale is default
#endif
        
        return updatedDrawing.image(
            from: .init(x: 0, y: 0, width: signatureSize.width, height: signatureSize.height),
            scale: scale
        )
    }
#endif
    
    /// Creates a representation of the consent form that is ready to be exported via the SwiftUI `ImageRenderer`.
    ///
    /// - Parameters:
    ///   - markdown: The markdown consent content as an `AttributedString`.
    ///
    /// - Returns: A SwiftUI `View` representation of the consent content and signature.
    ///
    /// - Note: This function avoids the use of asynchronous operations.
    /// Asynchronous tasks are incompatible with SwiftUI's `ImageRenderer`,
    /// which expects all rendering processes to be synchronous.
    
    
    /// Exports the signed consent form as a `PDFDocument` via the SwiftUI `ImageRenderer`.
    ///
    /// Renders the `PDFDocument` according to the specified ``ConsentDocument/ExportConfiguration``.
    ///
    /// - Returns: The exported consent form in PDF format as a PDFKit `PDFDocument`
    @MainActor
    func export() async -> PDFDocument? {
        let markdown = await asyncMarkdown()

        let markdownString = (try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(String(localized: "MARKDOWN_LOADING_ERROR", bundle: .module))

        let pageSize = CGSize(
            width: exportConfiguration.paperSize.dimensions.width,
            height: exportConfiguration.paperSize.dimensions.height
        )

        let pages = paginatedViews(markdown: markdownString)

        print("NumPages: \(pages.count)")
        return await withCheckedContinuation { continuation in
            guard let mutableData = CFDataCreateMutable(kCFAllocatorDefault, 0),
                  let consumer = CGDataConsumer(data: mutableData),
                  let pdf = CGContext(consumer: consumer, mediaBox: nil, nil) else {
                continuation.resume(returning: nil)
                return
            }

            for page in pages {
                pdf.beginPDFPage(nil)
               
                let hostingController = UIHostingController(rootView: page)
                 hostingController.view.frame = CGRect(origin: .zero, size: pageSize)

                 let renderer = UIGraphicsImageRenderer(bounds: hostingController.view.bounds)
                 let image = renderer.image { ctx in
                     hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
                 }

                pdf.saveGState()

                pdf.translateBy(x: 0, y: pageSize.height)
                pdf.scaleBy(x: 1.0, y: -1.0)

                hostingController.view.layer.render(in: pdf)

                pdf.restoreGState()
                 
                
                pdf.endPDFPage()
            }

            pdf.closePDF()
            continuation.resume(returning: PDFDocument(data: mutableData as Data))
        }
    }
    
    private func paginatedViews(markdown: AttributedString) -> [AnyView] 
    {
        var pages = [AnyView]()
        var remainingMarkdown = markdown
        let pageSize = CGSize(width: exportConfiguration.paperSize.dimensions.width, height: exportConfiguration.paperSize.dimensions.height)
        let headerHeight: CGFloat = 150
        let footerHeight: CGFloat = 150

        while !remainingMarkdown.unicodeScalars.isEmpty {
            let (currentPageContent, nextPageContent) = split(markdown: remainingMarkdown, pageSize: pageSize, headerHeight: headerHeight, footerHeight: footerHeight)

            let currentPage: AnyView = AnyView(
                VStack {
                    if pages.isEmpty {  // First page
                        OnboardingTitleView(title: exportConfiguration.consentTitle)
                    }

                    Text(currentPageContent)
                        .padding()

                    Spacer()

                    if nextPageContent.unicodeScalars.isEmpty {  // Last page
                        ZStack(alignment: .bottomLeading) {
                            SignatureViewBackground(name: name, backgroundColor: .clear)

                            #if !os(macOS)
                            Image(uiImage: blackInkSignatureImage)
                            #else
                            Text(signature)
                                .padding(.bottom, 32)
                                .padding(.leading, 46)
                                .font(.custom("Snell Roundhand", size: 24))
                            #endif
                        }
                        .padding(.bottom, footerHeight)
                    }
                }
                .frame(width: pageSize.width, height: pageSize.height)
            )

            pages.append(currentPage)
            remainingMarkdown = nextPageContent
        }

        return pages
    }

    private func split(markdown: AttributedString, pageSize: CGSize, headerHeight: CGFloat, footerHeight: CGFloat) -> (AttributedString, AttributedString) 
    {
        let contentHeight = pageSize.height - headerHeight - footerHeight
        var currentPage = AttributedString()
        var remaining = markdown

        let textStorage = NSTextStorage(attributedString: NSAttributedString(markdown))
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: pageSize.width, height: contentHeight))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        var index = 0
        var accumulatedHeight: CGFloat = 0
        var lastFitRange = NSRange(location: 0, length: 0)

        while index < textStorage.length {
            print("Index \(index) \(textStorage.length)")
            let range = NSRange(location: index, length: textStorage.length - index)
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)

            if usedRect.size.height > contentHeight {
                if lastFitRange.length == 0 {
                    // Handle case where a single line is taller than page height
                    lastFitRange = NSRange(location: index, length: 1)
                    index += 1
                }
                break
            }

            lastFitRange = glyphRange
            index += NSMaxRange(glyphRange)
            accumulatedHeight = usedRect.size.height
        }

        currentPage = AttributedString(textStorage.attributedSubstring(from: lastFitRange))
        remaining = AttributedString(textStorage.attributedSubstring(from: NSRange(location: lastFitRange.length, length: textStorage.length - lastFitRange.length)))

        return (currentPage, remaining)
    }

}
