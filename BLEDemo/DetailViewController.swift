//
//  DetailViewController.swift
//  BLEDemo
//
//  Created by Catherine on 2016/10/12.
//  Copyright © 2016年 Catherine. All rights reserved.
//

import UIKit
import CoreBluetooth

class DetailViewController: UIViewController, CBPeripheralDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var logTextField: UITextView!
    
    var targetPeripheral: CBPeripheral?
    var targetCharacteristic: CBCharacteristic?
        
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        logTextField.text = ""
        targetPeripheral?.delegate = self
        targetPeripheral?.setNotifyValue(true, for: targetCharacteristic!)
    }
    
    @IBAction func sendBtnPressed(_ sender: AnyObject) {
        guard let text = inputTextField.text else {
            return
        }
        guard text.characters.count > 0 else {
            return
        }
        
        // Dismiss the keyboard
        inputTextField.resignFirstResponder()
        guard let dataWillSend = text.data(using: .utf8) else {
            return
        }
        
        targetPeripheral?.writeValue(dataWillSend, for: targetCharacteristic!, type: .withoutResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let content = String(data: characteristic.value!, encoding: .utf8)
        if content != nil {
            NSLog("Recieve: \(content)")
            logTextField.text! += content!
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: NSDate? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }


}

