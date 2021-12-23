//
//  KeyboardAnimator.swift
//  Yelp Search
//
//  Code adjusted from https://www.advancedswift.com/animate-with-ios-keyboard-swift/

import UIKit

class KeyboardAnimator {
    
    private let animatedConstraint: NSLayoutConstraint
    private let adjustedView: UIView
    
    init(animatedConstraint: NSLayoutConstraint, adjustedView: UIView) {
        self.animatedConstraint = animatedConstraint
        self.adjustedView = adjustedView
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    dynamic func keyboardWillShow(
        _ notification: NSNotification
    ) {
        animateWithKeyboard(notification: notification) {
            (keyboardFrame) in
            let constant = 20 + keyboardFrame.height
            self.animatedConstraint.constant = constant
        }
    }
    
    @objc
    dynamic func keyboardWillHide(
        _ notification: NSNotification
    ) {
        animateWithKeyboard(notification: notification) {
            (keyboardFrame) in
            self.animatedConstraint.constant = 20
        }
    }
    
    func animateWithKeyboard(
        notification: NSNotification,
        animations: ((_ keyboardFrame: CGRect) -> Void)?
    ) {
        // Extract the duration of the keyboard animation
        let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        let duration = notification.userInfo![durationKey] as! Double
        
        // Extract the final frame of the keyboard
        let frameKey = UIResponder.keyboardFrameEndUserInfoKey
        let keyboardFrameValue = notification.userInfo![frameKey] as! NSValue
        
        // Extract the curve of the iOS keyboard animation
        let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
        let curveValue = notification.userInfo![curveKey] as! Int
        let curve = UIView.AnimationCurve(rawValue: curveValue)!
        
        // Create a property animator to manage the animation
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: curve
        ) {
            // Perform the necessary animation layout updates
            animations?(keyboardFrameValue.cgRectValue)
            
            // Required to trigger NSLayoutConstraint changes
            // to animate
            self.adjustedView.layoutIfNeeded()
        }
        
        // Start the animation
        animator.startAnimation()
    }
}
