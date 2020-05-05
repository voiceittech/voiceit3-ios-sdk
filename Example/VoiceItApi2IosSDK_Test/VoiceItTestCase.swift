//
//  VoiceItTestCase.swift
//  VoiceItApi2IosSDK_Test
//
//  Created by VoiceIt Technolopgies, LLC on 8/26/18.
//  Copyright © 2018 VoiceIt Technologies, LLC. All rights reserved.
//

import XCTest
@testable import VoiceItApi2IosSDK

class VoiceItTest : XCTestCase {
    var myVoiceIt:VoiceItAPITwo?
    var viewController: UIViewController!
    var VI_API_KEY: String?
    var VI_API_TOKEN: String?
    let TIMEOUT = 1000.0
    var started = false
    
    class func basicAssert(expectedRC: String, expectedSC: Int, jsonResponse : String){
        let ret = TestHelper.decodeSimpleJSON(jsonString: jsonResponse)!
        XCTAssertEqual(ret.responseCode, expectedRC)
        XCTAssertEqual(ret.status, expectedSC)
    }
    
    override func setUp() {
        if let viApiKey = TestHelper.getEnvironmentVar("VIAPIKEY") {
            VI_API_KEY = viApiKey
        }
        
        if let viApiTok = TestHelper.getEnvironmentVar("VIAPITOKEN") {
            VI_API_TOKEN = viApiTok
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController()
        self.myVoiceIt  = VoiceItAPITwo(viewController, apiKey: VI_API_KEY, apiToken: VI_API_TOKEN)
    }
    
    func setupVoiceEnrollment(userId: String, fileName : String, callback : @escaping (String) -> Void){
        TestHelper.downloadS3File(fileName: fileName, callback: {
            voiceEnrollmentPath in
            self.myVoiceIt?.createVoiceEnrollment(userId, contentLanguage: "en-US", audioPath: voiceEnrollmentPath, phrase: "never forget tomorrow is a new day", callback: {
                jsonResponse in
                callback(jsonResponse!)
            })
        })
    }
    
    func setupFaceEnrollment(userId: String, fileName : String, callback : @escaping (String) -> Void){
        TestHelper.downloadS3File(fileName: fileName, callback: {
            faceEnrollmentPath in
            self.myVoiceIt?.createFaceEnrollment(userId, videoPath: faceEnrollmentPath, callback: {
                jsonResponse in
                callback(jsonResponse!)
            })
        })
    }
    
    func setupVideoEnrollment(userId: String, fileName : String, callback : @escaping (String) -> Void){
        TestHelper.downloadS3File(fileName: fileName, callback: {
            videoEnrollmentPath in
            self.myVoiceIt?.createVideoEnrollment(userId, contentLanguage: "en-US", videoPath: videoEnrollmentPath, phrase: "never forget tomorrow is a new day", callback: {
                jsonResponse in
                callback(jsonResponse!)
            })
        })
    }
}
