//
//  StackInstructionType.swift
//
//
//  Created by onnerb on 14/09/22.
//

import Foundation

enum StackInstructionType {
    case push
    case pop
    case erase
    case insert(at: Int)
    case sync(() async -> Void)
}
