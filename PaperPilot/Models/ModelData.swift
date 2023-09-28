//
//  ModelData.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation

class ModelData: ObservableObject {
    static var paper1 = Paper(id: 1,
                              title: "A Study of Machine Learning Techniques for Sentiment Analysis",
                              abstract: "In this paper, we explore various machine learning techniques for sentiment analysis, including support vector machines, decision trees, and neural networks.",
                              keywords: ["machine learning", "sentiment analysis", "support vector machines", "decision trees", "neural networks"],
                              authors: ["John Smith", "Jane Doe"],
                              tags: ["machine learning", "sentiment analysis"],
                              publicationYear: "2021",
                              publication: "Journal of Machine Learning Research",
                              volume: "42",
                              issue: "3",
                              pages: "123-135",
                              url: "https://www.jmlr.org/papers/v42/Smith21a.html",
                              doi: "10.5555/123456789",
                              file: Bundle.main.url(forResource: "frames", withExtension: "pdf"))
    static var paper2 = Paper(id: 2,
                             title: "An Introduction to Swift Programming",
                             abstract: nil,
                             keywords: nil,
                             authors: ["John Smith"],
                             tags: ["Swift", "Programming"],
                             publicationYear: "2020",
                             publication: "ACM Transactions on Programming Languages and Systems",
                             volume: nil,
                             issue: nil)
    static var paper3 = Paper(id: 3,
                              title: "A Comprehensive Study of Natural Language Processing Techniques",
                              abstract: "In this paper, we present a comprehensive study of natural language processing techniques, including tokenization, part-of-speech tagging, named entity recognition, and sentiment analysis. We evaluate the performance of these techniques on several benchmark datasets and provide recommendations for future research.",
                              keywords: ["natural language processing", "tokenization", "part-of-speech tagging", "named entity recognition", "sentiment analysis"],
                              authors: ["John Smith", "Jane Doe", "Bob Johnson"],
                              tags: ["natural language processing", "machine learning", "sentiment analysis"],
                              publicationYear: "2022",
                              publication: "IEEE Transactions on Natural Language Processing",
                              volume: "10",
                              issue: "2",
                              file: Bundle.main.url(forResource: "frames", withExtension: "pdf"))
    static var project1 = Project(id: 1, name: "test", papers: [paper1, paper2, paper3])
    static var project2 = Project(id: 2, name: "test2", papers: [paper2, paper3])
    
    @Published var projects = [project1, project2]
}
