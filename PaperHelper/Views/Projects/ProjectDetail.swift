//
//  ProjectDetail.swift
//  PaperHelper
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ProjectDetail: View {
    var projectName: String
    
    var body: some View {
        Text(projectName)
    }
}

#Preview {
    ProjectDetail(projectName: "项目名称")
}
