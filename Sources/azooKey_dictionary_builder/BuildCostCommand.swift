import Foundation
import ArgumentParser

extension azooKey_dictionary_builder {
    struct BuildCostCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "cost", abstract: "Build cost files from source files.")

        @Argument(help: "Work directory that contains c/ directory which contains csv file named 'cid.csv' for each cid, and mm.csv which is a csv file of mid-mid bigram matrix.")
        var workDirectory: String = ""

        @Flag(name: [.customShort("k"), .customLong("gitkeep")], help: "Adds .gitkeep file.")
        var addGitKeepFile = false

        @Flag(name: [.customShort("c"), .customLong("clean")], help: "Cleans target directory.")
        var cleanTargetDirectory = false

        mutating func run() throws {
            let workDirectoryURL = URL(fileURLWithPath: workDirectory, isDirectory: true)
            if cleanTargetDirectory {
                let cbDirectoryURL = workDirectoryURL.appendingPathComponent("cb", isDirectory: true)
                print("Cleans target directory \(cbDirectoryURL.path)...")
                let fileURLs = try FileManager.default.contentsOfDirectory(at: cbDirectoryURL, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }
                let mmBinaryFileURL = workDirectoryURL.appendingPathComponent("mm.binary", isDirectory: false)
                try FileManager.default.removeItem(at: mmBinaryFileURL)
                print("Done!")
            }
            let builder = CostBuilder(workDirectory: workDirectoryURL)
            print("Generates binary files into \(workDirectoryURL.path)...")
            try builder.build()
            if self.addGitKeepFile {
                print("Adds .gitkeep file into \(workDirectoryURL.path)...")
                try builder.writeGitKeep()
            }
            print("Done!")
        }
    }
}

struct CostBuilder {
    struct Int2Float {
        let int: Int32
        let float: Float
    }

    let workDirectory: URL

    func loadBinaryMM(path: String) -> [Float] {
        do {
            let binaryData = try Data(contentsOf: URL(fileURLWithPath: path), options: [.uncached])

            let ui64array = binaryData.withUnsafeBytes {pointer -> [Float] in
                return Array(
                    UnsafeBufferPointer(
                        start: pointer.baseAddress!.assumingMemoryBound(to: Float.self),
                        count: pointer.count / MemoryLayout<Float>.size
                    )
                )
            }
            return ui64array
        } catch {
            print("Failed to read the file.", error)
            return []
        }
    }

    func loadBinaryIF(path: String) -> [(Int16, Float)] {
        do {
            let binaryData = try Data(contentsOf: URL(fileURLWithPath: path), options: [.uncached])

            let ui64array = binaryData.withUnsafeBytes {pointer -> [(Int16, Float)] in
                return Array(
                    UnsafeBufferPointer(
                        start: pointer.baseAddress!.assumingMemoryBound(to: (Int16, Float).self),
                        count: pointer.count / MemoryLayout<(Int16, Float)>.size
                    )
                )
            }
            return ui64array
        } catch {
            print("Failed to read the file.", error)
            return []
        }
    }

    func build_mm() throws {
        let sourceURL = self.workDirectory.appendingPathComponent("mm.csv", isDirectory: false)
        let targetURL = self.workDirectory.appendingPathComponent("mm.binary", isDirectory: false)

        let string = try String(contentsOf: sourceURL, encoding: .utf8)
        let floats = string.components(separatedBy: .newlines).map {
            $0.components(separatedBy: ",").map {Float($0) ?? -30}
        }
        var flatten: [Float] = floats.flatMap {$0}
        let data = Data(bytes: &flatten, count: flatten.count * MemoryLayout<Float>.size)
        try data.write(to: targetURL, options: .atomic)
    }

    func build_if_c(_ cid: Int) throws {
        let sourceURL = self.workDirectory.appendingPathComponent("c", isDirectory: true).appendingPathComponent("\(cid).csv", isDirectory: false)
        let targetURL = self.workDirectory.appendingPathComponent("cb", isDirectory: true).appendingPathComponent("\(cid).binary", isDirectory: false)

        let string = try String(contentsOf: sourceURL, encoding: .utf8)
        let list: [Int2Float] = string.components(separatedBy: .newlines).map {(string: String) in
            let components = string.components(separatedBy: ",")
            return Int2Float(int: Int32(components[0]) ?? -1, float: Float(components[1]) ?? -30.0)
        }
        let size = MemoryLayout<Int2Float>.size
        let data = Array(Data(bytes: list, count: list.count * size))
        try Data(data).write(to: targetURL, options: .atomic)
    }

    func build_if_m(_ mid: Int) throws {
        let sourceURL = self.workDirectory.appendingPathComponent("m", isDirectory: true).appendingPathComponent("\(mid).csv", isDirectory: false)
        let targetURL = self.workDirectory.appendingPathComponent("mb", isDirectory: true).appendingPathComponent("\(mid).binary", isDirectory: false)

        let string = try String(contentsOf: sourceURL, encoding: .utf8)
        let list: [Int2Float] = string.components(separatedBy: .newlines).map {(string: String) in
            let components = string.components(separatedBy: ",")
            return Int2Float(int: Int32(components[0]) ?? -1, float: Float(components[1]) ?? -30.0)
        }
        let size = MemoryLayout<Int2Float>.size
        let data = Array(Data(bytes: list, count: list.count * size))
        try Data(data).write(to: targetURL, options: .atomic)
    }

    func writeGitKeep() throws {
        let fileURL = self.workDirectory.appendingPathComponent("c", isDirectory: true).appendingPathComponent(".gitkeep", isDirectory: false)
        try "".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func build() throws {
        for i in 0...1318 {
            try build_if_c(i)
        }
        try build_mm()
    }

}
