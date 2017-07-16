//
//  ViewController.swift
//  Calculator
//
//  Created by Isaac To on 4/1/17.
//  Copyright © 2017 Isaac To. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var calculationSequenceDisplay: UILabel!
    
    var userIsInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTyping {
            let textCurrenlyInDisplay = display.text!
            if !(digit == "." && textCurrenlyInDisplay.contains(".")) {
                display.text = textCurrenlyInDisplay + digit
            }
        } else {
            display.text = digit
            userIsInTheMiddleOfTyping = true
        }
    }
    
    @IBAction func touchBackspace() {
        if userIsInTheMiddleOfTyping {
            var displayText = display.text!
            
            // Remove the last character
            displayText.remove(at: displayText.index(before: displayText.endIndex))
            
            if displayText == "" {
                displayText = "0"
                userIsInTheMiddleOfTyping = false
            }
            
            display.text = displayText
        }
    }
    
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            // Specify a number formatter for holding maximum of 6 decimal digits
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 6
            
            display.text = formatter.string(from: NSNumber(value: newValue))!
        }
    }
    
    private var brain = CalculatorBrain()
    private var variableValues: Dictionary<String, Double>?
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        if let result = brain.result {
            displayValue = result
        }
        calculationSequenceDisplay.text = brain.description +  (brain.resultIsPending ? " …" : " =")
    }
    
    @IBAction func reinitializeCalculator() {
        display.text = "0"
        calculationSequenceDisplay.text = " "
        userIsInTheMiddleOfTyping = false
        brain.reset()
        
    }
    
}
