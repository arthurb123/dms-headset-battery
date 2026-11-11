import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand("headsetBattery.depCheck", ["sh", "-c", "command -v headsetcontrol"], (stdout, exitCode) => {
            if (exitCode === 0) {
                done(null);
                return;
            }
            done({
                "title": "headsetcontrol is required",
                "details": "Install HeadsetControl (Arch: pacman -S headsetcontrol) and re-enable the Headset Battery plugin."
            });
        });
    }
}
