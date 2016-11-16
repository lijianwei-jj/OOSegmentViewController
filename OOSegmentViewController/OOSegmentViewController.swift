//
//  OOSegmentViewController.swift
//  OOSegmentViewController
//
//  Created by lee on 16/6/27.
//  Copyright © 2016年 clearlove. All rights reserved.
//

import UIKit


@objc public protocol OOSegmentDelegate {
    
    optional func segmentViewController(segmentViewController:OOSegmentViewController,willShowViewController viewController:UIViewController) -> Void;
    optional func segmentViewController(segmentViewController:OOSegmentViewController,didShowViewController viewController:UIViewController) -> Void;
    
}



public class OOSegmentViewController : UIPageViewController {
    
//    private var pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    public var navBar = OOSegmentNavigationBar()
    private var navBarHideAnimate = false
    private var lastContentOffset = CGFloat(0)
    private var lastScrollDirection = UIAccessibilityScrollDirection.Up
    private var scrollDistance = CGFloat(0)
    
    public var navBarTopLayoutConstraint : NSLayoutConstraint!
    
    public var navBarHeight = CGFloat(40)
    public var segmentDelegate : OOSegmentDelegate?
    public var titleColor = UIColor.blackColor()
    public var titleSelectedColor = UIColor.redColor()
    public var fontSize = CGFloat(15)
    public var cursorColor = UIColor.whiteColor()
    public var cursorHeight = CGFloat(2)
    public var cursorBottomMargin : CGFloat?
    public var navBarBackgroundColor = UIColor.whiteColor()
    public var titleMargin = CGFloat(8)
    public var titleOffset = CGFloat(0)
    
    public var cursorMoveEffect : CursorMoveEffect = OOCursorMoveEffect()
    
    public var pageIndex = 0 {
        didSet {
//            if pageIndex != oldValue {
//                moveToControllerAtIndex(pageIndex)
//            }
            pendingIndex = pageIndex
        }
    }
    var pendingIndex = 0
    private var autoFetchTitles = false
    public var titles = [String]() {
        didSet {
            pageIndex = 0
            navBar.titles = titles
        }
    }
    public var controllers = [UIViewController]() {
        didSet {
            if let first = controllers.first,vcs = self.viewControllers where !vcs.isEmpty {
                self.setViewControllers([first], direction: .Forward, animated: false, completion: nil)
            }
            if autoFetchTitles {
                titles = controllers.map {
                    $0.title ?? ""
                }
            }
        }
    }
    
    public init() {
        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    }
    
    required public init?(coder: NSCoder) {
//        super.init(coder: coder)
        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        configConstraints()
    }
    
    class PageControlView: UIView {
        var view:UIView
        init(view:UIView) {
            self.view = view
            super.init(frame:CGRectZero)
            addSubview(view)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var pageControl:UIPageControl? {
            return view.valueForKey("_pageControl") as? UIPageControl
        }
        
        var scrollView:UIScrollView {
            return view.valueForKey("_scrollView") as! UIScrollView
        }
        
    }
    
    public func configUI(){
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        
        
        if self.view.backgroundColor == nil {
            self.view.backgroundColor = UIColor.whiteColor()
        }
        
        delegate = self
        dataSource = self
        
//        addChildViewController(pageViewController)
//        view.insertSubview(pageViewController.view, atIndex: 0)
//        pageViewController.didMoveToParentViewController(self)
       
        setViewControllers([controllers[pageIndex]], direction: .Forward, animated: false, completion: nil)
        
        navBar.backgroundColor = navBarBackgroundColor
        navBar.titleColor = titleColor
        navBar.titleSelectedColor = titleSelectedColor
        navBar.cursorColor = cursorColor
        navBar.cursorHeight = cursorHeight
        navBar.cursorBottomMargin = cursorBottomMargin
        navBar.fontSize = fontSize
        navBar.segmentViewController = self
        if titles.count == 0 {
            autoFetchTitles = true
            controllers.forEach {
                titles.append($0.title ?? "")
            }
        }
        navBar.titles = titles
        navBar.itemMargin = titleMargin
        navBar.itemOffset = titleOffset
        navBar.moveEffect = cursorMoveEffect
        
        if let scrollView = self.valueForKey("_scrollView") as? UIScrollView {
            scrollView.delegate = navBar
            scrollView.scrollsToTop = false
        }
        
        let view = PageControlView(view: self.view)
        self.view = view
        view.addSubview(navBar)
        
    }
    
    public func configConstraints() {
        let views = ["navBar":navBar,"pageView":(self.view as! PageControlView).view]
        //        let views = ["navBar":navBar,"pageView":view]
        views.forEach {
            $1.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[navBar]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[pageView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))
        let constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[navBar(\(navBarHeight))][pageView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views)
        navBarTopLayoutConstraint = constraints.first!
        view.addConstraints(constraints)
 
    }
    
    public func moveToControllerAtIndex(index:Int, animated : Bool = true){
        guard index >= 0 && index < controllers.count else {
            return
        }
        let direction : UIPageViewControllerNavigationDirection = index > pageIndex ? .Forward : .Reverse
        pendingIndex = index
        viewControllerWillShow()
        if pageIndex == pendingIndex {
            viewControllerDidShow()
            return
        }
        setViewControllers([controllers[index]], direction: direction, animated: animated) { [weak self] completed in
            if completed {
                self?.viewControllerDidShow()
//                self?.pendingIndex = -1
            }
        }
    }
    
    func viewControllerWillShow() {
        
        segmentDelegate?.segmentViewController?(self, willShowViewController: (viewControllers?.last)!)
    }
    
    func viewControllerDidShow() {
//        self.pageIndex = self.pendingIndex
        self.pageIndex = getFocusViewControllerIndex()
        navBar.updateSelectItem(self.pageIndex)
        setNavBarHidden(false,animated:false)
        segmentDelegate?.segmentViewController?(self, didShowViewController: (viewControllers?.last)!)
    }
    
    public func setNavBarHidden(hidden: Bool , animated : Bool = true) {
        guard hidden || self.navBarTopLayoutConstraint.constant != 0 else {
            return
        }
        navBarHideAnimate = true
        scrollDistance = 0
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.navBarTopLayoutConstraint.constant = hidden ? -self.navBarHeight : 0
            if 8 == NSProcessInfo().operatingSystemVersion.majorVersion {
                var frame = self.view.subviews[0].frame
                frame.size.height += self.navBarHeight * (hidden ? 1 : -1)
                self.view.subviews[0].frame = frame
            }
            if (animated) {
                self.view.layoutIfNeeded()
            }
        }) { _ in
            self.navBarHideAnimate = false
        }
    }
    
    public func followScrollView(scrollView: UIScrollView,navBarHideChangeHandler:((Bool)->())? = nil) {
        let contentOffsetY = scrollView.contentOffset.y,
            topInset = scrollView.contentInset.top,
            buttomInset = scrollView.contentInset.bottom
        guard contentOffsetY >= 0 - topInset && contentOffsetY <= scrollView.contentSize.height + buttomInset - CGRectGetHeight(scrollView.bounds) else { return }
        // 流动方向
        let direction: UIAccessibilityScrollDirection = (scrollView.contentOffset.y > lastContentOffset) ? .Up : .Down
        if direction == lastScrollDirection {
            scrollDistance += scrollView.contentOffset.y - lastContentOffset
        }else{
            lastScrollDirection = direction
            scrollDistance = 0
        }
        lastContentOffset = scrollView.contentOffset.y
//        print("distance \(scrollDistance) \(contentOffsetY)  \(scrollView.contentSize.height)")
//        if scrollView.tracking == true && abs(scrollDistance) > navBarHeight && navBarHideAnimate == false {
        if abs(scrollDistance) > navBarHeight && navBarHideAnimate == false {
            
            if direction == .Up && self.navBarTopLayoutConstraint.constant == 0 {
                // 隐藏
                setNavBarHidden(true)
                navBarHideChangeHandler?(true)
            } else if direction == .Down && self.navBarTopLayoutConstraint.constant == -navBarHeight {
                // 显示
                setNavBarHidden(false)
                navBarHideChangeHandler?(false)
            }
        }
    }
    
    func getFocusViewControllerIndex()->Int {
        return controllers.indexOf((viewControllers?.last)!)!
    }
}

extension OOSegmentViewController : UIPageViewControllerDelegate,UIPageViewControllerDataSource {
    
    func nextViewController(viewController:UIViewController,combine: (Int,Int)->Int) -> UIViewController? {
        let index = combine(controllers.indexOf(viewController)!,1)
        guard (0..<controllers.count).contains(index) else {
            return nil
        }
        return controllers[index]
    }
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            viewControllerDidShow()
        } else {
            pendingIndex = pageIndex
        }
    }
    
    public func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        pendingIndex = controllers.indexOf(pendingViewControllers.first!)!
        viewControllerWillShow()
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, combine: +)
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, combine: -)
    }
    
}