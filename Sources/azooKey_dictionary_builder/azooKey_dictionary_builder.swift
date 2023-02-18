import ArgumentParser

@main
public struct azooKey_dictionary_builder: ParsableCommand {
    public static var configuration = CommandConfiguration(
        abstract: "A utility for building azooKey dictionary from source data.",
        subcommands: [Help.self, BuildLOUDSCommand.self, BuildCostCommand.self],
        defaultSubcommand: Help.self
    )

    public init() {}
}
