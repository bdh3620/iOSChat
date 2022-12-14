//
//  ChatManager.swift
//  iOSChat
//
//  Created by 백대홍 on 2022/11/24.
//

import Foundation
import StreamChat
import StreamChatUI

final class ChatManager {
    static let shared = ChatManager()
    
    
    private var client: ChatClient!
    
    private let tokens = [
        "bdh3620": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYmRoMzYyMCJ9.ev7VHhswPt8HlpSREI1wJHgRmFDna8JdIGAAnGEWJ4Q",
        "stevejobs": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3RldmVqb2JzIn0.8jzCiexPVFILdgfenXqZfnNlcqc46N1FcbtCgoJv39w"
    ]
    
    
    
    
    func setUp() {
        let client = ChatClient(config: .init(apiKey: .init("px6egm8j8zej")))
        self.client = client
    }
    
    // Authentication
    
    func signIn(with username: String, completion: @ escaping(Bool) -> Void) {
        guard !username.isEmpty else {
            completion(false)
            return
        }
        
        guard let token = tokens[username.lowercased()] else {
            completion(false)
            return
        }
        client.connectUser(
            userInfo: UserInfo(id: username, name: username),
            token: Token(stringLiteral: token)
        ) { error in
                completion(error == nil)
            }
    }
    
    func signOut() {
        client.disconnect()
        client.logout()
    }
    var isSignedIn: Bool {
        return client.currentUserId != nil
        
    }
    
    var currentUser: String? {
        return client.currentUserId 
        
    }
    // MARK: - ChannelList + Creation
    
    public func createChannelList() -> UIViewController? {
        guard let id = currentUser else { return nil }
        let list = client.channelListController(query: .init(filter: .containMembers(userIds: [id])))
        
        let vc = ChatChannelListVC()
        vc.content = list
        list.synchronize()
        return vc
        
    }
    public func createNewChannel(name:String) {
        guard let current = currentUser else {
            return
        }
        let keys: [String] = tokens.keys.filter({ $0 != current }).map { $0 }
        do {
            let result = try client.channelController(
                createChannelWithId: .init(type: .messaging, id: name),
                name: name,
                members: Set(keys),
                isCurrentUserMember: true
            
            )
            result.synchronize()
        }
        catch {
            print("\(error)")
            
        }
    }
}
