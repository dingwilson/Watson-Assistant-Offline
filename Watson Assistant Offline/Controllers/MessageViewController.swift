//
//  MessageViewController.swift
//  Watson Assistant Offline
//
//  Created by Wilson on 7/12/18.
//  Copyright © 2018 Wilson Ding. All rights reserved.
//

import UIKit
import MessageKit
import MapKit
import MultiPeer
import CoreLocation
import PKHUD

class MessageViewController: MessagesViewController {
    
    @IBOutlet weak var groupChatbutton: UIBarButtonItem!
    
    fileprivate let kCollectionViewCellHeight: CGFloat = 12.5
    
    // Group Chat
    var isGroupChat = false
    
    // Messages State
    var messageList: [AssistantMessages] = []
    
    var now = Date()
    
    // Watson Assistant Workspace
    var workspaceID: String?
    
    // UUID
    let uuid = UUID().uuidString
    
    // Users
    let current = Sender(id: "123456", displayName: "You")
    let watson = Sender(id: "654321", displayName: "Cape")
    
    // Location
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 184/255, green: 0, blue: 0, alpha: 1)
        
        // Setup CLLocation
        setupLocation()

        // Setup MultiPeerConnectivity
        setupMultiPeer()

        // Registers data sources and delegates + setup views
        setupMessagesKit()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.addMessage("Hi! I'm Cape, the offline disaster relief chatbot, powered by Watson Asssitant! I am here to help answer any questions and direct first responders to help assist you however necessary.")
            self.addMessage("""
                Feel free to try ask me private questions like:

                - Hey Cape, how do I perform CPR?
                - Cape, where can I find shelter?
                - Hey Cape, what are the current weather conditions?
                - Cape, I need help.
                """)
            self.addMessage("You can also chat with others in your area by tapping the private button to change it to public chat. Don't worry, messages to me will still be private.")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
    @IBAction func didPressRESCUE(_ sender: Any) {
        HUD.show(.progress)
        attemptRescue(for: uuid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            HUD.flash(.success, delay: 2.0)
            self.addMessage("First responders are now aware of your location, and are on their way. Don't worry, you're in good hands.")
        }
    }
    
    @IBAction func didPressChatPrivacyButton(_ sender: Any) {
        isGroupChat = !isGroupChat
        
        if isGroupChat {
            groupChatbutton.title = "Chat: Public"
        } else {
            groupChatbutton.title = "Chat: Private"
        }
    }
    
    
    // MARK: - Setup Methods
    
    // Method to set up messages kit data sources and delegates + configure
    func setupMessagesKit() {
        
        // Register datasources and delegates
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        // Configure views
        messageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
    }
    
    // Method to set up MultiPeerConnectivity
    func setupMultiPeer() {
        MultiPeer.instance.initialize(serviceType: "watson-offline")
        MultiPeer.instance.autoConnect()
        
        MultiPeer.instance.delegate = self
    }
    
    // Method to set up CLLocation
    func setupLocation() {
        self.locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    // Method to retrieve assistant avatar
    func getAvatarFor(sender: Sender) -> Avatar {
        switch sender {
        case current:
            return Avatar(image: UIImage(named: "empty_avatar"), initials: "YOU")
        case watson:
            return Avatar(image: UIImage(named: "watson_avatar"), initials: "CAPE")
        default:
            return Avatar(image: UIImage(named: "empty_avatar"), initials: "GROUP")
        }
    }
    
    // Method to attempt request to backend
    func attemptRequestWith(message: String, for userUUID: String) {
        if message.lowercased().range(of:" cape") != nil || !isGroupChat {
            let watsonMessage = message.replacingOccurrences(of: " cape", with: "")
            
            NetworkManager.instance.send(watsonMessage, uuid: userUUID) { (success, response) in
                if success {
                    guard let response = response else { return }
                    
                    let responseResult = response.components(separatedBy: "|")
                    
                    if responseResult[0] == self.uuid {
                        self.addMessage(responseResult[1])
                    } else {
                        MultiPeer.instance.send(object: response, type: DataType.response.rawValue)
                    }
                    
                } else {
                    MultiPeer.instance.send(object: "\(userUUID)|\(watsonMessage)", type: DataType.message.rawValue)
                }
            }
        } else {
            MultiPeer.instance.send(object: "\(UIDevice.current.name)|\(message)", type: DataType.chat.rawValue)
        }
    }
    
    // Method to attempt rescue request to backend
    func attemptRescue(for userUUID: String) {
        NetworkManager.instance.rescue(userUUID, lat: (locationManager.location?.coordinate.latitude)!, long: (locationManager.location?.coordinate.longitude)!) { (success, response) in
            // apparently the endpoint gives a 500 error, but still completes successfully...
            // magic spaghetti code on the backend
        }
        
    }
    
    // Method to add message
    func addMessage(_ message: String) {
        DispatchQueue.main.async {
            let attributedText = NSAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
            let id = UUID().uuidString
            let message = AssistantMessages(attributedText: attributedText, sender: self.watson, messageId: id, date: Date())
            self.messageList.append(message)
            self.messagesCollectionView.insertSections([self.messageList.count - 1])
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    // Method to add group chat message
    func addGroupMessage(_ message: String, name: String) {
        DispatchQueue.main.async {
            let attributedText = NSAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
            let id = UUID().uuidString
            let message = AssistantMessages(attributedText: attributedText, sender: Sender(id: "000000", displayName: name), messageId: id, date: Date())
            self.messageList.append(message)
            self.messagesCollectionView.insertSections([self.messageList.count - 1])
            self.messagesCollectionView.scrollToBottom()
        }
    }
}

// MARK: - MessagesDataSource
extension MessageViewController: MessagesDataSource {
    
    func currentSender() -> Sender {
        return current
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        struct AssistantDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter
            }()
        }
        let formatter = AssistantDateFormatter.formatter
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
}

// MARK: - MessagesDisplayDelegate
extension MessageViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .white
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return UIColor(red: 184/255, green: 0, blue: 0, alpha: 1)
        } else {
            if message.sender == self.watson {
                return UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
            } else {
                return UIColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1)
            }
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let avatar = getAvatarFor(sender: message.sender)
        avatarView.set(avatar: avatar)
    }
    
    // MARK: - Location Messages
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "pin")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }
    
    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(0, 0, 0)
            view.alpha = 0.0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1.0
            }, completion: nil)
        }
    }
}

// MARK: - MessagesLayoutDelegate
extension MessageViewController: MessagesLayoutDelegate {
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }
    
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }
    
    // MARK: - Location Messages
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
    
}

// MARK: - MessageCellDelegate

extension MessageViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapTopLabel(in cell: MessageCollectionViewCell) {
        print("Top label tapped")
    }
    
    func didTapBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }
    
}

// MARK: - MessageLabelDelegate

extension MessageViewController: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
}

// MARK: - MessageInputBarDelegate

extension MessageViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
        let id = UUID().uuidString
        let message = AssistantMessages(attributedText: attributedText, sender: currentSender(), messageId: id, date: Date())
        messageList.append(message)
        inputBar.inputTextView.text = String()
        messagesCollectionView.insertSections([messageList.count - 1])
        messagesCollectionView.scrollToBottom()
        
        // cleanup text that gets sent to Watson, which doesn't care about whitespace or newline characters
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: ". ")
        
        attemptRequestWith(message: cleanText, for: uuid)
        
        inputBar.inputTextView.text = String()
    }
    
}

// MARK: - MultiPeerDelegate

extension MessageViewController: MultiPeerDelegate {
    func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
        switch type {
        case DataType.message.rawValue:
            let string = data.convert() as! String
            
            let messageArray = string.components(separatedBy: "|")
            
            attemptRequestWith(message: messageArray[1], for: messageArray[0])
            
            break
            
        case DataType.response.rawValue:
            let string = data.convert() as! String
            
            let messageResult = string.components(separatedBy: "|")
            
            if messageResult[0] == self.uuid {
                self.addMessage(messageResult[1])
            }
            
            break
            
        case DataType.chat.rawValue:
            let string = data.convert() as! String
            
            if isGroupChat {
                let messageResult = string.components(separatedBy: "|")
                
                self.addGroupMessage(messageResult[1], name: messageResult[0])
            }
            
            break
            
        default:
            break
        }
    }
    
    func multiPeer(connectedDevicesChanged devices: [String]) {
    }
}

// MARK: - CLLocation

extension MessageViewController: CLLocationManagerDelegate {
    
}
