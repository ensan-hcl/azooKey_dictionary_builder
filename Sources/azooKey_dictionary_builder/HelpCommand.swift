import ArgumentParser

extension azooKey_dictionary_builder {
    struct Help: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show help for this utility.")
        mutating func run() {
            print(azooKey_dictionary_builder.helpMessage())
        }
    }
}
