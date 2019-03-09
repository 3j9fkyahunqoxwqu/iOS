//
//  CloudSaveBookmarksViewController.swift
//  DuckDuckGo
//
//  Created by Christopher Brind on 06/03/2019.
//  Copyright © 2019 DuckDuckGo. All rights reserved.
//

import UIKit
import Alamofire
import Core

class CloudSaveBookmarksViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var uploadImage: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var qrcodeImage: UIImageView!
    @IBOutlet weak var daxImage: UIImageView!

    var bookmarksManager = BookmarksManager()

    @IBAction func close() {
        dismiss(animated: true)
    }

    @IBAction func handleButtonTap() {

        if bookmarksManager.code != nil {

            promptToDelete()

        } else {
            saveToCloud()
        }

    }

    var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print("***", bookmarksManager.code ?? "no code")
        refreshUI()
    }

    func refreshUI() {
        updateQRCode()
        updateInfo()
        updateButton()
        updateActivity()
    }

    func updateActivity() {
        if busy {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func saveToCloud() {

        busy = true
        refreshUI()

        let code = bookmarksManager.code ?? UUID().uuidString

        bookmarksManager.saveToCloud(withCode: code) { [weak self] success in
            if !success {
                self?.view.makeToast("Failed to save bookmarks, try again later.")
            }
            self?.busy = false
            self?.refreshUI()
        }

    }

    func updateQRCode() {
        guard let code = bookmarksManager.code else { return }
        qrcodeImage.image = generateQRCode(from: code)
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }

    func updateInfo() {
        let hasCode = bookmarksManager.code != nil

        daxImage.isHidden = !hasCode
        infoLabel.isHidden = busy || hasCode
        uploadImage.isHidden = busy || hasCode
    }

    func updateButton() {

        button.isHidden = busy

        if bookmarksManager.code != nil {
            button.backgroundColor = UIColor.red
            button.setTitle("Delete from Cloud", for: .normal)
        } else {
            button.backgroundColor = UIColor.cornflowerBlue
            button.setTitle("Save to Cloud", for: .normal)
        }

    }

    func promptToDelete() {
        let alert = UIAlertController(title: "Please confirm",
                                      message: "Do you want to delete your bookmarks from the private cloud?",
                                      preferredStyle: .alert)
        alert.addAction(title: "Yes, please", style: .destructive) { [weak self] in
            self?.bookmarksManager.deleteFromCloud()
            self?.dismiss(animated: true)
        }

        alert.addAction(title: "No, thanks")

        present(controller: alert, fromView: button)
    }

}

struct CloudSaveBookmark: Codable {

    let title: String
    let url: String

}

struct CloudSaveBookmarksObject: Codable {

    let bookmark: [CloudSaveBookmark]

}

struct CloudSave: Codable {

    let command: String
    let objectKey: String
    let obj: CloudSaveBookmarksObject

}
