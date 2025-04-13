//
//  WalkthroughScreen.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI

// WalkThrough Screen....

struct WalkthroughScreen: View {
    @AppStorage("hasCompletedWalkthrough") var hasCompletedWalkthrough: Bool = false
    @AppStorage("currentPage") var currentPage = 1
    
    var body: some View{
        
        // For Slide Animation...
        
        ZStack{
            
            // Changing Between Views....
            
            if currentPage == 1 {
                ScreenView(
                    image: "image1",
                    title: "Search and select your destination:",
                    detail: "Find your desired stop or station using the search feature or move around the map and long press on the map.",
                    startColor: Color("4"),
                    endColor: Color("5")
                )
                .transition(.scale)
            }
            if currentPage == 2 {
                
                ScreenView(
                    image: "image2",
                    title: "Customize your alarm:",
                    detail: "Set how far from your stop you'd wish to be woken up.\n0.3 miles equals about 6 blocks away",
                    startColor: Color("4"),
                    endColor: Color("5")
                )
                .transition(.scale)
            }
            
            if currentPage == 3 {
                
                ScreenView(
                    image: "image3",
                    title: "Sit back and relax:",
                    detail: "We'll track your journey and you'll get a call from the when you're near your destination. Enjoy a worry-free rest!",
                    startColor: Color("4"),
                    endColor: Color("5")
                )
                .transition(.scale)
            }
            
        }
        .overlay(
            
            // Button...
            Button(action: {
                // changing views...
                withAnimation(.easeInOut){
                    
                    // checking....
                    if currentPage <= totalPages{
                        currentPage += 1
                    } else {
                        // For app testing only...
//                        currentPage = 1
                        // Marking the walkthrough as completed
                        hasCompletedWalkthrough = true
                    }
                }
            }, label: {
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 22))
                    .foregroundColor(Color("1"))
                    .frame(width: 30, height: 30)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color("MainOrange"),
                                    Color("MainOrange"),
                                    Color.orange
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                // Circlular Slider...
                    .overlay(
                        ZStack{
                            Circle()
                                .stroke(Color.white.opacity(0.04),lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: CGFloat(currentPage) / CGFloat(totalPages))
                                .stroke(Color.white,lineWidth: 4)
                                .rotationEffect(.init(degrees: -90))
                        }
                            .padding(-15)
                    )
            })
            .padding(.bottom,20)
            
            ,alignment: .bottom
        )
    }
}

struct ScreenView: View {
    
    var image: String
    var title: String
    var detail: String
    var startColor: Color
    var endColor: Color
    
    @AppStorage("currentPage") var currentPage = 1
    
    var body: some View {
        VStack(spacing: 20){
            
            HStack{
                
                // Showing it only for first Page...
                if currentPage == 1{
                    Text("Welcome to Snooze Lane!")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    // Letter Spacing...
                        .kerning(1.4)
                }
                else{
                    // Back Button...
                    Button(action: {
                        withAnimation(.easeInOut){
                            currentPage -= 1
                        }
                    }, label: {
                        
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(.vertical,10)
                            .padding(.horizontal)
                            .background(Color.white.opacity(0.4))
                            .cornerRadius(10)
                    })
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut){
                        currentPage = 4
                    }
                }, label: {
                    Text("Skip")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .kerning(1.2)
                        .padding(.vertical,8)
                        .padding(.horizontal,12)
                })
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                
            }
            .foregroundColor(.black)
            .padding()
            
            Spacer(minLength: 0)
            
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top)
            
            // Change with your Own Thing....
            Text(detail)
                .fontWeight(.semibold)
                .kerning(1.3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
            
            // Minimum Spacing When Phone is reducing...
            
            Spacer(minLength: 120)
        }
        .background(
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)
            .ignoresSafeArea()
        )
    }
}

// total Pages...
var totalPages = 3


#Preview {
    WalkthroughScreen()
}
