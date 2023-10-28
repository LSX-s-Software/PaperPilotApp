//
//  BookmarkView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/28.
//

import SwiftUI
import PDFKit

struct BookmarkView: View {
    var pdf: PDFDocument
    @Binding var bookmarks: [Bookmark]
    @EnvironmentObject private var pdfVM: PDFViewModel

    var body: some View {
        List(
            bookmarks.sorted(by: { $0.page < $1.page }), id: \.page, selection: Binding {
                pdf.index(for: pdfVM.currentPage)
            } set: {
                pdfVM.pdfView.go(to: pdf.page(at: $0!)!)
            }
        ) { bookmark in
            HStack {
                if let page = pdfVM.pdf!.page(at: bookmark.page) {
                    Image(image: page.thumbnail(of: PlatformSize(width: 180, height: 360).size, for: .trimBox))
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .frame(maxWidth: 60, maxHeight: 120)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    Spacer()
                }
                Text("Page \(bookmark.label ?? String(bookmark.page + 1))")
                    .fontWeight(.medium)
            }
            .tag(bookmark)
        }
    }
}

#Preview {
    BookmarkView(pdf: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!, bookmarks: .constant([]))
        .environmentObject(PDFViewModel())
}
