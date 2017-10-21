// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct RGBColor {
  let red : CGFloat
  let green : CGFloat
  let blue : CGFloat
  func cgColor() -> CGColor {
    return CGColor(red: red, green: green, blue: blue, alpha: 1)
  }
}

struct Gradient {
  let locationAndColors: [(CGFloat, RGBColor)]
  let startPoint: CGPoint
  let endPoint: CGPoint
  let options: CGGradientDrawingOptions
}

enum DrawStep {
  case saveGState
  case restoreGState
  case moveTo(CGPoint)
  case curve(CGPoint, CGPoint, CGPoint)
  case line(CGPoint)
  case closePath
  case clip(CGPathFillRule)
  case endPath
  case flatness(CGFloat)
  case nonStrokeColorSpace
  case strokeColorSpace
  case nonStrokeColor(RGBColor)
  case strokeColor(RGBColor)
  case appendRectangle(CGRect)
  case fill(CGPathFillRule)
  case concatCTM(CGAffineTransform)
  case lineWidth(CGFloat)
  case stroke
  case colorRenderingIntent
  case parametersFromGraphicsState
  case paintWithGradient(String)
}

class DrawRoute {
  let boundingRect: CGRect
  let gradients: [String:Gradient]
  private var steps: Array<DrawStep> = [];
  init(boundingRect: CGRect, gradients: [String:Gradient]) {
    self.boundingRect = boundingRect
    self.gradients = gradients
  }
  public func push(step: DrawStep) -> Int {
    steps.append(step)
    return steps.count
  }
  public func getSteps() -> [DrawStep] {
    return steps
  }
}

extension DrawRoute {
  func draw(scale: CGFloat) -> CGImage {
    let ctx = CGContext(data: nil,
                        width: Int(boundingRect.width * scale),
                        height: Int(boundingRect.height * scale),
                        bitsPerComponent: 8,
                        bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: scale, y: scale)
    for step in steps {
      switch step {
      case .saveGState:
        ctx.saveGState()
      case .restoreGState:
        ctx.restoreGState()
      case .moveTo(let p):
        ctx.move(to: p)
      case .curve(let p1, let p2, let p3):
        ctx.addCurve(to: p3, control1: p1, control2: p2)
      case .line(let p):
        ctx.addLine(to: p)
      case .closePath:
        ctx.closePath()
      case .clip(let rule):
        ctx.clip(using: rule)
      case .endPath:
        // FIXME: Decide what to do here
        break
      case .flatness(let flatness):
        ctx.setFlatness(flatness)
      case .nonStrokeColorSpace:
        // FIXME: Color space
        break
      case .nonStrokeColor(let color):
        ctx.setFillColor(color.cgColor())
      case .appendRectangle(let rect):
        ctx.addRect(rect)
      case .fill(let rule):
        ctx.fillPath(using: rule)
      case .strokeColorSpace:
        // FIXME: Color space
        break
      case .strokeColor(let color):
        ctx.setStrokeColor(color.cgColor())
      case .concatCTM(let transform):
        ctx.concatenate(transform)
      case .lineWidth(let w):
        ctx.setLineWidth(w)
      case .stroke:
        ctx.strokePath()
      case .colorRenderingIntent:
        break
      case .parametersFromGraphicsState:
        break
      case .paintWithGradient(let gradientKey):
        let grad = gradients[gradientKey]!
        let locs = grad.locationAndColors.map { $0.0 }
        let color = grad.locationAndColors.map { $0.1.cgColor() }
        let cgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                colors: color as CFArray,
                                locations: locs)!
        ctx.drawLinearGradient(cgGrad,
                               start: grad.startPoint,
                               end: grad.endPoint,
                               options: grad.options)
      }
    }
    return ctx.makeImage()!
  }
}