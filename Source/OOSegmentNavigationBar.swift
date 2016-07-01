//
//  OOSegmentNavigationBar.swift
//  OOSegmentViewController
//
//  Created by lee on 16/6/27.
//  Copyright © 2016年 clearlove. All rights reserved.
//

import UIKit

class OOSegmentNavigationBar : UIScrollView {

    var titles = [String]() {
        didSet {
            configItems()
        }
    }
    
    var titleColor : UIColor!
    var titleSelectedColor : UIColor!
    var fontSize : CGFloat!
    
    var segmentViewController : OOSegmentViewController?
    
    private var titleItemMap = [String:UIButton]()
    private var selectedItem : UIButton!
    
    private var contentView = UIView(frame: CGRectZero)
    private var cursor = UIView(frame: CGRectMake(0,0,0,2))
    var cursorColor : UIColor! {
        didSet {
            cursor.backgroundColor = cursorColor
        }
    }
    
    init(){
        super.init(frame: CGRectZero)
        configUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if contentView.frame == CGRectZero {
            contentView.frame.size.height = self.frame.size.height
            let height = CGRectGetHeight(self.frame)
            cursor.frame = CGRectMake(0, height - 2 - (height-fontSize)/4, 0, 2)
            layoutItems()
        }
        
    }
    
    func configUI() {
        self.showsHorizontalScrollIndicator = false
        
        addSubview(contentView)
        cursor.backgroundColor = cursorColor
        contentView.addSubview(cursor)
    }

    func configItems() {
        guard titleItemMap.count == 0 else {
            return
        }
        titles.enumerate().forEach {
            let item = UIButton()
            item.tag = $0
            item.setTitle($1, forState: .Normal)
            item.setTitleColor(titleColor, forState: .Normal)
            item.setTitleColor(titleSelectedColor, forState: .Selected)
            item.titleLabel?.font = UIFont.systemFontOfSize(fontSize)
            item.addTarget(self, action: #selector(itemClick(_:)), forControlEvents: .TouchUpInside)
            titleItemMap[$1] = item
            contentView.addSubview(item)
            
        }
//        layoutItems()
    }
    
    func layoutItems() {
        var contentWidth = 8 as CGFloat
        titles.enumerate().forEach {
            let item = titleItemMap[$1]
            let itemWidth = ceil(titleWidthAtFont(UIFont.systemFontOfSize(fontSize), index: $0))
            item?.frame = CGRectMake(contentWidth, 0, itemWidth, CGRectGetHeight(self.frame))
            if $0 == 0 {
                cursor.frame.size.width = itemWidth + 4
                cursor.frame.origin.x = contentWidth - 2
                item?.selected = true
                selectedItem = item
            }
            contentWidth += itemWidth + 8
        }
        contentSize.width = CGFloat(contentWidth)
        contentView.frame.size.width = CGFloat(contentWidth)
//        contentView.frame.origin.x = contentWidth < CGRectGetWidth(self.frame) ? (CGRectGetWidth(self.frame) - contentWidth) / 2.0 : 0
        if contentWidth < CGRectGetWidth(self.frame) {
            contentView.frame.origin.x = (CGRectGetWidth(self.frame) - contentWidth) / 2.0
        }
    }
    
    func itemClick(sender:UIButton) {
        print(sender)
        segmentViewController?.moveToControllerAtIndex(sender.tag)
    }
    
    func titleWidthAtFont(font:UIFont,index:Int) -> CGFloat {
        return titles[index].boundingRectWithSize(CGSize(width: CGFloat.max, height: font.lineHeight), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil).size.width + 4
    }
}


extension OOSegmentNavigationBar : UIScrollViewDelegate {
    
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let segmentViewController = segmentViewController where segmentViewController.pendingIndex != -1 else {
            return
        }
        
        let oldIndex = segmentViewController.pageIndex , index = segmentViewController.pendingIndex
        
        let button = titleItemMap[titles[index]]! , oldButton = titleItemMap[titles[oldIndex]]!
        let fullWidth = CGRectGetWidth(segmentViewController.view.frame)
        
        let xScale = scrollView.contentOffset.x % fullWidth / fullWidth
        if xScale == 0 {
            return
        }
//        let titleFont = UIFont.systemFontOfSize(fontSize)
        
        let indicatorWidth = button.frame.size.width // titleWidthAtFont(titleFont, index: index)
        let oldWidth = oldButton.frame.size.width // titleWidthAtFont(titleFont, index: oldIndex)
        let f = CGFloat(index - oldIndex)
        var s = (f > 0 ? 1.0 - (xScale == 0 ? 1.0 : xScale) : xScale) // == 1.0 ? xScale : 0
        s = s < 0.01 || s > 0.99 ? round(s) : s
        let w = (oldWidth - indicatorWidth) * s + indicatorWidth
        let xOffset = (oldButton.center.x - button.center.x) * s
        let x = xOffset + button.center.x
        
//        print("nx:\(button.center.x)    ox:\(oldButton.center.x)  x:\(x)   f:\(f)     s:\(s)  xs:\(xScale)")
        
        
        UIView.animateWithDuration(0.1) {
            self.cursor.frame.size.width = w
            self.cursor.center.x = x
//            print("\(CGRectGetMaxX(self.bounds))  \(CGRectGetMaxX(button.frame))")
        }
        UIView.animateWithDuration(0.3) {
            if CGRectGetMaxX(self.bounds) < CGRectGetMaxX(button.frame) + 2 {
                self.contentOffset.x += (CGRectGetMaxX(button.frame) - CGRectGetMaxX(self.bounds) + 2)
            } else if CGRectGetMinX(self.bounds) > CGRectGetMinX(button.frame) - 2 {
                self.contentOffset.x = CGRectGetMinX(button.frame) - 2
            }
        }
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollViewEndScroll()
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollViewEndScroll()
    }
    
    func scrollViewEndScroll() {
        if let pageIndex = segmentViewController?.pendingIndex == -1 ? segmentViewController?.pageIndex : segmentViewController?.pendingIndex {
            selectedItem.selected = false
            selectedItem = titleItemMap[titles[pageIndex]]
            selectedItem.selected = true
        }
    }
}