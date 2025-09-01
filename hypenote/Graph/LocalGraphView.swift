//
//  LocalGraphView.swift
//  hypenote
//
//  Local graph view showing connections for the current note
//

import SwiftUI

struct LocalGraphView: View {
    let centerNote: Note
    let connectedNotes: [Note]
    @ObservedObject var appViewModel: AppViewModel
    
    @State private var nodePositions: [String: CGPoint] = [:]
    @GestureState private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Canvas { context, size in
            drawGraph(context: context, size: size)
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = value
                }
        )
        .onAppear {
            calculateNodePositions()
        }
        .onChange(of: connectedNotes) { _ in
            calculateNodePositions()
        }
    }
    
    private func drawGraph(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Draw center note
        drawNode(
            context: context,
            note: centerNote,
            position: center,
            isCenter: true
        )
        
        // Draw connected notes and links
        for (index, note) in connectedNotes.enumerated() {
            let position = nodePositions[note.id] ?? calculateNodePosition(index: index, total: connectedNotes.count, center: center, size: size)
            
            // Draw link line
            drawLink(context: context, from: center, to: position)
            
            // Draw node
            drawNode(
                context: context,
                note: note,
                position: position,
                isCenter: false
            )
        }
    }
    
    private func drawNode(context: GraphicsContext, note: Note, position: CGPoint, isCenter: Bool) {
        let radius: CGFloat = isCenter ? 20 : 15
        let color: Color = isCenter ? .accentColor : .secondary
        
        // Draw node circle
        context.fill(
            Path(ellipseIn: CGRect(
                x: position.x - radius,
                y: position.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(color)
        )
        
        // Draw label
        let title = note.title.isEmpty ? "Untitled" : note.title
        let truncatedTitle = String(title.prefix(20))
        
        context.draw(
            Text(truncatedTitle)
                .font(.caption2)
                .foregroundColor(.primary),
            at: CGPoint(x: position.x, y: position.y + radius + 10),
            anchor: .top
        )
    }
    
    private func drawLink(context: GraphicsContext, from: CGPoint, to: CGPoint) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        
        context.stroke(
            path,
            with: .color(.secondary.opacity(0.5)),
            lineWidth: 1
        )
    }
    
    private func calculateNodePositions() {
        let totalNotes = connectedNotes.count
        guard totalNotes > 0 else { return }
        
        for (index, note) in connectedNotes.enumerated() {
            let angle = 2 * Double.pi * Double(index) / Double(totalNotes)
            let radius: Double = 80
            
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            
            nodePositions[note.id] = CGPoint(x: x, y: y)
        }
    }
    
    private func calculateNodePosition(index: Int, total: Int, center: CGPoint, size: CGSize) -> CGPoint {
        let angle = 2 * Double.pi * Double(index) / Double(total)
        let radius = min(size.width, size.height) * 0.3
        
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    let appViewModel = AppViewModel()
    let centerNote = Note(title: "Center Note")
    let connectedNotes = [
        Note(title: "Connected Note 1"),
        Note(title: "Connected Note 2"),
        Note(title: "Connected Note 3")
    ]
    
    LocalGraphView(
        centerNote: centerNote,
        connectedNotes: connectedNotes,
        appViewModel: appViewModel
    )
    .frame(width: 300, height: 200)
}