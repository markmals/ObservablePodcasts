import UIKit
import SwiftSignal

public typealias Accessor<T> = () -> T

public protocol UXView<NativeView> {
    associatedtype NativeView: UIView
    var nativeView: NativeView { get }
}

extension UXView {
    @discardableResult
    public func layout(@NSLayoutConstraint.Builder using configuration: (UIView) -> [NSLayoutConstraint]) -> Self {
        nativeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(configuration(nativeView))
        return self
    }
    
    @discardableResult
    public func frame(width: CGFloat? = nil, height: CGFloat? = nil) -> Self {
        return layout {
            if let width = width {
                $0.widthAnchor.constraint(equalToConstant: width)
            }
            
            if let height = height {
                $0.heightAnchor.constraint(equalToConstant: height)
            }
        }
    }
    
    @discardableResult
    public func frame(_ size: CGFloat? = nil) -> Self {
        frame(width: size, height: size)
    }
    
    @discardableResult
    public func margins(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) -> Self {
        var margins = nativeView.layoutMargins
        margins.top = top ?? margins.top
        margins.left = left ?? margins.left
        margins.bottom = bottom ?? margins.bottom
        margins.right = right ?? margins.right
        nativeView.layoutMargins = margins
        
        return self
    }
    
    public func pin(to guide: UILayoutGuide, insets: UIEdgeInsets = .zero) {
        guard nativeView.superview != nil else {
            return
        }
        
        layout {
            $0.topAnchor == guide.topAnchor + insets.top
            $0.bottomAnchor == guide.bottomAnchor - insets.bottom
            $0.leftAnchor == guide.leftAnchor + insets.left
            $0.rightAnchor == guide.rightAnchor - insets.right
        }
    }
    
    public func pin(to pinningView: some UXView, insets: UIEdgeInsets = .zero) {
        guard nativeView.superview != nil else {
            return
        }
        
        layout {
            $0.topAnchor == pinningView.nativeView.topAnchor + insets.top
            $0.bottomAnchor == pinningView.nativeView.bottomAnchor - insets.bottom
            $0.leftAnchor == pinningView.nativeView.leftAnchor + insets.left
            $0.rightAnchor == pinningView.nativeView.rightAnchor - insets.right
        }
    }
    
}

extension UIView: UXView {
    public typealias NativeView = UIView
    public var nativeView: Self {
        return self
    }
}

open class UIViewRepresentable<NativeView: UIView>: UXView {
    public var nativeView: NativeView
    var disposables: [DisposeAction] = []
    
    init(_ nativeView: NativeView) {
        self.nativeView = nativeView
    }
    
    deinit { disposables.forEach { $0() } }
    
    func bind<T>(_ value: @escaping Accessor<T>, to render: @escaping (T) -> Void) {
        disposables.append(createEffect {
            let v = value()
            Task { @MainActor in render(v) }
            return nil
        })
    }
    
    func effect(_ action: @escaping () -> Void) {
        disposables.append(createEffect {
            action()
            return nil
        })
    }
}

open class UXLabel: UIViewRepresentable<UILabel> {
    public init(_ text: @escaping @autoclosure Accessor<String>) {
        super.init(UILabel())
        nativeView.text = text()
        bind(text, to: { self.nativeView.text = $0 })
    }
    
    public func font(_ font: @escaping @autoclosure Accessor<UIFont>) -> Self {
        bind(font, to: { self.nativeView.font = $0 })
        return self
    }
    
    public func textColor(_ color: @escaping @autoclosure Accessor<UIColor>) -> Self {
        bind(color, to: { self.nativeView.textColor = $0 })
        return self
    }
    
    public func numberOfLines(_ lines: @escaping @autoclosure Accessor<Int>) -> Self {
        bind(lines, to: { self.nativeView.numberOfLines = $0 })
        return self
    }
    
    public func lineBreakMode(_ mode: @escaping @autoclosure Accessor<NSLineBreakMode>) -> Self {
        bind(mode, to: { self.nativeView.lineBreakMode = $0 })
        return self
    }
}

@resultBuilder
public struct UXViewBuilder {
    public static func buildBlock(_ views: any UXView...) -> [any UXView] {
        views
    }
    
    public static func buildBlock(_ view: any UXView) -> any UXView {
        view
    }
    
    public static func buildBlock(_ view: any UXView) -> [any UXView] {
        [view]
    }
    
    public static func buildExpression(_ view: any UXView) -> any UXView {
        view
    }
    
    public static func buildExpression(_ view: [any UXView]) -> [any UXView] {
        view
    }
    
    //    public static func buildOptional(_ view: (any UXView)?) -> any UXView {
    //        view ?? UIView()
    //    }
    
    //        public static func buildOptional(_ views: [UIView]?) -> [UIView] {
    //            views ?? []
    //        }
    
    public static func buildEither(first views: [any UXView]) -> [any UXView] {
        views
    }
    
    public static func buildEither(second views: [any UXView]) -> [any UXView] {
        views
    }
}

open class UXStackView<Child: UXView>: UIViewRepresentable<UIStackView> {
    public init(
        axis: @escaping @autoclosure Accessor<NSLayoutConstraint.Axis> = .horizontal,
        alignment: @escaping @autoclosure Accessor<UIStackView.Alignment> = .fill,
        spacing: @escaping @autoclosure Accessor<CGFloat> = 0.0,
        @UXViewBuilder children: @escaping Accessor<[Child]>
    ) {
        super.init(UIStackView())
        
        effect {
            let _axis = axis()
            let _alignment = alignment()
            let _spacing = spacing()
            
            Task { @MainActor in
                self.nativeView.axis = _axis
                self.nativeView.alignment = _alignment
                self.nativeView.spacing = _spacing
            }
        }
        
        effect {
            let _children = children()
            
            Task { @MainActor in
                self.replaceArrangedSubviews(with: _children.map { $0.nativeView })
            }
        }
    }
    
    private func removeAllArrangedSubviews() {
        let removedSubviews = nativeView.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            nativeView.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
    
    private func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach { nativeView.addArrangedSubview($0) }
    }
    
    private func replaceArrangedSubviews(with subviews: [UIView]) {
        removeAllArrangedSubviews()
        addArrangedSubviews(subviews)
    }
    
    public func distribution(_ distribution: @escaping @autoclosure Accessor<UIStackView.Distribution>) -> Self {
        bind(distribution, to: { self.nativeView.distribution = $0 })
        return self
    }
    
    public func layoutMarginsRelativeArrangement(
        _ isLayoutMarginsRelativeArrangement: @escaping @autoclosure Accessor<Bool>
    ) -> Self {
        bind(isLayoutMarginsRelativeArrangement, to: { self.nativeView.isLayoutMarginsRelativeArrangement = $0 })
        return self
    }
    
    public func backgroundColor(_ color: @escaping @autoclosure Accessor<UIColor>) -> Self {
        bind(color, to: { self.nativeView.backgroundColor = $0 })
        return self
    }
}

open class UXImageView: UIViewRepresentable<UIImageView> {
    public init(_ image: @escaping @autoclosure Accessor<UIImage?>) {
        super.init(UIImageView())
        bind(image, to: { self.nativeView.image = $0 })
    }
    
    public func contentMode(_ contentMode: @escaping @autoclosure Accessor<UIView.ContentMode>) -> Self {
        bind(contentMode, to: { self.nativeView.contentMode = $0 })
        return self
    }
}

public protocol Component: UXView {
    associatedtype View: UXView
    associatedtype NativeView = View.NativeView
    
    @UXViewBuilder func render() -> View
}

extension Component {
    var nativeView: View.NativeView {
        render().nativeView
    }
}

struct PodcastListItem: Component {
    let podcast: Accessor<Podcast>
    
    public init(podcast: @escaping @autoclosure Accessor<Podcast>) {
        self.podcast = podcast
    }
    
    func render() -> some UXView {
        UXStackView(axis: .horizontal, alignment: .center, spacing: 15) {
            UXImageView(podcast().image).frame(88)
            
            UXStackView(axis: .vertical, alignment: .leading, spacing: 5) {
                UXLabel(podcast().name)
                    .font(.preferredFont(forTextStyle: .headline))
                    .numberOfLines(2)
                    .lineBreakMode(.byTruncatingTail)
                //                    .layout { $0.trailingAnchor == self.labelStack?.trailingAnchor - 15 }
                
                UXLabel(podcast().creator)
                    .font(.preferredFont(forTextStyle: .subheadline))
                    .textColor(.secondaryLabel)
                    .lineBreakMode(.byTruncatingTail)
                //                    .layout { $0.trailingAnchor == self.nameLabel?.trailingAnchor }
            }
            .distribution(.equalSpacing)
            .layoutMarginsRelativeArrangement(true)
        }
        .backgroundColor(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
        })
    }
}

//final class PodcastViewModel {
//    var searchText = ""
//}

//@MainActor public protocol UIContentView : NSObjectProtocol {
//    @MainActor var configuration: any UIContentConfiguration { get set }
//    @MainActor func supports(_ configuration: any UIContentConfiguration) -> Bool
//}
//
//public protocol UIContentConfiguration {
//    @MainActor func makeContentView() -> any UIView & UIContentView
//    func updated(for state: any UIConfigurationState) -> Self
//}

extension UIViewController {
    func bind<T>(_ value: @escaping Accessor<T>, to render: @escaping (T) -> Void) {
        disposables.append(createEffect {
            let v = value()
            Task { @MainActor in render(v) }
            return nil
        })
    }
    
    func effect(_ action: @escaping () -> Void) {
        disposables.append(createEffect {
            action()
            return nil
        })
    }
    
    var disposables: [DisposeAction] {
        get {
            objc_getAssociatedObject(self, disposablesKey) as? [DisposeAction]
            ?? []
        }
        set {
            objc_setAssociatedObject(
                self, disposablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

@MainActor
private let disposablesKey = malloc(1)!

import ConcurrencyExtras

@MainActor protocol UXControl: UIControl {}
extension UIControl: UXControl {}

extension UXControl {
    @discardableResult
    public func on(_ event: UIControl.Event, _ perform: @escaping () -> Void) -> Self {
        addAction(UIAction { _ in perform() }, for: event)
        return self
    }
    
    @discardableResult
    public func assign<Value>(
        _ binding: @escaping @autoclosure Accessor<Value>,
        to keyPath: ReferenceWritableKeyPath<Self, Value>
    ) -> DisposeAction {
        unassign(keyPath)
        
        let dispose = createEffect {
            self[keyPath: keyPath] = binding()
            return nil
        }
        
        disposables[keyPath] = dispose
        return dispose
    }
    
    public func unassign<Value>(_ keyPath: KeyPath<Self, Value>) {
        disposables[keyPath]?()
        disposables[keyPath] = nil
    }
    
    var disposables: [AnyKeyPath: DisposeAction] {
        get {
            objc_getAssociatedObject(self, uiControlDisposablesKey) as? [AnyKeyPath: DisposeAction]
            ?? [:]
        }
        set {
            objc_setAssociatedObject(
                self, uiControlDisposablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

@MainActor
private let uiControlDisposablesKey = malloc(1)!


extension UISearchBar {
    convenience init(frame: CGRect = .zero, text: @escaping @autoclosure Accessor<String>) {
        self.init(frame: frame)
        self.searchTextField.assign(text(), to: \.text)
    }
    
    public func bind(to text: @escaping @autoclosure Accessor<String>) {
        self.searchTextField.assign(text(), to: \.text)
    }
    
    @discardableResult
    public func on(_ event: UIControl.Event, _ perform: @escaping () -> Void) -> Self {
        searchTextField.on(event, perform)
        return self
    }
}

extension UISearchController {
    convenience init(text: @escaping @autoclosure Accessor<String>) {
        self.init()
        self.searchBar.bind(to: text())
    }
    
    @discardableResult
    public func on(_ event: UIControl.Event, _ perform: @escaping () -> Void) -> Self {
        searchBar.on(event, perform)
        return self
    }
}

final class PodcastCollectionViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Podcast>
    private let cellRegistration = UICollectionView.CellRegistration { cell, indexPath, podcast in
        cell.contentConfiguration = podcast
    }
    private lazy var dataSource = DataSource(collectionView: collectionView) {
        (collectionView, indexPath, itemIdentifier) in
        collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: itemIdentifier
        )
    }
    
    let searchText = Signal(initialValue: "")
    @ViewLoading private var searchController: UISearchController
    
    private let manager = PodcastManager()
    private var podcastFetchTask: Task<Void, Never>?
    
    convenience init() {
        self.init(collectionViewLayout:
                    UICollectionViewCompositionalLayout.list(
                        using: .init(appearance: .insetGrouped)
                    )
        )
        
        self.title = "Podcasts"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposables.forEach { $0() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(text: self.searchText())
        searchController.on(.editingChanged) {
            self.searchText.write(self.searchController.searchBar.text ?? "")
        }
        
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = dataSource
        
        effect {
            self.podcastFetchTask?.cancel()
            let text = self.searchText()
            
            self.podcastFetchTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(3))
                if let podcasts = try? await self.manager.search(for: text) {
                    var snapshot = NSDiffableDataSourceSnapshot<Int, Podcast>()
                    snapshot.appendSections([0])
                    snapshot.appendItems(podcasts)
                    await self.dataSource.apply(snapshot)
                }
            }
        }
    }
}
