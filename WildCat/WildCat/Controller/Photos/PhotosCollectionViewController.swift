//
//  PhotosCollectionViewController.swift
//  WildCat
//
//  Created by 陰山賢太 on 2018/10/23.
//  Copyright © 2018 Azuma. All rights reserved.
//

import UIKit
import SKPhotoBrowser
import Photos

class PhotosCollectionViewController: UICollectionViewController, SKPhotoBrowserDelegate {

    private let refreshControl = UIRefreshControl()
    private var page: Int = 0
    private var browser: SKPhotoBrowser?

    // Twitter
    private var images = [UIImage]()
    private var photos = [Photo]()
    private var skPhotos = [SKPhoto]()
    private var status = SegmentStatus.Twitter

    // Save
    private var saveImages = [UIImage]()
    private var savePhotos = [Photo]()
    private var saveSKPhotos = [SKPhoto]()
    private var index: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        for _ in 0..<30 {
            images.append(UIImage(named: "black")!)
            skPhotos.append(SKPhoto.photoWithImage(UIImage(named: "black")!))
        }
        SKPhotoBrowserOptions.displayBackAndForwardButton = false
        SKPhotoBrowserOptions.displayAction = false
        getData()
        localRefresh()
    }

    private func localRefresh() {
        LocalPhoto.load { (images) in
            self.saveImages  = images
            self.saveSKPhotos = []
            for image in images {
                self.saveSKPhotos.append(SKPhoto.photoWithImage(image))
            }
        }
    }

    @objc private func refresh() {
        self.page += 1
        getData()
    }

    @IBAction private func segmentAction(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.status = .Twitter
            self.collectionView.refreshControl = refreshControl
            self.collectionView.reloadData()
        } else {
            self.status = .Save
            self.collectionView.refreshControl = nil
            self.collectionView.reloadData()
        }
    }

    private func getData() {
        // Sample
//        guard let path = Bundle.main.path(forResource: "Photo", ofType: "json") else { return }
//        let url = URL(fileURLWithPath: path)
//        do {
//            let data = try Data(contentsOf: url)
//            let photos = try
//                JSONDecoder().decode([Photo].self, from: data)
//            self.photos = photos
//            self.collectionView.reloadData()
//        } catch  {
//            print(error)
//        }

        // RemoteURL
        let url = URL(string: "http://13.115.170.124/api/images/?size=30&offset=\(page)")!
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let data = data {
                do {
                    let photos = try JSONDecoder().decode([Photo].self, from: data)
                    self.photos = photos
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch status {
        case .Twitter:
            return photos.count
        case .Save:
            return saveImages.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        switch status {
        case .Twitter:
            cell.configure(photo: photos[indexPath.item]) { (image) in
                if let image = image {
                    self.images[indexPath.item] = image
                    let skImage = SKPhoto.photoWithImage(image)
                    self.skPhotos[indexPath.item] = skImage
                }
            }
        case .Save:
            cell.imageView.image = saveImages[indexPath.item].cropping2square()
            break
        }
    
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        var originImage = cell.imageView.image
        var images = [SKPhoto]()

        switch status {
        case .Twitter:
            images = skPhotos
            self.browser = SKPhotoBrowser(originImage: self.images[indexPath.item], photos: images, animatedFromView: cell)
            browser!.delegate = self
            let addImage = UIImageView(image: UIImage(named: "Add"))
            addImage.isUserInteractionEnabled = true
            addImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(save)))
            addImage.translatesAutoresizingMaskIntoConstraints = false
            browser!.view.addSubview(addImage)
            let customMargins = browser!.view.layoutMarginsGuide
            addImage.trailingAnchor.constraint(equalTo: customMargins.trailingAnchor, constant: -16).isActive = true
            addImage.bottomAnchor.constraint(equalTo: customMargins.bottomAnchor, constant: -40).isActive = true
            addImage.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
            addImage.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
            browser!.initializePageIndex(indexPath.item)
            present(browser!, animated: true, completion: nil)
        case .Save:
            originImage = saveImages[indexPath.item]
            images = saveSKPhotos
            let browser = SKPhotoBrowser(originImage: originImage ?? UIImage(), photos: images, animatedFromView: cell)
            browser.initializePageIndex(indexPath.item)
            present(browser, animated: true, completion: nil)
        }
    }

    func didShowPhotoAtIndex(_ browser: SKPhotoBrowser, index: Int) {
        self.index = index
    }

    @objc private func save(sender: UITapGestureRecognizer) {
        LocalPhoto.savePhoto(skPhotos[self.index].underlyingImage, toAlbum: "WildCat") { (imagePath) in
            self.browser?.showAlert(title: "画像を保存しました", message: "")
            let remotePath = RemotePath()
            remotePath.id = imagePath
            remotePath.remotePath = self.photos[self.index].imagePath
            RemotePath.add(path: remotePath)
            self.localRefresh()
        }
    }
}
