//
//  PDFViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI
import PDFKit

@Observable class PDFViewModel {
    var loading = true
    var pdf: PDFDocument?
    var pdfView = PDFView()
    var currentPage = PDFPage()
}
