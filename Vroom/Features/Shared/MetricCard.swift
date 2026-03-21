import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    var accent: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(accent.opacity(0.64))
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(accent)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RoadSpacing.regular)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                .strokeBorder(Color.white.opacity(0.09))
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.18))
            }
    }
}
