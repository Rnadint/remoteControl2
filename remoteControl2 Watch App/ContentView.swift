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




func requesting(){
    
    
    WKInterfaceDevice.current().play(.start)
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
        WKInterfaceDevice.current().play(.success)
    })
    let t = Date().millisecondsSince1970
    
    let sign = token+String(t)+nonce
    let digest = mac(secretKey: secret, message: sign)
    
    let data = json(command: "turnOn",parameter: "default",commandType: "command")
    
    guard let jsonData = try? JSONEncoder().encode(data) else{
        return
    }
    
    
    let urlString = "https://api.switch-bot.com/v1.1/devices/"+device_name+"/commands"
    guard let requestUrl = URL(string:urlString) else { return }
    
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
            print(response ?? 0)
            return
        }
    }
    task.resume()
}

     
     struct ContentView: View {
     
         var button = Button("⬤",action:requesting)
         var body: some View {
         VStack {
             button.frame(width: 50).buttonStyle(BorderedButtonStyle(tint: Color.white.opacity(255)))
         }.padding()
         }
     }
     

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

