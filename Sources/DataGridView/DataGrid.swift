/**
 * Copyright 2020, Ray Fix
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software * without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public struct DataGrid {
  private(set) var rowNames: [String]
  private(set) var columnNames: [String]

  private var data: [[String?]]

  public var columns: Range<Int> {
    columnNames.indices
  }

  public var rows: Range<Int> {
    rowNames.indices
  }

  public init(rowNames: [String], columnNames: [String], repeating value: String? = nil) {
    self.rowNames = rowNames
    self.columnNames = columnNames
    self.data = rowNames.indices.map { _ in
      columnNames.indices.map { _ in
        value
      }
    }
  }

  public func contains(row: Int, column: Int) -> Bool {
    rows.contains(row) && columns.contains(column)
  }

  public subscript(row row: Int, column column: Int) -> String? {
    get {
      guard contains(row: row, column: column) else {
        return nil
      }
      return data[row][column]
    }
    set {
      data[row][column] = newValue
    }
  }

  public func column(at columnIndex: Int) -> AnySequence<String?> {
    AnySequence(
      sequence(state: 0) { rowIndex in
        guard rows.contains(rowIndex) else {
          return nil
        }
        defer {
          rowIndex += 1
        }
        return self[row: rowIndex, column: columnIndex]
      }
    )
  }
}


/// Test data
extension DataGrid {
  static func test(rows: Int, columns: Int) -> DataGrid {
    var dataGrid = DataGrid(
      rowNames: (1...rows).map { "Row \($0)" },
      columnNames: (1...columns).map { "Column \($0)" }   )

    // Add some random data
    (0..<rows).forEach { row in
      (0..<columns).forEach { column in
        dataGrid[row: row, column: column] = String(Double.random(in: 0..<1))
      }
    }
    return dataGrid
  }
}
