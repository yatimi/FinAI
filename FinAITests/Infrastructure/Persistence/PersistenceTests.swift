//
//  PersistenceTests.swift
//  FinAITests
//
//  Created by Tommy on 08.10.26.
//

import Testing

// SwiftData shares entity metadata in-process. Legacy and current schemas must not be built concurrently.
@Suite(.serialized)
struct PersistenceTests {}
