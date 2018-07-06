<img src="https://raw.githubusercontent.com/voiceittech/VoiceItApi2IosSDK/master/Graphics/VoiceItAPI2ioSSDKHeaderImage.png" width="100%" style="width:100%">

[![Version](https://img.shields.io/cocoapods/v/VoiceItApi2IosSDK.svg?style=flat)](http://cocoapods.org/pods/VoiceItApi2IosSDK)
[![License](https://img.shields.io/cocoapods/l/VoiceItApi2IosSDK.svg?style=flat)](http://cocoapods.org/pods/VoiceItApi2IosSDK)
[![Platform](https://img.shields.io/cocoapods/p/VoiceItApi2IosSDK.svg?style=flat)](http://cocoapods.org/pods/VoiceItApi2IosSDK)
<!-- [![Build Status](https://travis-ci.org/voiceittech/VoiceItApi2IosSDK.svg?branch=master)](https://travis-ci.org/voiceittech/VoiceItApi2IosSDK) -->

A fully comprehensive SDK that gives you access to VoiceIt's API 2.0 featuring Voice + Face Verification and Identification right from your iOS app. Now with client - side basic liveness detection.

* [Getting Started](#getting-started)
* [Installation](#installation)
* [Strings and Prompts](#strings-and-prompts)
* [API Calls](#api-calls)
  * [Initialization](#initialization)
  * [User API Calls](#user-api-calls)
      * [Get All Users](#get-all-users)
      * [Create User](#create-user)
      * [Get User](#get-user)
      * [Get Groups for User](#get-groups-for-user)
      * [Delete User](#delete-user)
  * [Group API Calls](#group-api-calls)
      * [Get All Groups](#get-all-groups)
      * [Create Group](#create-group)
      * [Get Group](#get-group)
      * [Delete Group](#delete-group)
      * [Group exists](#group-exists)
      * [Add User to Group](#add-user-to-group)
      * [Remove User from Group](#remove-user-from-group)      
  * [Enrollment API Calls](#enrollment-api-calls)
      * [Get All Enrollments for User](#get-all-enrollments-for-user)
      * [Delete Enrollment for User](#delete-enrollment-for-user)
      * [Create Voice Enrollment](#create-voice-enrollment)
      * [Create Face Enrollment](#create-face-enrollment)
      * [Create Video Enrollment](#create-video-enrollment)
      * [Encapsulated Voice Enrollment](#encapsulated-voice-enrollment)
      * [Encapsulated Face Enrollment](#encapsulated-face-enrollment)
      * [Encapsulated Video Enrollment](#encapsulated-video-enrollment)
  * [Verification API Calls](#verification-api-calls)
      * [Voice Verification](#voice-verification)
      * [Face Verification](#face-verification)
      * [Video Verification](#video-verification)
      * [Encapsulated Voice Verification](#encapsulated-voice-verification)
      * [Encapsulated Face Verification](#encapsulated-face-verification)
      * [Encapsulated Video Verification](#encapsulated-video-verification)
  * [Identification API Calls](#identification-api-calls)
      * [Voice Identification](#voice-identification)
      * [Video Identification](#video-identification)

## Getting Started

Get a Developer Account at <a href="https://voiceit.io/signup" target="_blank">VoiceIt</a> and activate API 2.0 from the settings page, you should now be able view the API Key and Token (as shown below). Also review the HTTP Documentation at <a href="https://api.voiceit.io" target="_blank">api.voiceit.io</a>. All the documentation shows code snippets in both Swift 3 and Objective-C.

<img src="Graphics/Screenshot1.png" alt="API Key and Token" width="400px" />

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

<img src="Graphics/Screenshot2.png" alt="API Key and Token" width="400px" style="margin:auto;display:block"/>

## Strings and Prompts

All strings utilized in the encapsulated views for the SDK and the prompts provided to the user can be modified by editing the strings in the Prompts.strings file located at

```
Pods/VoiceItApi2IosSDK/Resources/Prompts.strings
```
You might have to unlock the Cocoapod to edit the file.

## API Calls

### Initialization

#### *Swift*

First import *VoiceItApi2IosSDK* into your Swift file then initialize a reference to the SDK inside a ViewController passing in a reference to the ViewController as the first argument, then the API Credentials and finally a styles dictionary ( *kThemeColor* can be any hexadecimal color code and *kIconStyle* can be "default" or "monochrome").

```swift
import VoiceItApi2IosSDK

class ViewController: UIViewController {
    var myVoiceIt:VoiceItAPITwo?

    override func viewDidLoad() {
        super.viewDidLoad()
        /* Reference to ViewController , API Credentials and styles dictionary*/
        let styles = NSMutableDictionary(dictionary: ["kThemeColor":"#FBC132","kIconStyle":"default"])
        myVoiceIt  = VoiceItAPITwo(self, apiKey: "API_KEY_HERE", apiToken: "API_TOKEN_HERE", styles: styles)
    }
}
```
#### *Objective-C*

First import *VoiceItAPITwo.h* into your Objective-C file, then initialize a reference to the SDK inside a ViewController passing in a reference to the ViewController as the first argument

```objc
#import "ViewController.h"
#import "VoiceItAPITwo.h"

@interface ViewController ()
    @property VoiceItAPITwo * myVoiceIt;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /* Reference to ViewController , API Credentials and styles dictionary*/
    NSMutableDictionary * styles = [[NSMutableDictionary alloc] init];
    [styles setObject:@"#FBC132" forKey:@"kThemeColor"];
    [styles setObject:@"default" forKey:@"kIconStyle"];
    self.myVoiceIt = [[VoiceItAPITwo alloc] init:self apiKey:@"API_KEY_HERE" apiToken:@"API_TOKEN_HERE" styles: styles];
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
##### *Objective-C*
```objc
[self.myVoiceIt getAllUsers:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
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
[self.myVoiceIt createUser:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Check if a Specific User Exists

Check whether a user exists for the given userId(begins with 'usr_')
##### *Swift*
```swift
myVoiceIt?.checkUserExists("USER_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[self.myVoiceIt checkUserExists:@"USER_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Delete a Specific User

Delete user with given userId(begins with 'usr_')
##### *Swift*
```swift
myVoiceIt?.deleteUser("USER_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[self.myVoiceIt deleteUser:@"USER_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
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
[self.myVoiceIt getGroupsForUser:@"USER_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

### Group API Calls

#### Get All Groups

Get all the groups associated with the apiKey
##### *Swift*
```swift
myVoiceIt?.getAllGroups({
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[self.myVoiceIt getAllGroups:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Get a Specific Group

Returns a group for the given groupId(begins with 'grp_')
##### *Swift*
```swift
myVoiceIt?.getGroup("GROUP_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[self.myVoiceIt getGroup:@"GROUP_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Check if Group Exists

Checks if group with given groupId(begins with 'grp_') exists
##### *Swift*
```swift
myVoiceIt?.groupExists("GROUP_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt groupExists:@"GROUP_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Create Group

Create a new group with the given description
##### *Swift*
```swift
myVoiceIt?.createGroup("A Sample Group Description", callback: {
    jsonResponse in
})
```
##### *Objective-C*
```objc
[self.myVoiceIt createGroup:@"A Sample Group Description" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Add User to Group

Adds user with given userId(begins with 'usr_') to group with given groupId(begins with 'grp_')
##### *Swift*
```swift
myVoiceIt?.addUser(toGroup: "GROUP_ID_HERE", userId: "USER_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt addUserToGroup:@"GROUP_ID_HERE" userId:@"USER_ID_HERE" callback:^(NSString * jsonResponse){
            NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Remove User from Group

Removes user with given userId(begins with 'usr_') from group with given groupId(begins with 'grp_')
##### *Swift*
```swift
myVoiceIt?.removeUser(fromGroup: "GROUP_ID_HERE", userId: "USER_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt removeUserFromGroup:@"GROUP_ID_HERE" userId:@"USER_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Delete Group

Delete group with given groupId(begins with 'grp_'), note: this call does not delete any users, but simply deletes the group and disassociates the users from the group
##### *Swift*
```swift
myVoiceIt?.deleteGroup("GROUP_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```
##### *Objective-C*
```objc
[self.myVoiceIt deleteGroup:@"GROUP_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

### Enrollment API Calls

#### Get All Enrollments for User

Gets all enrollment for user with given userId(begins with 'usr_')
##### *Swift*
```swift
myVoiceIt?.getAllEnrollments(forUser: "USER_ID_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt getAllEnrollmentsForUser:@"USER_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Delete Enrollment for User

Delete enrollment for user with given userId(begins with 'usr_') and enrollmentId(integer)
##### *Swift*
```swift
myVoiceIt?.deleteEnrollment(forUser: "USER_ID_HERE", enrollmentId: "ENROLLMENT_ID_HERE", callback: {
    jsonResponse in
})
```

##### *Objective-C*
```objc
[self.myVoiceIt deleteEnrollmentForUser:@"USER_ID_HERE" enrollmentId:@"ENROLLMENT_ID_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
}];
```

#### Create Voice Enrollment

Create voice enrollment for user with given userId(begins with 'usr_') , contentLanguage('en-US','es-ES' etc.) and audio file.
##### *Swift*
```swift
myVoiceIt?.createVoiceEnrollment("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", audioPath: "FILE_PATH_TO_VOICE_ENROLLMENT_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt createVoiceEnrollment:@"USER_ID_HERE" contentLanguage: @"CONTENT_LANGUAGE_HERE" audioPath: @"FILE_PATH_TO_VOICE_ENROLLMENT_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Create Face Enrollment

Create face enrollment for user with given userId(begins with 'usr_') and video file.
##### *Swift*
```swift
myVoiceIt?.createFaceEnrollment("USER_ID_HERE", videoPath: "FILE_PATH_TO_FACE_ENROLLMENT_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt createVideoEnrollment:@"USER_ID_HERE" videoPath: @"FILE_PATH_TO_FACE_ENROLLMENT_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Create Video Enrollment

Create video enrollment for user with given userId(begins with 'usr_') , contentLanguage('en-US','es-ES' etc.) and video file.
##### *Swift*
```swift
myVoiceIt?.createVideoEnrollment("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", videoPath: "FILE_PATH_TO_VIDEO_ENROLLMENT_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt createVideoEnrollment:@"USER_ID_HERE" contentLanguage: @"CONTENT_LANGUAGE_HERE" videoPath: @"FILE_PATH_TO_VIDEO_ENROLLMENT_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Encapsulated Voice Enrollment

Create three voice enrollments for user with the given userId(begins with 'usr_') and contentLanguage('en-US','es-ES' etc.) and a given phrase such as "my face and voice identify me". Note: Immediately upon calling this method it displays the user and enrollment view controller that completely takes care of the three enrollments, including the UI and then provides relevant callbacks for whether the user cancelled their enrollments or successfully completed them.

##### *Swift*
```swift
myVoiceIt?.encapsulatedVoiceEnrollUser("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", voicePrintPhrase: "my face and voice identify me", userEnrollmentsCancelled: {
print("User Enrollment Cancelled")
}, userEnrollmentsPassed: {
print("User Enrollments Passed")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt encapsulatedVoiceEnrollUser:@"USER_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" voicePrintPhrase:@"my face and voice identify me" userEnrollmentsCancelled:^{
NSLog(@"User Enrollments Cancelled");
} userEnrollmentsPassed:^{
NSLog(@"User Enrollments Passed");
}];
```

#### Encapsulated Face Enrollment

Create a face enrollment for user with the given userId(begins with 'usr_'). Note: Immediately upon calling this method it displays the user and enrollment view controller that completely takes care of enrolling the user's face, including the UI and then provides relevant callbacks for whether the user cancelled their enrollment or successfully completed it.

##### *Swift*
```swift
myVoiceIt?.encapsulatedFaceEnrollUser("USER_ID_HERE", userEnrollmentsCancelled: {
  print("User Enrollment Cancelled")
}, userEnrollmentsPassed: {
  print("User Enrollments Passed")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt encapsulatedFaceEnrollUser:@"USER_ID_HERE" userEnrollmentsCancelled:^{
      NSLog(@"User Enrollments Cancelled");
  } userEnrollmentsPassed:^{
      NSLog(@"User Enrollments Passed");
  }];
```

#### Encapsulated Video Enrollment

Create three video enrollments for user with the given userId(begins with 'usr_') and contentLanguage('en-US','es-ES' etc.) and a given phrase such as "my face and voice identify me". Note: Immediately upon calling this method it displays the user and enrollment view controller that completely takes care of the three enrollments, including the UI and then provides relevant callbacks for whether the user cancelled their enrollments or successfully completed them.

##### *Swift*
```swift
myVoiceIt?.encapsulatedVideoEnrollUser("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", voicePrintPhrase: "my face and voice identify me", userEnrollmentsCancelled: {
  print("User Enrollment Cancelled")
}, userEnrollmentsPassed: {
  print("User Enrollments Passed")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt encapsulatedVideoEnrollUser:@"USER_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" voicePrintPhrase:@"my face and voice identify me" userEnrollmentsCancelled:^{
      NSLog(@"User Enrollments Cancelled");
  } userEnrollmentsPassed:^{
      NSLog(@"User Enrollments Passed");
  }];
```

#### Voice Verification

Verify user with the given userId(begins with 'usr_'), contentLanguage('en-US','es-ES' etc.) and audio file.
##### *Swift*
```swift
myVoiceIt?.voiceVerification("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", audioPath: "FILE_PATH_TO_VOICE_FOR_VERIFICATION_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt voiceVerification:@"USER_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" audioPath: @"FILE_PATH_TO_VOICE_FOR_VERIFICATION_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Face Verification

Verify user's face with given userId(begins with 'usr_') and video file.

##### *Swift*
```swift
myVoiceIt?.faceVerification("USER_ID_HERE", videoPath: "FILE_PATH_TO_VIDEO_FOR_FACE_VERIFICATION_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt faceVerification:@"USER_ID_HERE" videoPath: @"FILE_PATH_TO_VIDEO_FOR_FACE_VERIFICATION_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Video Verification

Verify user with given userId(begins with 'usr_') , contentLanguage('en-US','es-ES' etc.) and video file.

##### *Swift*
```swift
myVoiceIt?.videoVerification("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", videoPath: "FILE_PATH_TO_VIDEO_FOR_VERIFICATION_HERE", callback: {
    jsonResponse in
    print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt videoVerification:@"USER_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" videoPath: @"FILE_PATH_TO_VIDEO_FOR_VERIFICATION_HERE" callback:^(NSString * jsonResponse){
    NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Encapsulated Voice Verification

Verify user with given userId(begins with 'usr_'). Note: Immediately upon calling this method it displays a view controller with a view that records and verifies the user's voice and provides relevant callbacks for whether the verification was successful or not, and associated voice confidence

##### *Swift*
```swift
myVoiceIt?.encapsulatedVoiceVerification("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", voicePrintPhrase: "my face and voice identify me", userVerificationCancelled: {
print("User Cancelled Verification");
}, userVerificationSuccessful: {(voiceConfidence, jsonResponse) in
print("User Verication Successful, voiceConfidence is \(voiceConfidence)")
}, userVerificationFailed: { (voiceConfidence, jsonResponse) in
print("User Verication Failed, voiceConfidence is \(voiceConfidence)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt encapsulatedVoiceVerification:@"USER_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" voicePrintPhrase:@"my face and voice identify me" userVerificationCancelled:^{
NSLog(@"User Cancelled Verification");
} userVerificationSuccessful:^(float voiceConfidence, NSString * jsonResponse){
NSLog(@"User Verication Successful, voiceConfidence : %g",voiceConfidence);
} userVerificationFailed:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
NSLog(@"User Verication Failed, voiceConfidence : %g",voiceConfidence);
}];
```

#### Encapsulated Face Verification

Verify user with given userId(begins with 'usr_') and a parameter to enable or disable liveness detection. Note: Immediately upon calling this method it displays a view controller with a camera view that verifies the user's face and provides relevant callbacks for whether the verification was successful or not, and associated face confidence

##### *Swift*
```swift
myVoiceIt?.encapsulatedFaceVerification("USER_ID_HERE", doLivenessDetection:true, userVerificationCancelled: {
print("User Cancelled Verification");
}, userVerificationSuccessful: {(faceConfidence, jsonResponse) in
print("User Verication Successful faceConfidence is \(faceConfidence)")
}, userVerificationFailed: { (faceConfidence, jsonResponse) in
print("User Verication Failed, faceConfidence is \(faceConfidence)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt encapsulatedFaceVerification:@"USER_ID_HERE" doLivenessDetection:YES userVerificationCancelled:^{
NSLog(@"User Cancelled Verification");
} userVerificationSuccessful:^(float faceConfidence, NSString * jsonResponse){
NSLog(@"User Verication Successful faceConfidence : %g", faceConfidence);
} userVerificationFailed:^(float faceConfidence, NSString * jsonResponse){
NSLog(@"User Verication Failed, faceConfidence : %g",faceConfidence);
}];
```


#### Encapsulated Video Verification

Verify user with given userId(begins with 'usr_') , contentLanguage('en-US','es-ES' etc.) and a parameter to enable or disable liveness detection. Note: Immediately upon calling this method it displays a view controller with a camera view that verifies the user and provides relevant callbacks for whether the verification was successful or not, and associated voice and face confidences

##### *Swift*
```swift
myVoiceIt?.encapsulatedVideoVerification("USER_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", voicePrintPhrase: "my face and voice identify me", doLivenessDetection:true, userVerificationCancelled: {
      print("User Cancelled Verification");
    }, userVerificationSuccessful: {(faceConfidence, voiceConfidence, jsonResponse) in
      print("User Verication Successful, voiceConfidence is \(voiceConfidence), faceConfidence is \(faceConfidence)")
}, userVerificationFailed: { (faceConfidence, voiceConfidence, jsonResponse) in
      print("User Verication Failed, voiceConfidence is \(voiceConfidence), faceConfidence is \(faceConfidence)")
    })
```

##### *Objective-C*
```objc
[self.myVoiceIt encapsulatedVideoVerification:@"USER_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" voicePrintPhrase:@"my face and voice identify me" doLivenessDetection:YES userVerificationCancelled:^{
     NSLog(@"User Cancelled Verification");
} userVerificationSuccessful:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
    NSLog(@"User Verication Successful, voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
} userVerificationFailed:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
    NSLog(@"User Verication Failed, voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
}];
```

#### Voice Identification

Identify user inside group with the given groupId(begins with 'grp_') and contentLanguage('en-US','es-ES' etc.). Note: Immediately upon calling this method it records the user saying their VoicePrint phrase for 5 seconds calling the recordingFinished callback first, then it sends the recording to be identified and returns the found userId and confidence in the callback

##### *Swift*
```swift
myVoiceIt?.voiceIdentification("GROUP_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", audioPath: "FILE_PATH_TO_VOICE_FOR_IDENTIFICATION_HERE", callback: {
jsonResponse in
print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt voiceIdentification:@"GROUP_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" audioPath: @"FILE_PATH_TO_VOICE_FOR_IDENTIFICATION_HERE" callback:^(NSString * jsonResponse){
NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

#### Video Identification

Identify user inside group with the given groupId(begins with 'grp_') and contentLanguage('en-US','es-ES' etc.) and videoFile.

##### *Swift*
```swift
myVoiceIt?.videoIdentification("GROUP_ID_HERE", contentLanguage: "CONTENT_LANGUAGE_HERE", videoPath: "FILE_PATH_TO_VIDEO_FOR_IDENTIFICATION_HERE", callback: {
jsonResponse in
print("JSON RESPONSE: \(jsonResponse!)")
})
```

##### *Objective-C*
```objc
[self.myVoiceIt videoIdentification:@"GROUP_ID_HERE" contentLanguage:@"CONTENT_LANGUAGE_HERE" videoPath: @"FILE_PATH_TO_VIDEO_FOR_IDENTIFICATION_HERE" callback:^(NSString * jsonResponse){
NSLog(@"JSONResponse: %@", jsonResponse);
} ];
```

## Author

armaanbindra, armaan@voiceit.io

## License

VoiceItApi2IosSDK is available under the MIT license. See the LICENSE file for more info.
