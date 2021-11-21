//
//  SmallWidgetData.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/11/20.
//

import Foundation

struct SmallRemainWidgetData {
  let category: Category
  let title: String
  let description: String
  let deepLink: String
  
  init(category: Category, count: Int) {
    self.category = category
    
    switch category {
    case .wantToDo:
      self.title = "하고 싶은 것들이"
      self.description = String(format: "%02d개", count)
      
    case .wantToGet:
      self.title = "갖고 싶은 것들이"
      self.description = String(format: "%02d개", count)
      
    case .wantToGo:
      self.title = "가고 싶은 곳들이"
      self.description = String(format: "%02d곳", count)
    }
    self.deepLink = "widget://home"
  }
}
