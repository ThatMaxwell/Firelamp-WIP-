// The animated logo with a soft ember glow behind it.
import QtQuick
import QtQuick.Effects

Logo {
    id: gl
    property real glow: 0.5
    animated: true
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1; shadowColor: "#ff6a30"; shadowOpacity: gl.glow; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }
}
