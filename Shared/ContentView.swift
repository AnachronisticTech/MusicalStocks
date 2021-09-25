//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Marriner on 25/09/2021.
//

import SwiftUI
import CoreAudio
import AVKit

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear { generate_pitch(frequency: 440)}
    }


    func generate_pitch(frequency:Int){
        
        
        let engine = AVAudioEngine()
        let speedControl = AVAudioUnitVarispeed()
        let pitchControl = AVAudioUnitTimePitch()
        
        
        func play(_ url: URL) throws {
            // 1: load the file
            let file = try AVAudioFile(forReading: url)

            // 2: create the audio player
            let audioPlayer = AVAudioPlayerNode()

            // 3: connect the components to our playback engine
            engine.attach(audioPlayer)
            engine.attach(pitchControl)
            engine.attach(speedControl)

            // 4: arrange the parts so that output from one is input to another
            engine.connect(audioPlayer, to: speedControl, format: nil)
            engine.connect(speedControl, to: pitchControl, format: nil)
            engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)

            // 5: prepare the player to play its file from the beginning
            audioPlayer.scheduleFile(file, at: nil)

            // 6: start the engine and player
            try engine.start()
            audioPlayer.play()
        }
        
        do {
            try play(
                Bundle.main.url(forResource: "A", withExtension: "mp3")!
            )
        }
        catch{
            print("Couldn't play file")
        }
        
    }

    

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



