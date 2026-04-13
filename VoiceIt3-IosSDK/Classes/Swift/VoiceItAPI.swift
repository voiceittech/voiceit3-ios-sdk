import Foundation
import UIKit

/// Swift networking client for VoiceIt API 3.0
/// Provides both callback-based and async/await interfaces
@objc public class VoiceItAPI: NSObject {

    // MARK: - Constants

    static let defaultHost = "https://api.voiceit.io/"
    static let platformVersion = "3.2.0"
    static let platformId = "41"

    // MARK: - Properties

    @objc public var apiKey: String
    @objc public var apiToken: String
    private var notificationParam: String = ""

    let authHeader: String
    private let session = URLSession.shared

    // MARK: - Init

    @objc public init(apiKey: String, apiToken: String) {
        self.apiKey = apiKey
        self.apiToken = apiToken
        let credentials = "\(apiKey):\(apiToken)"
        self.authHeader = "Basic \(Data(credentials.utf8).base64EncodedString())"
        super.init()
    }

    // Characters allowed in a single URL query value. Starts from
    // CharacterSet.urlQueryAllowed (RFC 3986 query chars) and removes
    // the query-component delimiters so a literal '&', '=', '+', or '#'
    // in the notification URL cannot inject or truncate our query string.
    private static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+#")
        return set
    }()

    @objc public func setNotificationURL(_ url: String) {
        if url.isEmpty {
            notificationParam = ""
            return
        }
        let encoded = url.addingPercentEncoding(
            withAllowedCharacters: Self.urlQueryValueAllowed
        ) ?? ""
        notificationParam = "?notificationURL=\(encoded)"
    }

    // MARK: - Generic Request

    private func request(
        method: String,
        endpoint: String,
        body: Data? = nil,
        contentType: String = "application/json",
        callback: @escaping (String) -> Void
    ) {
        let urlString = Self.defaultHost + endpoint + notificationParam
        guard let url = URL(string: urlString) else {
            callback("{\"responseCode\":\"GERR\",\"message\":\"Invalid URL\"}")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(Self.platformId, forHTTPHeaderField: "platformId")
        req.addValue(Self.platformVersion, forHTTPHeaderField: "platformVersion")
        req.addValue(authHeader, forHTTPHeaderField: "Authorization")
        req.httpBody = body

        session.dataTask(with: req) { data, _, error in
            let result = data.flatMap { String(data: $0, encoding: .utf8) }
                ?? "{\"responseCode\":\"GERR\",\"message\":\"\(error?.localizedDescription ?? "Unknown error")\"}"
            callback(result)
        }.resume()
    }

    private func multipartRequest(
        method: String,
        endpoint: String,
        formData: MultipartFormData,
        callback: @escaping (String) -> Void
    ) {
        request(method: method, endpoint: endpoint, body: formData.finalize(), contentType: formData.contentType, callback: callback)
    }

    // MARK: - Phrases

    @objc public func getPhrases(_ contentLanguage: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "phrases/\(contentLanguage)", callback: callback)
    }

    // MARK: - Users

    @objc public func getAllUsers(callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "users", callback: callback)
    }

    @objc public func createUser(callback: @escaping (String) -> Void) {
        request(method: "POST", endpoint: "users", callback: callback)
    }

    @objc public func checkUserExists(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "users/\(userId)", callback: callback)
    }

    @objc public func deleteUser(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "DELETE", endpoint: "users/\(userId)", callback: callback)
    }

    @objc public func getGroupsForUser(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "users/\(userId)/groups", callback: callback)
    }

    // MARK: - Groups

    @objc public func getAllGroups(callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "groups", callback: callback)
    }

    @objc public func getGroup(_ groupId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "groups/\(groupId)", callback: callback)
    }

    @objc public func groupExists(_ groupId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "groups/\(groupId)/exists", callback: callback)
    }

    @objc public func createGroup(_ description: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "description", value: description)
        multipartRequest(method: "POST", endpoint: "groups", formData: form, callback: callback)
    }

    @objc public func addUserToGroup(_ groupId: String, userId: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["groupId": groupId, "userId": userId])
        multipartRequest(method: "PUT", endpoint: "groups/addUser", formData: form, callback: callback)
    }

    @objc public func removeUserFromGroup(_ groupId: String, userId: String, callback: @escaping (String) -> Void) {
        request(method: "DELETE", endpoint: "groups/removeUser?groupId=\(groupId)&userId=\(userId)", callback: callback)
    }

    @objc public func deleteGroup(_ groupId: String, callback: @escaping (String) -> Void) {
        request(method: "DELETE", endpoint: "groups/\(groupId)", callback: callback)
    }

    // MARK: - Enrollment Listing

    @objc public func getAllVoiceEnrollments(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "enrollments/voice/\(userId)", callback: callback)
    }

    @objc public func getAllFaceEnrollments(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "enrollments/face/\(userId)", callback: callback)
    }

    @objc public func getAllVideoEnrollments(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "GET", endpoint: "enrollments/video/\(userId)", callback: callback)
    }

    @objc public func deleteAllEnrollments(_ userId: String, callback: @escaping (String) -> Void) {
        request(method: "DELETE", endpoint: "enrollments/\(userId)/all", callback: callback)
    }

    // MARK: - Voice Enrollment

    @objc public func createVoiceEnrollment(_ userId: String, contentLanguage: String, phrase: String, audioPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["userId": userId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addFile(name: "recording", filePath: audioPath)
        multipartRequest(method: "POST", endpoint: "enrollments/voice", formData: form, callback: callback)
    }

    // MARK: - Face Enrollment

    @objc public func createFaceEnrollment(_ userId: String, videoPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "userId", value: userId)
        form.addFile(name: "video", filePath: videoPath)
        multipartRequest(method: "POST", endpoint: "enrollments/face", formData: form, callback: callback)
    }

    @objc public func createFaceEnrollment(_ userId: String, imageData: Data, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "userId", value: userId)
        form.addImageData(name: "photo", data: imageData)
        multipartRequest(method: "POST", endpoint: "enrollments/face", formData: form, callback: callback)
    }

    // MARK: - Video Enrollment

    @objc public func createVideoEnrollment(_ userId: String, contentLanguage: String, phrase: String, videoPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["userId": userId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addFile(name: "video", filePath: videoPath)
        multipartRequest(method: "POST", endpoint: "enrollments/video", formData: form, callback: callback)
    }

    @objc public func createVideoEnrollment(_ userId: String, contentLanguage: String, phrase: String, imageData: Data, audioPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["userId": userId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addImageData(name: "photo", data: imageData)
        form.addFile(name: "recording", filePath: audioPath)
        multipartRequest(method: "POST", endpoint: "enrollments/video", formData: form, callback: callback)
    }

    // MARK: - Voice Verification

    @objc public func voiceVerification(_ userId: String, contentLanguage: String, phrase: String, audioPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["userId": userId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addFile(name: "recording", filePath: audioPath)
        multipartRequest(method: "POST", endpoint: "verification/voice", formData: form, callback: callback)
    }

    // MARK: - Face Verification

    @objc public func faceVerification(_ userId: String, videoPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "userId", value: userId)
        form.addFile(name: "video", filePath: videoPath)
        multipartRequest(method: "POST", endpoint: "verification/face", formData: form, callback: callback)
    }

    @objc public func faceVerification(_ userId: String, imageData: Data, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "userId", value: userId)
        form.addImageData(name: "photo", data: imageData)
        multipartRequest(method: "POST", endpoint: "verification/face", formData: form, callback: callback)
    }

    // MARK: - Video Verification

    @objc public func videoVerification(_ userId: String, contentLanguage: String, phrase: String, videoPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["userId": userId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addFile(name: "video", filePath: videoPath)
        multipartRequest(method: "POST", endpoint: "verification/video", formData: form, callback: callback)
    }

    @objc public func videoVerification(_ userId: String, contentLanguage: String, phrase: String, imageData: Data, audioPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["userId": userId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addImageData(name: "photo", data: imageData)
        form.addFile(name: "recording", filePath: audioPath)
        multipartRequest(method: "POST", endpoint: "verification/video", formData: form, callback: callback)
    }

    // MARK: - Voice Identification

    @objc public func voiceIdentification(_ groupId: String, contentLanguage: String, phrase: String, audioPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["groupId": groupId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addFile(name: "recording", filePath: audioPath)
        multipartRequest(method: "POST", endpoint: "identification/voice", formData: form, callback: callback)
    }

    // MARK: - Face Identification

    @objc public func faceIdentification(_ groupId: String, videoPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "groupId", value: groupId)
        form.addFile(name: "video", filePath: videoPath)
        multipartRequest(method: "POST", endpoint: "identification/face", formData: form, callback: callback)
    }

    @objc public func faceIdentification(_ groupId: String, imageData: Data, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addField(name: "groupId", value: groupId)
        form.addImageData(name: "photo", data: imageData)
        multipartRequest(method: "POST", endpoint: "identification/face", formData: form, callback: callback)
    }

    // MARK: - Video Identification

    @objc public func videoIdentification(_ groupId: String, contentLanguage: String, phrase: String, videoPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["groupId": groupId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addFile(name: "video", filePath: videoPath)
        multipartRequest(method: "POST", endpoint: "identification/video", formData: form, callback: callback)
    }

    @objc public func videoIdentification(_ groupId: String, contentLanguage: String, phrase: String, imageData: Data, audioPath: String, callback: @escaping (String) -> Void) {
        var form = MultipartFormData()
        form.addFields(["groupId": groupId, "contentLanguage": contentLanguage, "phrase": phrase])
        form.addImageData(name: "photo", data: imageData)
        form.addFile(name: "recording", filePath: audioPath)
        multipartRequest(method: "POST", endpoint: "identification/video", formData: form, callback: callback)
    }
}
