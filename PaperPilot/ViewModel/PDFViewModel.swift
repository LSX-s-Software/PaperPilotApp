//
//  PDFViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI
import PDFKit

class PDFViewModel: ObservableObject {
    @Published var loading = true
    @Published var pdf: PDFDocument?
    @Published var pdfView = PDFView()
    @Published var currentPage = PDFPage()
}
