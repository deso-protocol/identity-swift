# DeSoIdentity

This library is currently a work in progress.

[x] Login/Logout with DeSo Identity  
[x] Derived Key managament  
[x] Sign & Submit Transacitons with Derived Keys  
[ ] Message Encrypt/Decrypt (Work in progress)  

## Installation

DeSoIdentity is available through [Swift Package Manager](https://www.swift.org/package-manager/). Add DeSoIdentity as a dependency to your Package.swift. For more information, please see the [Swift Package Manager](https://www.swift.org/package-manager/) documentation.

```swift
.package(url: "https://github.com/deso-protocol/identity-swift.git", .branch("rework"))
```

Usage examples to come soon. For now you can take a look at the documentation built into each of the major functions.

All public functions live on the static class **DeSoIdentity**.

###Important Note###

We use CryptoSwift in this library and is and since Swift Package Manager uses debug there known performance issue when running under debug builds. You will see this when trying to encyrpt/decrypt messages. To overcome this you can set your build to release mode while testing encrypt/decrypting messages. Of course, when you release this will not be an issue.
