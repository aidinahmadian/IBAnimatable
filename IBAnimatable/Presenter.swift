//
//  Created by Jake Lin on 2/24/16.
//  Copyright © 2016 IBAnimatable. All rights reserved.
//

import UIKit

/**
 Presenter for `UIViewController` to support custom transition animation for Present and Dismiss
 */
public class Presenter: NSObject {
  private var transitionAnimationType: TransitionAnimationType
  var presenterSetup: PresentedSetup?
  var transitionDuration: Duration {
    didSet {
      if oldValue != transitionDuration {
        updateTransitionDuration()
      }
    }
  }
  
  var interactiveGestureType: InteractiveGestureType? {
    // Update `interactiveAnimator` if needed
    didSet {
      if oldValue?.stringValue != interactiveGestureType?.stringValue {
        updateInteractiveAnimator()
      }
    }
  }
  
  // animation controller
  private var animator: AnimatedTransitioning?
  
  // interaction controller
  private var interactiveAnimator: InteractiveAnimator?
  
  public init(transitionAnimationType: TransitionAnimationType, transitionDuration: Duration = defaultTransitionDuration, interactiveGestureType: InteractiveGestureType? = nil, presenterSetup: PresentedSetup? = nil) {
    self.transitionAnimationType = transitionAnimationType
    self.transitionDuration = transitionDuration
    self.presenterSetup = presenterSetup
    super.init()
    
    updateTransitionDuration()
    animator = AnimatorFactory.generateAnimator(transitionAnimationType, transitionDuration: transitionDuration)
    
    self.interactiveGestureType = interactiveGestureType
    updateInteractiveAnimator()
  }
  
  // MARK: - Private
  private func updateTransitionDuration() {
    if transitionDuration.isNaN {
      transitionDuration = defaultTransitionDuration
    }
  }
  
  private func updateInteractiveAnimator() {
    // If interactiveGestureType has been set
    if let interactiveGestureType = interactiveGestureType {
      // If configured as `.Default` then use the default interactive gesture type from the Animator
      switch interactiveGestureType {
      case .Default:
        if let interactiveGestureType = animator?.interactiveGestureType {
          interactiveAnimator = InteractiveAnimatorFactory.generateInteractiveAnimator(interactiveGestureType, transitionType: .PresentationTransition(.Dismissal))
        }
      default:
        interactiveAnimator = InteractiveAnimatorFactory.generateInteractiveAnimator(interactiveGestureType, transitionType: .PresentationTransition(.Dismissal))
      }
    } else {
      interactiveAnimator = nil
    }
  }
}

extension Presenter: UIViewControllerTransitioningDelegate {

  public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
    guard let unwrappedPresenterSetup = presenterSetup else {
      return nil
    }
    return PresentationAnimatable(presentedViewController: presented, presentingViewController: presenting, presenterSetup: unwrappedPresenterSetup)
  }

  // MARK: - animation controller
  public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    animator?.transitionDuration = transitionDuration
    interactiveAnimator?.connectGestureRecognizer(presented)
    return animator
  }

  public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    // Use the reverse animation
    if let reverseTransitionAnimationType = animator?.reverseAnimationType {
      return AnimatorFactory.generateAnimator(reverseTransitionAnimationType, transitionDuration: transitionDuration)
    }
    return nil
  }
  
  // MARK: - interaction controller
  public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    if let interactiveAnimator = interactiveAnimator where interactiveAnimator.interacting {
      return interactiveAnimator
    } else {
      return nil
    }
  }
}
