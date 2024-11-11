//
//  ContentView.swift
//  Swift14Basics
//
//  Created by Bibek Bhujel on 09/11/2024.
//
import StoreKit
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            AppStoreReview()
        }
        .padding()
    }
}

// how property Wrapper becomes structs
// @State is actually a structure State<Double> in this case

struct HowProperyWrapperBecomesStructs: View{
    // this line of code doesnot mean when the blur amount changes print out the blur amount
    // what it actually saying is when the
    // structure that wraps around the property blur amount changes print out the blur amount
    // State<Double> in this case
    // Neither blur amount or the state structure wrapping it is changing
    // our binding is directly changing the internaly stored value which means the property observer is never being triggered
    // changing the property directly using a button is fine , it goes through the non mutating setter and therefore triggers the didSet observer but using the binding does not , it bypass the setter and adjust the value directly

    @State private var blurAmount = 0.0

    var body: some View {
        VStack {
            Text("Hello, World!")
                .blur(radius: blurAmount)

            // using binding
            Slider(value: $blurAmount, in: 0...20)
                .onChange(of: blurAmount) { oldValue, newValue in
                    print("New value is \(newValue)")
                }

            Button("Random Blur") {
                // using a button bypass the nonmutating setter and triggers the property observer
                blurAmount = Double.random(in: 0...20)
            }
        }
    }

    // how to solve this problem ?
    // and change the value when we bind the property
    // for this we can use the onChange closure
    
}

// confirmation dialogue
struct ConfirmationDialogue: View {
    @State private var showConfirmation = false
    @State private var backgroundColor = Color.white
    var body: some View {
        VStack {
            Button {
                showConfirmation = true
            }label: {
                Text("Show Confirmation")
                    .foregroundStyle(.black)
            }
        }
        .frame(width: 300, height: 300)
        .background(backgroundColor)
         .confirmationDialog(
                    "Choose Color",
                    isPresented: $showConfirmation,
                    actions:  {
                        Button("Red") {
                            backgroundColor = .red
                        }
                        Button("Blue") {
                            backgroundColor = .blue
                        }
                        Button("Yellow") {
                            backgroundColor = .yellow
                        }
                    }
                )
    }
}

// Integrating coreimage framework with swiftUI

struct LearningCoreImage : View {
    @State private var image: Image?
    var body: some View {
        VStack {
            image?
                .resizable()
                .scaledToFit()
        }.onAppear(perform: loadImage)
    }

    // load the image
    func loadImage() {
        // use the UI image
        let inputImage = UIImage(resource: .bibek)
        // image recipe: the core image works with CIImage type
        let beginImage = CIImage(image: inputImage)

        // create core image context and filter
        let context = CIContext()
        let currentFilter = CIFilter.twirlDistortion()
        currentFilter.inputImage = beginImage

        let amount = 1.0
        // using older api to handle the inputs like scale and radius dynamically
        // so regardless of filter we use we can adjust the scale and radius
        // for new api we have to provide the values for each filter dynamically
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(amount, forKey: kCIInputIntensityKey)
        }

        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(amount * 10, forKey: kCIInputScaleKey)
        }

        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(amount * 200, forKey: kCIInputRadiusKey)
        }


        // the output after applying the filter will be an CIImage , this might fail so returns an optional
        guard let outputImage = currentFilter.outputImage else {
            print("Failed to generate output from using filter")
            return
        }
        // use CIcontext to convert it into CGImage, this might also fail so it returns an optional as well
        guard let cgImage = context.createCGImage(
            outputImage,
            from: outputImage
                .extent) else {
            print("Failed to generate cg image from output image")
            return
        }
        // convert CGImage into UIImage
        let uiImage = UIImage(cgImage: cgImage)
        // finally convert UIImage into SwiftUI Image
        image = Image(uiImage: uiImage)
    }
}


// using content unavailable view

struct UsingContextUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No snippets", systemImage: "swift")
        } description: {
            Text("You don't have any snippets yet.")
        } actions: {
            Button {
                // create a snippet
            }label: {
                 Text("Create Snippet")
                    .padding(8)
            }.buttonStyle(.borderedProminent)
        }
    }
}

// loading photos from the user's photo library

struct LoadingPhotosFromUsers: View {
    // store the photo item that was selected
    @State private var pickerItem: PhotosPickerItem?
    // store the selected image as swiftUI image
    @State private var selectedImage: Image?

    var body: some View {
        VStack {
            PhotosPicker(
                "Select a picture",
                selection: $pickerItem,
                matching: .images
            )
            selectedImage?
                .resizable()
                .scaledToFit()
        }.onChange(of: pickerItem) {
            Task {
                selectedImage = try await pickerItem?.loadTransferable(type: Image.self)
            }
        }
    }
}


struct LoadingListOfPhotosSelectedByUsers: View {
    @State private var pickerItems = [PhotosPickerItem]()
    @State private var selectedImages = [Image]()

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 3,
                // load any images except screenshots
                matching: .any(of: [.images, .not(.screenshots)])
            ) {
                Label("Select a picture", systemImage: "photo")
            }

            ScrollView {
                ForEach(0..<selectedImages.count, id: \.self) { i in
                    selectedImages[i]
                        .resizable()
                        .scaledToFit()
                }
            }
        }.onChange(of: pickerItems) {
            Task {
                selectedImages.removeAll()

                for item in pickerItems {
                    if let loadedImage = try await item.loadTransferable(type: Image.self) {
                        selectedImages.append(loadedImage)
                    }
                }
            }
        }
    }
}

// share content using share link
struct ShareLinkView: View {
    var body: some View {
        VStack {
            ShareLink(item: URL(string: "https://www.hackingwithswift.com")!,
                      subject: Text("Learn Swift here"), message: Text("Check out the 100 days of SwiftUI!"))


            // another link with custom label
            ShareLink(item: URL(string: "https://www.hackingwithswift.com")!) {
                Label("Spread the word about Swift", systemImage: "swift")
            }


            // sharing more complex custom data
            // here , image is being used
            let myImage = Image(.bibek)

            ShareLink(item: myImage, preview: SharePreview("Handsome Man", image: myImage)) {
                Label("Click to share", systemImage: "person")
            }
        }
    }


}

// import storekit
    // how to ask the user to leave an appstore review
// leaving a review using a button is not practical
// Only show the review if the user has performed some important task in your app multiple times
// then it is clear that the user wants to review your app ( kinda )
    struct AppStoreReview: View {
        @Environment(\.requestReview) var requestReview

        var body: some View {
            Button("Leave a review") {
                requestReview()
            }
        }
    }

#Preview {
    ContentView()
}
