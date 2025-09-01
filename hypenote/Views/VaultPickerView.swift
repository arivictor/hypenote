//
//  VaultPickerView.swift
//  hypenote
//
//  First-run vault selection interface
//

import SwiftUI

struct VaultPickerView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var showingFolderPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App icon and title
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Welcome to hypenote")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("A fast, minimal Zettelkasten note-taking app for macOS")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Text("Choose a location for your notes")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await appViewModel.createDefaultVault()
                        }
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Use Default Location")
                            Spacer()
                            Text("~/Library/Application Support/hypenote-vault")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingFolderPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                            Text("Choose Custom Location")
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if appViewModel.vaultManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Setting up vault...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = appViewModel.vaultManager.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(40)
        .frame(width: 500, height: 400)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await appViewModel.setVaultLocation(url)
                    }
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }
}