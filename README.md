<img src="Screenshots/VoiceItHeaderImage.png">

[![Version](https://img.shields.io/cocoapods/v/VoiceItApi2IosSDK.svg?style=flat)](http://cocoapods.org/pods/VoiceItApi2IosSDK)
[![License](https://img.shields.io/cocoapods/l/VoiceItApi2IosSDK.svg?style=flat)](http://cocoapods.org/pods/VoiceItApi2IosSDK)
[![Platform](https://img.shields.io/cocoapods/p/VoiceItApi2IosSDK.svg?style=flat)](http://cocoapods.org/pods/VoiceItApi2IosSDK)

## VoiceIt API 2.0 iOS SDK

A library that gives you access to the VoiceIt's New VoiceIt API 2.0 featuring Voice + Face Verification and Identification right from your iOS app.

* [Getting Started](#getting-started)
* [Installation](#installation)
* [API Calls](#api-calls)
  * [Initialization](#initialization)
  * [User API Calls](#user-api-calls)
      * [Get All Users](#get-all-users)
      * [Create User](#create-user)
      * [Get User](#create-user)
      * [Get Groups for User](#get-groups-for-user)
      * [Delete User](#delete-user)
  * [Group API Calls](#group-api-calls)
      * [Get All Groups](#get-all-groups)
      * [Create Group](#create-group)
      * [Get Group](#get-group)
      * [Delete Group](#delete-group)
      * [Check group exists](#check-group-exists)
      * [Add User to Group](#add-user-to-group)
      * [Remove User from Group](#remove-user-from-group)      
  * [Enrollment API Calls](#enrollment-api-calls)
      * [Get All Enrollments for User](#get-all-enrollments-for-user)
      * [Delete Enrollment for User](#delete-enrollment-for-user)
      * [Create Audio Enrollment](#create-audio-enrollment)
      * [Create Audio Enrollment by URL](#create-audio-enrollment-by-url)
      * [Create Video Enrollment](#create-video-enrollment)
      * [Create Video Enrollment by URL](#create-video-enrollment-by-url)
  * [Verification API Calls](#verification-api-calls)
      * [Audio Verification](#audio-verification)
      * [Audio Verification by URL](#audio-verification-by-url)
      * [Video Verification](#video-verification)
      * [Video Verification by URL](#video-verification-by-url)
  * [Identification API Calls](#identification-api-calls)
      * [Audio Identification](#audio-identification)
      * [Audio Identification by URL](#audio-identification-by-url)
      * [Video Identification](#video-identification)
      * [Video Identification by URL](#video-identification-by-url)

## Getting Started

Get a Developer Account at <a href="https://siv.voiceprintportal.com/getDeveloperIDTile.jsp" target="_blank">VoiceIt</a> and activate API 2.0 from the settings page, you should now be able view the API Key and Token (as shown below). Also review the HTTP Documentation at <a href="https://api.voiceit.io" target="_blank">api.voiceit.io</a>

<img src="Screenshots/Screenshot1.png" alt="API Key and Token" width="400px" style="margin:auto;display:block"/>

## Installation

VoiceItApi2IosSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "VoiceItApi2IosSDK"
```

and then run pod install in your terminal

```bash
pod install
```

Also add the following permission keys to your <b>info.plist</b> file like shown below:

* NSCameraUsageDescription - Needed for Face Biometrics
* NSMicrophoneUsageDescription - Needed for Voice Biometrics

<img src="Screenshots/Screenshot2.png" alt="API Key and Token" width="400px" style="margin:auto;display:block"/>

## API Calls

### Initialization

#### *Swift*

First import VoiceItApi2IosSDK into your Swift file then initialize a reference to the SDK inside a ViewController passing in a reference to the ViewController as the first argument

```swift
import VoiceItApi2IosSDK

class ViewController: UIViewController {
    var myVoiceIt:VoiceItAPITwo?

    override func viewDidLoad() {
        super.viewDidLoad()
        /* Reference to ViewController and API Credentials */
        myVoiceIt  = VoiceItAPITwo(self, apiKey: "API_KEY_HERE", apiToken: "API_TOKEN_HERE")
    }
}
```
#### *Objective-C*

First import VoiceItAPITwo.h into your Objective-C file, then initialize a reference to the SDK inside a ViewController passing in a reference to the ViewController as the first argument

```objc
#import "ViewController.h"
#import "VoiceItAPITwo.h"

@interface ViewController ()
    @property VoiceItAPITwo * myVoiceIt;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _myVoiceIt = [[VoiceItAPITwo alloc] init:self apiKey:@"API_KEY_HERE" apiToken:@"API_TOKEN_HERE"];
}
```

### User API Calls

#### Get All Users

Get all the users associated with the apiKey
##### *Swift*
```swift
myVoiceIt?.getAllUsers({
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
#### *Objective-C*
```objc
[_myVoiceIt getAllUsers:^(NSString * jsonResult){
    NSLog(@"JSONResponse: %@", jsonResult);
}];
```

#### Create User

Create a new user
##### *Swift*
```swift
myVoiceIt?.createUser({
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[_myVoiceIt createUser:^(NSString * jsonResult){
    NSLog(@"JSONResponse: %@", jsonResult);
}];
```

#### Get User

Check whether a user exists for the given userId(begins with 'usr_')
##### *Swift*
```swift
myVoiceIt?.getUser("USER_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[_myVoiceIt getUser:@"USER_ID_HERE" callback:^(NSString * jsonResult){
    NSLog(@"JSONResponse: %@", jsonResult);
}];
```

#### Get Groups for User

Get a list of groups that the user with given userId(begins with 'usr_') is a part of
##### *Swift*
```swift
myVoiceIt?.getGroupsForUser("USER_ID_HERE", callback: {
                jsonResponse in
                print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[_myVoiceIt getGroupsForUser:@"USER_ID_HERE" callback:^(NSString * jsonResult){
    NSLog(@"JSONResponse: %@", jsonResult);
}];
```
Rest of the Documentation Coming Soon!!

## Author

armaanbindra, armaan.bindra@voiceit-tech.com

## License

VoiceItApi2IosSDK is available under the MIT license. See the LICENSE file for more info.
