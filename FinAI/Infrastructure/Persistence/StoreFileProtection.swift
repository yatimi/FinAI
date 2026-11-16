//
//  StoreFileProtection.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import Foundation

/// Applies iOS Data Protection to the existing store location without changing its backup policy.
struct StoreFileProtection {
    enum ProtectionError: Error, Equatable { case invalidStoreLocation, unexpectedFile, protectionUnavailable }

    func prepareDirectory(for store: URL) throws {
        guard store.isFileURL else { throw ProtectionError.invalidStoreLocation }
        let directory = store.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                 attributes: [.protectionKey: FileProtectionType.complete])
        try protect(directory, expectedType: .typeDirectory)
    }

    func protectStoreFiles(at store: URL) throws {
        guard store.isFileURL else { throw ProtectionError.invalidStoreLocation }
        for suffix in ["", "-wal", "-shm"] {
            let file = URL(fileURLWithPath: store.path + suffix)
            if FileManager.default.fileExists(atPath: file.path) { try protect(file, expectedType: .typeRegular) }
        }
    }

    private func protect(_ url: URL, expectedType: FileAttributeType) throws {
        let manager = FileManager.default
        let before = try manager.attributesOfItem(atPath: url.path)
        guard before[.type] as? FileAttributeType == expectedType else { throw ProtectionError.unexpectedFile }
        try manager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        #if !targetEnvironment(simulator)
        // The simulator does not expose iOS protection classes. A device must verify this boundary.
        let protection = try manager.attributesOfItem(atPath: url.path)[.protectionKey]
        guard (protection as? FileProtectionType) == .complete
                || (protection as? String) == FileProtectionType.complete.rawValue else {
            throw ProtectionError.protectionUnavailable
        }
        #endif
    }
}
