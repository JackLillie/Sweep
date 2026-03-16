import SwiftUI

struct SmartCleanView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning your Mac...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.cleanableItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(.purple)
                    Text("Ready to scan")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Find junk files, caches, and logs to clean up.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await viewModel.scanForCleanables() }
                    } label: {
                        Text("Scan")
                            .frame(minWidth: 80)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary
                        GroupBox {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(viewModel.formattedCleanableSize) can be cleaned")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("\(viewModel.cleanableItems.count) categories found")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                        }

                        // Items
                        GroupBox {
                            VStack(spacing: 0) {
                                ForEach(viewModel.cleanableItems.indices, id: \.self) { index in
                                    CleanableItemRow(item: $viewModel.cleanableItems[index])
                                    if index < viewModel.cleanableItems.count - 1 {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                Divider()

                // Bottom bar
                HStack {
                    Text("Selected: \(viewModel.formattedCleanableSize)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Task { await viewModel.scanForCleanables() }
                    } label: {
                        Text("Scan Again")
                    }
                    .controlSize(.regular)

                    Button {
                        // TODO: Wire clean action
                    } label: {
                        Text("Clean")
                            .frame(minWidth: 60)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
    }
}

struct CleanableItemRow: View {
    @Binding var item: CleanableItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.system(size: 14))
                .foregroundStyle(color(for: item.category))
                .frame(width: 32, height: 32)
                .background(color(for: item.category).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                Text(item.path)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.formattedSize)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)

            Toggle("", isOn: $item.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }

    private func color(for category: CleanableCategory) -> Color {
        switch category.color {
        case "blue": .blue
        case "purple": .purple
        case "orange": .orange
        case "red": .red
        case "green": .green
        case "indigo": .indigo
        default: .gray
        }
    }
}
