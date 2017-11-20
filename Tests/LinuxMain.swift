#if os(Linux)

import XCTest
@testable import AppTests

XCTMain([
    // AppTests
    testCase(GenerateSignerTests.allTests)
])

#endif
