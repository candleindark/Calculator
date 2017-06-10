//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Isaac To on 4/2/17.
//  Copyright © 2017 Isaac To. All rights reserved.
//

import Foundation



struct CalculatorBrain {
    
    private var accumulator: (value: Double, representation: String)?
    
    var description: String {
        let accumulatorRepresentation = (accumulator?.representation ?? "")
        if resultIsPending {
            return pendingBinaryOperation!.representation + " " + accumulatorRepresentation
        }
        return accumulatorRepresentation
    }
    
    private let formatter = NumberFormatter()
    
    private enum Operation {
        case random(randomGenerator: (Void) -> Double)
        case constant(Double)
        case unaryOperation(operation: (Double) -> Double, representationGenerator: (String) -> String)
        case binaryOperation((Double, Double) -> Double)
        case equals
    }
    
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
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .random(let randomGenerator):
                let value = randomGenerator()
                accumulator = (value, formatter.string(from: NSNumber(value: value))!)
            case .constant(let value):
                accumulator = (value, symbol)
            case .unaryOperation(let function, let representationGenerator):
                if let accumulator = accumulator {
                    self.accumulator = (function(accumulator.value), representationGenerator(accumulator.representation))
                }
            case .binaryOperation(let function):
                if let accumulator = accumulator {
                    pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator.value, representation: accumulator.representation + " " + symbol)
                    self.accumulator = nil
                }
            case .equals:
                performPendingBinaryOperation()
            }
        }
    }
    
    private mutating func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil && accumulator != nil {
            accumulator = (pendingBinaryOperation!.perform(with: accumulator!.value), pendingBinaryOperation!.representation + " " + accumulator!.representation)
            pendingBinaryOperation = nil
        }
    }
    
    /// Indicator of whether there is a pending binary operation
    var resultIsPending: Bool {
        return pendingBinaryOperation != nil
    }
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private struct PendingBinaryOperation {
        let function: (Double, Double) -> Double
        let firstOperand: Double
        let representation: String
        
        func perform(with secondOperand: Double) -> Double {
            return function(firstOperand, secondOperand)
        }
    }
    
    mutating func setOperand(_ operand: Double) {
        accumulator = (operand, formatter.string(from: NSNumber(value: operand))!)
    }
    
    var result: Double? {
        return accumulator?.value
    }
    
    /// Reset the CalculatorBrain Structure
    mutating func reset() {
        accumulator = nil
        pendingBinaryOperation = nil
    }
    
    init() {
        formatter.maximumFractionDigits = 6
    }
}
