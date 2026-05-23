import Foundation

enum EDLParser {
    static func parseIOReg(_ output: String) -> [DeviceInfo] {
        var devices: [DeviceInfo] = []
        let lines = output.split(separator: "\n").map(String.init)

        var currentVendor = ""
        var currentProduct = ""
        var currentSerial = ""

        for line in lines {
            if line.contains("idVendor") {
                currentVendor = value(from: line)
            }
            if line.contains("idProduct") {
                currentProduct = value(from: line)
            }
            if line.contains("USB Serial Number") {
                currentSerial = value(from: line)
            }

            if line.contains("}") {
                let isQualcommVendor = currentVendor.lowercased().contains("0x05c6")
                let is9008Product = currentProduct.lowercased().contains("0x9008")
                if isQualcommVendor && is9008Product {
                    devices.append(DeviceInfo(serial: currentSerial.isEmpty ? "9008" : currentSerial, model: "Qualcomm HS-USB QDLoader 9008", state: "edl"))
                }

                currentVendor = ""
                currentProduct = ""
                currentSerial = ""
            }
        }

        return devices
    }

    private static func value(from line: String) -> String {
        line
            .components(separatedBy: "=")
            .dropFirst()
            .joined(separator: "=")
            .trimmingCharacters(in: CharacterSet(charactersIn: " \"<>"))
    }
}
