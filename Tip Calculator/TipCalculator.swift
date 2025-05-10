//
//  TipCalculator.swift
//  Tip Calculator
//
//  Created by Jamie on 26/9/24.
//

import Foundation

class TipCalculator: ObservableObject {
    /*
     Published state variables that are used for UI elements
     as well as for computation
     */
    @Published var price: Decimal = 0.0
    @Published var tip: Decimal = 0.1
    @Published var split: Bool = false
    @Published var splitSize: Int = 2
    
    @Published var useCash: Bool = false
    @Published var selectedLocale: String = Locale.current.currency?.identifier ?? "Other"
    @Published var otherDenominator: Decimal = 0.01
    
    /**
     This function gets the total tip amount as a string based on the current culture info.
     
     - Returns: price x tip, formatted as currency (tries Locale.current, defaults to AUD)
     */
    func getTip() -> String {
        let total: Decimal = roundMoney(amount: price + price * tip)
        let realTip: Decimal = total - price
        return realTip.formatted(.currency(code: Locale.current.currency?.identifier ?? "AUD"))
    }
    
    /**
     This function gets the total amount, including tip, as a string based on the current culture info.
     
     - Returns: price + price x tip, formatted as currency (tries Locale.current, defaults to AUD)
     */
    func getTotal() -> String {
        let total: Decimal = roundMoney(amount: price + price * tip)
        return total.formatted(.currency(code: Locale.current.currency?.identifier ?? "AUD")) + getCashString()
    }
    
    func getCashString() -> String {
        if useCash {
            return " (Cash)"
        }
        return ""
    }
    
    func getDenominator() -> Decimal {
        var denominator: Decimal = 0.01
        if useCash {
            if selectedLocale == "Other" {
                denominator = otherDenominator
            } else if selectedLocale == "AUD" {
                denominator = 0.05
            }
        }
        return denominator
    }
    
    func roundMoney(amount: Decimal) -> Decimal {
        let denominator: Decimal = getDenominator()
        var divided = amount / denominator
        var rounded = Decimal()
        NSDecimalRound(&rounded, &divided, 0, .plain)
        return rounded * denominator
    }
    
    
    /**
     This functions gets the general amount per person if the total is being split amongst a group. This can be off be a cent for specific cases, in which case, use getShares().
     
     - Returns: (price + price x tip) / groupSize, formatted as currency (tries Locale.current, defaults to AUD)
     */
    func getSplit() -> String {
        let baseSplit: Decimal = roundMoney(amount: (price + price * tip) / Decimal(splitSize))
        return baseSplit.formatted(.currency(code: Locale.current.currency?.identifier ?? "AUD")) + getCashString()
    }
    
    /**
     This function gets a list of shares, representing each person's share to make up the total cost (based on the group size). This is useful in specific circumstances where one or more people need to pay one extra cent than others due to rounding.
     
     - Returns: Array of Decimal, such as [12.33, 12.33, 12.34]
     */
    func getShares() -> [Decimal] {
        // first we get the denominations, then use that to determine the number of people who need to pay 1 extra denomination
        let total: Decimal = roundMoney(amount: price + price * tip)
        let denominator: Decimal = getDenominator()
        let totalDenominations: Decimal = total / denominator
        var preciseShare: Decimal = totalDenominations / Decimal(splitSize)
        var baseShare: Decimal = Decimal()
        NSDecimalRound(&baseShare, &preciseShare, 0, .down)
        let extraShareCount: Int = NSDecimalNumber(decimal: (preciseShare - baseShare) * Decimal(splitSize)).rounding(accordingToBehavior: nil).intValue
        var shares: [Decimal] = Array(repeating: baseShare * denominator, count: splitSize)
        if extraShareCount > 0 {
            for i in 0...extraShareCount - 1 {
                shares[i] += denominator
            }
        }
        
        return shares
    }
    
    /**
     This function returns a share and its corresponding count. This is helps reduce the number of Text elements in the "Per Person" details list.
     
     - Returns: Dictionary of Decimal: Int, such as [12.33: 2, 12.34: 1]
     */
    func getCountedShares() -> [Decimal: Int] {
        return Dictionary(grouping: getShares(), by: { $0 })
            .mapValues { $0.count }
    }
}
