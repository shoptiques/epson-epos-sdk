//
//  ePOS.swift
//
//  Created by Sam Galizia on 6/27/17.
//  Copyright © 2017 Sam Galizia. All rights reserved.
//

import Foundation

private var grayscale: Bool { return Defaults.object(for: .printerGrayscale) ?? false }
private var blackLine: Bool { return Defaults.object(for: .printerBlackLine) ?? false }

class ePOS: NSObject {
  fileprivate let printer: Epos2Printer
  fileprivate let address: String

  init(address: String) {
    self.address = address
    printer = Epos2Printer(printerSeries: EPOS2_TM_M30.rawValue, lang: EPOS2_MODEL_ANK.rawValue)
    super.init()
  }

  deinit {
    Log.verbose(#function, self, context: "printer")
  }

  fileprivate func send() {
    let status = printer.connect(address, timeout: Int(EPOS2_PARAM_DEFAULT))
    if status == 0 {
      printer.setReceiveEventDelegate(self) // retains
      printer.beginTransaction()
      printer.sendData(Int(EPOS2_PARAM_DEFAULT))
    } else {
      Log.warning("status:", status, "address:", address, context: "printer")
    }
    // cleanup done via delegate
  }

  func print(image: UIImage) {
    printer.add(image, x: 0, y: 0,
                width:Int(image.size.width),
                height:Int(image.size.height) - (blackLine ? 0 : 20),
                color: EPOS2_PARAM_DEFAULT,
                mode: (grayscale ? EPOS2_MODE_GRAY16 : EPOS2_MODE_MONO).rawValue,
                halftone: EPOS2_HALFTONE_THRESHOLD.rawValue,
                brightness: Double(EPOS2_PARAM_DEFAULT),
                compress: EPOS2_COMPRESS_AUTO.rawValue)

    printer.addCut(EPOS2_CUT_FEED.rawValue)
    send()
  }

  func openDrawer() {
    printer.addPulse(EPOS2_PARAM_DEFAULT, time: EPOS2_PARAM_DEFAULT)
    send()
  }
}

// MARK: - Epos2PtrReceiveDelegate

extension ePOS: Epos2PtrReceiveDelegate {
  func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
    printerObj.endTransaction()
    printerObj.disconnect()
    printerObj.clearCommandBuffer()
    printerObj.setReceiveEventDelegate(nil)
    Log.verbose(#function, self, context: "printer")
  }
}
