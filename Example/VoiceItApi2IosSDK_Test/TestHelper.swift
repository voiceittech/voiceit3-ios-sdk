//
//  TestHelper.swift
//  VoiceItApi2IosSDK_Test
//
//  Created by VoiceIt Technolopgies, LLC on 8/26/18.
//  Copyright © 2018 VoiceIt Technologies, LLC. All rights reserved.
//

import Foundation

struct VoiceItResponse: Decodable {
    let responseCode: String
    let message: String
    let status: Int
}

struct UserResponse: Decodable {
    let userId: String
    let responseCode: String
    let message: String
    let status: Int
}

struct GroupResponse: Decodable {
    let groupId: String
    let responseCode: String
    let message: String
    let status: Int
}

struct GetVoiceEnrollmentsResponse: Decodable {
    let responseCode: String
    let message: String
    let status: Int
    let voiceEnrollments: [VoiceEnrollmentResponse]?
}

struct VoiceEnrollmentResponse: Decodable {
    let id: Int
    let responseCode: String
    let message: String
    let status: Int
}

struct GetVideoEnrollmentsResponse: Decodable {
    let responseCode: String
    let message: String
    let status: Int
    let videoEnrollments: [VideoEnrollmentResponse]?
}

struct VideoEnrollmentResponse: Decodable {
    let id: Int
    let responseCode: String
    let message: String
    let status: Int
}

struct GetFaceEnrollmentsResponse: Decodable {
    let responseCode: String
    let message: String
    let status: Int
    let faceEnrollments: [FaceEnrollmentResponse]?
}

struct FaceEnrollmentResponse: Decodable {
    let faceEnrollmentId: Int
    let responseCode: String
    let message: String
    let status: Int
}

class TestHelper {
    
    class func getEnvironmentVar(_ name: String) -> String? {
        guard let rawValue = getenv(name) else { return nil }
        return String(utf8String: rawValue)
    }
    
    class func decodeSimpleJSON(jsonString: String) -> VoiceItResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(VoiceItResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeUserJSON(jsonString: String) -> UserResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(UserResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeGroupJSON(jsonString: String) -> GroupResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(GroupResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeVoiceEnrollmentJSON(jsonString: String) -> VoiceEnrollmentResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(VoiceEnrollmentResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeFaceEnrollmentJSON(jsonString: String) -> FaceEnrollmentResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(FaceEnrollmentResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeVideoEnrollmentJSON(jsonString: String) -> VideoEnrollmentResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(VideoEnrollmentResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeGetVoiceEnrollmentsJSON(jsonString: String) -> GetVoiceEnrollmentsResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(GetVoiceEnrollmentsResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeGetFaceEnrollmentsJSON(jsonString: String) -> GetFaceEnrollmentsResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(GetFaceEnrollmentsResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func decodeGetVideoEnrollmentsJSON(jsonString: String) -> GetVideoEnrollmentsResponse?{
        let jsonData = jsonString.data(using: .utf8)
        guard let ret = try? JSONDecoder().decode(GetVideoEnrollmentsResponse.self, from: jsonData!) else {
            return nil
        }
        return ret
    }
    
    class func downloadS3File(fileName : String, callback : @escaping (String) -> Void){
        let remoteURL = URL(string: "https://s3.amazonaws.com/voiceit-api2-testing-files/test-data/\(fileName)")!
        let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        let destinationFileUrl = documentsUrl.appendingPathComponent(remoteURL.lastPathComponent)
        let task = URLSession(configuration: URLSessionConfiguration.default).downloadTask(with: URLRequest(url:remoteURL)) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                }
                callback(destinationFileUrl.relativePath)
            } else {
                print("Error Downloading File. Error description: %@", error?.localizedDescription ?? "");
            }
        }
        task.resume()
    }
    
    class func deleteTempFiles(){
        let fileManager = FileManager.default
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let documentsPath = documentsUrl.path
        do {
            if let documentPath = documentsPath
            {
                let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                for fileName in fileNames {
                   let filePathName = "\(documentPath)/\(fileName)"
                   try fileManager.removeItem(atPath: filePathName)
                }
            }
        } catch {
            print("Could Clear Temp Folder: \(error)")
        }
    }
}
