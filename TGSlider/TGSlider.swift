//
//  TGSlider.swift
//  TGSlider
//
//  Created by Anthony Gorb on 17.04.2020.
//  Copyright © 2020 Anthony Gorb. All rights reserved.
//

import UIKit

protocol TGSliderDelegate: class {
    func startDragging(slider: TGSlider)
    func endDragging(slider: TGSlider)
    func markSlider(slider: TGSlider, dragged to: Float)
}

@IBDesignable
final class TGSlider: UISlider {
    
    weak var delegate: TGSliderDelegate?
    var markPositions: [Float]?
    
    @IBInspectable
    var markWidth : CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var markColor : UIColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var selectedBarColor: UIColor = UIColor.darkGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var unselectedBarColor: UIColor = UIColor.lightGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var handlerImage: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var handlerColor: UIColor = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }
        
    var lineCap: CGLineCap = .round {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var height: CGFloat = 12.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var toolTipView: TooltipView!
    
    var thumbRect: CGRect {
        let rect = trackRect(forBounds: bounds)
        return thumbRect(forBounds: bounds, trackRect: rect, value: value)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        setup()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame);
        setup()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        delegate?.startDragging(slider: self)
        let touchPoint = touch.location(in: self)
        if thumbRect.contains(touchPoint) {
            positionAndUpdatePopupView()
            fadePopupViewInAndOut(fadeIn: true)
        }
        
        return super.beginTracking(touch, with: event)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        positionAndUpdatePopupView()
        
        return super.continueTracking(touch, with: event)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        delegate?.endDragging(slider: self)
        
        super.cancelTracking(with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        delegate?.endDragging(slider: self)
        delegate?.markSlider(slider: self, dragged: value)
        fadePopupViewInAndOut(fadeIn: false)
        
        super.endTracking(touch, with: event)
    }
    
    private func setup() {
        toolTipView = TooltipView(frame: CGRect.zero)
        toolTipView.backgroundColor = UIColor.clear
        self.addSubview(toolTipView)
    }
    
    private func positionAndUpdatePopupView() {
        var tRect = thumbRect
        let size = " €".size(withAttributes: [NSAttributedString.Key.font: toolTipView.font])
        tRect.size.width += size.width + 2
        let popupRect = tRect.offsetBy(dx: -10, dy: -(tRect.size.height * 1.0))
        toolTipView.frame = popupRect.insetBy(dx: -20, dy: -5)
        toolTipView.value = value
        toolTipView.fillColor = selectedBarColor
    }
    
    private func fadePopupViewInAndOut(fadeIn: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            if fadeIn {
                self.toolTipView.alpha = 1.0
            } else {
                self.toolTipView.alpha = 0.0
            }
        })
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let innerRect = rect.insetBy(dx: 1.0, dy: 10.0)
        
        UIGraphicsBeginImageContextWithOptions(innerRect.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            // Selected side
            context.setLineCap(lineCap)
            context.setLineWidth(height)
            context.move(to: CGPoint(x:height/2, y:innerRect.height/2))
            context.addLine(to: CGPoint(x:innerRect.size.width - 10, y:innerRect.height/2))
            context.setStrokeColor(self.selectedBarColor.cgColor)
            context.strokePath()
            
            let selectedSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero)
            
            // Unselected side
            context.setLineCap(lineCap)
            context.setLineWidth(height)
            context.move(to: CGPoint(x: height/2, y: innerRect.height/2))
            context.addLine(to: CGPoint(x: innerRect.size.width - 10,y: innerRect.height/2))
            context.setStrokeColor(self.unselectedBarColor.cgColor)
            context.strokePath()
            
            let unselectedSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero)
            
            // Set strips on selected side
            selectedSide?.draw(at: CGPoint.zero)
            
            if let positions = self.markPositions {
                for i in 0..<positions.count {
                    context.setLineWidth(self.markWidth)
                    let position = CGFloat(positions[i]) * innerRect.size.width / 100.0
                    context.move(to: CGPoint(x:position, y:innerRect.height/2 - (height/2 - 1)))
                    context.addLine(to: CGPoint(x:position, y:innerRect.height/2 + (height/2 - 1)))
                    context.setStrokeColor(self.markColor.cgColor)
                    context.strokePath()
                }
            }
            
            let selectedStripSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero)
            
            // Set trips on unselected side
            unselectedSide?.draw(at: CGPoint.zero)
            if let positions = self.markPositions {
                for i in 0..<positions.count {
                    context.setLineWidth(self.markWidth)
                    let position = CGFloat(positions[i])*innerRect.size.width/100.0
                    context.move(to: CGPoint(x:position,y:innerRect.height/2-(height/2 - 1)))
                    context.addLine(to: CGPoint(x:position,y:innerRect.height/2+(height/2 - 1)))
                    context.setStrokeColor(self.markColor.cgColor)
                    context.strokePath()
                }
            }
            
            let unselectedStripSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero)
            
            context.clear(rect)
            UIGraphicsEndImageContext()
            
            setMinimumTrackImage(selectedStripSide, for: .normal)
            setMaximumTrackImage(unselectedStripSide, for: .normal)
            if handlerImage != nil {
                setThumbImage(handlerImage, for: .normal)
            } else {
                setThumbImage(UIImage(), for: .normal)
                thumbTintColor = handlerColor
            }
        }
    }
    
}

private final class TooltipView: UIView {

    var font: UIFont = UIFont.boldSystemFont(ofSize: 18.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var text: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var value: Float {
        get {
            if let text = text {
                return Float(text) ?? 0
            }
            return 0.0
        }
        set {
            text = String(format: "%.2f",newValue) + " €"
        }
    }
    
    var fillColor = UIColor(white: 0, alpha: 0.8) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var textColor = UIColor(white: 1.0, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        fillColor.setFill()
        
        let roundedRect = CGRect(x:bounds.origin.x, y:bounds.origin.y, width:bounds.size.width, height:bounds.size.height * 0.8)
        let roundedRectPath = UIBezierPath(roundedRect: roundedRect, cornerRadius: 6.0)
        
        // create arrow
        let arrowPath = UIBezierPath()
        
        let p0 = CGPoint(x: bounds.midX, y: bounds.maxY - 2.0 )
        arrowPath.move(to: p0)
        arrowPath.addLine(to: CGPoint(x:bounds.midX - 6.0, y: roundedRect.maxY))
        arrowPath.addLine(to: CGPoint(x:bounds.midX + 6.0, y: roundedRect.maxY))
        
        roundedRectPath.append(arrowPath)
        roundedRectPath.fill()
        
        // draw text
        if let text = self.text {
            let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
            let yOffset = (roundedRect.size.height - size.height) / 2.0
            let textRect = CGRect(x:roundedRect.origin.x, y: yOffset, width: roundedRect.size.width, height: size.height)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs = [NSAttributedString.Key.font: font,
                         NSAttributedString.Key.paragraphStyle: paragraphStyle,
                         NSAttributedString.Key.foregroundColor: textColor] as [NSAttributedString.Key : Any]
            text.draw(in:textRect, withAttributes: attrs)
        }
    }
}
