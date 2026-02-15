# 1. Schritte

Wie beginne ich mit diesem Projekt?

## Projekt aufsetzen

Siehe <doc:Requirements-de> zur Prüfung der Systemvoraussetzungen.

Klone diese Projekt lokal, gehe in das Verzeichnis und wechsle anschließend in den Branch `BareMetal`. Führe dann die Bashdatei `makeOS.sh` aus.



```bash
$ git clone https://github.com/bastie/SOS.git
Klone nach 'SOS'...
remote: Enumerating objects: 15, done.
remote: Counting objects: 100% (15/15), done.
remote: Compressing objects: 100% (13/13), done.
remote: Total 15 (delta 0), reused 15 (delta 0), pack-reused 0 (from 0)
Empfange Objekte: 100% (15/15), 5.74 KiB | 5.74 MiB/s, fertig.

$ cd SOS

$ git switch BareMetal
Branch 'BareMetal' folgt nun 'origin/BareMetal'.
Zu neuem Branch 'BareMetal' gewechselt

$ ./makeOS.sh 
STEP 1: compile Swift kernel...
Building for production...
/Users/bastie/Documents/workspace/temp/SOS/Sources/Kernel/RuntimeSupport.swift:21:2: warning: symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error
19 | 
20 | // Bad future bug is "Symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error"
21 | @_cdecl("free")
|  `- warning: symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error
22 | public func free(_ ptr: UnsafeMutableRawPointer?) {
23 |   // at this moment wie dont have something todo

Build complete! (0.45s)
STEP 2: compile Assembler bridge...
STEP 3: link all together ...
STEP 4: start QEMU...
Boot SOS Kernel
Shutdown system!

$
```

### Ergebnis

Sofern die Anzeige mit den beiden Zeilen `Boot SOS Kernel` und `Shutdown system!` endet, ist **dein System korrekt** aufgesetzt. 

*Was macht `makeOS.sh`?*

0. **Die Zielplattform**: Jedes Betriebssystem ist eigentlich nichts anderes als ein Program, welches BareMetal arbeitet. Damit SOS sich als BareMetal verhält, wird es zwar als für unseren ARM64 mit dem Triple `aarch64-none-none-elf` arbeiten, denn wir benötigen das *ELF* Format. Dieses Triple ist elementar und an verschiedenen Stellen hinterlegt.
1. **Embedded Swift**: Das Skript dient dazu zunächst mit SPM die Swift Quellen im Embedded Modus zu compilieren.
2. **Assembler**: Leider geht es nicht ganz ohne Assembler (bis ich dafür mehr Zeit habe) und das Skipt compiliert auch die notwendigen Assembler Quellen.
3. **Linken**: Für Hochsprachen-Entwickler ungewohnt, werden die Objektdateien nun zusammengesetzt. Eigentlich sind wir jetzt fertig.
4. **Testen**: Zum Test starten wir jetzt unser SOS (aus Assembler und Swift zusammengesetzt) mit `qemu`. Als Ergebnis sehen wir drei Ausgaben, da wir UART aktiviert haben.

    0. Die Ausgabe `Boot` kommt aus dem Assembler. Damit wissen wir, dass unser Assemblerteil erfolgreich ausgeführt wurde. 
    1. Die Ausgabe ` SOS Kernel` kommt bereits aus Embedded Swift. Das bedeutet, dass der Assembler die Steuerung erfolgreich an Swift übergeben hat und wir auch aus Swift Ausgaben auf UART absetzen konnten.
    2. Die Ausgabe `Shutdown system!` - eigentlich das wir anschließend wieder in unserer Shell sind und nicht in `qemu` verbleiben. Damit sehen wir, dass wir typsicher aus Swift den Shutdown auslösen konnten. Dies bedeutet auch, dass wir aus Swift (hier leider noch nötig) unser Assembler aufrufen konnten.

Wir müssen aber beachten, dass wir uns hier noch vollständig in der Qemu-Welt befinden und diese auch noch fest hinterlegt ist. Doch dies ist eine Aufgabe die hier gar nicht gelöst werden sollte.

## Nächste Schritte

Du kannst nun wieder in den `main` branch wechseln und dich ins Projektleben stürzen - Viel Erfolg! 
