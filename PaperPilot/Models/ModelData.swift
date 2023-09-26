//
//  ModelData.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation

class ModelData: ObservableObject {
    static var paper1 = Paper(id: 1, name: "paper1", doi: "12.45678", authors: ["Haibo Chen", "et al."], year: 2021, source: "OSDI", file: Bundle.main.url(forResource: "frames", withExtension: ".pdf"))
    static var paper2 = Paper(id: 2, name: "paper2", authors: ["et al."], tags: ["HPC"], year: 2020, source: "OSDI", file: nil, read: true)
    static var paper3 = Paper(id: 3, name: "paper3", authors: [], year: nil, source: nil, file: nil)
    static var project1 = Project(id: 1, name: "test", papers: [paper1, paper2, paper3])
    static var project2 = Project(id: 2, name: "test2", papers: [paper2, paper3])
    
    @Published var projects = [project1, project2]
}
