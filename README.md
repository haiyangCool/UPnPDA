# UPnPDA

[![CI Status](https://img.shields.io/travis/haiyangCool/UPnPDA.svg?style=flat)](https://travis-ci.org/haiyangCool/UPnPDA)
[![Version](https://img.shields.io/cocoapods/v/UPnPDA.svg?style=flat)](https://cocoapods.org/pods/UPnPDA)
[![License](https://img.shields.io/cocoapods/l/UPnPDA.svg?style=flat)](https://cocoapods.org/pods/UPnPDA)
[![Platform](https://img.shields.io/cocoapods/p/UPnPDA.svg?style=flat)](https://cocoapods.org/pods/UPnPDA)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

UPnPDA is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'UPnPDA'
```
## Usage

Search UPnP Service

```swift 
lazy var serviceSearcher: UPnPServiceSearch = {
    let search = UPnPServiceSearch()
    search.searchTarget = M_SEARCH_Targert.all()
    search.delegate = self
    return search
}()
```
And in Delegate methods you can get the result

```swift
func serviceSearch(_ serviceSearch: UPnPServiceSearch, upnpDevices devices: [UPnPDeviceDescriptionDocument]) {
    /// the device list
}

func serviceSearch(_ serviceSearch: UPnPServiceSearch, dueTo error: Error) {
    print(" Search Occur Error \(error)")
}
```

you can find some DLNA details in Demo 

## Author

haiyangCool, haiyang_wang_cool@126.com

## License

UPnPDA is available under the MIT license. See the LICENSE file for more info.
