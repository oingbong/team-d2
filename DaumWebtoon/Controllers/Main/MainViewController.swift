//
//  MainViewController.swift
//  DaumWebtoon
//
//  Created by Gaon Kim on 06/02/2019.
//  Copyright © 2019 Gaon Kim. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    // MARK: - Properties
    let tabContents: [TabContent] = [
        TabContent(tabColor: UIColor.blue, tabTitle: "", tabIndex: 0),
        TabContent(tabColor: UIColor.red, tabTitle: "웹디자인", tabIndex: 1),
        TabContent(tabColor: UIColor.brown, tabTitle: "프로그래밍", tabIndex: 2),
        TabContent(tabColor: UIColor.purple, tabTitle: "가상현실", tabIndex: 3),
        TabContent(tabColor: UIColor.blue, tabTitle: "스타트업", tabIndex: 4),
        TabContent(tabColor: UIColor.red, tabTitle: "", tabIndex: 5)
    ]
    enum Genre: Int {
        case webDesign = 140
        case programming = 143
        case vrAndAr = 139
        case startup = 157
    }
    private let interactor = Interactor()
    private let genres: [Genre?] = [.startup, .webDesign, .programming, .vrAndAr, .startup, .webDesign]
    private var tabBarViewCenterYAnchorConstraint: NSLayoutConstraint?
    private let menuViewHeight: CGFloat = 70
    private lazy var tabBarViewWidth: CGFloat = view.frame.width - 20
    private lazy var tabBarViewHeight: CGFloat = 30
    private lazy var tableViewInsetTop: CGFloat = {
        return view.frame.height / 2 - menuViewHeight - tabBarViewHeight / 2 - UIApplication.shared.statusBarFrame.height
    }()
    private var lastContentOffset: CGFloat = 0
    private var contentOffsetInPage: CGFloat = 0
    private let slidePanelViewController = SlidePanelViewController()
    private var slidePanelBaseView: UIView!
    private var baseViewMaxX: CGFloat = 0.0
    private var currentIndex = 1
    private var isSplashViewDidAppear = false
    
    // MARK: Views
    private lazy var splashView = SplashView()
    private lazy var tabBarView = {
        return TabBarView(frame: CGRect(x: 0.0, y: 0.0, width: tabBarViewWidth, height: tabBarViewHeight))
    } ()
    private lazy var scrollView = UIScrollView()
    private lazy var scrollContentView = UIView()
    private lazy var tabBarViewContainer = UIView()
    private lazy var tableView = UITableView()
    private lazy var menuView = UIView()
    private lazy var tableStackView = UIStackView()
    lazy var headerView = HeaderView()
    private var contentViewControllers = [ContentViewController]()
    var isFirstConfigure = true
    var headerContentsDictionary = [Int: HeaderContent]() {
        // 컨텐츠를 새로고침 할 때 기존 데이터가 유지되도록 첫번째 세팅인지 확인합니다.
        willSet {
            if headerContentsDictionary.count == 4 {
                isFirstConfigure = false
            }
        }
        didSet {
            if isFirstConfigure {
                let emptyTab = 2
                if headerContentsDictionary.count == tabContents.count - emptyTab {
                    headerView.configureFirstContent(with: headerContentsDictionary)
                }
            }
            
        }
    }
    
    // MARK: Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        addScrollView()
        addMenuView()
        addTableStackView()
        addContentViewControllers()
        addTabBarView()
        addHeaderView()
        addSplashView()
        setupSlidePanelView()
        addContentOffsetNotification()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showCurrentTab(currentIndex: currentIndex)
        animateSplashViewIfViewDidNotAppeared()
    }
}

// MARK: - Methods
extension MainViewController {
    // MARK: Splash View Methods
    func addSplashView() {
        splashView.delegate = self
        view.addSubview(splashView)
        setSplashViewLayout()
    }
    
    func setSplashViewLayout() {
        splashView.translatesAutoresizingMaskIntoConstraints = false
        splashView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        splashView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        splashView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        splashView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    func animateSplashViewIfViewDidNotAppeared() {
        if !isSplashViewDidAppear {
            isSplashViewDidAppear.toggle()
            splashView.animate()
        }
    }
    
    // MARK: Header View Methods
    func addHeaderView() {
        view.addSubview(headerView)
        headerView.delegate = self
        headerView.symbolView.dataSource = self
        headerView.configure()
        setHeaderViewLayout()
        // scrollView 가 헤더뷰를 덮도록 앞으로 가져옵니다.
        view.bringSubviewToFront(scrollView)
        view.bringSubviewToFront(menuView)
    }
    
    func setHeaderViewLayout() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.topAnchor.constraint(equalTo: menuView.bottomAnchor).isActive = true
        headerView.bottomAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    // MARK: Scroll View Methods
    func addScrollView() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        setScrollViewLayout()
        setScrollViewProperties()
    }
    
    func setScrollViewLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        let widthAnchor = scrollContentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        scrollContentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        widthAnchor.priority = .defaultLow
        widthAnchor.isActive = true
    }
    
    func setScrollViewProperties() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }

    // MARK: Tab Bar View Methods
    func addTabBarView() {
        tabBarView.dataSource = self
        tabBarView.delegate = self
        scrollContentView.addSubview(tabBarViewContainer)
        tabBarViewContainer.addSubview(tabBarView)
        tabBarView.showCurrentTabIndicator()
        setTabBarViewLayout()
        setTabBarViewProperties()
    }
    
    func setTabBarViewLayout() {
        tabBarViewContainer.translatesAutoresizingMaskIntoConstraints = false
        tabBarViewContainer.heightAnchor.constraint(equalToConstant: 30).isActive = true
        tabBarViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        tabBarViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        tabBarViewCenterYAnchorConstraint = tabBarViewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        tabBarViewCenterYAnchorConstraint?.priority = .defaultLow
        tabBarViewCenterYAnchorConstraint?.isActive = true
        tabBarViewContainer.centerYAnchor.constraint(lessThanOrEqualTo: view.centerYAnchor).isActive = true
        tabBarViewContainer.centerYAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: menuViewHeight + (tabBarViewHeight / 2)).isActive = true
    }
    
    func setTabBarViewProperties() {
        tabBarViewContainer.clipsToBounds = true
        tabBarViewContainer.backgroundColor = .red
    }
    
    // MARK :- SlidePanelView
    private func setupSlidePanelView() {
        slidePanelBaseView = UIView(frame: CGRect(x: view.bounds.size.width, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))
        slidePanelBaseView.backgroundColor = UIColor.clear
        baseViewMaxX = slidePanelBaseView.frame.maxX
        
        addChild(slidePanelViewController)
        slidePanelViewController.didMove(toParent: self)
        slidePanelViewController.view.frame = CGRect(x: 0, y: 0, width: slidePanelBaseView.bounds.size.width, height: slidePanelBaseView.bounds.size.height)
        slidePanelViewController.delegate = self
        slidePanelBaseView.addSubview(slidePanelViewController.view)
        
        view.addSubview(slidePanelBaseView)
        view.bringSubviewToFront(slidePanelBaseView)
    }
    
    func hideMiniPlayer() {
        let window = UIApplication.shared.keyWindow
        window?.viewWithTag(100)?.isHidden = true
    }
    
    func showMiniPlayer() {
        let window = UIApplication.shared.keyWindow
        window?.viewWithTag(100)?.isHidden = false
    }
    
    func removeSlidePanelView() {
        slidePanelViewController.willMove(toParent: nil)
        slidePanelViewController.view.removeFromSuperview()
        slidePanelViewController.removeFromParent()
        
        slidePanelBaseView.willRemoveSubview(slidePanelViewController.view)
        slidePanelBaseView.removeFromSuperview()
    }
    
    func adjustIndexForIndex(currentIndex: Int, previousIndex: Int) -> (Int, Int) {
        if currentIndex > tabContents.count - 2 {
            return (1, tabContents.count - 2)
        } else if currentIndex < 1 {
            return (tabContents.count - 2, 1)
        } else {
            return (currentIndex, previousIndex)
        }
    }
    
    func isInvisibleTabForIndex(contentOffset: CGFloat) -> Bool {
        return contentOffset <= 0.0 ||
            contentOffset >= scrollView.frame.width * CGFloat(tabContents.count - 1)
            ? true : false
    }
    
    func showCurrentTab(currentIndex: Int, animated: Bool = true) {
        let frame = CGRect(
            x: scrollView.frame.width * CGFloat(currentIndex),
            y: 0,
            width: scrollView.frame.width,
            height: scrollView.frame.height)
        scrollView.setContentOffset(frame.origin, animated: animated)
        
        lastContentOffset = scrollView.frame.width * CGFloat(currentIndex)
    }
    
    func scrollToTab(currentIndex: Int, previousIndex: Int = 0) {
        let index = adjustIndexForIndex(currentIndex: currentIndex, previousIndex: previousIndex)
        tabBarView.showEachTabs(currentIndex: index.0)
        tabBarView.showCurrentTabIndicator(currentIndex: index.0, previousIndex: index.1)
    }
    
    // MARK: Menu View Methods
    func addMenuView() {
        view.addSubview(menuView)
        setMenuViewLayout()
        setupHambergerButton()
        setupSearchView()
    }
    
    func setMenuViewLayout() {
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        menuView.heightAnchor.constraint(equalToConstant: menuViewHeight).isActive = true
    }
    
    func setupSearchView() {
        let search = UIButton()
        search.addTarget(self, action: #selector(searchTapped(_:)), for: .touchUpInside)
        search.setImage(UIImage(named: "search"), for: .normal)
        menuView.addSubview(search)
        
        search.translatesAutoresizingMaskIntoConstraints = false
        search.widthAnchor.constraint(equalToConstant: 30).isActive = true
        search.heightAnchor.constraint(equalToConstant: 30).isActive = true
        search.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -70).isActive = true
        search.centerYAnchor.constraint(equalTo: menuView.centerYAnchor).isActive = true
    }
    
    func setupHambergerButton() {
        let hamberger = UIButton()
        hamberger.setImage(UIImage(named: "hamberger"), for: .normal)
        hamberger.addTarget(self, action: #selector(hambergerButtonDidTapped(_:)), for: .touchUpInside)
        menuView.addSubview(hamberger)
        
        hamberger.translatesAutoresizingMaskIntoConstraints = false
        hamberger.widthAnchor.constraint(equalToConstant: 30).isActive = true
        hamberger.heightAnchor.constraint(equalToConstant: 30).isActive = true
        hamberger.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -18).isActive = true
        hamberger.centerYAnchor.constraint(equalTo: menuView.centerYAnchor).isActive = true
    }
    
    // MARK: Content View Controller Methods
    func addContentViewControllers() {
        for index in 0..<tabContents.count {
            let contentViewController = ContentViewController()
            contentViewController.genre = genres[index]?.rawValue
            addChild(contentViewController)
            contentViewController.didMove(toParent: self)
            tableStackView.addArrangedSubview(contentViewController.view)
            contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentViewController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
            contentViewController.tableView.contentInset = UIEdgeInsets(
                top: tableViewInsetTop,
                left: 0,
                bottom: 0,
                right: 0)
                // MARK: - For HeaderView
            contentViewController.delegate = self
            
            contentViewControllers.append(contentViewController)
        }
    }
    
    // MARK: Table Stack View Methods
    func addTableStackView() {
        scrollContentView.addSubview(tableStackView)
        setTableStackViewLayout()
    }
    
    func setTableStackViewLayout() {
        tableStackView.translatesAutoresizingMaskIntoConstraints = false
        tableStackView.topAnchor.constraint(equalTo: menuView.bottomAnchor, constant: tabBarViewHeight).isActive = true
        tableStackView.bottomAnchor.constraint(equalTo: scrollContentView.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableStackView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        tableStackView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
        tableStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: CGFloat(tabContents.count)).isActive = true
    }
    
    func addContentOffsetNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onDidChageContentOffset(_:)), name: .didChangeContentOffset, object: nil)
    }
    
    @objc func onDidChageContentOffset(_ notification: Notification) {
        tabBarViewCenterYAnchorConstraint?.constant = -tableViewInsetTop - MainCommon.shared.contentOffset
        tabBarViewContainer.updateConstraints()
        let topLimit = menuViewHeight + tabBarViewHeight + UIApplication.shared.statusBarFrame.height - (scrollView.frame.height / 2)
        guard let currentTabBarViewCenterYConstant = tabBarViewCenterYAnchorConstraint?.constant else { return }
        updateHeaderViewAlpha(topLimit: topLimit, currentTabBarViewCenterYConstant: currentTabBarViewCenterYConstant)
    }
    
    func updateHeaderViewAlpha(topLimit: CGFloat, currentTabBarViewCenterYConstant: CGFloat) {
        let headerViewHeight = -topLimit
        headerView.alpha = (currentTabBarViewCenterYConstant - topLimit) / headerViewHeight
    }
    
    @objc func searchTapped(_ sender: UIButton) {
        guard let searchViewController = UIStoryboard(name: "Search", bundle: nil).instantiateViewController(withIdentifier: "Search") as? SearchViewController else { return }
        searchViewController.transitioningDelegate = self
        searchViewController.interactor = interactor
        let currentContentOffset = MainCommon.shared.contentOffset
        present(searchViewController, animated: false, completion: {
            MainCommon.shared.contentOffset = currentContentOffset
        })
    }
    
    @objc func hambergerButtonDidTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5) {
            self.slidePanelBaseView.frame.origin.x = 0
        }
        
        hideMiniPlayer()
    }
}

// MARK :- SlidePanelView Delegate
extension MainViewController: SlidePanelViewDelegate {
    func dismiss() {
        UIView.animate(withDuration: 0.6, animations: {
            self.slidePanelBaseView.frame.origin.x = self.baseViewMaxX
        }) { (success) in
            if success {
                self.showMiniPlayer()
                self.removeSlidePanelView()
                self.setupSlidePanelView()
            }
        }
    }
    
    func panGestureDraggingEnded() {
        showMiniPlayer()
        removeSlidePanelView()
        setupSlidePanelView()
    }
}

// MARK: - Splash View Delegate
extension MainViewController: SplashViewDelegate {
    func splashViewDidFinished(_ splashView: SplashView) {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.splashView.alpha = 0
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.splashView.removeFromSuperview()
        })
    }
}

// MARK: - Scroll View Delegate
extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        guard contentOffsetInPage >= UIScreen.main.bounds.width / 2 else { return }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        if lastContentOffset <= scrollView.contentOffset.x {
            tabBarView.drawTabBarColorRightToLeftWhileScrolling(x: scrollView.frame.width, currentIndex: currentIndex - 1)
        }
        
        let nextTabIndex = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        showCurrentTab(currentIndex: nextTabIndex)
        scrollToTab(currentIndex: nextTabIndex, previousIndex: currentIndex)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollWidth = scrollView.frame.width
        let contentOffset = scrollView.contentOffset.x
        var nextTabIndex = Int(round(contentOffset / scrollWidth))
        if nextTabIndex == 0 {
            nextTabIndex = tabContents.count - 2
        } else if nextTabIndex == tabContents.count - 1 {
            nextTabIndex = 1
        }
        
        slideSymbol(with: contentOffset / scrollWidth - 1)
        
        let contentOffsetInPage = contentOffset - scrollWidth * floor(contentOffset / scrollWidth)
        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
            NSObject.cancelPreviousPerformRequests(withTarget: scrollView)
            perform(#selector(scrollViewDidEndScrollingAnimation(_:)), with: scrollView, afterDelay: 0.0)
            
            if lastContentOffset > contentOffset {
                let index = contentOffsetInPage >= view.bounds.width / 2 ? nextTabIndex : nextTabIndex + 1
                tabBarView.drawTabBarColorLeftToRightWhileScrolling(x: abs(contentOffsetInPage - scrollWidth), currentIndex: index)
                self.contentOffsetInPage = abs(contentOffsetInPage - scrollWidth)
            } else if lastContentOffset <= contentOffset && contentOffsetInPage != 0.0 {
                let index = contentOffsetInPage >= view.bounds.width / 2 ? nextTabIndex - 1 : nextTabIndex
                tabBarView.drawTabBarColorRightToLeftWhileScrolling(x: contentOffsetInPage, currentIndex: index)
                self.contentOffsetInPage = contentOffsetInPage
            }
        } else {
            if lastContentOffset > contentOffset {
                let index = contentOffsetInPage >= view.bounds.width / 2 ? nextTabIndex - 1 : nextTabIndex
                tabBarView.drawTabBarColorRightToLeftWhileScrolling(x: contentOffsetInPage, currentIndex: index)
                self.contentOffsetInPage = contentOffsetInPage
            } else if lastContentOffset <= contentOffset && contentOffsetInPage != 0.0 {
                let index = contentOffsetInPage >= view.bounds.width / 2 ? nextTabIndex : nextTabIndex + 1
                tabBarView.drawTabBarColorLeftToRightWhileScrolling(x: abs(contentOffsetInPage - scrollWidth), currentIndex: index)
                self.contentOffsetInPage = abs(contentOffsetInPage - scrollWidth)
            }
        }
        
        tabBarView.showEachTabs(currentIndex: currentIndex)
        tabBarView.showCurrentTabIndicator(currentIndex: nextTabIndex, previousIndex: currentIndex)
        if isInvisibleTabForIndex(contentOffset: contentOffset) {
            showCurrentTab(currentIndex: nextTabIndex, animated: false)
        }
        
        currentIndex = Int(nextTabIndex)
    }
}

// MARK: - Tab Bar View Data Source
extension MainViewController: TabBarDataSource {
    func tabContents(_ tabBarView: TabBarView) -> [TabContent] {
        return tabContents
    }
}

// MARK: - Tab Bar View Delegate
extension MainViewController: TabBarDelegate {
    func tabBarView(_ tabBarView: TabBarView, viewControllerAtIndex index: Int?) {
        guard let index = index else { return }
        
        showCurrentTab(currentIndex: index)
    }
}

// MARK: - Gesture Recognizer Delegate
extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MainViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
