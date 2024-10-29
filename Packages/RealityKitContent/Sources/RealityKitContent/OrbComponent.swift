import RealityKit
import UIKit

// Ensure you register this component in your app’s delegate using:
// OrbComponent.registerComponent()
public struct OrbComponent: Component, Codable {
    // This is an example of adding a variable to the component.
    var count: Int = 0

    public init() {
    }
}
