/// https://stackoverflow.com/questions/28487146/how-to-add-live-camera-preview-to-uiview
///
import UIKit
import AVFoundation
import CoreBluetooth

class ViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate{

  @IBOutlet weak var customCameraView: UIView!
  @IBOutlet weak var connectionStatus: UIImageView!
  @IBOutlet weak var weightLabel: UILabel!
  
  //Camera Capture required properties
  var imagePickers:UIImagePickerController?
  var weightMeasure: Double = 0
  var weightMeasureGrams: Double = 0
  
  var centralManager: CBCentralManager!
  let scaleUUID = CBUUID(string: "0x181B")
  var scalePeripheral : CBPeripheral!
  
  override func viewDidLoad() {
      addCameraInView()
      super.viewDidLoad()
      centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  // MARK: - Camera live view, maybe you can overlay the weight value to picture for documentation?
  func addCameraInView(){

      imagePickers = UIImagePickerController()
      if UIImagePickerController.isCameraDeviceAvailable( UIImagePickerController.CameraDevice.rear) {
          imagePickers?.delegate = self
          imagePickers?.sourceType = UIImagePickerController.SourceType.camera

          //add as a childviewcontroller
          addChild(imagePickers!)

          // Add the child's View as a subview
          self.customCameraView.addSubview((imagePickers?.view)!)
          imagePickers?.allowsEditing = false
          imagePickers?.showsCameraControls = false
          imagePickers?.view.autoresizingMask = [.flexibleWidth,  .flexibleHeight]
          }
      }
}

extension ViewController: CBCentralManagerDelegate,CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
      guard let services = peripheral.services else {return}
      
      for service in services {
        print(service)
        peripheral.discoverCharacteristics(nil, for: service)
      }
    }
  
  // MARK: - Parsing data, Byte 11 and 12 for weight data, byte 9 and 10 for Body composition
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
      guard let scaleData = characteristic.value
          else { print("missing updated value"); return }
      
      let weightData = scaleData as NSData
      //                print(weightData)
      
      let lastHex = weightData.last!
      //                print("Weight: ",lastHex)
      let multiplierHex = weightData[11]
      //                print("Multiplier: ",multiplierHex)
      let weightStringValue = lastHex.description
      let weightValue = Int(weightStringValue)!
      print("IntValue: \(weightValue)")
      
      let multiplierStringValue = multiplierHex.description
      let mulitplierValue = Int(multiplierStringValue)!
      print("MulitplierValue: \(mulitplierValue)")
      
      weightMeasure = (((Double(weightValue) * 256) + Double(mulitplierValue)) * 0.005)
      weightMeasureGrams = weightMeasure * 1000
      //                print(weightMeasure)
      self.weightLabel.text = String("\(weightMeasure)") + " Kg"
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
      if let characteristics = service.characteristics {
          for characteristic in characteristics {
              
              switch characteristic.uuid.uuidString{
                  
              case "2A9C":
                  peripheral.setNotifyValue(true, for: characteristic)
                  print("Characteristic: \(characteristic)")
                  peripheral.readValue(for: characteristic)
              default:
                  print("")
              }
          }
      }
  }
  

  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
      case .unknown:
        print("central.state is .unknown")
      case .resetting:
        print("central.state is .resetting")
      case .unsupported:
        print("central.state is .unsupported")
      case .unauthorized:
        print("central.state is .unauthorized")
      case .poweredOff:
        print("central.state is .poweredOff")
      case .poweredOn:
        print("central.state is .poweredOn")
        centralManager.scanForPeripherals(withServices: [scaleUUID])
      //centralManager.scanForPeripherals(withServices: nil)
      @unknown default:
        print("Error")
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected to MiScale")
    connectionStatus.tintColor = .green
    scalePeripheral.discoverServices([scaleUUID])
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    connectionStatus.tintColor = .gray
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print(peripheral)
    scalePeripheral = peripheral
    scalePeripheral.delegate = self
    centralManager.stopScan()
    centralManager.connect(scalePeripheral)
  }
  
}



