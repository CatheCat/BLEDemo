//
//  SensorDetailViewController.swift
//  BLEDemo
//
//  Created by Catherine on 2016/10/22.
//  Copyright © 2016年 Catherine. All rights reserved.
//

import UIKit
import CoreBluetooth

class SensorDetailViewController: UIViewController, CBPeripheralDelegate {
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
    var tartgetPeripheral: CBPeripheral?
    var targetCharacteristic: CBCharacteristic?
    var incomingBuffer = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let receivedString = String(data: characteristic.value!, encoding: .utf8) else {
            return
        }
        NSLog("Receive: \(receivedString)")
        incomingBuffer += receivedString
        // We got a Json such as {"Humidity": 59.00, "Temperature": 27.00}\r\n
        if incomingBuffer.hasSuffix("\r\n") {
            // Got end of a Json packet
            let data = incomingBuffer.data(using: .utf8) //get NSData
            incomingBuffer = ""
            // JSONSerialization accept NSData
            let jsonObject = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            if let info = jsonObject as? Dictionary<String, Any> {
                // ...
            }
        }
    }

}
