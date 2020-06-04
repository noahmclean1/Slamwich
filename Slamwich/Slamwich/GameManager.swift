//
//  ConnectToGame.swift
//  Slamwich
//
//  Created by Noah McLean on 4/24/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import Foundation
import FirebaseDatabase

class GameManager {
    
    public static let global = GameManager()
    let ref = Database.database().reference()
    
    var gameData: GameData?
    var queueListener: UInt?
    var gameListener: UInt?
    var username: String?
    
    var userID:String? {
        didSet {
            // When the UserID is defined, begin listening for when a game is created
            queueListener = createQueueListener()
        }
    }
    
    var gameID:String?{
        didSet {
            if queueListener == nil {
                return
            }
            removeQueueListener(handle: queueListener!)
            gameListener = createGameListener()
        }
    }
    
    // MARK: - Entering the Queue
    func enqueueUser(user: String) {
        username = user
        
        ref.child("queuedUsers").childByAutoId().setValue(["username":user, "gameID":""]) { (error:Error?, newref:DatabaseReference) in
            
            if error != nil {
                print("Error: \(error.debugDescription)")
                return
            }
            
            // Log the generated ID
            let UID = newref.key!
            self.userID = UID
            //print(self.userID)
            
            
            // Find the oldest users in the queue
            self.ref.child("queuedUsers").queryOrderedByKey().queryLimited(toLast: 10).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let val = snapshot.value as? Dictionary<String, Any> else {return}
                if val.count > 1 {
                    for (id,item) in val {
                        // Determine that there is another unique user who has not been assigned a game
                        guard let dict = item as? Dictionary<String, String> else {continue}
                        if dict["gameID"] == "" && id != UID {
                            
                            let otherPlayer = PlayerData(id: id, name: dict["username"]!, score: 0)
                            self.createNewGame(with: otherPlayer, myID: UID, gameId: "game")
                            break
                        }
                    }
                }
            })
        }
    }

    func createQueueListener() -> UInt? {
        // Signal an error if there is no userID yet
        guard let UID = userID else {print("Queue Listener FAILED"); return nil}
        
        // This listener waits for UserID -> GameID to be set, then removes user from queue
        let listenerHandle = ref.child("queuedUsers").child(UID).child("gameID").observe(.value, with: {(snapshot: DataSnapshot) in
            
            if !snapshot.exists() {
                print("No snapshot value in createQueueListener")
                return
            }
            
            let val = snapshot.value as! String
            if val == "" {
                return
            }
            else {
                print(val)
                self.gameID = val
                self.ref.child("queuedUsers").child(UID).removeValue()
            }
        })
        
        return listenerHandle
    }

    // MARK: - Exiting the Queue & Creating a Game

    func removeQueueListener(handle: UInt) {
        ref.removeObserver(withHandle: handle)
    }

    func createNewGame(with otherPlayer: PlayerData, myID: String, gameId: String) {
        // Reserve a space on the DB for a new game, assign both players
        let playerChoice = chooseFirstPlayer()
        let turns = [1] // TODO
        let me = PlayerData(id: myID, name: username!, score: 0)
        
        print("Creating new game on FireBase")
        ref.child("currentGames").child(gameId).setValue(["player1":otherPlayer, "player2":me, "whoseTurn":playerChoice, "turns":turns]) { (error: Error?, newGame:DatabaseReference) in
            if error != nil {
                print("Error: \(error.debugDescription)")
            }
            
            // Update both queued users so their listeners can remove them & set up the game
            self.ref.child("queuedUsers").child(otherPlayer.id).child("gameID").setValue(gameId) {(error, reference) in
                if error != nil {
                    print(error.debugDescription)
                }
            }
            
            self.ref.child("queuedUsers").child(myID).child("gameID").setValue(gameId) {(error, reference) in
                if error != nil {
                    print(error.debugDescription)
                }
            }
        }
    }
    
    func chooseFirstPlayer() -> Int {
        if Int.random(in: 0...1) == 0 {
            return 1
        }
        else {
            return 2
        }
    }
    
    func createGameListener() -> UInt? {
        guard let game = gameID else {print("Game listener FAILED"); return nil}
        
        // This listener basically runs all game updates!
        let listenerHandle = ref.child("currentGames").child(game).observe(.value, with: {(snapshot: DataSnapshot) in
            
            if !snapshot.exists() {
                return
            }
            
            print("Game Snapshot:", snapshot.key)
            
            var gData: GameData!
            
            print(snapshot.value as! [String: Any])
            do {
                gData = try GameData(snapshot: snapshot)
            }
            catch {
                print("GameListener snapshot error \(error)")
                print(snapshot.value as! [String: Any])
                return // TODO handle error
            }
            
            self.gameData = gData
            
            // Update the game locally
            NotificationCenter.default.post(name: NSNotification.Name("Process Other Turn"), object: nil)
        })
        return listenerHandle
    }
    
    // MARK: - Running the Game
}
