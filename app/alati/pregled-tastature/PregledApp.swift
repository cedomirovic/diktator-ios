import SwiftUI
import UIKit

/// Probna aplikacija za snimak tastature u „drugoj“ aplikaciji.
/// Ne ulazi u build Diktatora: koristi je samo `app/uzmi-snimak-tastature.sh`,
/// koji je prevede zajedno sa pravim `KeyboardViewController`-om.
struct PregledTastature: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let pozadina = UIViewController()
        pozadina.view.backgroundColor = .clear

        let tastatura = KeyboardViewController()
        pozadina.addChild(tastatura)
        tastatura.view.translatesAutoresizingMaskIntoConstraints = false
        pozadina.view.addSubview(tastatura.view)
        NSLayoutConstraint.activate([
            tastatura.view.leadingAnchor.constraint(equalTo: pozadina.view.leadingAnchor),
            tastatura.view.trailingAnchor.constraint(equalTo: pozadina.view.trailingAnchor),
            tastatura.view.bottomAnchor.constraint(equalTo: pozadina.view.bottomAnchor),
        ])
        tastatura.didMove(toParent: pozadina)

        return pozadina
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@main
struct PregledApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                Color(red: 0.97, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes")
                        .font(.system(size: 34, weight: .bold))

                    Text("Message")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("Hello! This is the text Diktator recognised from speech, with names and punctuation in place.")
                        .font(.system(size: 17))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)

                VStack {
                    Spacer()
                    PregledTastature()
                        .frame(height: 291)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
