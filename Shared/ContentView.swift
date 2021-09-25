//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Marriner on 25/09/2021.
//

import SwiftUI
import CoreAudio
import AVFoundation

struct ContentView: View {
    
    @State var sound: AVAudioPlayer!
    @State var engine = AVAudioEngine()
    @State var speedControl = AVAudioUnitVarispeed()
    @State var pitchControl = AVAudioUnitTimePitch()
 

    // 2: create the audio player
    @State var audioPlayer = AVAudioPlayerNode()
    
    
    var body: some View {
        VStack{
            Text("Hello, world!").padding()
            
            Button("Play Sound"){
                play_numbers(notes:[0.0,200.0,400.0,500.0,700.0,400.0,700.0,400.0,200.0,400.0,500,200.0,400.0,700])
               
            }
            
        }
    }
    
    func play_numbers(notes:[Float]){
        
        let starting_offset:Float = -pow(2.0, 11.0) - 12000
        
        let time_increment = 0.15
        var current_time = DispatchTime.now()
        
        
        for note in notes{
            
            DispatchQueue.main.asyncAfter(deadline: current_time+time_increment) {
                generate_pitch(frequency: starting_offset + note)
            }
            
            current_time = current_time + time_increment
        }
                    
    }
    
    func generate_pitch(frequency:Float){
        
        speedControl.rate = 10
        pitchControl.pitch = frequency
        
        let soundFileURL = Bundle.main.url(forResource: "A", withExtension: "mp3")!
//        do{
//            self.sound = try AVAudioPlayer(contentsOf: soundFileURL)
//            self.sound?.play()
//        }
//        catch{
//            print(":(")
//        }
        func play(_ url: URL) throws {
            // 1: load the file
            let file = try AVAudioFile(forReading: url)

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
        try! play(soundFileURL)

    }
           
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



