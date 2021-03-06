//
//  AlarmTableViewCell.swift
//  WildCat
//
//  Created by 陰山賢太 on 2018/10/25.
//  Copyright © 2018 Azuma. All rights reserved.
//

import UIKit

class AlarmTableViewCell: UITableViewCell {

    // MARK: - Propaties

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var alarmSwitch: UISwitch!
    private var alarm: Alarm?
    // MARK: - Method

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func update(target alarm:Alarm) {
        self.alarm = alarm
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.timeLabel.text = formatter.string(from: alarm.date)
        self.messageLabel.text = alarm.pattern?.message
        LocalPhoto.load(localIdentifer: (alarm.pattern?.imagePath)!) { (resultImage) in
            if let resultImage = resultImage {
                self.photoImage.image = resultImage.cropping2square()
            }
        }
        if self.alarmSwitch.isOn {
            NotificationManager().addNotification(alarm: alarm)
        }
    }

    @IBAction func notificateAction(_ sender: UISwitch) {
        let notificationManager = NotificationManager()
        if let alarm = self.alarm {
            if sender.isOn {
                notificationManager.addNotification(alarm: alarm)
                self.timeLabel.textColor = UIColor.title
                self.messageLabel.textColor = UIColor.title
            } else {
                notificationManager.deletePendingNotification(alarm: alarm)
                notificationManager.deleteDeliveredNotification(alarm: alarm)
                self.timeLabel.textColor = UIColor.label
                self.messageLabel.textColor = UIColor.label
            }
        }
    }
}
