//
//  MasterViewController.swift
//  BLEDemo
//
//  Created by Catherine on 2016/10/12.
//  Copyright © 2016年 Catherine. All rights reserved.
//

import UIKit
import CoreBluetooth

class MasterViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var detailViewController: DetailViewController? = nil
    var allItems = [String:DiscoveredItem](); //store all discoverd peripheral
    var lastReloadDate:Date?
    var objects = [Any]()
    // For Service/Characteristic scan
    var deatailInfo = ""
    var restServices = [CBService]()
    var centalManager: CBCentralManager? //?表示可選型別，可能回傳是空

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        centalManager = CBCentralManager(delegate:self, queue: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: Any) {
        objects.insert(NSDate(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //here is called according whole rows
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let allKeys = Array(allItems.keys)
        let targetKey = allKeys[indexPath.row]
        let targetItem = allItems[targetKey]
        let name = targetItem?.peripheral?.name ?? "Unknow"
        cell.textLabel!.text = "\(name) RSSI: \(targetItem!.lastRSSI)"
        let lastScanSecondAgo = String(format: "%if", Date().timeIntervalSince(targetItem!.lastScanDateTime))
        cell.detailTextLabel!.text = "Last scan \(lastScanSecondAgo) seconds ago"
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //detect one of lists is selected, and indexPath represent row index
        let allKeys = Array(allItems.keys)
        let targetKey = allKeys[indexPath.row]
        let targetItem = allItems[targetKey]
        
        NSLog("Connection to \(targetKey) ...")
        centalManager?.connect(targetItem?.peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "Unknown"
        NSLog("Connected to \(name)")
        
        stopScanning()
        
        // Try to discovery the services of peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        showAlert(msg: "Fail to connect!")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let name = peripheral.name ?? "UnKnown"
        NSLog("Disconnected to \(name)")
        
        startToScan()
    }
    
    func startToScan()
    {
        NSLog("start scanning")
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey:true]
        centalManager?.scanForPeripherals(withServices: nil, options: options)
    }
    
    func stopToScan()
    {
        centalManager?.stopScan()
    }
    
    func showAlert(msg: String) {
        // using UIAlertController to show alert msg
        let alert = UIAlertController(title: "", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let status = central.state;
        if status != .poweredOn {
            //show Error Msg
            showAlert(msg: "BLE is not avaiable. (\(status.rawValue))");
        } else {
            startToScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let existItem = allItems[peripheral.identifier.uuidString]
        if existItem == nil {
            let name = (peripheral.name ?? "Unknown")
            NSLog("Discovered: \(name), RSSI: \(RSSI), UDID: \(peripheral.identifier.uuidString), AdvDate: \(advertisementData.description)")
        }
        let newItem = DiscoveredItem(newPeripheral: peripheral, RSSI: Int(RSSI))
        allItems[peripheral.identifier.uuidString] = newItem
        
        //Decide when to reload tableview
        let now = Date()
        if existItem == nil || lastReloadDate == nil || now.timeIntervalSince(lastReloadDate!) > 2.0 {
            lastReloadDate = now
            tableView.reloadData() // Refresh TableView
        }
    }
}

// define data structure for storing bluetooth device information
struct DiscoveredItem {
    var peripheral:CBPeripheral?
    var lastRSSI:Int
    var lastScanDateTime:Date
    init(newPeripheral:CBPeripheral, RSSI:Int) {
        peripheral = newPeripheral
        lastRSSI = RSSI
        lastScanDateTime = Date()
    }
}

