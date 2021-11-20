//
//  SmallWidgetData.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/11/20.
//

import Foundation

struct SmallWidgetData {
  let category: Category
  let emoji: String
  let title: String
  let description: String
  let deepLink: String
  
  init(category: Category) {
    self.category = category
    
    switch category {
    case .wantToDo:
      self.emoji = "😍"
      self.title = "지금"
      self.description = "뭐 하고 싶어요?"
      
    case .wantToGet:
      self.emoji = "🤩"
      self.title = "생일 선물"
      self.description = "뭐 갖고 싶어요?"
      
    case .wantToGo:
      self.emoji = "😆"
      self.title = "지금"
      self.description = "어디\n가고 싶어요?"
    }
    self.deepLink = "widget://add?category=\(category.rawValue)"
  }
}
