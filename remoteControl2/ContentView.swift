//
//  ContentView.swift
//  remoteControl2
//
//  Created by Rnadint's Macbook on 10/1/22.
//
//
//  ContentView.swift
//  project_one Watch App
//
//  Created by Rnadint's Macbook on 9/30/22.
//

import SwiftUI
import UIKit
import CryptoKit
import CommonCrypto

extension SecTrust {
    
    var isSelfSigned: Bool? {
        guard SecTrustGetCertificateCount(self) == 1 else {
            return false
        }
        guard let cert = SecTrustGetCertificateAtIndex(self, 0) else {
            return nil
        }
        return cert.isSelfSigned
    }
}

extension SecCertificate {

    var isSelfSigned: Bool? {
        guard
            let subject = SecCertificateCopyNormalizedSubjectSequence(self),
            let issuer = SecCertificateCopyNormalizedIssuerSequence(self)
        else {
            return nil
        }
        return subject == issuer
    }
}

func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
        let trust = challenge.protectionSpace.serverTrust!
        NSLog("is self-signed: %@", trust.isSelfSigned.flatMap { "\($0)" } ?? "unknown" )
    }
    completionHandler(.performDefaultHandling, nil)
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

struct json: Codable{
    let command: String
    let parameter: String
    let commandType: String
}

func mac(secretKey: String, message: String) -> String {
  let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
  let mac = UnsafeMutablePointer<CChar>.allocate(capacity: digestLength)

  let cSecretKey: [CChar]? = secretKey.cString(using: .utf8)
  let cSecretKeyLength = secretKey.lengthOfBytes(using: .utf8)

  let cMessage: [CChar]? = message.cString(using: .utf8)
  let cMessageLength = message.lengthOfBytes(using: .utf8)

  CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), cSecretKey, cSecretKeyLength, cMessage, cMessageLength, mac)

  let macData = Data(bytes: mac, count: digestLength)

  return macData.base64EncodedString()
}

func get_stat(){
    let t = Date().millisecondsSince1970
    
    let sign = token+String(t)+nonce
    let digest = mac(secretKey: secret, message: sign)
    
    guard let url = URL(string: "https://api.switch-bot.com/v1.1/devices/"+device_name+"/status") else { return }
    
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval:10.0)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(token, forHTTPHeaderField: "Authorization")
    request.setValue(digest, forHTTPHeaderField:"sign")
    request.setValue(String(t), forHTTPHeaderField: "t")
    request.setValue(nonce, forHTTPHeaderField: "nonce")
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    
    let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
        guard let data = data else { return }
        
        print(String(data: data, encoding: .utf8)!)
    }
    print(1)
    task.resume()
    
    
    
    
}

func requesting(){
    let t = Date().millisecondsSince1970
    
    let sign = token+String(t)+nonce
    let digest = mac(secretKey: secret, message: sign)
    
    let data = json(command: "turnOn",parameter: "default",commandType: "command")
    
    guard let jsonData = try? JSONEncoder().encode(data) else{
        return
    }
    
    
    
    let urlString = "https://api.switch-bot.com/v1.1/devices/"+device_name+"/commands"
    
    guard let requestUrl = URL(string: urlString) else { return }
    
    var request = URLRequest(url: requestUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval:10.0)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(token, forHTTPHeaderField: "Authorization")
    request.setValue(digest, forHTTPHeaderField:"sign")
    request.setValue(String(t), forHTTPHeaderField: "t")
    request.setValue(nonce, forHTTPHeaderField: "nonce")
    request.httpBody = jsonData
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    
    let task = URLSession(configuration: config).dataTask(with: request){data, response, error in
        guard error == nil else {
            print("Error: error calling POST")
            print(error!)
            return
        }
        guard let data = data else {
            print("Error: Did not receive data")
            return
        }
        guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
            print("Error: HTTP request failed")
            print(response!)
            return
        }
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Error: Cannot convert data to JSON object")
                return
            }
            guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                print("Error: Cannot convert JSON object to Pretty JSON data")
                return
            }
            guard let prettyPrintedJson = String(data: prettyJsonData, encoding: .utf8) else {
                print("Error: Couldn't print JSON in String")
                return
            }
            print(prettyPrintedJson)
            
        } catch {
            print("Error: Trying to convert JSON data to string")
            return
        }
    }
    task.resume()
}

     

struct ContentView: View {
    var body: some View {
        VStack {
            Button("???", action: requesting)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
