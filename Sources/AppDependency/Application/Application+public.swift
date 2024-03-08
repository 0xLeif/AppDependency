import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif

// MARK: Application Functions

public extension Application {
    /// Provides a description of the current application state
    static var description: String {
       """
       {
       \(cacheDescription)
       }
       """
    }

    /**
     This static function promotes the shared singleton instance of the Application class to a custom Application type.

     - Parameters:
        - customApplication: A custom Application subclass to be promoted to.

     - Returns: The type of the custom Application subclass.

     This function is particularly useful when your Application subclass needs to override the `didChangeExternally(notification:)` function. It allows you to extend the functionalities of the Application class and use your custom Application type throughout your application.

     Example:
     ```swift
     class CustomApplication: Application {
         override func didChangeExternally(notification: Notification) {
             super.didChangeExternally(notification: notification)

             // Update UI
             // ...

             // Example updating an ObservableObject that has SyncState inside of it.
             DispatchQueue.main.async {
                 Application.dependency(\.userSettings).objectWillChange.send()
             }

             // Example updating all SyncState in SwiftUI Views.
             DispatchQueue.main.async {
                 self.objectWillChange.send()
             }
         }
     }
     ```

     To use the `promote` function to promote the shared singleton to `CustomApplication`:

     ```swift
     Application.promote(to: CustomApplication.self)
     ```

     In this way, your custom Application subclass becomes the shared singleton instance, which you can then use throughout your application.
     */
    @discardableResult
    static func promote<CustomApplication: Application>(
        to customApplication: CustomApplication.Type
    ) -> CustomApplication.Type {
        NotificationCenter.default.removeObserver(shared)

        let cache = shared.cache
        shared = customApplication.init()
        customApplication.shared = shared

        for (key, value) in cache.allValues {
            shared.cache.set(value: value, forKey: key)
            cache.remove(key)
        }

        return CustomApplication.self
    }

    /// Enables or disabled the default logging inside of Application.
    @discardableResult
    static func logging(isEnabled: Bool) -> Application.Type {
        Application.isLoggingEnabled = isEnabled

        return Application.self
    }
}

// MARK: - Dependency Functions

public extension Application {
    /**
     Use this function to make sure Dependencies are intialized. If a Dependency is not loaded, it will be initialized whenever it is used next.

     - Parameter dependency: KeyPath of the Dependency to be loaded
     - Returns: `Application.self` to allow chaining.
     */
    @discardableResult
    static func load<Value>(
        dependency keyPath: KeyPath<Application, Dependency<Value>>
    ) -> Application.Type {
        shared.load(dependency: keyPath)

        return Application.self
    }

    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the Dependency to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func dependency<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Value {
        log(
            debug: "🔗 Getting Dependency \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return shared.value(keyPath: keyPath).value
    }

    /**
     Overrides the specified `Dependency` with the given value. This is particularly useful for SwiftUI Previews and Unit Tests.
     - Parameters:
        - keyPath: Key path of the dependency to be overridden.
        - value: The new value to override the current dependency.

     - Returns: A `DependencyOverride` object. You should retain this token for as long as you want your override to be effective. Once the token is deallocated or the `cancel()` method is called on it, the original dependency is restored.

     Note: If the `DependencyOverride` object gets deallocated without calling `cancel()`, it will automatically cancel the override, restoring the original dependency.
     */
    static func `override`<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        with value: Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencyOverride {
        let dependency = shared.value(keyPath: keyPath)

        log(
            debug: "🔗 Starting Dependency Override \(String(describing: keyPath)) with \(value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        shared.cache.set(
            value: Dependency(value, scope: dependency.scope),
            forKey: dependency.scope.key
        )

        return DependencyOverride {
            log(
                debug: "🔗 Cancelling Dependency Override \(String(describing: keyPath)) ",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            shared.cache.set(
                value: dependency,
                forKey: dependency.scope.key
            )
        }
    }

    /**
     Retrieves a dependency for the provided `id`. If dependency is not present, it is created once using the provided closure.

     - Parameters:
        - object: The closure returning the dependency.
        - feature: The name of the feature to which the dependency belongs, default is "App".
        - id: The specific identifier for this dependency.
     - Returns: The requested dependency of type `Dependency<Value>`.
     */
    func dependency<Value>(
        _ object: () -> Value,
        feature: String = "App",
        id: String
    ) -> Dependency<Value> {
        let scope = Scope(name: feature, id: id)
        let key = scope.key

        guard let dependency = cache.get(key, as: Dependency<Value>.self) else {
            let value = object()
            let dependency = Dependency(
                value,
                scope: scope
            )

            cache.set(value: dependency, forKey: key)

            return dependency
        }

        return dependency
    }

    /// Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
    func dependency<Value>(
        setup: () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<Value> {
        dependency(
            setup,
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

    /**
     Retrieves a dependency for the provided `id`. If dependency is not present, it is created once using the provided closure.

     - Parameters:
        - object: The closure returning the dependency.
        - feature: The name of the feature to which the dependency belongs, default is "App".
        - id: The specific identifier for this dependency.
     - Returns: The requested dependency of type `Dependency<Value>`.
     */
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> Dependency<Value> {
        dependency(object, feature: feature, id: id)
    }


    /// Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<Value> {
        dependency(
            object(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

#if !os(Linux) && !os(Windows)
// MARK: - SwiftUI Preview Dependency Functions

public extension Application {
    /**
    Use in SwiftUI previews to inject mock dependencies into the content view.
     - Parameters:
        - dependencyOverrides: An array of `Application.override(_, with:)` outputs that you want to use for the preview.
        - content: A closure that returns the View you want to preview.
     - Returns: A View with the overridden dependencies applied.
     */
    @ViewBuilder
    static func preview<Content: View>(
        _ dependencyOverrides: DependencyOverride...,
        content: @escaping () -> Content
    ) -> some View {
        ApplicationPreview(
            dependencyOverrides: dependencyOverrides,
            content: content
        )
    }
}
#endif

// MARK: - DependencySlice Functions

extension Application {
    /**
     This function creates a `DependencySlice` of AppDependency that allows access to a specific part of the AppDependency's dependencies. It provides granular control over the AppDependency.

     - Parameters:
         - dependencyKeyPath: A KeyPath pointing to the dependency in AppDependency that should be sliced.
         - valueKeyPath: A KeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access to a specific part of an AppDependency's state.
     */
    public static func dependencySlice<Value, SliceValue>(
        _ dependencyKeyPath: KeyPath<Application, Dependency<Value>>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencySlice<Value, SliceValue, KeyPath<Value, SliceValue>> {
        let slice = DependencySlice(
            dependencyKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let dependencyKeyPathString = String(describing: dependencyKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🔗 Getting DependencySlice \(dependencyKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     This function creates a `DependencySlice` of AppDependency that allows access to a specific part of the AppDependency's dependencies. It provides granular control over the AppDependency.

     - Parameters:
         - dependencyKeyPath: A KeyPath pointing to the dependency in AppDependency that should be sliced.
         - valueKeyPath: A KeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access to a specific part of an AppDependency's state.
     */
    public static func dependencySlice<Value, SliceValue>(
        _ dependencyKeyPath: KeyPath<Application, Dependency<Value>>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencySlice<Value, SliceValue, WritableKeyPath<Value, SliceValue>> {
        let slice = DependencySlice(
            dependencyKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let dependencyKeyPathString = String(describing: dependencyKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🔗 Getting DependencySlice \(dependencyKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }
}
