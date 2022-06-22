//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

import XCTest
@testable import Glider

final class TableFormattersTest: XCTestCase {
    
    func test_tableFormattersTests() async throws {
        let console = ConsoleTransport {
            $0.formatters = [TableFormatter(messageFields: [
                .timestamp(style: .iso8601),
                .delimiter(style: .spacedPipe),
                .message()
            ],
            tableFields: [
                .subsystem(),
                .level(style: .simple),
                .callSite(),
                .extra(keys: ["MixPanel", "Logged"])
            ])]
        }
        let log = Log {
            $0.subsystem = "Indomio.Network"
            $0.transports = [console]
            $0.level = .debug
        }
        
        log.info?.write(event: {
            $0.message = "Just a simple text message"
            $0.extra = [
                "MixPanel": "enabled",
                "Logged": true
            ]
        })
        /*
        let col1 = Table.Column {
            $0.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            $0.header = .init(title: "INFO", { header in
                header.fillCharacter = " "
                header.topBorder = .boxDraw.heavyHorizontal
                header.trailingMargin = " \(Character.boxDraw.heavyVertical)"
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            $0.maxWidth = 20
            $0.horizontalAlignment = .leading
            $0.leadingMargin = "\(Character.boxDraw.heavyVertical) "
            $0.trailingMargin = " \(Character.boxDraw.heavyVertical)"
        }
        let col2 = Table.Column {
            $0.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            $0.header = .init(title: "VALORE", { header in
                header.fillCharacter = " "
                header.leadingMargin = "\(Character.boxDraw.heavyVertical) "
                header.topBorder = .boxDraw.heavyHorizontal
                header.trailingMargin = " \(Character.boxDraw.heavyVertical)"
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            $0.horizontalAlignment = .leading
            $0.leadingMargin = "\(Character.boxDraw.heavyVertical) "
            $0.trailingMargin = " \(Character.boxDraw.heavyVertical)"
        }
        let col3 = Table.Column {
            $0.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            $0.header = .init(title: "col3", { header in
                header.fillCharacter = " "
                header.leadingMargin = "\(Character.boxDraw.heavyVertical) "
                header.topBorder = .boxDraw.heavyHorizontal
                header.trailingMargin = " \(Character.boxDraw.heavyVertical)"
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            $0.horizontalAlignment = .leading
            $0.leadingMargin = "\(Character.boxDraw.heavyVertical) "
            $0.trailingMargin = " \(Character.boxDraw.heavyVertical)"
        }
        let cols = Table.Column.configureBorders(in: [col1, col2, col3], style: .light)

        
        let table: Table = Table(columns: cols, content: [
            "riga 1 molto molto lunga ma anche molto interessante da leggere e ricordare!\ncerto che si!",
            "colonna 2",
            "la colonna 3"
        ])
    
        print(table.stringValue)*/
    }
    
}
