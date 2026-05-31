import Foundation

enum GenericFastbootFlashValidationResult: Equatable {
    case valid
    case invalid(String)
}

struct GenericFastbootFlashValidation {
    static func validate(imagePath: String, partition: String) -> GenericFastbootFlashValidationResult {
        let image = imagePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetPartition = partition.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !image.isEmpty else {
            return .invalid("镜像路径不能为空")
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: image, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return .invalid("镜像文件不存在")
        }

        guard !targetPartition.isEmpty else {
            return .invalid("分区名不能为空")
        }

        guard targetPartition.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return .invalid("分区名不能包含空格")
        }

        return .valid
    }
}
