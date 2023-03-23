# CircleAccessLock

CircleAccessLock is a package that allows you to display a lock screen using Circle Technology.

## Installation

To install CircleAccessLock in your project, follow these steps:

1. In Xcode, open your project and select File > Swift Packages > Add Package Dependency.
2. In the search bar, paste the following URL: `https://github.com/circlesystems/CircleAccessLock`
3. Select the version you want to install.
4. Click Next.
5. Choose your options.
6. Click Finish.

## Usage

1. Import the package in your file:

```swift
import CircleAccessLock

// Initialize the CircleAccessLock object in your main UIViewController:
let circleAccessLock = CircleAccessLock(parentViewController: self)
````

Customize the CircleAccessLock object:

```swift
// Disable CircleAccessLock
circleAccessLock.disable()

// Enable CircleAccessLock
circleAccessLock.enable()
