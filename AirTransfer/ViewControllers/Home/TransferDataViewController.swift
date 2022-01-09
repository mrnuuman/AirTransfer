//
//  ViewController.swift
//  AirTransfer
//
//  Created by Mac on 1/9/22.
//

import UIKit
import MultipeerConnectivity

class TransferDataViewController: UIViewController {

    //MARK: - Variables
   private var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var imagePicker: ImagePicker!
    var receivedImages: [UIImage] = []
    
    //MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            self.imageView.setRounded()
        }
    }
    @IBOutlet weak var imagesCollectionView: UICollectionView! {
        didSet {
            self.imagesCollectionView.registerNibWithNames("ImagesCollectionViewCell")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendImage))
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(showConnectionMenu))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickImage(sender:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    @objc func pickImage(sender: UITapGestureRecognizer) {
        self.imagePicker.present(from: sender.view ?? UIView())
    }
    
    @objc func sendImage() {
        if mcSession.connectedPeers.count > 0 {
            guard let img = self.imageView.image else {return}
            if let imageData = img.pngData() {
                do {
                    navigationItem.rightBarButtonItem?.isEnabled = false
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                    self.imageView.image = nil
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    @objc func showConnectionMenu() {
        let ac = UIAlertController(title: "Connection Menu", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: hostSession))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func hostSession(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ioscreator-chat", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func joinSession(action: UIAlertAction) {
        let mcBrowser = MCBrowserViewController(serviceType: "ioscreator-chat", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
}

//MARK: Extension to hold MCSession methods

extension TransferDataViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            DispatchQueue.main.async {
                self.navigationItem.leftBarButtonItem?.title = "Connected: \(peerID.displayName)"
                self.dismiss(animated: true, completion: nil)
            }
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("fatal error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.receivedImages.append(image)
                self.imagesCollectionView.reloadData()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        DispatchQueue.main.async {
            print("progress is \(progress)")
        }
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finish")
    }
}

//MARK: Extension to hold MCBrowserViewController methods

extension TransferDataViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: Extension to hold ImagePicker methods

extension TransferDataViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.imageView.image = image
    }
}

//MARK: Extension to hold CollectionView methods

extension TransferDataViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return receivedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = imagesCollectionView.dequeueReusableCell(withReuseIdentifier: "ImagesCollectionViewCell", for: indexPath ) as? ImagesCollectionViewCell else {return UICollectionViewCell()}
        cell.imageView.image = receivedImages[indexPath.row]
        cell.imageView.layer.cornerRadius = 10
        cell.imageView.layer.masksToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
}
