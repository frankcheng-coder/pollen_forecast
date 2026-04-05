import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(_ message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
