//
//  BoardViewController+DragDrop.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/24.
//

import Cocoa

//extension BoardViewController {
//    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//        return fundData[row][0] as NSString
//    }
//
//    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
//        guard dropOperation == .above,
//              let tableView = info.draggingSource as? NSTableView else { return [] }
//
//        tableView.draggingDestinationFeedbackStyle = .gap
//        return [.move]
//    }
//
//    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
//        guard let items = info.draggingPasteboard.pasteboardItems,
//              let pasteBoardItem = items.first,
//              let pasteBoardItemName = pasteBoardItem.string(forType: .string),
//              let index = fundData.firstIndex(where: {$0[0] == pasteBoardItemName}) else { return false }
//
//        let indexset = IndexSet(integer: index)
//        fundData.move(fromOffsets: indexset, toOffset: row)
//
//        /* Animate the move to the rows in the table view. The ternary operator
//         is needed because dragging a row downwards means the row number is 1 less */
//        tableView.beginUpdates()
//        tableView.moveRow(at: index, to: (index < row ? row - 1 : row))
//        tableView.endUpdates()
//
//        return true
//    }
//}

//MARK: - SupportDragAndDrop

extension BoardViewController {
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let typeIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "z" as CFString, nil)
        let provider = FundPromiseProvider(fileType: typeIdentifier!.takeRetainedValue() as String, delegate: self)
        provider.userInfo = [FundPromiseProvider.UserInfoKeys.rowNumberKey: row]
        return provider
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard dropOperation == .above, let draggingSource = info.draggingSource as? NSTableView else { return [] }
        draggingSource.draggingDestinationFeedbackStyle = .gap
        return [.move]
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if let draggingSource = info.draggingSource as? NSTableView, draggingSource == tableView {
            var idxToMove = IndexSet()

            info.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: tableView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: {(draggingItem, idx, stop) in
                    if  let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                        let fundRow = pasteboardItem.propertyList(forType: .rowDragType) as? Int {
                        idxToMove.insert(fundRow)
                    }
                })

            // Move/drop the photos in their correct place using their indexes.
            moveObjectsFromIndexes(idxToMove, toIndex: row)

            // Set the selected rows to those that were just moved.
            let rowsMovedDown = rowsMovedDownward(row, indexSet: idxToMove)
            let selectionRange = row - rowsMovedDown..<row - rowsMovedDown + idxToMove.count
            let indexSet = IndexSet(integersIn: selectionRange)
            tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        }
        return true
    }

    // Move the set of objects within the indexSet to the 'toIndex' row number.
    func moveObjectsFromIndexes(_ indexSet: IndexSet, toIndex: Int) {
        var insertIndex = toIndex
        var currentIndex = indexSet.last
        var aboveInsertCount = 0
        var removeIndex = 0

        while currentIndex != nil {
            if currentIndex! >= toIndex {
                removeIndex = currentIndex! + aboveInsertCount
                aboveInsertCount += 1
            } else {
                removeIndex = currentIndex!
                insertIndex -= 1
            }

            let object = fundData[removeIndex]
            fundData.remove(at: removeIndex)
            fundData.insert(object, at: insertIndex)

            currentIndex = indexSet.integerLessThan(currentIndex!)
        }
    }

    // Returns the number of rows dragged in a downward direction within the table view.
    func rowsMovedDownward(_ row: Int, indexSet: IndexSet) -> Int {
        var rowsMovedDownward = 0
        var currentIndex = indexSet.first
        while currentIndex != nil {
            if currentIndex! < row {
                rowsMovedDownward += 1
            }
            currentIndex = indexSet.integerGreaterThan(currentIndex!)
        }
        return rowsMovedDownward
    }

}

extension BoardViewController: NSFilePromiseProviderDelegate {
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        var returnFund: [String]?
        if  let userInfo = filePromiseProvider.userInfo as? [String: Any],
            let row = userInfo[FundPromiseProvider.UserInfoKeys.rowNumberKey] as? Int {
            returnFund = fundData[row]
        }
        return returnFund?[0] ?? ""
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {

    }
}

class FundPromiseProvider: NSFilePromiseProvider {
    struct UserInfoKeys {
        static let rowNumberKey = "rowNumber"
        static let urlKey = "url"
    }

    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.rowDragType)
        return types
    }

    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard let userInfoDict = userInfo as? [String: Any] else { return nil }

        switch type {
        case .rowDragType:
            if let numObj = userInfoDict[UserInfoKeys.rowNumberKey] as? Int {
                return numObj
            }
        default: break
        }

        return super.pasteboardPropertyList(forType: type)
    }
}
