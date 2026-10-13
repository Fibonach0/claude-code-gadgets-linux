// En Wayland ninguna aplicación puede preguntar qué ventana tiene el foco; el
// escritorio sí lo sabe. Esta extensión lo publica por D-Bus, y nada más:
//   gdbus call --session --dest org.gnome.Shell \
//     --object-path /org/gnome/Shell/Extensions/ClaudeGadgets \
//     --method org.gnome.Shell.Extensions.ClaudeGadgets.Foco
// Devuelve el PID de la ventana activa, cuántas ventanas tiene ese proceso y
// su clase. Lo usa ~/.claude/hooks/avisar.sh.
import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const INTERFAZ = `<node>
  <interface name="org.gnome.Shell.Extensions.ClaudeGadgets">
    <method name="Foco">
      <arg type="i" direction="out" name="pid"/>
      <arg type="i" direction="out" name="ventanas"/>
      <arg type="s" direction="out" name="clase"/>
    </method>
  </interface>
</node>`;

export default class ClaudeGadgets extends Extension {
    enable() {
        this._dbus = Gio.DBusExportedObject.wrapJSObject(INTERFAZ, this);
        this._dbus.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/ClaudeGadgets');
    }

    disable() {
        this._dbus?.unexport();
        this._dbus = null;
    }

    Foco() {
        const ventana = global.display.focus_window;
        if (!ventana)
            return [0, 0, ''];
        const pid = ventana.get_pid();
        const ventanas = global.get_window_actors().filter(a =>
            a.meta_window.get_pid() === pid &&
            a.meta_window.get_window_type() === Meta.WindowType.NORMAL).length;
        return [pid, ventanas, ventana.get_wm_class() ?? ''];
    }
}
