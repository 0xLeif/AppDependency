# AppDependency

AppDependency is a Swift Package that simplifies the management of application dependencies in a thread-safe, type-safe, and SwiftUI-friendly way. Featuring dedicated struct types for managing dependencies, AppDependency provides easy and coordinated access to this state across your application. Added to this, the package incorporates built-in logging mechanisms to aid debugging and error tracking. The AppDependency package also boasts a cache-based system to persistently store and retrieve any application-wide data at any given time.

**Requirements:** iOS 15.0+ / watchOS 8.0+ / macOS 11.0+ / tvOS 15.0+ / visionOS 1.0+ | Swift 5.9+ / Xcode 15+

**Non Apple Platform Support:** Linux & Windows

## Key Features

(🍎 Apple OS only)

### Dependency Management

- **Dependency:** Struct for encapsulating dependencies within the app's scope.
- **Scope:** Represents a specific context within an app, defined by a unique name and ID.

### Fine-Grained Control

- **DependencySlice:** Struct that provides access to and modification of specific AppDependency's dependency parts.

### Property Wrappers

- **AppDependency:** Simplifies the handling of dependencies throughout your application.
- 🍎 **ObservedDependency:** Simplifies the handling of dependencies throughout your application. Dependencies must conform to ObservableObject. Backed by an `@ObservedObject` to publish changes to SwiftUI views.
- **DependencySlice:** Allows users to access and modify a specific part of AppDependency's dependency.
- **DependencyConstant:** Allows users to access a specific part of AppDependency's dependency.

## Getting Started

To integrate AppDependency into your Swift project, you'll need to use the Swift Package Manager (SPM). SPM makes it easy to manage Swift package dependencies. Here's what you need to do:

1. Add a package dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppDependency.git", from: "1.0.0")
]
```

If you're working with an App project, open your project in Xcode. Navigate to `File > Swift Packages > Add Package Dependency...` and enter `https://github.com/0xLeif/AppDependency.git`.

2. Next, don't forget to add AppDependency as a target to your project. This step is necessary for both Xcode and SPM Package.swift.

After successfully adding AppDependency as a dependency, you need to import AppDependency into your Swift file where you want to use it. Here's a code example:

```swift
import AppDependency
```

## Usage

### Defining Dependencies

`Dependency` is a feature provided by AppDependency, allowing you to define shared resources or services in your application.

To define a dependency, you should extend the `Application` object. Here's an example of defining a `networkService` dependency:

```swift
extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

In this example, `Dependency<NetworkServiceType>` represents a type safe container for `NetworkService`.

### Reading and Using Dependencies

Once you've defined a dependency, you can access it anywhere in your app:

```swift
let networkService = Application.dependency(\.networkService)
```

This approach allows you to work with dependencies in a type-safe manner, avoiding the need to manually handle errors related to incorrect types.

### AppDependency Property Wrapper

AppDependency provides the `@AppDependency` property wrapper that simplifies access to dependencies. When you annotate a property with `@AppDependency`, it fetches the appropriate dependency from the `Application` object directly.

```swift
struct ContentView: View {
    @AppDependency(\.networkService) var networkService

    // Your view code
}
```

In this case, ContentView has access to the networkService dependency and can use it within its code.

### Using Dependency with ObservableObject

When your dependency is an `ObservableObject`, any changes to it will automatically update your SwiftUI views. Make sure your service conforms to the `ObservableObject` protocol. To do this, you should not use the `@AppDependency` property wrapper, but instead use the `@ObservedDependency` property wrapper. 

Here's an example:

```swift
class DataService: ObservableObject {
    @Published var data: [String]

    func fetchData() { ... }
}

extension Application {
    var dataService: Dependency<DataService> {
        dependency(DataService())
    }
}

struct ContentView: View {
    @ObservedDependency(\.dataService) private var dataService

    var body: some View {
        List(dataService.data, id: \.self) { item in
            Text(item)
        }
        .onAppear {
            dataService.fetchData()
        }
    }
}
```

In this example, whenever data in `DataService` changes, SwiftUI automatically updates the `ContentView`.

### Testing with Mock Dependencies

One of the great advantages of using `Dependency` in AppDependency is the capability to replace dependencies with mock versions during testing. This is incredibly useful for isolating parts of your application for unit testing. 

You can replace a dependency by calling the `Application.override` function. This function returns a `DependencyOverride`, you'll want to hold onto this token for as long as you want the mock dependency to be effective. When the token is deallocated, the dependency reverts back to its original condition.

Here's an example:

```swift
// Real network service
extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}

// Mock network service
class MockNetworkService: NetworkServiceType {
    // Your mock implementation
}

func testNetworkService() {
    // Keep hold of the `DependencyOverride` for the duration of your test.
    let networkOverride = Application.override(\.networkService, with: MockNetworkService())

    let mockNetworkService = Application.dependency(\.networkService)
    
    // Once done, you can allow the `DependencyOverrideen` to be deallocated 
    // or call `networkOverride.cancel()` to revert back to the original service.
}
```

## Promoting the Application

In AppDependency, you have the ability to promote your custom Application subclass to a shared singleton instance. This can be particularly useful when your Application subclass needs to conform to a protocol.

Here's an example of how to use the `promote` function:

```swift
class CustomApplication: Application {
    func customFunction() { ... }
}

Application.promote(to: CustomApplication.self)
```


## License

AppDependency is released under the MIT License. See [LICENSE](https://github.com/0xLeif/AppDependency/blob/main/LICENSE) for more information.

## Communication and Contribution

- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.
