import Cache
#if !os(Linux) && !os(Windows)
import Combine
import OSLog
#else
import Foundation
#endif

/// `Application` is a class that can be observed for changes, keeping track of the states within the application.
open class Application: NSObject {
    /// Singleton shared instance of `Application`
    static var shared: Application = Application()

    #if !os(Linux) && !os(Windows)
    /// Logger specifically for AppState
    public static let logger: Logger = Logger(subsystem: "AppState", category: "Application")
    #else
    /// Logger specifically for AppState
    public static let logger: ApplicationLogger = ApplicationLogger()
    #endif

    static var isLoggingEnabled: Bool = false

    let lock: NSRecursiveLock

    /// Cache to store values
    let cache: Cache<String, Any>

    #if !os(Linux) && !os(Windows)
    private var bag: Set<AnyCancellable> = Set()

    deinit { bag.removeAll() }
    #endif

    /// Default init used as the default Application, but also any custom implementation of Application. You should never call this function, but instead should use `Application.promote(to: CustomApplication.self)`
    public override required init() {
        lock = NSRecursiveLock()
        cache = Cache()

        super.init()

        #if !os(Linux) && !os(Windows)
        consume(object: cache)
        #endif
    }

    #if !os(Linux) && !os(Windows)
    /// Consumes changes in the provided ObservableObject and sends updates before the object will change.
    ///
    /// - Parameter object: The ObservableObject to observe
    private func consume<Object: ObservableObject>(
        object: Object
    ) where ObjectWillChangePublisher == ObservableObjectPublisher {
        bag.insert(
            object.objectWillChange.sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] _ in
                    self?.objectWillChange.send()
                }
            )
        )
    }
    #endif
}

#if !os(Linux) && !os(Windows)
extension Application: ObservableObject { }
#endif
