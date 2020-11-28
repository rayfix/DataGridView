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

import SwiftUI

// MARK: -

private class GridViewLayout : UICollectionViewLayout {

  let rowHeights: [CGFloat]
  let columnWidths: [CGFloat]
  let xPositions: [CGFloat]
  let yPositions: [CGFloat]

  init(rowHeights: [CGFloat], columnWidths: [CGFloat]) {
    self.rowHeights = rowHeights
    self.columnWidths = columnWidths

    xPositions = columnWidths.reduce(into: [CGFloat(0)]) {
      $0.append($0.last! + $1)
    }
    yPositions = rowHeights.reduce(into: [CGFloat(0)]) {
      $0.append($0.last! + $1)
    }
    super.init()
  }

  required init?(coder decoder: NSCoder) {
    fatalError()
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var attributes: [UICollectionViewLayoutAttributes] = []
    for y in yPositions.dropLast().enumerated() {
      for x in xPositions.dropLast().enumerated() {
        let testPoint = CGPoint(x: x.element, y: y.element)
        if rect.contains(testPoint) {
          let item = layoutAttributesForItem(at: IndexPath(gridRow: y.offset, gridColumn: x.offset))!
          attributes.append(item)
        }
      }
    }
    return attributes
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
    attributes.frame = CGRect(x: xPositions[indexPath.gridColumn],
                              y: yPositions[indexPath.gridRow],
                              width: columnWidths[indexPath.gridColumn],
                              height: rowHeights[indexPath.gridRow])
    return attributes
  }

  override var collectionViewContentSize: CGSize {
    CGSize(width: xPositions.last!, height: yPositions.last!)
  }
}

// MARK: -

private final class RFGridCell: UICollectionViewCell {
  var label: UILabel!

  override init(frame: CGRect) {
    label = UILabel(frame: frame)
    label.textAlignment = .center
    label.font = UIFont.boldSystemFont(ofSize: 17)
    super.init(frame: frame)
    contentView.addSubview(label)
    contentView.layer.borderWidth = 0.5
    contentView.layer.borderColor = UIColor.black.cgColor
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = contentView.bounds
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

private extension IndexPath {
  init(gridRow: Int, gridColumn: Int) {
    self.init(item: gridColumn, section: gridRow)
  }
  var gridRow: Int { section }
  var gridColumn: Int { item }
}

// MARK: -

private final class RFGridView: UIView {

  private var dataGrid: DataGrid
  private var columnHeaderHeight: CGFloat
  private var rowHeaderWidth: CGFloat

  private var rowsView: UICollectionView
  private var columnsView: UICollectionView
  private var contentView: UICollectionView

  private var font: UIFont
  private var missing: String

  override func layoutSubviews() {
    super.layoutSubviews()

    columnsView.frame = CGRect(x: rowHeaderWidth, y: 0,
                               width: bounds.width-rowHeaderWidth,
                               height: columnHeaderHeight)
    rowsView.frame = CGRect(x: 0, y: columnHeaderHeight,
                            width: rowHeaderWidth,
                            height: bounds.height-columnHeaderHeight)
    contentView.frame = CGRect(x: rowHeaderWidth, y: columnHeaderHeight,
                               width: bounds.width-rowHeaderWidth,
                               height: bounds.height-columnHeaderHeight)
  }

  required init?(coder: NSCoder) {
    fatalError("not implemented")
  }

  init(dataGrid: DataGrid, missing: String = "NA", font: UIFont = .boldSystemFont(ofSize: 17)) {
    self.dataGrid = dataGrid
    self.missing = missing
    let height = CGFloat(50)
    self.columnHeaderHeight = height
    let padding = CGFloat(10)
    self.font = font
    let rowHeights = Array(repeating: height, count: dataGrid.rows.count)
    let columnWidths: [CGFloat] = dataGrid.columns.map { columnIndex in
      dataGrid
        .column(at: columnIndex)
        .map { string in
          let bb = NSAttributedString(string: string ?? missing,
                                      attributes: [NSAttributedString.Key.font: font])
            .boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                       height: CGFloat.greatestFiniteMagnitude),
                          options: [.usesLineFragmentOrigin], context: nil)
          return bb.width.rounded(.awayFromZero) + padding
        }
        .max() ?? 0
    }
    rowHeaderWidth = (dataGrid.columnNames.map { string in
      let bb = NSAttributedString(string: string,
                                  attributes: [NSAttributedString.Key.font: font])
        .boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                   height: CGFloat.greatestFiniteMagnitude),
                      options: [.usesLineFragmentOrigin], context: nil)
      return bb.width.rounded(.awayFromZero)  + padding
    }
    .max() ?? 0)

    rowsView =
      UICollectionView(frame: .zero,
                       collectionViewLayout:
                        GridViewLayout(rowHeights: rowHeights,
                                       columnWidths: [rowHeaderWidth]))
    rowsView.backgroundColor = .lightGray
    rowsView.layer.borderColor = UIColor.black.cgColor
    rowsView.layer.borderWidth = 1

    columnsView =
      UICollectionView(frame: .zero,
                       collectionViewLayout:
                        GridViewLayout(rowHeights: [columnHeaderHeight],
                                       columnWidths: columnWidths))
    columnsView.backgroundColor = .lightGray
    columnsView.layer.borderColor = UIColor.black.cgColor
    columnsView.layer.borderWidth = 1

    contentView =
      UICollectionView(frame: .zero,
                       collectionViewLayout:
                        GridViewLayout(rowHeights: rowHeights,
                                       columnWidths: columnWidths))
    contentView.backgroundColor = .white

    super.init(frame: CGRect.zero)

    self.addSubview(rowsView)
    self.addSubview(columnsView)
    self.addSubview(contentView)
    backgroundColor = .lightGray

    rowsView.dataSource = self
    rowsView.delegate = self
    columnsView.dataSource = self
    columnsView.delegate = self
    contentView.dataSource = self
    contentView.delegate = self

    rowsView.register(RFGridCell.self, forCellWithReuseIdentifier: "cell")
    columnsView.register(RFGridCell.self, forCellWithReuseIdentifier: "cell")
    contentView.register(RFGridCell.self, forCellWithReuseIdentifier: "cell")
    layer.borderColor = UIColor.black.cgColor
    layer.borderWidth = 1
  }
}

// MARK: -

extension RFGridView: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    switch collectionView {
    case contentView, rowsView:
      return dataGrid.rows.count
    case columnsView:
      return 1
    default:
      fatalError()
    }
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    switch collectionView {
    case columnsView, contentView:
      return dataGrid.columns.count
    case rowsView:
      return 1
    default:
      fatalError()
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let string: String
    switch collectionView {
    case rowsView:
      string = dataGrid.rowNames[indexPath.gridRow]
    case columnsView:
      string = dataGrid.columnNames[indexPath.gridColumn]
    case contentView:
      string = dataGrid[row: indexPath.gridRow, column: indexPath.gridColumn] ?? missing
    default:
      fatalError()
    }

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell",
                                                  for: indexPath) as! RFGridCell
    cell.label.text = string
    cell.label.font = font
    return cell
  }
}

// MARK: -

/// Link scrolling of the three different collection views.
extension RFGridView: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {

    let contentOffset = scrollView.contentOffset

    switch scrollView {
    case contentView:
      rowsView.contentOffset.y = contentOffset.y
      columnsView.contentOffset.x = contentOffset.x
    case columnsView:
      contentView.contentOffset.x = contentOffset.x
    case rowsView:
      contentView.contentOffset.y = contentOffset.y
    default:
      break
    }
  }
}

// MARK: -

public struct DataGridView: UIViewRepresentable {

  let dataGrid: DataGrid

  public func makeUIView(context: Context) -> some UIView {
    RFGridView(dataGrid: dataGrid, missing: "NA")
  }

  public func updateUIView(_ uiView: UIViewType, context: Context) {
  }
}

