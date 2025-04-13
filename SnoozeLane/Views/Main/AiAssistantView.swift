//
//  AiAssistantView.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 7/27/24.
//

import SwiftUI
import SiriWaveView

struct AiAssistantView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State var vm = AiAssistantViewModel()
    @State var isSymbolAnimating = false
    @State var power: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Personal Voice Assistant")
                .font(.title2)
            
            Spacer()
            SiriWaveView(power: $power)
                .opacity(vm.siriWaveFormOpacity)
                .frame(height: 256)
                .overlay { overlayView }
            Spacer()
            
            switch vm.state {
            case .recordingSpeech:
                cancelRecordingButton
                
            case .processingSpeech, .playingSpeech:
                cancelButton
                
            default: EmptyView()
            }
            
            Picker("Select Voice", selection: $vm.selectedVoice) {
                ForEach(VoiceType.allCases, id: \.self) {
                    Text($0.rawValue).id($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!vm.isIdle)
            
            if case let .error(error) = vm.state {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    var overlayView: some View {
        switch vm.state {
        case .idle, .error:
            startCaptureButton
        case .processingSpeech:
            Image(systemName: "brain")
                .symbolEffect(.bounce.up.byLayer, options: .repeating, value: isSymbolAnimating)
                .font(.system(size: 128))
                .onAppear { isSymbolAnimating = true }
                .onDisappear { isSymbolAnimating = false }
        default: EmptyView()
        }
    }
    
    var startCaptureButton: some View {
        Button {
            vm.startCaptureAudio()
        } label: {
            Image(systemName: "mic.circle")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 128))
        }.buttonStyle(.borderless)
    }
    
    var stopRecordingButton: some View {
            Button {
                vm.finishCaptureAudio()
            } label: {
                Text("Stop Recording")
                    .font(.headline)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.borderless)
        }
    
    var cancelRecordingButton: some View {
        Button(role: .destructive) {
            vm.cancelRecording()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 44))
        }.buttonStyle(.borderless)

    }
    
    var cancelButton: some View {
        Button(role: .destructive) {
            vm.cancelProcessingTask()
        } label: {
            Image(systemName: "stop.circle.fill")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.red)
                .font(.system(size: 44))
        }.buttonStyle(.borderless)

    }
}

#Preview("Idle") {
    AiAssistantView()
}

#Preview("Recording Speech") {
    let vm = AiAssistantViewModel()
    vm.state = .recordingSpeech
    vm.audioPower = 0.2
    return AiAssistantView(vm: vm)
}

#Preview("Processing Speech") {
    let vm = AiAssistantViewModel()
    vm.state = .processingSpeech
    return AiAssistantView(vm: vm)
}

#Preview("Playing Speech") {
    let vm = AiAssistantViewModel()
    vm.state = .playingSpeech
    vm.audioPower = 0.3
    return AiAssistantView(vm: vm)
}

#Preview("Error") {
    let vm = AiAssistantViewModel()
    vm.state = .error("An error has occured")
    return AiAssistantView(vm: vm)
}
