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
import UIKit

//alert.modalPresentationStyle = UIModalPresentationCustom;
//alert.transitioningDelegate = alert;

class ViewControllerTransition: NSObject {
    
    enum TransitionType {
        case Present
        case Dismiss
    }
    
    internal var transitionType: TransitionType
    
    internal var duration: NSTimeInterval = 0.4
    
    required init(transitionType: TransitionType) {
        self.transitionType = transitionType
    }
    
    internal func containerView(transitionContext: UIViewControllerContextTransitioning) -> UIView {
        return transitionContext.containerView()!
    }
    
    internal func fromViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController {
        return transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
    }
    
    internal func toViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController {
        return transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
    }
    
    internal func presentAnimation(transitionContext: UIViewControllerContextTransitioning, containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController, completion: () -> ()) {
        
    }
    
    internal func dismissAnimation(transitionContext: UIViewControllerContextTransitioning, containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController, completion: () -> ()) {
        
    }
    
}

// MARK: UIViewControllerAnimatedTransitioning
extension ViewControllerTransition: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = self.containerView(transitionContext)
        let toViewController = self.toViewController(transitionContext)
        let fromViewController = self.fromViewController(transitionContext)
        
        let completion = {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
        
        if transitionType == .Present {
            toViewController.view.frame = containerView.frame
            toViewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            toViewController.view.translatesAutoresizingMaskIntoConstraints = true
            containerView.addSubview(toViewController.view)
            toViewController.view.layoutIfNeeded()
            
            presentAnimation(transitionContext, containerView: containerView, fromViewController: fromViewController, toViewController: toViewController, completion: completion)
            
        } else {
            containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
            
            dismissAnimation(transitionContext, containerView: containerView, fromViewController: fromViewController, toViewController: toViewController, completion: completion)
            
        }
    }
    
}