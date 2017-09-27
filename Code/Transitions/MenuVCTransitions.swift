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

class MenuVCTransitions: ViewControllerTransition {
    
    override func presentAnimation(transitionContext: UIViewControllerContextTransitioning, containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController, completion: () -> ()) {
        
        let view = toViewController.view
        view.alpha = 0
        
        UIView.animateWithDuration(self.duration, delay: 0, options: .CurveEaseInOut, animations: {
            view.alpha = 1
        }) { _ in
            completion()
        }
    }
    
    override func dismissAnimation(transitionContext: UIViewControllerContextTransitioning, containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController, completion: () -> ()) {
        
        let view = fromViewController.view
        
        UIView.animateWithDuration(self.duration, delay: 0, options: .CurveEaseInOut, animations: {
            view.alpha = 0
        }) { _ in
            completion()
        }
    }
    
}