//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import TPPDF
import PencilKit
import PDFKit
import SwiftUI


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
    private func exportHeader() -> some View {
        VStack {
            if exportConfiguration.includingTimestamp {
                HStack {
                    Spacer()

                    Text("EXPORTED_TAG", bundle: .module)
                        + Text(verbatim: ": \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))")
                }
                .font(.caption)
                .padding()
            }
            
            OnboardingTitleView(title: exportConfiguration.consentTitle)
        }
    }
    
    private func exportSignature() -> some View {
        VStack {
            
            
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
                #if !os(macOS)
                .frame(width: signatureSize.width, height: signatureSize.height)
                #else
                .padding(.horizontal, 100)
                #endif
        }
    }
    
    @MainActor
    func renderViewToImage(view: some View) async -> UIImage {
        let renderer = ImageRenderer(content: view)
        
        let uiImage = renderer.uiImage
        return uiImage!
    }
    
    func headerToImage() async -> UIImage {
        let content = exportHeader()
        return await renderViewToImage(view: content)
    }
    
    func signatureToImage() async -> UIImage {
        let content = exportSignature()
        return await renderViewToImage(view: content)
    }
    
    
    
    /// Exports the signed consent form as a `PDFDocument` via the SwiftUI `ImageRenderer`.
    ///
    /// Renders the `PDFDocument` according to the specified ``ConsentDocument/ExportConfiguration``.
    ///
    /// - Returns: The exported consent form in PDF format as a PDFKit `PDFDocument`
    @MainActor
    func export() async -> PDFKit.PDFDocument? {
        let markdown = await asyncMarkdown()
        
        let markdownString = (try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(String(localized: "MARKDOWN_LOADING_ERROR", bundle: .module))
        
        // Create your TPPDF document
        let document = TPPDF.PDFDocument(format: .usLetter)
        
        let header = await headerToImage()
        let signature = await signatureToImage()
        
        document.add(image: PDFImage(image: header))
        document.add(attributedText: NSAttributedString(markdownString))
        document.add(image: PDFImage(image: signature))
                     
        let generator = PDFGenerator(document: document)
        
        let data = try? generator.generateData()
            // Initialize PDFKit.PDFDocument with the generated data
            if let pdfKitDocument = PDFKit.PDFDocument(data: data!) {
                // Now you can use your PDFKit.PDFDocument
                print("PDFKit document created successfully")
                
                return pdfKitDocument
                
            } else {
                return nil
            }

    }
}

