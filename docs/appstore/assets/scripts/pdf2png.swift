import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
let a=CommandLine.arguments; let px=CGFloat(Double(a[3])!)
guard let doc=CGPDFDocument(URL(fileURLWithPath:a[1]) as CFURL), let page=doc.page(at:1) else { exit(1) }
let box=page.getBoxRect(.mediaBox); let s=px/box.width
let ctx=CGContext(data:nil,width:Int(px),height:Int(box.height*s),bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .high; ctx.scaleBy(x:s,y:s); ctx.drawPDFPage(page)
let d=CGImageDestinationCreateWithURL(URL(fileURLWithPath:a[2]) as CFURL,UTType.png.identifier as CFString,1,nil)!
CGImageDestinationAddImage(d,ctx.makeImage()!,nil); CGImageDestinationFinalize(d)
