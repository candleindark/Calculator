//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Isaac To on 4/2/17.
//  Copyright © 2017 Isaac To. All rights reserved.
//

import Foundation



struct CalculatorBrain {
    
    var description: String {
        return evaluate().description
    }
    
    private let formatter = NumberFormatter()
    
    /// Type used to represent entries to the calculator
    private enum Entry {
        case constantOperand(Double)
        case variableOperand(String)
        case operation(String)
    }
    
    /// Array for storing the input of operations and operands to the calculator
    private var entries = [Entry]()
    
    /// Type representing different kinds of operations
    private enum Operation {
        case random(randomGenerator: (Void) -> Double)
        case constant(Double)
        case unaryOperation(operation: (Double) -> Double, representationGenerator: (String) -> String)
        case binaryOperation((Double, Double) -> Double)
        case equals
    }
    
    /// Dictionary of operations identified by symbols of type strings
    private var operations: Dictionary<String, Operation> = [
        "RAN" : .random(randomGenerator: { Double(arc4random()) / Double(UInt32.max) }),
        "π" : .constant(Double.pi),
        "e" : .constant(M_E),
        "√" : .unaryOperation(operation: sqrt, representationGenerator: CalculatorBrain.prefixUnaryOperatorRepresentationGenerator(of: "√")),
        "cos" : .unaryOperation(operation: cos, representationGenerator: CalculatorBrain.prefixUnaryOperatorRepresentationGenerator(of: "cos")),
        "eˣ" : .unaryOperation(operation: exp, representationGenerator: CalculatorBrain.prefixUnaryOperatorRepresentationGenerator(of: "e^")),
        "ln" : .unaryOperation(operation: log, representationGenerator: CalculatorBrain.prefixUnaryOperatorRepresentationGenerator(of: "ln")),
        "1/x" : .unaryOperation(operation: {1/$0}, representationGenerator: {"1 / (" + $0 + ")"}),
        "%" : .unaryOperation(operation: {$0/100}, representationGenerator: {"(" + $0 + ") / 100"}),
        "±" : .unaryOperation(operation: {-$0}, representationGenerator: CalculatorBrain.prefixUnaryOperatorRepresentationGenerator(of: "-")),
        "×" : .binaryOperation({$0 * $1}),
        "÷" : .binaryOperation({$0 / $1}),
        "+" : .binaryOperation({$0 + $1}),
        "-" : .binaryOperation({$0 - $1}),
        "=" : .equals
    ]
    
    private static func prefixUnaryOperatorRepresentationGenerator(of symbol: String) -> (String) -> String {
        return {symbol + "(" + $0 + ")"}
    }
    
    /// Perform an operation by adding it to the accumulating entries of operations and operands
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .random, .constant:
                entries.append(.operation(symbol))
            case .unaryOperation, .binaryOperation:
                let (result, _, _) = evaluate()
                if result != nil {
                    entries.append(.operation(symbol))
                }
            case .equals:
                let (result, isPending, _) = evaluate()
                if result != nil && isPending == true {
                    entries.append(.operation(symbol))
                }
            }
        }
    }
    
    /// Evalulate the entries of operations and operands in the calculator brain
    func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String) {
        var accumulator: (value: Double, representation: String)?
        var pendingBinaryOperations = [PendingBinaryOperation]()
        
        for index in entries.indices {
            switch entries[index] {
            case .constantOperand(let operand):
                accumulator = (operand, formatter.string(from: NSNumber(value: operand))!)
            case .variableOperand(let operand):
                accumulator = (variables?[operand] ?? 0.0, operand)
            case .operation(let operationSymbol):
                if let operation = operations[operationSymbol] {
                    switch operation {
                    case .random(let randomGenerator):
                        let value = randomGenerator()
                        accumulator = (value, "RAN()")
                    case .constant(let value):
                        accumulator = (value, operationSymbol)
                    case .unaryOperation(let function, let representationGenerator):
                        accumulator = (function(accumulator!.value), representationGenerator(accumulator!.representation))
                    case .binaryOperation(let function):
                        pendingBinaryOperations.append(PendingBinaryOperation(function: function, firstOperand: accumulator!.value, representation: accumulator!.representation + " " + operationSymbol))
                        accumulator = nil
                    case .equals:
                        let pendingBinaryOperation = pendingBinaryOperations.popLast()!
                        let formatString = pendingBinaryOperations.isEmpty && index == entries.index(before: entries.endIndex) ? "%@ %@" : "(%@ %@)"
                        accumulator = (pendingBinaryOperation.perform(with: accumulator!.value),
                                       String(format: formatString, pendingBinaryOperation.representation, accumulator!.representation))
                    }
                }
            }
        }
        
        var description = ""    // Description of the calculation so far
        for pendingBinaryOperation in pendingBinaryOperations {
            description += pendingBinaryOperation.representation + " "
        }
        description += accumulator?.representation ?? ""
        
        return (accumulator?.value, !pendingBinaryOperations.isEmpty, description)
    }
    
    /// Indicator of whether there is a pending binary operation
    var resultIsPending: Bool {
        return evaluate().isPending
    }
    
    /// Structure for represending a pending binary operation
    private struct PendingBinaryOperation {
        let function: (Double, Double) -> Double
        let firstOperand: Double
        let representation: String
        
        func perform(with secondOperand: Double) -> Double {
            return function(firstOperand, secondOperand)
        }
    }
    
    /// Set an operand
    mutating func setOperand(_ operand: Double) {
        entries.append(.constantOperand(operand))
    }
    
    /// Set a variable operand
    mutating func setOperand(variable named: String) {
        entries.append(.variableOperand(named))
    }
    
    /// The result of the evaluation of the entries of operations and operands in the calculator brain
    var result: Double? {
        return evaluate().result
    }
    
    /// Reset the CalculatorBrain Structure
    mutating func reset() {
        entries = [Entry]()
    }
    
    init() {
        formatter.maximumFractionDigits = 6
    }
}
