//
//  ContentView.swift
//  Tip Calculator
//
//  Created by Jamie on 26/9/24.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var tipCalculator = TipCalculator()
    
    // State variables that are used for UI elements and automatically update
    @State private var defaultTips: [Decimal] = [0.05, 0.1, 0.15, 0.2]
    @State private var showShares: Bool = false
    let localeOptions: [String] = ["AUD", "USD", "GBP", "EUR", "Other"]
    @State private var useCashText: String = "I'm Paying Cash"
    
    
    
    /*
     isMacOS:
     
     Useful for UI elements that either don't work on iOS or don't look right
     For example, a popover's arrowEdge doesn't look the same on iOS as it does on macOS
     */
    var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /*
     This is the main view of the app
     All controls are placed inside here, including groups/stacks
     */
    var body: some View {
        /// Title shown on iOS because it looks nice, but isn't really needed on macOS as that has a title bar
        if !isMacOS {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(maxHeight: 12)
                Text("Tip Calculator")
                    .font(.largeTitle)
                    .padding(.horizontal, 12)
                Text("A SwiftUI demo with cross-platform compatibility")
                    .padding(.horizontal, 12)
                Spacer().frame(maxHeight: 12)
            }
        }
        
        /// This primary VStack contains all elements and lays them out in a vertical order, top to bottom
        VStack(alignment: .center, spacing: 0) {
            /// This is the top field of objects; text fields and buttons
            VStack {
                
                // Use .currency formatting and a decimal value for extremely easy visual formatting while retaining a error-checked and validated decimal stored in TipCalculature.swift
                HStack {
                    Text("Price:")
                    TextField("Price", value: $tipCalculator.price, format: .currency(code: Locale.current.currency?.identifier ?? "AUD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Tip %:")
                    TextField("Tip %", value: $tipCalculator.tip, format: .percent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onAppear {
                            
                        }
                }
                
                HStack {
                    ForEach(defaultTips, id: \.self) { t in
                        Button(action: {
                            tipCalculator.tip = t
                        }) {
                            Text(t.formatted(.percent))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding()
            .frame(alignment: .top) /// keep it aligned to the top instead of center
            
            /// GroupBox for the group splitting feature, includes the toggle and a numerical stepper if the toggle is on. Looks really nice in the groupbox and also contains it for the animation at the end when toggled
            GroupBox {
                VStack(alignment: .center) {
                    Toggle(isOn: $tipCalculator.split) {
                        Text("Group Split")
                    }
                    .toggleStyle(.automatic)
                    .zIndex(2)
                    .onChange(of: tipCalculator.split) { _, _ in
                        useCashText = tipCalculator.split ? "We're Paying Cash" : "I'm Paying Cash"
                    }
                    
                    if tipCalculator.split {
                        Stepper("\(tipCalculator.splitSize) People", value: $tipCalculator.splitSize, in: 2...20) /// Limited to 20 for the sake of the individual shares list provided at the bottom, but technically it could go to a very large number
                            .transition(.opacity.combined(with: .move(edge: .top))) /// This transition is an Opacity transition combined with a Move from top to bottom (down) transition. It gives a very nice Apple feel, especially with the use of the .spring animation timing below.
                            .zIndex(1)
                    }
                }
            }
            .animation(.spring, value: tipCalculator.split) /// .spring is Apple's own animation timer that feels natural and pleasing. Similar to Easing, but not quite the same.
            .frame(alignment: .topLeading)
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            GroupBox {
                VStack {
                    Toggle(isOn: $tipCalculator.useCash) {
                        Text(useCashText)
                    }
                    .frame(alignment: .leading)
                    .zIndex(2)
                    
                    if tipCalculator.useCash {
                        Picker("", selection: $tipCalculator.selectedLocale) {
                            ForEach(localeOptions, id: \.self) { locale in
                                Text(locale).tag(locale)
                            }
                        }
                        .pickerStyle(.segmented)
                        #if os(macOS)
                        .padding(.leading, -7) // macOS has this weird extra padding on the left side of the picker, I don't like it
                        #endif
                        .frame(maxWidth: isMacOS ? 220 : .infinity)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.spring, value: tipCalculator.useCash)
                        .zIndex(1)
                    }
                }
            }
            .animation(.spring, value: tipCalculator.split)
            .animation(.spring, value: tipCalculator.useCash)
            .frame(alignment: .top)
            .padding(.horizontal)
            
            /**
             This VStack is aligned to the bottom and provides a list of our totals: Tip Amount, Total (Price + Tip), and a share split price if group split has been checked.
             
             It feels over engineered but the results are a pleasant iOS feel with the animations and a popover that provides a more specific list of each individual share.
            */
            VStack {
                /// Basic totals can be set to a function call that gets automatically called/updated whenever the @Published variables change (very cool Swift)
                Text("Tip Amount: \(tipCalculator.getTip())")
                Text("Total: \(tipCalculator.getTotal())")
                
                /// The following contains the label for a generalised share split as well as an info button that provides a popover
                HStack(spacing: 0) {
                    if tipCalculator.split {
                        Text("Per Person: \(tipCalculator.getSplit())")
                            .transition(.opacity)
                            .padding(.trailing, 2)
                        
                        Button(action: {
                            showShares.toggle()
                        }) {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        // IMPORTANT: arrowEdge appears different on iOS and macOS. it looks great to have it on the right-side (.trailing) on macOS, however, when set to .bottom it comes out on top on iOS which is the preferred appearance. Unsure why top and bottom are flipped on iOS.
                        .popover(isPresented: $showShares, arrowEdge: isMacOS ? .trailing : .bottom) {
                            VStack {
                                Text("Shares" + (tipCalculator.useCash ? " (Cash)" : ""))
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                
                                ForEach(tipCalculator.getShares(), id: \.self) { share in
                                    Text(share, format: .currency(code: Locale.current.currency?.identifier ?? "AUD"))
                                }
                            }
                            .padding()
                            .presentationCompactAdaptation(.popover) // IMPORTANT: This ensures iOS uses the same popover you see on macOS, as opposed to the large full-screen window popup, which we don't need for this.
                        }
                    }
                }
                .frame(height: 0)
                .animation(.spring, value: tipCalculator.split)
                
            }
            .padding()
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        #if os(macOS)
        // Restrict frame on macOS because otherwise it doesn't look good.
        // It looks fine on iOS, however
        .frame(width: 300, height:  340)
        .fixedSize()
        #endif
    }
}

struct InnerContentView: View {
    @ObservedObject var tipCalculator: TipCalculator
    var body: some View {
        Text(tipCalculator.split ? "We're Paying Cash" : "I'm Paying Cash")
//            .animation(.spring, value: tipCalculator.split)
//            .transition(.move(edge: .trailing))
    }
}


#Preview {
    ContentView()
}
