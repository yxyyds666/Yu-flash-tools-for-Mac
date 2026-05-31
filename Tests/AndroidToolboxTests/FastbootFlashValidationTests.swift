import Foundation
import Testing
@testable import AndroidToolbox

@Test
func genericFlashValidation_acceptsExistingImageAndSimplePartition() throws {
    let image = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".img")
    FileManager.default.createFile(atPath: image.path, contents: Data([0x01]))
    defer { try? FileManager.default.removeItem(at: image) }

    let result = GenericFastbootFlashValidation.validate(imagePath: image.path, partition: "boot")

    #expect(result == .valid)
}

@Test
func genericFlashValidation_rejectsMissingImagePath() {
    let result = GenericFastbootFlashValidation.validate(imagePath: "/tmp/not-exist-\(UUID().uuidString).img", partition: "boot")

    #expect(result == .invalid("镜像文件不存在"))
}

@Test
func genericFlashValidation_rejectsPartitionWithWhitespace() throws {
    let image = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".img")
    FileManager.default.createFile(atPath: image.path, contents: Data([0x01]))
    defer { try? FileManager.default.removeItem(at: image) }

    let result = GenericFastbootFlashValidation.validate(imagePath: image.path, partition: "boot slot")

    #expect(result == .invalid("分区名不能包含空格"))
}
