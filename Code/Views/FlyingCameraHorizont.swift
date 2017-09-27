//
//	DroneVR.
//	Created by:				Bruno Wernimont
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Foundation
import EasyPeasy

class FlyingCameraHorizont: UIView {
    private var offset: CGPoint = CGPoint()
    
    private let horizontalView: UIView = {
        let view = UIView()
        let image = UIImage(asset: .CameraLineHorizontal)
        view.backgroundColor = UIColor(patternImage: image)
        return view
    }()
    
    private let verticalView: UIView = {
        let view = UIView()
        let image = UIImage(asset: .CameraLineVertical)
        view.backgroundColor = UIColor(patternImage: image)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubViews([horizontalView, verticalView])
        self.backgroundColor = UIColor.clearColor()
        
        verticalView <- [
            Top(),
            Bottom(),
            Width(2),
            CenterX()
        ]
        
        horizontalView <- [
            Left(),
            Right(),
            Height(2),
            CenterY()
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateOffset(offset: CGPoint) {
        self.offset = offset
        self.setNeedsLayout()
    }
    
//    override func drawRect(rect: CGRect) {
//        super.drawRect(rect)
//        
//        // Vertical
//        
//        
//        
//        // Horizontal
//
//        let verticalPath: UIBezierPath = UIBezierPath()
//        verticalPath.moveToPoint(CGPointMake(rect.width/2, 0))
//        verticalPath.addLineToPoint(CGPointMake(rect.width/2, rect.height))
//        UIColor.blackColor().setStroke()
//        verticalPath.lineWidth = 1
//        verticalPath.stroke()
//        
//        let horizontalPath: UIBezierPath = UIBezierPath()
//        horizontalPath.moveToPoint(CGPointMake(0, rect.height/2))
//        horizontalPath.addLineToPoint(CGPointMake(rect.width, rect.height/2))
//        UIColor.blackColor().setStroke()
//        horizontalPath.lineWidth = 1
//        horizontalPath.stroke()
//    }
}